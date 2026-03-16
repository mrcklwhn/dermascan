from python.pipeline.json_dataclasses import FilterType, ModelType, ModelConfig
from torchvision import models
import torch
import torch.nn as nn


class ModelFactory:
    _models: dict[ModelType, callable, any] = {
        ModelType.RESNET_18: models.resnet18,
        ModelType.RESNET_50: models.resnet50,
        ModelType.RESNET_101: models.resnet101,
    }

    @classmethod
    def build(cls, model_arch: ModelConfig):
        model_builder = cls._models.get(model_arch.model)

        # Default weights if pretrained, else None
        weights = model_builder.weights.DEFAULT if model_arch.pretrained else None
        model = model_builder(weights=weights)
        
        # Modify Input and Output layers, and freeze weights if specified
        model = cls._freeze_weights(model) if model_arch.freeze_weights else model
        model = cls._modify_input_layer(model, model_arch.filter_type.num_channels) if model_arch.filter_type is not FilterType.RGB else model
        model = cls._modify_output_layer(model, model_arch.num_classes)

        return model
    
    @staticmethod
    def _freeze_weights(model):
        for param in model.parameters():
            param.requires_grad = False
        return model
    
    @staticmethod
    def _modify_input_layer(model, num_input_channels):
        # Modify input layer for filter channels (INPUT)
        old_conv = model.conv1 # old weights
        # new input layer
        model.conv1 = nn.Conv2d(
            in_channels=num_input_channels,
            out_channels=old_conv.out_channels,
            kernel_size=old_conv.kernel_size,
            stride=old_conv.stride,
            padding=old_conv.padding,
            bias=old_conv.bias
        )
        # new input layer weights need to be initialized
        with torch.no_grad():
            # init all input channels with kaiming normal
            nn.init.kaiming_normal_(model.conv1.weight,
                                    mode='fan_out',
                                    nonlinearity='relu')
        return model
    
    @staticmethod
    def _modify_output_layer(model, num_classes):
        # Modify output layer for number of classes (OUTPUT)
        model.fc = nn.Linear(model.fc.in_features, num_classes)
        return model
    
