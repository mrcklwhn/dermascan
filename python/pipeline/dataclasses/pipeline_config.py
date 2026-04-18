from pathlib import Path
from typing import Annotated, Literal, Union
from pydantic import BaseModel, Field, field_validator

from pipeline.dataclasses.enums import SplitType, ModelType, FilterType, AugmentationType, DatasetLoaderType
from pipeline.dataclasses.training_configs import AdamConfig, SGDConfig, ReduceLROnPlateauConfig

class TrainValTestSplitRatio(BaseModel, frozen=True):
    split_type: Literal["ratio"] = SplitType.RATIO
    val_ratio: float
    test_ratio: float

class CustomSplitConfig(BaseModel, frozen=True):
    split_type: Literal["custom"] = SplitType.CUSTOM
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

    @field_validator("filter_type", mode="before")
    @classmethod
    def coerce_filter_type(cls, v):
        if isinstance(v, (list, tuple)):
            v = tuple(v)
            for member in FilterType:
                if member.value == v:
                    return member
            raise ValueError(f"No FilterType with value {v}")
        return v

OptimizerConfig = Union[AdamConfig, SGDConfig]

SchedulerConfig = Union[ReduceLROnPlateauConfig]

class TrainerConfig(BaseModel, frozen=True):
    batch_size: int
    num_epochs: int
    learning_rate: float
    criterion_weights: tuple[float, float] | None = (0.87, 0.13)
    optimizer: OptimizerConfig
    scheduler: SchedulerConfig

class AugmentationConfig(BaseModel, frozen=True):
    train: list[AugmentationType]
    val: list[AugmentationType]

class BranchConfig(BaseModel, frozen=True):
    branch_id: str
    branch_model_config: ModelConfig
    trainer_config: TrainerConfig
    dataset_loader: DatasetLoaderType
    augmentation: AugmentationConfig = None

class PipelineConfig(BaseModel, frozen=True):
    pipeline_id: str
    data_path: Path
    split_config: SplitConfig
    branches: list[BranchConfig]