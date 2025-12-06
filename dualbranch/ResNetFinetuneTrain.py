import torch
import torch.nn as nn
import torchvision.transforms as transforms
import torchvision.models as models
import torch.optim as optim
import os
import time
from tempfile import TemporaryDirectory
from dualbranch.ham10000_dataset import HAM10000Dataset
from torch.utils.data import DataLoader
import matplotlib.pyplot as plt
from sklearn.metrics import f1_score, roc_auc_score, accuracy_score, confusion_matrix
import numpy as np
import pandas as pd

class ResNetFineTuneTrainer:
    """
    This wrapper class facilitates fine-tuning of ResNet models (ResNet18, ResNet50, ResNet101)
    for skin lesion classification using the HAM10000 dataset.
    The class provides methods for setting up the model, data loaders, optimizer, and training process.

    :Workflow:
    1. Initialize the ResNetFineTuneTrainer class.
    2. Set the ResNet model using `set_model()`, specifying the model type and number of output classes.
    3. Set the data loaders using `set_data_loaders()`, providing training, validation, and test dataframes.
    4. Configure the optimizer using `configure_optimizer()`.
    5. (Optional) Configure the learning rate scheduler using `configure_scheduler()`.
    6. Set output paths for saving models and results using `set_output_paths()`.
    7. Train the model using the `train()` method.
    8. Evaluate the model using the `evaluate()` method.

    :Restrictions:
    Only melanoma vs melanocytic nevi classification is supported.
    """
    def __init__(self):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None
        self.supported_models = {'resnet18', 'resnet50', 'resnet101', }
        self.optimizer = None
        self.scheduler = None  # ReduceLROnPlateau, etc.
        self.train_df = None
        self.val_df = None
        self.test_df = None
        self.train_loader = None
        self.val_loader = None
        self.test_loader = None

        self.results = {}  # Store metrics
        # Initialize lists for history tracking
        self.history = {'train_loss': [], 'train_acc': [], 'val_loss': [], 'val_acc': []}  

    def _generate_id(self):
        """
        Generate a unique identifier for storing results and models.

        :return: Unique identifier string
        """

        model_name = type(self.model).__name__
        timestamp = time.strftime("%d%m%Y-%H%M%S")
        unique_id = f"{model_name}_{timestamp}"
        return unique_id
    
    def save_results_to_csv(self):
        """
        Save the results dictionary to a CSV file.
        Results consist of model_id, all metrics and hyperparameters.
        """

        results_df = pd.DataFrame([self.results])
        if os.path.exists(self.results_csv_path):
            existing_df = pd.read_csv(self.results_csv_path)
            results_df = pd.concat([existing_df, results_df], ignore_index=True)

        results_df.to_csv(self.results_csv_path, index=False)

    def set_model(self, model_name, pretrained=True):
        """
        Set up the ResNet model for fine-tuning or transfer learning.

        
        :param model_name: Name of the ResNet model (e.g., resnet18, resnet50)
        :param pretrained: Whether to use a pretrained model weights
        """

        if model_name not in self.supported_models:
            raise ValueError(f"Model {model_name} is not supported. Choose from {self.supported_models}")

        match model_name:
            case 'resnet18':
                self.model = models.resnet18(pretrained=pretrained)
            case 'resnet50':
                self.model = models.resnet50(pretrained=pretrained)
            case 'resnet101':
                self.model = models.resnet101(pretrained=pretrained)

        # Freeze all layers except the final fully connected layer
        for param in self.model.parameters():
            param.requires_grad = False

        # Modify the final layer for fine-tuning
        num_ftrs = self.model.fc.in_features
        self.model.fc = nn.Linear(num_ftrs, 2)
        self.model = self.model.to(self.device)

    def set_data_loaders(self, train_df, val_df, test_df):
        """
        Sets the data loaders from dataframes for training, validation, and testing.
        This will load the images from the 'image_path' column in the dataframes and the categorical labels from the 'lesion_idx' column.
        This will add augmentation and normalization for training data, and only normalization for validation and testing data.
        
        :param train_df: DataFrame for training data
        :param val_df: DataFrame for validation data
        :param test_df: DataFrame for testing data
        """

        data_transforms = {
            'train': transforms.Compose([
                transforms.RandomResizedCrop(224),
                transforms.RandomHorizontalFlip(),
                transforms.ToTensor(),
                transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
            ]),
            'val': transforms.Compose([
                transforms.Resize(256),
                transforms.CenterCrop(224),
                transforms.ToTensor(),
                transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
            ]),
        }

        train_dataset = HAM10000Dataset(train_df, transform=data_transforms['train'])
        val_dataset = HAM10000Dataset(val_df, transform=data_transforms['val'])
        test_dataset = HAM10000Dataset(test_df, transform=data_transforms['val'])

        self.train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True, num_workers=4)
        self.val_loader = DataLoader(val_dataset, batch_size=32, shuffle=False, num_workers=4)
        self.test_loader = DataLoader(test_dataset, batch_size=32, shuffle=False, num_workers=4)

    def configure_optimizer(self, optimizer_type='adam', **kwargs):
        """
        Configure the optimizer and learning rate scheduler.

        :param optimizer_type: Optimizer instance (e.g., Adam, SGD)
        :param kwargs: Additional arguments for the optimizer
        """
        if optimizer_type == 'adam':
            self.optimizer = optim.Adam(self.model.parameters(), **kwargs)
        elif optimizer_type == 'sgd':
            self.optimizer = optim.SGD(self.model.parameters(), **kwargs)
        else:
            raise ValueError(f"Unsupported optimizer type: {optimizer_type}")
        
        self.results['optimizer_type'] = optimizer_type
        self.results.update(kwargs) # Stores learning_rate, weight_decay etc.


    def configure_scheduler(self, scheduler_type='reduce_on_plateau', **kwargs):
        """
        Configure the learning rate scheduler.

        :param scheduler_type: Type of scheduler (e.g., 'reduce_on_plateau')
        :param kwargs: Additional arguments for the scheduler
        """
        if scheduler_type == 'reduce_on_plateau':
            self.scheduler = optim.lr_scheduler.ReduceLROnPlateau(self.optimizer, **kwargs)
        else:
            raise ValueError(f"Unsupported scheduler type: {scheduler_type}")

    def set_output_paths(self, model_save_dir="../results/models", results_csv_path="../results/results.csv", history_plot_dir="../results/plots"):
        """
        Set the output paths for saving model, results, and training history.

        :param model_save_dir: Directory to save the trained model
        :param results_csv_path: Path to save the results CSV
        :param history_plot_dir: Directory to save training history plots
        """
        # Create directories if they don't exist
        os.makedirs(model_save_dir, exist_ok=True)
        os.makedirs(history_plot_dir, exist_ok=True)

        self.model_save_dir = model_save_dir
        self.results_csv_path = results_csv_path
        self.history_plot_dir = history_plot_dir


    def train(self, epochs=50, metrics=None):
        """
        Train the model.

        :param epochs: Number of training epochs
        :param metrics: List of metrics to evaluate during training
        """
        since = time.time()
        self.history = {'train_loss': [], 'train_acc': [], 'val_loss': [], 'val_acc': []}
        
        # Clear previous evaluation metrics to prevent stale data in CSV
        keys_to_keep = ['optimizer_type', 'learning_rate', 'weight_decay'] # and other config keys
        self.results = {k: v for k, v in self.results.items() if k in keys_to_keep}

        # Check if model, optimizer, and data loaders are set
        if self.model is None:
            raise ValueError("Model must be set before training.")
        elif self.optimizer is None:
            raise ValueError("Optimizer must be set before training.")
        elif self.train_loader is None or self.val_loader is None:
            raise ValueError("Data loaders must be set before training.")

        with TemporaryDirectory() as temp_dir:
            best_model_params_path = os.path.join(temp_dir, 'best_model.pt')
            torch.save(self.model.state_dict(), best_model_params_path)
            best_acc = 0.0

            for epoch in range(epochs):
                print(f'Epoch {epoch + 1}/{epochs}')
                print('-' * 10)

                val_loss_value = 0.0

                # Each epoch has a training and validation phase
                for phase in ['train', 'val']:
                    if phase == 'train':
                        self.model.train()  # Set model to training mode
                        data_loader = self.train_loader
                    else:
                        self.model.eval()   # Set model to evaluate mode
                        data_loader = self.val_loader

                    running_loss = 0.0
                    running_corrects = 0

                    # Iterate over data.
                    for inputs, labels in data_loader:
                        inputs = inputs.to(self.device)
                        labels = labels.to(self.device)

                        # Zero the parameter gradients
                        self.optimizer.zero_grad()

                        # Forward
                        with torch.set_grad_enabled(phase == 'train'):
                            outputs = self.model(inputs)
                            _, preds = torch.max(outputs, 1)
                            loss = nn.CrossEntropyLoss()(outputs, labels)

                            # Backward + optimize only if in training phase
                            if phase == 'train':
                                loss.backward()
                                self.optimizer.step()

                        # Statistics
                        running_loss += loss.item() * inputs.size(0)
                        running_corrects += torch.sum(preds == labels.data)

                    epoch_loss = running_loss / len(data_loader.dataset)
                    epoch_acc = running_corrects.double() / len(data_loader.dataset)

                    if phase == 'val':
                        val_loss_value = epoch_loss

                    # Record history
                    if phase == 'train':
                        self.history['train_loss'].append(epoch_loss)
                        self.history['train_acc'].append(epoch_acc.item())
                    else:
                        self.history['val_loss'].append(epoch_loss)
                        self.history['val_acc'].append(epoch_acc.item())

                    print(f'{phase} Loss: {epoch_loss:.4f} Acc: {epoch_acc:.4f}')

                    # Deep copy the model
                    if phase == 'val' and epoch_acc > best_acc:
                        best_acc = epoch_acc
                        torch.save(self.model.state_dict(), best_model_params_path)

                # Step the scheduler if provided
                if self.scheduler:
                    self.scheduler.step(val_loss_value)

            time_elapsed = time.time() - since
            print(f'Training complete in {time_elapsed // 60:.0f}m {time_elapsed % 60:.0f}s')
            print(f'Best val Acc: {best_acc:.4f}')

            # Store best model in model_save_dir
            model_id = self._generate_id()
            model_save_path = os.path.join(self.model_save_dir, f"{model_id}.pt")
            torch.save(torch.load(best_model_params_path), model_save_path)

            # Store best model data and history in results
            self.results['model_id'] = model_id
            self.results['best_val_acc'] = best_acc.item()

            # Store training history plots
            plt.figure(figsize=(12, 4))
            plt.subplot(1, 2, 1)
            plt.plot(self.history['train_loss'], label='Train Loss')
            plt.plot(self.history['val_loss'], label='Val Loss')
            plt.xlabel('Epoch')
            plt.ylabel('Loss')
            plt.legend()
            plt.subplot(1, 2, 2)
            plt.plot(self.history['train_acc'], label='Train Acc')
            plt.plot(self.history['val_acc'], label='Val Acc')
            plt.xlabel('Epoch')
            plt.ylabel('Accuracy')
            plt.legend()

            plot_path = os.path.join(self.history_plot_dir, f"{model_id}_history.png")
            plt.savefig(plot_path)
            plt.close()

            # Load best model weights
            self.model.load_state_dict(torch.load(best_model_params_path))
            self.model.to(self.device)

    def evaluate(self):
        """
        Evaluate the model on a given data loader with metrics F1, AUC, accuracy.
        """

        if self.model is None:
            raise ValueError("Model must be set before evaluation.")
        if self.test_loader is None:
            raise ValueError("Test data loader must be set before evaluation.")
        

        self.model.eval()
        all_preds = []
        all_labels = []
        all_probs = []

        with torch.no_grad():
            for inputs, labels in self.test_loader:
                inputs = inputs.to(self.device)
                labels = labels.to(self.device)

                outputs = self.model(inputs)
                _, preds = torch.max(outputs, 1)

                probs = nn.functional.softmax(outputs, dim=1)

                all_preds.extend(preds.cpu().numpy())
                all_labels.extend(labels.cpu().numpy())
                all_probs.extend(probs.cpu().numpy())


        # Calculate metrics
        f1 = f1_score(all_labels, all_preds, average='weighted')
        accuracy = accuracy_score(all_labels, all_preds)
        tn, fp, fn, tp = confusion_matrix(all_labels, all_preds, labels=[0, 1]).ravel()
        
        sensitivity = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        specificity = tn / (tn + fp) if (tn + fp) > 0 else 0.0

        try:
            # FIX: Use probabilities of the positive class (column 1) for binary AUC
            all_probs_np = np.array(all_probs)
            if all_probs_np.shape[1] == 2:
                auc = roc_auc_score(all_labels, all_probs_np[:, 1])
            else:
                # Fallback for actual multiclass
                auc = roc_auc_score(all_labels, all_probs_np, multi_class='ovr')
        except ValueError:
            auc = float('nan')

        print(f'Evaluation results - F1: {f1:.4f}, AUC: {auc:.4f}, Accuracy: {accuracy:.4f}, Sensitivity: {sensitivity:.4f}, Specificity: {specificity:.4f}')

        # Store results
        self.results.update({
            'f1_score': f1,
            'auc': auc,
            'accuracy': accuracy,
            'sensitivity': sensitivity,
            'specificity': specificity,
        })