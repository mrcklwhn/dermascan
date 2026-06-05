import mlflow
import mlflow.pytorch
import torch
from pathlib import Path

from pipeline.dataclasses.pipeline_config import BranchConfig
from pipeline.dataclasses.pipeline_runtime import MetricsResult

class MLFlowLogger:

    @staticmethod
    def log_branch_params(branch_config: BranchConfig):
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
        mlflow.log_param(key, value)