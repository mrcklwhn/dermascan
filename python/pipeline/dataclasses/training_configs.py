from pydantic import BaseModel
from typing import Tuple

from pipeline.dataclasses.enums import OptimizerType, SchedulerType

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


# Scheduler Configs with default values

class ReduceLROnPlateauConfig(BaseModel, frozen=True):
    scheduler_type: SchedulerType = SchedulerType.REDUCE_ON_PLATEAU
    mode: str = "min"
    factor: float = 0.1
    patience: int = 10
    min_lr: float = 0
    cooldown: int = 0