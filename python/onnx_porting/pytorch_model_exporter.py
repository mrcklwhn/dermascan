import torch
import torch.nn as nn
import onnx
import onnxruntime
from pathlib import Path
import numpy as np
import cv2
import torchvision.models as models
from enum import Enum

from dataset_manager import DatasetManager
from pipeline.dataclasses.enums import ModelType
from pipeline.training.model_archs import _modelArchRegistry


class PytorchModelExporter:
    def __init__(self, input_channels: int, output_channels: int):
        self.input_dim: int = input_channels
        self.output_dim: int = output_channels
        self.torch_model: nn.Module = None
        self.onnx_model: onnx.ModelProto = None

    def load_sample_tensor(
        self,
        sample_img: np.ndarray,
        target_shape: tuple[int, int] = (224, 224),
        normalize: bool = False,
    ) -> torch.Tensor:
        # Resize channel by channel for better dart compatibility
        # if sample_img.ndim == 3 and sample_img.shape[2] > 1:
        #     resized_channels = []
        #     for i in range(sample_img.shape[2]):
        #         # OpenCV handles 1-channel (2D) arrays perfectly
        #         ch_resized = cv2.resize(sample_img[:, :, i], target_shape, interpolation=cv2.INTER_LINEAR)
        #         resized_channels.append(ch_resized)
        #     sample_img = np.stack(resized_channels, axis=-1)
        # else:
        sample_img = cv2.resize(sample_img, target_shape, interpolation=cv2.INTER_NEAREST)

        # ensure channel-last 3D array
        if sample_img.ndim == 2:
            sample_img = np.expand_dims(sample_img, axis=-1)

        img_tensor = torch.from_numpy(sample_img).float() / 255.0
        img_tensor = img_tensor.permute(2, 0, 1).unsqueeze(0)

        if normalize and img_tensor.shape[1] == 3:
            # Use standard ImageNet normalization for 3-channel RGB
            mean = torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1)
            std = torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1)
            img_tensor = (img_tensor - mean) / std

        return img_tensor

    def load_sample_from_dataset(
        self,
        dataset: DatasetManager,
        filter_type: str = "rgb",
        target_shape: tuple[int, int] = (224, 224),
        normalize: bool = False,
    ) -> torch.Tensor:
        sample_row = dataset.df.sample(1).iloc[0]
        img_path = Path(dataset.data_dir) / sample_row["image_path"]
        sample_img = cv2.imread(str(img_path))
        sample_img = cv2.cvtColor(sample_img, cv2.COLOR_BGR2RGB)
        return self.load_sample_tensor(sample_img, target_shape, normalize)

    def build_torch_model(
        self, model_definition: nn.Module, pretrained_weights: Path = None, device: str = "cpu"
    ) -> nn.Module:
        self.torch_model = model_definition
        if pretrained_weights:
            state_dict = torch.load(pretrained_weights, map_location=device)
            if "state_dict" in state_dict:
                self.torch_model.load_state_dict(state_dict["state_dict"])
            else:
                self.torch_model.load_state_dict(state_dict)
        self.torch_model.eval()
        return self.torch_model

    def create_model(self, arch: ModelType, input_channels: int, num_classes: int = 2) -> nn.Module:
        """
        Create a model using the project's `_modelArchRegistry` configs. This ensures
        consistent input/output handling across training and export.

        Args:
            arch: `ModelType` enum or string value (e.g. 'resnet18' or ModelType.RESNET_18)
            input_channels: number of input channels
            num_classes: number of output channels/classes
        Returns:
            nn.Module
        """
        # Normalize to ModelType

        arch_cfg = _modelArchRegistry.get(arch)
        if arch_cfg is None:
            raise ValueError(f"Architecture not registered: {arch}")

        # Build uninitialized model (no pretrained weights by default)
        try:
            model = arch_cfg.builder(weights=None)
        except TypeError:
            # fallback if builder doesn't accept weights kwarg
            model = arch_cfg.builder()

        # Modify input layer if necessary
        if input_channels != 3:
            old_input = arch_cfg.get_input_layer(model)
            new_input = nn.Conv2d(
                in_channels=input_channels,
                out_channels=old_input.out_channels,
                kernel_size=old_input.kernel_size,
                stride=getattr(old_input, "stride", 1),
                padding=getattr(old_input, "padding", 0),
                bias=(old_input.bias is not None),
            )
            with torch.no_grad():
                nn.init.kaiming_normal_(new_input.weight, mode="fan_out", nonlinearity="relu")
            arch_cfg.set_input_layer(model, new_input)

        # Modify output layer for number of classes
        old_output = arch_cfg.get_output_layer(model)
        if isinstance(old_output, nn.Conv2d):
            new_output = nn.Conv2d(old_output.in_channels, num_classes, kernel_size=1)
        else:
            # assume Linear-like
            new_output = nn.Linear(old_output.in_features, num_classes)
        arch_cfg.set_output_layer(model, new_output)

        # Handle Inception AuxLogits
        if hasattr(model, "AuxLogits") and model.AuxLogits is not None:
            if hasattr(model.AuxLogits, "fc") and isinstance(model.AuxLogits.fc, nn.Linear):
                model.AuxLogits.fc = nn.Linear(model.AuxLogits.fc.in_features, num_classes)

        return model

    def build_model_from_arch(self, arch: ModelType, input_channels: int, num_classes: int = 2, pretrained_weights: Path = None, device: str = "cpu") -> nn.Module:
        """
        Convenience: create a model for `arch`, optionally load weights, set as current `torch_model` and return it.
        """
        model_def = self.create_model(arch, input_channels, num_classes)
        return self.build_torch_model(model_def, pretrained_weights=pretrained_weights, device=device)

    def export_torch_model(self, example_input: torch.Tensor, save_to: Path) -> onnx.ModelProto:
        torch.onnx.export(self.torch_model, (example_input,), str(save_to), dynamo=False)
        self.onnx_model = onnx.load(str(save_to))
        onnx.checker.check_model(self.onnx_model)
        return self.onnx_model

    def compare_model_outputs(
        self, sample_tensor: torch.Tensor, onnx_model_path: Path
    ) -> tuple[float, np.ndarray, np.ndarray]:
        torch_output = self.torch_model(sample_tensor).detach().numpy()

        ort_session = onnxruntime.InferenceSession(str(onnx_model_path), providers=["CPUExecutionProvider"])
        onnx_input = {ort_session.get_inputs()[0].name: sample_tensor.numpy(force=True)}
        onnx_output = ort_session.run(None, onnx_input)[0]

        distance_percent = (np.linalg.norm(torch_output - onnx_output) / (np.linalg.norm(torch_output) + 1e-8)) * 100

        return distance_percent, torch_output, onnx_output
