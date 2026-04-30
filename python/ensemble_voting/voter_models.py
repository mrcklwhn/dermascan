"""
This file contains the two subclasses of EnsembleBaseModel: ResNetRGBModel and ResNetFilterModel.
Each subclass implements the specific logic for loading the model, processing the input data, and generating predictions for their respective types of voters (RGB images and filtered features).
"""

import torch
import torch.nn as nn
import torchvision.models as models
from torchvision import transforms
from PIL import Image
import numpy as np
from pathlib import Path

from ensemble_voting.voter import EnsembleBaseModel


class ResNetRGBModel(EnsembleBaseModel):
    def __init__(self, model_id: str, model_path: str):
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        super().__init__(model_id, model_path)

    def load_model(self):
        model = models.resnet18()
        model.fc = nn.Linear(model.fc.in_features, 2)
        model.load_state_dict(torch.load(self.model_path, map_location=self.device))
        model.to(self.device)
        model.eval()
        return model

    def load_image(self, image_info):
        img_path = image_info['image_path']
        img = Image.open(img_path).convert('RGB')
        tensor = transforms.functional.to_tensor(img)
        return tensor.unsqueeze(0) # Add batch dimension as pyTorch models expect (B, C, H, W)

    def predict_proba(self, image_tensor):
        with torch.no_grad():
            image_tensor = image_tensor.to(self.device)
            outputs = self.model(image_tensor)
            probs = torch.nn.functional.softmax(outputs, dim=1)
        return probs.squeeze(0).tolist()


class ResNetFilterModel(EnsembleBaseModel):
    def __init__(self, model_id: str, proj_dir: str, model_path: str, filter_name: str, input_channels: int):
        self.filter_name = filter_name
        self.in_channels = input_channels
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.proj_dir = Path(proj_dir)
        super().__init__(model_id, model_path)

    def load_model(self):
        model = models.resnet18()
        
        # Adapt first conv layer for current filter channels
        old_conv = model.conv1
        model.conv1 = nn.Conv2d(
            self.in_channels, 
            old_conv.out_channels, 
            kernel_size=old_conv.kernel_size, 
            stride=old_conv.stride, 
            padding=old_conv.padding, 
            bias=old_conv.bias
        )
        model.fc = nn.Linear(model.fc.in_features, 2)
        
        model.load_state_dict(torch.load(self.model_path, map_location=self.device))
        model.to(self.device)
        model.eval()
        return model

    def load_image(self, image_info):
        filtered_path = self.proj_dir / "data" / "filtered"
        # Load npy file directly using image_id and the filter_name folder
        filtered_features = np.load(filtered_path / self.filter_name / (image_info['image_id'] + ".npy"))
        
        # Convert to Tensor directly without transforms
        tensor = torch.from_numpy(filtered_features).float()
        
        if len(tensor.shape) == 3:
            # Add batch dimension for multi-channel filters like Gabor, GLCM
            tensor = tensor.unsqueeze(0)
        elif len(tensor.shape) == 2:
            # Add channel dimension and batch dimension for single-channel filters like LBP
            tensor = tensor.unsqueeze(0).unsqueeze(0)
            
        return tensor

    def predict_proba(self, image_tensor):
        with torch.no_grad():
            image_tensor = image_tensor.to(self.device)
            outputs = self.model(image_tensor)
            probs = torch.nn.functional.softmax(outputs, dim=1)
        return probs.squeeze(0).tolist() # 