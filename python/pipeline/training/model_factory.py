from torchvision import models
from torchvision.models import ResNet18_Weights, ResNet50_Weights, ResNet101_Weights
import torch
import torch.nn as nn

from pipeline.dataclasses.pipeline_config import ModelConfig
from pipeline.dataclasses.enums import ModelType, FilterType

class ModelFactory:
    """
    Factory class to build models based on ModelConfig. 
    It supports:
    - Building specified model architectures (e.g. ResNet18, ResNet50, ResNet101).
    - Modifying input layer to accommodate different number of channels based on filter type.
    - Modifying output layer to match the number of classes.
    - Optionally freezing weights for transfer learning.
    """
    _models: dict[ModelType, callable] = {
        ModelType.RESNET_18: (models.resnet18, ResNet18_Weights),
        ModelType.RESNET_50: (models.resnet50, ResNet50_Weights),
        ModelType.RESNET_101: (models.resnet101, ResNet101_Weights),
    }

    @classmethod
    def build(cls, model_config: ModelConfig) -> nn.Module:
        """
        Builds a model based on the provided ModelConfig.

        Args:
            model_config (ModelConfig): Configuration for the model to be built.
        Returns:
            nn.Module: The constructed model ready for training.
        """
        model_builder, weights_class = cls._models.get(model_config.model)

        # Default weights if pretrained, else None
        weights = weights_class.DEFAULT if model_config.pretrained else None
        model = model_builder(weights=weights)
        
        # Modify Input and Output layers, and freeze weights if specified
        model = cls._freeze_weights(model) if model_config.freeze_weights else model
        model = cls._modify_input_layer(model, model_config.filter_type.num_channels) if model_config.filter_type is not FilterType.RGB else model
        model = cls._modify_output_layer(model, model_config.num_classes)

        return model
    
    @staticmethod
    def _freeze_weights(model) -> nn.Module:
        """
        Freezes the weights of the model preventing them from being updated during training.

        Args:            
            model (nn.Module): The model whose weights are to be frozen.
        Returns:            
            nn.Module: The model with frozen weights.
        """
        for param in model.parameters():
            param.requires_grad = False
        return model
    
    @staticmethod
    def _modify_input_layer(model, num_input_channels) -> nn.Module:
        """
        Modifies the input layer of the model to accommodate a different number of input channels.

        Args:
            model (nn.Module): The model whose input layer is to be modified.
            num_input_channels (int): The number of input channels for the new input layer.
        Returns:
            nn.Module: The model with the modified input layer.
        """
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
    def _modify_output_layer(model, num_classes) -> nn.Module:
        """
        Modifies the output layer of the model to match the number of classes.

        Args:
            model (nn.Module): The model whose output layer is to be modified.
            num_classes (int): The number of classes for the new output layer.
        Returns:
            nn.Module: The model with the modified output layer.
        """
        # Modify output layer for number of classes (OUTPUT)
        model.fc = nn.Linear(model.fc.in_features, num_classes)
        return model