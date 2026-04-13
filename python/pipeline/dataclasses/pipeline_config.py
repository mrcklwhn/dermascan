from pathlib import Path
from typing import Annotated, Literal, Union
from pydantic import BaseModel, Field

from pipeline.dataclasses.enums import SplitType, ModelType, FilterType, MetricsType, AugmentationType, DatasetLoaderType
from pipeline.dataclasses.training_configs import AdamConfig, SGDConfig, ReduceLROnPlateauConfig

class TrainValTestSplitRatio(BaseModel, frozen=True):
    split_type: Literal[SplitType.RATIO] = SplitType.RATIO
    val_ratio: float
    test_ratio: float

class CustomSplitConfig(BaseModel, frozen=True):
    split_type: Literal[SplitType.CUSTOM] = SplitType.CUSTOM
    train_csv_path: Path
    val_csv_path: Path
    test_csv_path: Path

SplitConfig = Annotated[
    Union[TrainValTestSplitRatio, CustomSplitConfig],
    Field(discriminator='split_type')
]

class ModelConfig(BaseModel, frozen=True):
    model: ModelType
    filter_type: FilterType
    num_classes: int
    pretrained: bool = True
    freeze_weights: bool = True

OptimizerConfig = Union[AdamConfig, SGDConfig]

SchedulerConfig = Union[ReduceLROnPlateauConfig]

class TrainerConfig(BaseModel, frozen=True):
    batch_size: int
    num_epochs: int
    learning_rate: float
    optimizer: OptimizerConfig
    scheduler: SchedulerConfig

class BranchConfig(BaseModel, frozen=True):
    branch_id: str
    branch_model_config: ModelConfig
    trainer_config: TrainerConfig
    dataset_loader: DatasetLoaderType
    augmentation: list[AugmentationType]

class PipelineConfig(BaseModel, frozen=True):
    pipeline_id: str
    data_path: Path
    split_config: SplitConfig
    branches: list[BranchConfig]