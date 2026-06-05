import mlflow
import mlflow.pytorch
import torch
from pathlib import Path

from pipeline.dataclasses.pipeline_config import BranchConfig
from pipeline.dataclasses.pipeline_runtime import MetricsResult

class MLFlowLogger:
    """
    MLFlowLogger is a utility class responsible for logging parameters, metrics, and artifacts to MLflow during the execution of a branch in the pipeline.
    It provides static methods for:
    - Logging branch parameters and configurations.
    - Logging evaluation metrics and artifacts after branch execution.
    - Logging epoch-level metrics during training.
    - Logging the model architecture and weights at specific steps during training.
    - Logging individual parameters as needed.
    """
    @staticmethod
    def log_branch_params(branch_config: BranchConfig):
        """
        Logs the parameters and configurations of a branch to MLflow.
        Args:
            branch_config (BranchConfig): The configuration of the branch to be logged.
        """
        mlflow.log_params({
            "branch_id": branch_config.branch_id,
            "model": branch_config.branch_model_config.model_type.value,
            "filter_type": branch_config.branch_model_config.filter_type.filter_name,
            "pretrained": branch_config.branch_model_config.pretrained,
            "freeze_weights": branch_config.branch_model_config.freeze_weights,
            "batch_size": branch_config.trainer_config.batch_size,
            "num_epochs": branch_config.trainer_config.num_epochs,
            "learning_rate": branch_config.trainer_config.learning_rate,
            "optimizer": branch_config.trainer_config.optimizer.optimizer_type.value,
            "scheduler": branch_config.trainer_config.scheduler.scheduler_type.value,
            "criterion_weights": branch_config.trainer_config.class_weights,
            "pos_weight": branch_config.trainer_config.pos_weight,
            "dataset_loader": branch_config.dataset_loader.value,
        })

        mlflow.log_dict(branch_config.model_dump(mode="json"), "configs/branch_config.json")

        mlflow.set_tags({
            "branch_id": branch_config.branch_id,
            "filter_type": branch_config.branch_model_config.filter_type.filter_name,
            "model_type": branch_config.branch_model_config.model_type.value
        })

    @staticmethod
    def log_branch_results(branch_run_path: Path, metrics_result: MetricsResult):
        """
        Logs the evaluation metrics and artifacts of a branch execution to MLflow.
        Args:
            branch_run_path (Path): The path to the branch run directory containing artifacts.
            metrics_result (MetricsResult): The evaluation metrics result to be logged.
        """
        mlflow.log_metrics(metrics_result.model_dump())

        mlflow.log_artifact(str(branch_run_path / "confusion_matrix.png"))
        mlflow.log_artifact(str(branch_run_path / "training_history.png"))
        mlflow.log_artifact(str(branch_run_path / "precision_recall_curve.png"))
        mlflow.log_artifact(str(branch_run_path / "roc_curve.png"))
        mlflow.log_artifact(str(branch_run_path / "confidence_distribution.png"))
        mlflow.log_artifact(str(branch_run_path / "training_history.json"))
        mlflow.log_artifact(str(branch_run_path / "metrics.json"))

    @staticmethod
    def log_epoch(epoch_train_loss: float, 
                  epoch_train_acc: float, 
                  epoch_val_loss: float, 
                  epoch_val_acc: float, 
                  epoch_val_f1: float, 
                  learning_rate: float, 
                  epoch: int,
                  best_epoch: int,
                  best_f1: float):
        """
        Logs epoch-level metrics during training to MLflow.
                
        Args:            
            epoch_train_loss (float): The average training loss for the epoch.
            epoch_train_acc (float): The average training accuracy for the epoch.
            epoch_val_loss (float): The average validation loss for the epoch.
            epoch_val_acc (float): The average validation accuracy for the epoch.
            epoch_val_f1 (float): The average validation F1 score for the epoch.
            learning_rate (float): The learning rate used during the epoch.
            epoch (int): The current epoch number.
            best_epoch (int): The epoch number with the best validation F1 score so far.
            best_f1 (float): The best validation F1 score achieved so far.
        """
        mlflow.log_metrics({
            "train_loss": epoch_train_loss,
            "train_acc": epoch_train_acc,
            "val_loss": epoch_val_loss,
            "val_acc": epoch_val_acc,
            "val_f1_macro": epoch_val_f1,
            "learning_rate": learning_rate,
            "best_epoch": best_epoch,
            "best_val_f1_macro": best_f1,
        }, step=epoch)

    @staticmethod
    def log_model(model: torch.nn.Module, name: str, sample_input: torch.Tensor, step: int):
        """
        Logs the model architecture and weights to MLflow at a specific step during training.
        Args:
            model (torch.nn.Module): The PyTorch model to be logged.
            name (str): The name under which the model will be logged in MLflow.
            sample_input (torch.Tensor): A sample input tensor for the model, used for input schema inference.
            step (int): The training step or epoch number at which the model is being logged.
        """
        model.eval()
        mlflow.pytorch.log_model(
            pytorch_model=model,
            name=name,
            serialization_format="pickle",
            input_example=sample_input,
            step = step,
        )

    @staticmethod
    def log_param(key: str, value: any):
        """Logs an individual parameter to MLflow.
        Args:
            key (str): The name of the parameter to log.
            value (any): The value of the parameter to log.
        """
        mlflow.log_param(key, value)