from pathlib import Path
from typing import Union, Optional
from pydantic import BaseModel, field_validator

from pipeline.dataclasses.enums import SplitType, ModelType, FilterType, AugmentationType, DatasetLoaderType, LossType
from pipeline.dataclasses.training_configs import AdamConfig, AdamWConfig, SGDConfig, ReduceLROnPlateauConfig, CosineAnnealingLRConfig

class TrainValTestSplitRatio(BaseModel, frozen=True):
    split_type: SplitType = SplitType.RATIO
    val_ratio: float
    test_ratio: float

class CustomSplitConfig(BaseModel, frozen=True):
    split_type: SplitType = SplitType.CUSTOM
    train_csv_path: Path
    val_csv_path: Path
    test_csv_path: Path

SplitConfig = Union[TrainValTestSplitRatio, CustomSplitConfig]

class ModelConfig(BaseModel, frozen=True):
    model_type: ModelType
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

OptimizerConfig = Union[AdamConfig, AdamWConfig, SGDConfig]

SchedulerConfig = Union[ReduceLROnPlateauConfig, CosineAnnealingLRConfig]

class TrainerConfig(BaseModel, frozen=True):
    batch_size: int
    num_epochs: int
    learning_rate: float
    loss_type: LossType = LossType.BCE_WITH_LOGITS
    pos_weight: float = 1.0 
    class_weights: Optional[tuple[float, float]] = None
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
    sampler_weights: Optional[tuple[float, float]] = None
    augmentation: Optional[AugmentationConfig] = None

class PipelineConfig(BaseModel, frozen=True):
    pipeline_id: str
    data_path: Path
    split_config: SplitConfig
    branches: list[BranchConfig]
    seed: int | None = None