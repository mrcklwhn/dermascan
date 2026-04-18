import albumentations as A
from albumentations.pytorch import ToTensorV2

from pipeline.dataclasses.enums import AugmentationType, FilterType

class AugmentationBuilder:

    @staticmethod
    def build(filter_type: FilterType,augmentation_types: list[AugmentationType]) -> A.Compose:
        """
        Builds a list of augmentation transforms based on the specified augmentation types and filter type.

        Args:
            filter_type (FilterType): The type of filter to apply (only relevant for certain augmentations).
            augmentation_types (list[AugmentationType]): A list of augmentation types to apply.
        Returns:
            A.Compose: A composed augmentation transform to be applied to the dataset.
        """
        augmentations = []

        for aug_type in augmentation_types:
            match aug_type:
                case AugmentationType.RESIZE:
                    augmentations.append(A.Resize(height=224, width=224))
                case AugmentationType.CENTER_CROP:
                    augmentations.append(A.CenterCrop(height=224, width=224))
                case AugmentationType.RANDOM_RESIZE_CROP:
                    augmentations.append(A.RandomResizedCrop(size=(224, 224),
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

        augmentations.append(ToTensorV2())
        
        return A.Compose(augmentations)