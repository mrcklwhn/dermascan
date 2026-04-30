import torch
import torch.nn as nn
import onnx
import onnxruntime
from pathlib import Path
import numpy as np
import cv2

from dataset_manager import DatasetManager


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
        if sample_img.ndim == 3 and sample_img.shape[2] > 1:
            resized_channels = []
            for i in range(sample_img.shape[2]):
                # OpenCV handles 1-channel (2D) arrays perfectly
                ch_resized = cv2.resize(sample_img[:, :, i], target_shape, interpolation=cv2.INTER_NEAREST)
                resized_channels.append(ch_resized)
            sample_img = np.stack(resized_channels, axis=-1)
        else:
            sample_img = cv2.resize(sample_img, target_shape, interpolation=cv2.INTER_NEAREST)

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
