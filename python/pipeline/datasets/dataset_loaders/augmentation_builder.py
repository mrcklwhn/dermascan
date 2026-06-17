import albumentations as A
from albumentations.pytorch import ToTensorV2

from pipeline.training.model_archs import _modelArchRegistry

from pipeline.dataclasses.enums import AugmentationType, FilterType, ModelType

class AugmentationBuilder:
    """Builds model-size-aware Albumentations transforms for RGB and filtered feature inputs."""

    @staticmethod
    def build(filter_type: FilterType, model_type: ModelType, augmentation_types: list[AugmentationType], seed: int | None = None) -> A.Compose:
        """
        Builds a list of augmentation transforms based on the specified augmentation types and filter type.

        Args:
            filter_type (FilterType): The type of filter to apply (only relevant for certain augmentations).
            model_type (ModelType): The model architecture, used to determine the target image size.
            augmentation_types (list[AugmentationType]): A list of augmentation types to apply.
            seed (int | None): The seed for reproducibility.
        Returns:
            A.Compose: A composed augmentation transform to be applied to the dataset.
        """
        image_size = _modelArchRegistry.get(model_type).image_size

        augmentations = []

        for aug_type in augmentation_types:
            match aug_type:
                case AugmentationType.RESIZE:
                    augmentations.append(A.Resize(height=image_size, width=image_size))
                case AugmentationType.CENTER_CROP:
                    augmentations.append(A.CenterCrop(height=image_size, width=image_size))
                case AugmentationType.RANDOM_RESIZE_CROP:
                    augmentations.append(A.RandomResizedCrop(size=(image_size, image_size),
                                                            scale=(0.8, 1.0), 
                                                            ratio=(0.75, 1.33)))
                case AugmentationType.RANDOM_HORIZONTAL_FLIP:
                    augmentations.append(A.HorizontalFlip(p=0.5))
                case AugmentationType.RANDOM_VERTICAL_FLIP:
                    augmentations.append(A.VerticalFlip(p=0.5))
                case AugmentationType.RANDOM_ROTATION:
                    augmentations.append(A.Rotate(limit=30, p=0.5))
                case AugmentationType.COLOR_JITTER:
                    augmentations.append(A.ColorJitter(brightness=0.1,
                                                    contrast=0.1,
                                                    saturation=0.1,
                                                    hue=0.02,
                                                    p=0.3))
                case AugmentationType.RANDOM_ERASING:
                    augmentations.append(A.CoarseDropout(num_holes_range=(1, 8),
                                                        hole_height_range=(8, 32),
                                                        hole_width_range=(8, 32),
                                                        fill=0,
                                                        p=0.3))
                case _:
                    raise ValueError(f"Unsupported augmentation type: {aug_type}")

        if filter_type == FilterType.RGB:
            augmentations.append(A.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]))
        elif filter_type == FilterType.GABOR:
            augmentations.append(A.Normalize(mean=[0.5] * 40, std=[0.5] * 40, max_pixel_value=1.0))
        elif filter_type == FilterType.LBP:
            augmentations.append(A.Normalize(mean=[0.5] * 1, std=[0.5] * 1, max_pixel_value=1.0))
        elif filter_type == FilterType.GLCM:
            augmentations.append(A.Normalize(mean=[0.5] * 32, std=[0.5] * 32, max_pixel_value=1.0))

        augmentations.append(ToTensorV2())
        
        return A.Compose(augmentations, seed=seed)