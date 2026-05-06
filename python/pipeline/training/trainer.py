from pathlib import Path
import shutil
from tempfile import TemporaryDirectory
import torch
from torch.utils.data import DataLoader
import numpy as np
from sklearn.metrics import f1_score
from tqdm.auto import tqdm

from pipeline.dataclasses.pipeline_config import TrainerConfig, OptimizerConfig, SchedulerConfig
from pipeline.dataclasses.pipeline_runtime import EvalResult, TrainingHistory
from pipeline.dataclasses.enums import OptimizerType, SchedulerType

from pipeline.utils.mlflow_logger import MLFlowLogger


class Trainer:
    """
    Trainer class responsible for training and evaluating a PyTorch model based on the provided configuration.
    It handles:
    - Training the model for a specified number of epochs.
    - Validating the model on a validation dataset.
    - Saving the best model based on validation accuracy.
    - Testing the model on a test dataset and returning evaluation results.
    - Building the optimizer and scheduler based on the provided configurations.
    """

    def __init__(self, model: torch.nn.Module, trainer_config: TrainerConfig, device: torch.device, save_path: Path):
        self.model = model
        self.trainer_config = trainer_config

        self.device = device
        self.model = self.model.to(self.device)

        self.criterion = self._build_criterion(trainer_config.criterion_weights)
        self.optimizer = self._build_optimizer(trainer_config.optimizer)
        self.scheduler = self._build_scheduler(trainer_config.scheduler)
        self.model_save_path = save_path / "model.pt"

    def train(self, train_loader: DataLoader, val_loader: DataLoader) -> TrainingHistory:
        """
        Trains the model for a specified number of epochs, validating after each epoch.
        Saves the best model based on validation accuracy.

        Args:
            train_loader (DataLoader): DataLoader for the training dataset.
            val_loader (DataLoader): DataLoader for the validation dataset.
        Returns:
            TrainingHistory: Object containing training and validation loss, accuracy, and F1 macro score for each epoch.
        """
        epochs = self.trainer_config.num_epochs

        train_loss = []
        train_accuracy = []
        val_loss = []
        val_accuracy = []

        val_f1_macro = []
        best_f1_macro = 0.0

        with TemporaryDirectory() as temp_dir:
            temp_best_model_path = Path(temp_dir) / "best_model.pt"

            epoch_bar = tqdm(range(epochs), desc="Epochs", leave=True)
            for epoch in epoch_bar:
                epoch_train_loss, epoch_train_acc = self._train_epoch(train_loader)
                epoch_val_loss, epoch_val_acc, epoch_val_f1 = self._validate_epoch(val_loader)

                val_f1_macro.append(epoch_val_f1)

                tqdm.write(
                    f"Epoch {epoch + 1}/{epochs} - "
                    f"Train Loss: {epoch_train_loss:.4f}, Train Acc: {epoch_train_acc:.4f} - "
                    f"Val Loss: {epoch_val_loss:.4f}, Val Acc: {epoch_val_acc:.4f}, Val F1 Macro: {epoch_val_f1:.4f}"
                )
                
                MLFlowLogger.log_epoch(epoch_train_loss,
                                       epoch_train_acc,
                                       epoch_val_loss,
                                       epoch_val_acc,
                                       epoch_val_f1,
                                       self.optimizer.param_groups[0]["lr"],
                                       epoch)

                train_loss.append(epoch_train_loss)
                train_accuracy.append(epoch_train_acc)
                val_loss.append(epoch_val_loss)
                val_accuracy.append(epoch_val_acc)

                # Save the best model based on validation F1 macro score
                if epoch_val_f1 > best_f1_macro:
                    best_f1_macro = epoch_val_f1
                    torch.save(self.model.state_dict(), temp_best_model_path)

                self.scheduler.step(epoch_val_loss)

            if temp_best_model_path.exists():
                self.model_save_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(temp_best_model_path, self.model_save_path)

        return TrainingHistory(
            train_loss=train_loss,
            val_loss=val_loss,
            train_accuracy=train_accuracy,
            val_accuracy=val_accuracy,
            val_f1_macro=val_f1_macro,
        )

    def _train_epoch(self, train_loader: DataLoader) -> tuple[float, float]:
        """
        Trains the model for one epoch.

        Args:
            train_loader (DataLoader): DataLoader for the training dataset.
        Returns:
            tuple[float, float]: Training loss and accuracy for the epoch.
        """
        self.model.train()
        running_loss = 0.0
        running_corrects = 0

        for inputs, labels in tqdm(train_loader, desc="Training", leave=False):
            inputs = inputs.to(self.device, non_blocking=True)
            labels = labels.to(self.device, non_blocking=True)

            self.optimizer.zero_grad()

            outputs = self.model(inputs)
            _, preds = torch.max(outputs, 1)
            loss = self.criterion(outputs, labels)
            loss.backward()
            self.optimizer.step()

            running_loss += loss.item() * inputs.size(0)
            running_corrects += torch.sum(preds == labels.data).item()

            del inputs, labels, outputs, preds, loss

        n = len(train_loader.dataset)
        epoch_loss = running_loss / n
        epoch_acc = running_corrects / n

        torch.cuda.empty_cache()

        return epoch_loss, epoch_acc

    def _validate_epoch(self, val_loader: DataLoader) -> tuple[float, float, float]:
        """
        Validates the model for one epoch.

        Args:
            val_loader (DataLoader): DataLoader for the validation dataset.
        Returns:
            tuple[float, float, float]: Validation loss, accuracy, and F1 macro score for the epoch.
        """
        self.model.eval()
        running_loss = 0.0
        running_corrects = 0

        all_preds = []
        all_labels = []

        with torch.inference_mode():
            for inputs, labels in val_loader:
                inputs = inputs.to(self.device, non_blocking=True)
                labels = labels.to(self.device, non_blocking=True)

                outputs = self.model(inputs)
                _, preds = torch.max(outputs, 1)
                loss = self.criterion(outputs, labels)

                running_loss += loss.item() * inputs.size(0)
                running_corrects += torch.sum(preds == labels.data).item()

                all_preds.append(preds.cpu().numpy())
                all_labels.append(labels.cpu().numpy())
                            
                del inputs, labels, outputs, preds, loss

        n = len(val_loader.dataset)
        epoch_loss = running_loss / n
        epoch_acc = running_corrects / n
        f1 = f1_score(np.concatenate(all_labels), np.concatenate(all_preds), average="macro", zero_division=0)

        torch.cuda.empty_cache()

        return epoch_loss, epoch_acc, f1

    def test(self, test_loader: DataLoader) -> tuple[EvalResult, torch.nn.Module]:
        """
        Tests the model on the test dataset.

        Args:
            test_loader (DataLoader): DataLoader for the test dataset.
        Returns:
            EvalResult: Evaluation results containing true labels, predicted labels, and predicted probabilities.
        """
        self.model.load_state_dict(torch.load(self.model_save_path, weights_only=True, map_location=self.device))
        self.model.eval()

        all_preds = []
        all_labels = []
        all_probs = []

        with torch.inference_mode():
            for inputs, labels in test_loader:
                inputs = inputs.to(self.device, non_blocking=True)
                labels = labels.to(self.device, non_blocking=True)

                outputs = self.model(inputs)
                probs = torch.softmax(outputs, dim=1)
                _, preds = torch.max(probs, dim=1)

                all_preds.append(preds.cpu())
                all_labels.append(labels.cpu())
                all_probs.append(probs.cpu())

        result = EvalResult(
            y_true=torch.cat(all_labels).cpu(),
            y_pred=torch.cat(all_preds).cpu(),
            y_prob=torch.cat(all_probs).cpu(),
        )

        del all_preds, all_labels, all_probs
        torch.cuda.empty_cache()

        return result, self.model

    def _build_optimizer(self, optimizer_config: OptimizerConfig) -> torch.optim.Optimizer:
        """
        Builds the optimizer based on the provided configuration.

        Args:
            optimizer_config (OptimizerConfig): Configuration for the optimizer.
        Returns:
            torch.optim.Optimizer: Initialized optimizer.
        """
        match optimizer_config.optimizer_type:
            case OptimizerType.ADAM:
                return torch.optim.Adam(
                    self.model.parameters(),
                    lr=self.trainer_config.learning_rate,
                    weight_decay=optimizer_config.weight_decay,
                    betas=optimizer_config.betas,
                    eps=optimizer_config.eps,
                )
            case OptimizerType.SGD:
                return torch.optim.SGD(
                    self.model.parameters(),
                    lr=self.trainer_config.learning_rate,
                    momentum=optimizer_config.momentum,
                    weight_decay=optimizer_config.weight_decay,
                    nesterov=optimizer_config.nesterov,
                )

    def _build_scheduler(self, scheduler_config: SchedulerConfig) -> torch.optim.lr_scheduler.LRScheduler:
        """
        Builds the learning rate scheduler based on the provided configuration.

        Args:
            scheduler_config (SchedulerConfig): Configuration for the scheduler.
        Returns:
            torch.optim.lr_scheduler._LRScheduler: Initialized learning rate scheduler.
        """
        match scheduler_config.scheduler_type:
            case SchedulerType.REDUCE_ON_PLATEAU:
                return torch.optim.lr_scheduler.ReduceLROnPlateau(
                    self.optimizer,
                    mode=scheduler_config.mode,
                    factor=scheduler_config.factor,
                    patience=scheduler_config.patience,
                    min_lr=scheduler_config.min_lr,
                    cooldown=scheduler_config.cooldown,
                )

    def _build_criterion(self, weights=None) -> torch.nn.CrossEntropyLoss:
        """
        Builds the loss function criterion, optionally applying class weights.

        Args:
            weights (list or torch.Tensor): Class weights for the loss function.
        Returns:
            torch.Tensor: CrossEntropyLoss criterion with or without class weights.
        """
        if weights is None:
            return torch.nn.CrossEntropyLoss()

        tensor_weights = torch.tensor(weights, dtype=torch.float).to(self.device)
        return torch.nn.CrossEntropyLoss(weight=tensor_weights)