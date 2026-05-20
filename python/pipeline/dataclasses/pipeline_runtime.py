from enum import Enum

from dataclasses import dataclass
from pandas import DataFrame
import torch
from torch.utils.data import DataLoader
from pydantic import BaseModel

class ModelMode(Enum):
    TRAIN = "train"
    VAL = "val"
    TEST = "test"

@dataclass(frozen=True)
class TrainValTestSplit:
    train_df: DataFrame
    val_df: DataFrame
    test_df: DataFrame

@dataclass(frozen=True)
class TrainValTestDataLoaders:
    train_loader: DataLoader
    val_loader: DataLoader
    test_loader: DataLoader

class TrainingHistory(BaseModel, frozen=True):
    train_loss: list[float]
    val_loss: list[float]
    train_accuracy: list[float]
    val_accuracy: list[float]
    val_f1_macro: list[float]
    best_epoch: int

@dataclass(frozen=True)
class EvalResult:
    y_true: torch.Tensor
    y_pred: torch.Tensor
    y_prob: torch.Tensor

class MetricsResult(BaseModel, frozen=True):
    f1_macro: float
    f1_weighted: float
    accuracy: float
    precision: float
    sensitivity: float
    specificity: float
    auc: float
    mcc: float

class BranchResult(BaseModel, frozen=True):
    branch_id: str
    training_history: TrainingHistory
    metrics_result: MetricsResult