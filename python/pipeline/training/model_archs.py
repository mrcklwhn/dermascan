import torch.nn as nn
from torchvision import models
from torchvision.models import (
    ResNet18_Weights, ResNet50_Weights, ResNet101_Weights, 
    EfficientNet_V2_S_Weights,
    Inception_V3_Weights,
    SqueezeNet1_1_Weights,
    MobileNet_V3_Small_Weights, MobileNet_V3_Large_Weights)
from dataclasses import dataclass
from typing import Callable, Any

from pipeline.dataclasses.pipeline_config import ModelConfig
from pipeline.dataclasses.enums import ModelType, FilterType

@dataclass
class _ModelArchConfig:
    # builder
    builder: Callable
    weights: Any
    # different image_size depending on arch
    image_size: int
    # input
    get_input_layer: Callable[[nn.Module], nn.Conv2d]
    set_input_layer: Callable[[nn.Module, nn.Conv2d], None]
    # output
    get_output_layer: Callable[[nn.Module], nn.Module]
    set_output_layer: Callable[[nn.Module, nn.Linear], None]

# configs for supported model architectures with pretrained weights and layer accessors for input and output layers
# supported architectures:
# ResNet18, ResNet50, ResNet101, EfficientNet_V2_S, Inception_V3, SqueezeNet_1_1, MobileNet_V3_Small, MobileNet_V3_Large

def _resnet_config(builder, weights) -> _ModelArchConfig:
    def set_input_layer(m, l): m.conv1 = l
    def set_ouput_layer(m, l): m.fc = l
    return _ModelArchConfig(
        builder= builder,
        weights=weights,
        image_size=224,
        get_input_layer=lambda m: m.conv1,
        set_input_layer=set_input_layer,
        get_output_layer=lambda m: m.fc,
        set_output_layer=set_ouput_layer
    )

def _efficientnet_config(builder, weights) -> _ModelArchConfig:
    def set_input_layer(m, l): m.features[0][0] = l
    def set_ouput_layer(m, l): m.classifier[1] = l
    return _ModelArchConfig(
        builder=builder,
        weights=weights,
        image_size=384,
        get_input_layer=lambda m: m.features[0][0],
        set_input_layer=set_input_layer,
        get_output_layer=lambda m: m.classifier[1],
        set_output_layer=set_ouput_layer
    )

def _inception_config(builder, weights) -> _ModelArchConfig:
    def set_input_layer(m, l): m.Conv2d_1a_3x3.conv = l
    def set_output_layer(m, l): m.fc = l
    return _ModelArchConfig(
        builder=builder,
        weights=weights,
        image_size=299,
        get_input_layer=lambda m: m.Conv2d_1a_3x3.conv,
        set_input_layer=set_input_layer,
        get_output_layer=lambda m: m.fc,
        set_output_layer=set_output_layer
    )

def _squeezenet_config(builder, weights) -> _ModelArchConfig:
    def _build(weights):
        model = builder(weights=weights)
        model.classifier[2] = nn.Identity()  # ReLU deaktivieren
        return model
    
    def set_input_layer(m, l):  m.features[0] = l
    def set_output_layer(m, l): m.classifier[1] = l
    return _ModelArchConfig(
        builder=_build,
        weights=weights,
        image_size=224,
        get_input_layer=lambda m: m.features[0],
        set_input_layer=set_input_layer,
        get_output_layer=lambda m: m.classifier[1],
        set_output_layer=set_output_layer
    )

def _mobilenet_config(builder, weights) -> _ModelArchConfig:
    def set_input_layer(m, l): m.features[0][0] = l
    def set_ouput_layer(m, l): m.classifier[3] = l
    return _ModelArchConfig(
        builder=builder,
        weights=weights,
        image_size=224,
        get_input_layer=lambda m: m.features[0][0],
        set_input_layer=set_input_layer,
        get_output_layer=lambda m: m.classifier[3],
        set_output_layer=set_ouput_layer
    )

# registry for supported model architectures

_modelArchRegistry: dict[ModelType, _ModelArchConfig] = {
        # ──────────────────────────────────────────
        # ResNet
        # ──────────────────────────────────────────
        ModelType.RESNET_18: _resnet_config(models.resnet18, ResNet18_Weights),
        ModelType.RESNET_50: _resnet_config(models.resnet50, ResNet50_Weights),
        ModelType.RESNET_101: _resnet_config(models.resnet101, ResNet101_Weights),
        # ──────────────────────────────────────────
        # EfficientNet
        # ──────────────────────────────────────────
        ModelType.EFFICIENTNET_V2_S: _efficientnet_config(models.efficientnet_v2_s, EfficientNet_V2_S_Weights),
        # ──────────────────────────────────────────
        # Inception
        # ──────────────────────────────────────────
        ModelType.INCEPTION_V3: _inception_config(models.inception_v3, Inception_V3_Weights),
        # ──────────────────────────────────────────
        # SqueezeNet
        # ──────────────────────────────────────────
        ModelType.SQUEEZENET_1_1: _squeezenet_config(models.squeezenet1_1, SqueezeNet1_1_Weights),
        # ──────────────────────────────────────────
        # MobileNet
        # ──────────────────────────────────────────
        ModelType.MOBILENET_V3_SMALL: _mobilenet_config(models.mobilenet_v3_small, MobileNet_V3_Small_Weights),
        ModelType.MOBILENET_V3_LARGE: _mobilenet_config(models.mobilenet_v3_large, MobileNet_V3_Large_Weights),
}