from enum import Enum

from pandas import DataFrame
import torch
from torch.utils.data import DataLoader
from pydantic import BaseModel

class ModelMode(Enum):
    TRAIN = "train"
    VAL = "val"
    TEST = "test"

class MetricsType(Enum):
    ACCURACY = "accuracy"
    PRECISION = "precision"
    RECALL = "recall"
    AUC = "auc"
    F1_SCORE_MACRO = "f1_score_macro"
    F1_SCORE_WEIGHTED = "f1_score_weighted"
    SENSITIVITY = "sensitivity"
    SPECIFICITY = "specificity"
    



class TrainValTestSplit(BaseModel, frozen=True):
    train_ids: DataFrame
    val_ids: DataFrame
    test_ids: DataFrame

class TrainValTestDataLoaders(BaseModel, frozen=True):
    train_loader: DataLoader
    val_loader: DataLoader
    test_loader: DataLoader

class TrainingHistory(BaseModel, frozen=True):
    train_loss: list[float]
    val_loss: list[float]
    train_accuracy: list[float]
    val_accuracy: list[float]

class PredictionResult(BaseModel, frozen=True):
    y_true: torch.Tensor
    y_pred: torch.Tensor
    y_prob: torch.Tensor