from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import List

class ModelType(Enum):
    RESNET_18 = "resnet18"
    RESNET_50 = "resnet50"
    RESNET_101 = "resnet101"

class DatasetLoaderType(Enum):
    RGB = "rgb"
    FILTER = "filter"

class AugmentationType(Enum):
    RANDOM_HORIZONTAL_FLIP = "random_horizontal_flip"
    RANDOM_RESIZE_CROP = "random_resize_crop"
    RESIZE = "resize"
    CENTER_CROP = "center_crop"
    NORMALIZE = "normalize"

class MetricsType(Enum):
    ACCURACY = "accuracy"
    PRECISION = "precision"
    RECALL = "recall"
    F1_SCORE = "f1_score"
    AUC = "auc"

class FilterType(Enum):
    RGB = "rgb"
    GABOR = "gabor"
    GLCM = "glcm"
    LBP = "lbp"

@dataclass
class Training:
    batch_size: int
    num_epochs: int
    learning_rate: float
    optimizer: str
    scheduler: str

@dataclass
class ModelArch:
    model: ModelType
    num_input_channels: int
    num_classes: int
    pretrained: bool

@dataclass
class Branch:
    branch_id: str
    filter_type: FilterType
    model: ModelArch
    training: Training
    dataset_loader: DatasetLoaderType
    augmentation: List[AugmentationType]

@dataclass
class Pipeline:
    pipeline_id: str
    data_path: Path
    output_path: Path
    trai_test_split_ratio: float
    branches: List[Branch]
    eval: List[MetricsType]

# ids_df should be separate Pipeline Runner init param