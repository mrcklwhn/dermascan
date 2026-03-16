from enum import Enum
from pathlib import Path
from typing import List, Union, Tuple
from pydantic import BaseModel

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
    RGB = ("rgb", 3)
    GABOR = ("gabor", 40)
    GLCM = ("glcm", 32)
    LBP = ("lbp", 1)

    def __init__(self, filter_name: str, num_channels: int):
        self.filter_name = filter_name
        self.num_channels = num_channels

class OptimizerType(Enum):
    ADAM = "adam"
    SGD = "sgd"

class SchedulerType(Enum):
    REDUCE_ON_PLATEAU = "reduce_on_plateau"

class ModelConfig(BaseModel, frozen=True):
    model: ModelType
    filter_type: FilterType
    num_classes: int
    pretrained: bool = True
    freeze_weights: bool = True

# Optimizer Configs with default values

class AdamConfig(BaseModel, frozen=True):
    optimizer_type: OptimizerType = OptimizerType.ADAM
    weight_decay: float = 1e-4
    betas: Tuple[float, float] = (0.9, 0.999)
    eps: float = 1e-8


class SGDConfig(BaseModel, frozen=True):
    optimizer_type: OptimizerType = OptimizerType.SGD
    momentum: float = 0.9
    weight_decay: float = 1e-4
    nesterov: bool = True

OptimizerConfig = Union[AdamConfig, SGDConfig]

# Scheduler Configs with default values

class ReduceLROnPlateauConfig(BaseModel, frozen=True):
    scheduler_type: SchedulerType = SchedulerType.REDUCE_ON_PLATEAU
    mode: str = "min"
    factor: float = 0.1
    patience: int = 5
    min_lr: float = 1e-7
    cooldown: int = 0

SchedulerConfig = Union[ReduceLROnPlateauConfig]

class TrainerConfig(BaseModel, frozen=True):
    batch_size: int
    num_epochs: int
    learning_rate: float
    optimizer: OptimizerConfig
    scheduler: SchedulerConfig

class BranchConfig(BaseModel, frozen=True):
    branch_id: str
    model: ModelConfig
    trainer: TrainerConfig
    dataset_loader: DatasetLoaderType
    augmentation: List[AugmentationType]

class PipelineConfig(BaseModel, frozen=True):
    pipeline_id: str
    data_path: Path
    output_path: Path
    val_split_ratio: float
    test_split_ratio: float
    branches: List[BranchConfig]
    eval_metrics: List[MetricsType]

# ids_df should be separate Pipeline Runner init param