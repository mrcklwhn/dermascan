import torch
import torch.nn as nn
from torchvision import models
import onnx
from voter import EnsembleBaseModel
from pathlib import Path
import os

# --- Model Definitions (from notebook) ---

class ResNetRGBModel(nn.Module):
    def __init__(self):
        super(ResNetRGBModel, self).__init__()
        self.model = models.resnet18()
        self.model.fc = nn.Linear(self.model.fc.in_features, 2)

    def forward(self, x):
        return self.model(x)

class ResNetFilterModel(nn.Module):
    def __init__(self, input_channels):
        super(ResNetFilterModel, self).__init__()
        self.model = models.resnet18()

        # Adapt first conv layer for current filter channels
        old_conv = self.model.conv1
        self.model.conv1 = nn.Conv2d(
            input_channels,
            old_conv.out_channels,
            kernel_size=old_conv.kernel_size,
            stride=old_conv.stride,
            padding=old_conv.padding,
            bias=old_conv.bias
        )
        self.model.fc = nn.Linear(self.model.fc.in_features, 2)

    def forward(self, x):
        return self.model(x)

def export_model_to_onnx(model, input_shape, output_path):
    """
    Exports a PyTorch model to ONNX format.

    Args:
        model: The PyTorch model to export.
        input_shape: The shape of the input tensor (e.g., (1, 3, 224, 224)).
        output_path: The path to save the ONNX file.
    """
    model.eval()

    # Create a dummy input tensor
    dummy_input = torch.randn(*input_shape)

    try:
        torch.onnx.export(
            model,
            dummy_input,
            output_path,
            export_params=True,
            opset_version=11,
            do_constant_folding=True,
            input_names=['input'],
            output_names=['output'],
            dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
        )
        print(f"Successfully exported model to {output_path}")
    except Exception as e:
        print(f"Failed to export model: {e}")

def run_poc_export():
    # Define paths
    output_dir = Path("exported_models_poc")
    output_dir.mkdir(exist_ok=True)

    print("--- Starting Ensemble Voting PoC Export ---")

    # 1. Export RGB Model
    print("\nExporting RGB Model (ResNet18)...")
    rgb_model = ResNetRGBModel()
    # Note: normally we load weights here: rgb_model.load_state_dict(torch.load("path.pt"))
    # For PoC without weights, we use random initialization.
    export_model_to_onnx(rgb_model, (1, 3, 224, 224), output_dir / "resnet18_rgb.onnx")

    # 2. Export Gabor Filter Model (40 channels)
    print("\nExporting Gabor Filter Model (ResNet18, 40 channels)...")
    # According to prompt/context, Gabor model takes 40 channels
    gabor_model = ResNetFilterModel(input_channels=40)
    export_model_to_onnx(gabor_model, (1, 40, 224, 224), output_dir / "resnet18_gabor.onnx")

    # 3. Export LBP Filter Model (1 channel)
    print("\nExporting LBP Filter Model (ResNet18, 1 channel)...")
    lbp_model = ResNetFilterModel(input_channels=1)
    export_model_to_onnx(lbp_model, (1, 1, 224, 224), output_dir / "resnet18_lbp.onnx")

    # 4. Export GLCM Filter Model (32 channels)
    print("\nExporting GLCM Filter Model (ResNet18, 32 channels)...")
    # Prompt says GLCM is 32d matrix input
    glcm_model = ResNetFilterModel(input_channels=32)
    export_model_to_onnx(glcm_model, (1, 32, 224, 224), output_dir / "resnet18_glcm.onnx")

    print("\n--- Export Complete. Files are in 'exported_models_poc/' ---")

if __name__ == "__main__":
    run_poc_export()

