from pathlib import Path
import shutil
from tempfile import TemporaryDirectory

import torch
from torch.utils.data import DataLoader

from python.pipeline.json_dataclasses import OptimizerType, SchedulerType, TrainerConfig, OptimizerConfig, SchedulerConfig
from python.pipeline.pipeline_dataclasses import ModelMode, PredictionResult, TrainingHistory


class Trainer:
    def __init__(self, model: torch.nn.Module, trainer_config: TrainerConfig, device: torch.device, save_path: Path):
        self.model = model
        self.trainer_config = trainer_config
        self.device = device
        self.criterion = torch.nn.CrossEntropyLoss()
        self.optimizer = self._build_optimizer(trainer_config.optimizer)
        self.scheduler = self._build_scheduler(trainer_config.scheduler)
        self.save_path = save_path

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

                train_loss, train_acc = self._train_epoch(train_loader)
                val_loss, val_acc = self._validate_epoch(val_loader)

                train_loss.append(train_loss)
                train_accuracy.append(train_acc)
                val_loss.append(val_loss)
                val_accuracy.append(val_acc)

                if val_acc > best_acc:
                    best_acc = val_acc
                    torch.save(self.model.state_dict(), temp_best_model_path)
                
                self.scheduler.step(val_loss)

            if best_acc > 0.0:
                self.save_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(temp_best_model_path, self.save_path)

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


    def test(self, test_loader: DataLoader) -> PredictionResult:
        self.model.load_state_dict(torch.load(self.save_path, weights_only=True))
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

        return PredictionResult(
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