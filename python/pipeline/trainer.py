from pathlib import Path
import shutil
from tempfile import TemporaryDirectory

import torch
from torch.utils.data import DataLoader

from pipeline.json_dataclasses import OptimizerType, SchedulerType, TrainerConfig, OptimizerConfig, SchedulerConfig
from pipeline.pipeline_dataclasses import EvalResult, TrainingHistory


class Trainer:
    def __init__(self, model: torch.nn.Module, trainer_config: TrainerConfig, device: torch.device, save_path: Path):
        self.model = model
        self.trainer_config = trainer_config
        
        self.device = device
        self.model = self.model.to(self.device)

        self.criterion = torch.nn.CrossEntropyLoss()
        self.optimizer = self._build_optimizer(trainer_config.optimizer)
        self.scheduler = self._build_scheduler(trainer_config.scheduler)
        self.model_save_path = save_path / "model.pt"

    def train(self, train_loader: DataLoader, val_loader: DataLoader) -> TrainingHistory:
        epochs = self.trainer_config.num_epochs
        best_acc = 0.0

        train_loss = []
        train_accuracy = []
        val_loss = []
        val_accuracy = []

        with TemporaryDirectory() as temp_dir:
            temp_best_model_path = Path(temp_dir) / "best_model.pt"

            for epoch in range(epochs):
                print(f"Epoch {epoch + 1}/{epochs}")
                print("-" * 10)

                epoch_train_loss, epoch_train_acc = self._train_epoch(train_loader)
                epoch_val_loss, epoch_val_acc = self._validate_epoch(val_loader)

                print(f"Train Loss: {epoch_train_loss:.4f} | Train Acc: {epoch_train_acc:.4f}")
                print(f"Val Loss: {epoch_val_loss:.4f} | Val Acc: {epoch_val_acc:.4f}\n")

                train_loss.append(epoch_train_loss)
                train_accuracy.append(epoch_train_acc)
                val_loss.append(epoch_val_loss)
                val_accuracy.append(epoch_val_acc)

                if epoch_val_acc > best_acc:
                    best_acc = epoch_val_acc
                    torch.save(self.model.state_dict(), temp_best_model_path)
                
                self.scheduler.step(epoch_val_loss)

            if temp_best_model_path.exists():
                self.model_save_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(temp_best_model_path, self.model_save_path)

        return TrainingHistory(
            train_loss=train_loss,
            val_loss=val_loss,
            train_accuracy=train_accuracy,
            val_accuracy=val_accuracy)

    def _train_epoch(self, train_loader: DataLoader) -> tuple[float, float]:
        self.model.train()
        running_loss = 0.0
        running_corrects = 0

        for inputs, labels in train_loader:
            inputs = inputs.to(self.device)
            labels = labels.to(self.device)
            
            self.optimizer.zero_grad()

            outputs = self.model(inputs)
            _, preds = torch.max(outputs, 1)
            loss = self.criterion(outputs, labels)
            loss.backward()
            self.optimizer.step()

            running_loss += loss.item() * inputs.size(0)
            running_corrects += torch.sum(preds == labels.data).item()

        n = len(train_loader.dataset)
        epoch_loss = running_loss / n
        epoch_acc = running_corrects / n

        return epoch_loss, epoch_acc
    
    def _validate_epoch(self, val_loader: DataLoader) -> tuple[float, float]:
        self.model.eval()
        running_loss = 0.0
        running_corrects = 0

        with torch.inference_mode():
            for inputs, labels in val_loader:
                inputs = inputs.to(self.device)
                labels = labels.to(self.device)

                outputs = self.model(inputs)
                _, preds = torch.max(outputs, 1)
                loss = self.criterion(outputs, labels)

                running_loss += loss.item() * inputs.size(0)
                running_corrects += torch.sum(preds == labels.data).item()

        n = len(val_loader.dataset)
        epoch_loss = running_loss / n
        epoch_acc = running_corrects / n

        return epoch_loss, epoch_acc


    def test(self, test_loader: DataLoader) -> EvalResult:
        self.model.load_state_dict(torch.load(self.model_save_path, weights_only=True, map_location=self.device))
        self.model.eval()

        all_preds = []
        all_labels = []
        all_probs = []

        with torch.inference_mode():
            for inputs, labels in test_loader:
                inputs = inputs.to(self.device)
                labels = labels.to(self.device)

                outputs = self.model(inputs)
                probs = torch.softmax(outputs, dim=1)
                preds = torch.argmax(probs, dim=1)

                all_preds.append(preds)
                all_labels.append(labels)
                all_probs.append(probs)

        return EvalResult(
            y_true=torch.cat(all_labels),
            y_pred=torch.cat(all_preds),
            y_prob=torch.cat(all_probs),
        )

    def _build_optimizer(self, optimizer_config: OptimizerConfig):
        match optimizer_config.optimizer_type:
            case OptimizerType.ADAM:
                return torch.optim.Adam(
                    self.model.parameters(), 
                    lr=self.trainer_config.learning_rate,
                    weight_decay=optimizer_config.weight_decay,
                    betas=optimizer_config.betas,
                    eps=optimizer_config.eps)
            case OptimizerType.SGD:
                return torch.optim.SGD(
                    self.model.parameters(), 
                    lr=self.trainer_config.learning_rate, 
                    momentum=optimizer_config.momentum,
                    weight_decay=optimizer_config.weight_decay,
                    nesterov=optimizer_config.nesterov)

    def _build_scheduler(self, scheduler_config: SchedulerConfig):
        match scheduler_config.scheduler_type:
            case SchedulerType.REDUCE_ON_PLATEAU:
                return torch.optim.lr_scheduler.ReduceLROnPlateau(
                    self.optimizer, 
                    mode=scheduler_config.mode, 
                    factor=scheduler_config.factor, 
                    patience=scheduler_config.patience,
                    min_lr=scheduler_config.min_lr,
                    cooldown=scheduler_config.cooldown)