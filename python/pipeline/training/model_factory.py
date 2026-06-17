import torch
import torch.nn as nn

from pipeline.training.model_archs import _modelArchRegistry

from pipeline.dataclasses.pipeline_config import ModelConfig
from pipeline.dataclasses.enums import FilterType

class ModelFactory:
    """
    Factory class to build models based on ModelConfig. 
    It supports:
    - Building registered Torchvision model architectures.
    - Modifying input layer to accommodate different number of channels based on filter type.
    - Modifying output layer to match the number of classes.
    - Optionally freezing weights for transfer learning.
    """
    @classmethod
    def build(cls, model_config: ModelConfig, seed: int | None = None) -> nn.Module:
        """
        Builds a model based on the provided ModelConfig.

        Args:
            model_config (ModelConfig): Configuration for the model to be built.
            seed (int | None): The seed for reproducibility when modifying the input layer. Defaults to None.
        Returns:
            nn.Module: The constructed model ready for training.
        """
        model_arch = _modelArchRegistry.get(model_config.model_type)

        # Default weights if pretrained, else None
        weights = model_arch.weights.DEFAULT if model_config.pretrained else None
        model = model_arch.builder(weights=weights)
        
        # Modify Input and Output layers, and freeze weights if specified
        model = cls._freeze_weights(model) if model_config.freeze_weights else model
        model = cls._modify_input_layer(model, model_arch, model_config.filter_type.num_channels, seed=seed) if model_config.filter_type is not FilterType.RGB else model
        model = cls._modify_output_layer(model, model_arch, model_config.num_classes)

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
    def _modify_input_layer(model, model_arch, num_input_channels, seed: int | None = None) -> nn.Module:
        """
        Modifies the input layer of the model to accommodate a different number of input channels.

        Args:
            model (nn.Module): The model whose input layer is to be modified.
            model_arch (_ModelArchConfig): The architecture configuration for the model, containing layer accessors.
            num_input_channels (int): The number of input channels for the new input layer.
            seed (int | None): The seed for reproducibility.
        Returns:
            nn.Module: The model with the modified input layer.
        """
        # Modify input layer for filter channels (INPUT)
        old_input = model_arch.get_input_layer(model) # old weights
        # new input layer
        new_input = nn.Conv2d(
            in_channels=num_input_channels,
            out_channels=old_input.out_channels,
            kernel_size=old_input.kernel_size,
            stride=old_input.stride,
            padding=old_input.padding,
            bias=old_input.bias is not None
        )
        # new input layer weights need to be initialized
        with torch.no_grad():
            generator = None
            if seed is not None:
                generator = torch.Generator()
                generator.manual_seed(seed)
            # init all input channels with kaiming normal
            nn.init.kaiming_normal_(new_input.weight,
                                    mode='fan_out',
                                    nonlinearity='relu',
                                    generator=generator)
        model_arch.set_input_layer(model, new_input)
        return model
    
    @staticmethod
    def _modify_output_layer(model, model_arch, num_classes) -> nn.Module:
        """
        Modifies the output layer of the model to match the number of classes.

        Args:
            model (nn.Module): The model whose output layer is to be modified.
            model_arch (_ModelArchConfig): The architecture configuration for the model, containing layer accessors.
            num_classes (int): The number of classes for the new output layer.
        Returns:
            nn.Module: The model with the modified output layer.
        """
        # Modify output layer for number of classes (OUTPUT)
        old_output = model_arch.get_output_layer(model)
        if isinstance(old_output, nn.Conv2d):
            # SqueezeNet — Conv2d(512, num_classes, kernel_size=1)
            new_output = nn.Conv2d(old_output.in_channels, num_classes, kernel_size=1)
        else:
            # alle anderen — nn.Linear
            new_output = nn.Linear(old_output.in_features, num_classes)
        model_arch.set_output_layer(model, new_output)

        # for Inception aux_logits-Layer
        if hasattr(model, 'AuxLogits') and model.AuxLogits is not None:
            model.AuxLogits.fc = nn.Linear(model.AuxLogits.fc.in_features, num_classes)
        return model