from pathlib import Path
import numpy as np
from matplotlib import pyplot as plt
from matplotlib import ticker
from sklearn.metrics import confusion_matrix, precision_recall_curve, roc_curve, auc
import seaborn as sns

from pipeline.dataclasses.pipeline_runtime import EvalResult, TrainingHistory

class Plotter:
    """
    Plotter class for visualizing training history and evaluation results.
    It provides methods to:
    - Plot training and validation loss and accuracy over epochs.
    - Plot confusion matrix for evaluation results.
    """
    @staticmethod
    def plot_training_history(training_history: TrainingHistory, plot_path: Path) -> None:
        """
        Plots the training and validation loss and accuracy on a graph over epochs.

        Args:
            training_history (TrainingHistory): Training history containing loss and accuracy values.
            plot_path (Path): Path to save the training history plot.
        """
        epochs = range(1, len(training_history.train_loss) + 1)

        fig, (ax_loss, ax_acc) = plt.subplots(1, 2, figsize=(12, 4))

        # Loss
        ax_loss.plot(epochs, training_history.train_loss, label="Train Loss", linewidth=2)
        ax_loss.plot(epochs, training_history.val_loss, label="Val Loss", linewidth=2, linestyle="--")
        ax_loss.set_title("Training and Validation Loss")
        ax_loss.set_xlabel("Epoch")
        ax_loss.set_ylabel("Loss")
        ax_loss.legend()
        ax_loss.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))

        # Accuracy + F1 Macro
        ax_acc.plot(epochs, training_history.train_accuracy, label="Train Acc", linewidth=2)
        ax_acc.plot(epochs, training_history.val_accuracy, label="Val Acc", linewidth=2, linestyle="--")
        ax_acc.plot(epochs, training_history.val_f1_macro, label="Val F1 Macro", linewidth=2, linestyle=":", color="green")
        ax_acc.set_title("Training and Validation Accuracy")
        ax_acc.set_xlabel("Epoch")
        ax_acc.set_ylabel("Accuracy")
        ax_acc.set_ylim(0, 1)
        ax_acc.legend()
        ax_acc.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))

        fig.tight_layout()
        plot_path = Path(plot_path) / "training_history.png"
        plt.savefig(plot_path, dpi=150, bbox_inches="tight")
        plt.close(fig)

    @staticmethod
    def plot_confusion_matrix(eval_result: EvalResult, plot_path: Path, class_names: list[str] = ["nv", "mel"]) -> None:
        """
        Plots the raw and normalized confusion matrix for the evaluation results.

        Args:
            eval_result (EvalResult): Evaluation results containing true labels, predicted labels, and predicted probabilities.
            plot_path (Path): Path to save the confusion matrix plot.
            class_names (list[str], optional): List of class names. Defaults to ["nv", "mel"].
        """
        labels = eval_result.y_true
        preds = eval_result.y_pred
        num_classes = len(class_names)
        
        cm = confusion_matrix(labels, preds, labels=list(range(num_classes)))
        cm_normalized = cm.astype(float) / cm.sum(axis=1, keepdims=True).clip(min=1)

        fig, (ax_raw, ax_norm) = plt.subplots(1, 2, figsize=(14, 5))

        # Raw counts confusion matrix
        sns.heatmap(cm, 
                    annot=True, fmt="d", cmap="Blues", ax=ax_raw, 
                    xticklabels=class_names, yticklabels=class_names)
        ax_raw.set_title("Confusion Matrix (Counts)")
        ax_raw.set_xlabel("Predicted Label")
        ax_raw.set_ylabel("True Label")

        # Normalized confusion matrix
        # Important for handling class imbalance and understanding model performance across classes
        # Per-class performance in percentage terms, which is more interpretable than raw counts, 
        # especially when classes are imbalanced
        sns.heatmap(cm_normalized,
                    annot=True, fmt=".2f", cmap="Blues", ax=ax_norm, 
                    xticklabels=class_names, yticklabels=class_names)
        ax_norm.set_title("Confusion Matrix (Normalized)")
        ax_norm.set_xlabel("Predicted Label")
        ax_norm.set_ylabel("True Label")

        fig.tight_layout()
        plot_path = Path(plot_path) / "confusion_matrix.png"
        plt.savefig(plot_path, dpi=150, bbox_inches="tight")
        plt.close(fig)

    @staticmethod
    def plot_precision_recall_curve(eval_result: EvalResult, plot_path: Path, class_names: list[str] = ["nv", "mel"]) -> None:
        """
        Plots the precision-recall curve for binary classification.

        Args:
            eval_result (EvalResult): Evaluation results containing true labels and predicted probabilities.
            plot_path (Path): Path to save the precision-recall curve plot.
            class_names (list[str], optional): List of class names. Defaults to ["nv", "mel"].
        """
        y_true = eval_result.y_true.numpy() if hasattr(eval_result.y_true, 'numpy') else np.array(eval_result.y_true)
        y_prob = eval_result.y_prob.numpy() if hasattr(eval_result.y_prob, 'numpy') else np.array(eval_result.y_prob)
        
        fig, ax = plt.subplots(figsize=(8, 6))
        
        # Handle binary and multi-class cases
        if y_prob.ndim == 2 and y_prob.shape[1] == 2:
            # Binary classification with 2D probabilities
            positive_probs = y_prob[:, 1]
        elif y_prob.ndim == 2 and y_prob.shape[1] == 1:
            # Binary classification with 1D probabilities
            positive_probs = y_prob[:, 0]
        else:
            # 1D probabilities
            positive_probs = y_prob.reshape(-1)
        
        precision, recall, _ = precision_recall_curve(y_true, positive_probs)
        pr_auc = auc(recall, precision)
        
        ax.plot(recall, precision, linewidth=2, label=f"PR Curve (AUC = {pr_auc:.3f})")
        ax.fill_between(recall, precision, alpha=0.2)
        ax.set_xlabel("Recall")
        ax.set_ylabel("Precision")
        ax.set_title("Precision-Recall Curve")
        ax.set_xlim([0, 1])
        ax.set_ylim([0, 1])
        ax.legend(loc="best")
        ax.grid(True, alpha=0.3)
        
        fig.tight_layout()
        plot_path = Path(plot_path) / "precision_recall_curve.png"
        plt.savefig(plot_path, dpi=150, bbox_inches="tight")
        plt.close(fig)

    @staticmethod
    def plot_roc_curve(eval_result: EvalResult, plot_path: Path, class_names: list[str] = ["nv", "mel"]) -> None:
        """
        Plots the ROC curve for binary classification.

        Args:
            eval_result (EvalResult): Evaluation results containing true labels and predicted probabilities.
            plot_path (Path): Path to save the ROC curve plot.
            class_names (list[str], optional): List of class names. Defaults to ["nv", "mel"].
        """
        y_true = eval_result.y_true.numpy() if hasattr(eval_result.y_true, 'numpy') else np.array(eval_result.y_true)
        y_prob = eval_result.y_prob.numpy() if hasattr(eval_result.y_prob, 'numpy') else np.array(eval_result.y_prob)
        
        fig, ax = plt.subplots(figsize=(8, 6))
        
        # Handle binary and multi-class cases
        if y_prob.ndim == 2 and y_prob.shape[1] == 2:
            # Binary classification with 2D probabilities
            positive_probs = y_prob[:, 1]
        elif y_prob.ndim == 2 and y_prob.shape[1] == 1:
            # Binary classification with 1D probabilities
            positive_probs = y_prob[:, 0]
        else:
            # 1D probabilities
            positive_probs = y_prob.reshape(-1)
        
        fpr, tpr, _ = roc_curve(y_true, positive_probs)
        roc_auc = auc(fpr, tpr)
        
        ax.plot(fpr, tpr, linewidth=2, label=f"ROC Curve (AUC = {roc_auc:.3f})")
        ax.plot([0, 1], [0, 1], linewidth=2, linestyle="--", color="gray", label="Random Classifier")
        ax.fill_between(fpr, tpr, alpha=0.2)
        ax.set_xlabel("False Positive Rate")
        ax.set_ylabel("True Positive Rate")
        ax.set_title("ROC Curve")
        ax.set_xlim([0, 1])
        ax.set_ylim([0, 1])
        ax.legend(loc="best")
        ax.grid(True, alpha=0.3)
        
        fig.tight_layout()
        plot_path = Path(plot_path) / "roc_curve.png"
        plt.savefig(plot_path, dpi=150, bbox_inches="tight")
        plt.close(fig)

    @staticmethod
    def plot_confidence_distribution(eval_result: EvalResult, plot_path: Path, class_names: list[str] = ["nv", "mel"]) -> None:
        """
        Plots the distribution of confidence scores for correct and incorrect predictions.

        Args:
            eval_result (EvalResult): Evaluation results containing predictions, true labels, and predicted probabilities.
            plot_path (Path): Path to save the confidence distribution plot.
            class_names (list[str], optional): List of class names. Defaults to ["nv", "mel"].
        """
        y_true = eval_result.y_true.numpy() if hasattr(eval_result.y_true, 'numpy') else np.array(eval_result.y_true)
        y_pred = eval_result.y_pred.numpy() if hasattr(eval_result.y_pred, 'numpy') else np.array(eval_result.y_pred)
        y_prob = eval_result.y_prob.numpy() if hasattr(eval_result.y_prob, 'numpy') else np.array(eval_result.y_prob)
        
        # Extract confidence for each prediction
        if y_prob.ndim == 2 and y_prob.shape[1] > 1:
            confidence = np.max(y_prob, axis=1)
        else:
            probs = y_prob.reshape(-1)
            confidence = np.maximum(probs, 1.0 - probs)
        
        # Determine correct vs incorrect predictions
        correct = (y_pred == y_true)
        
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Plot histograms for correct and incorrect predictions
        ax.hist(confidence[correct], bins=30, alpha=0.6, label="Correct", color="green", edgecolor="black")
        ax.hist(confidence[~correct], bins=30, alpha=0.6, label="Incorrect", color="red", edgecolor="black")
        
        ax.set_xlabel("Confidence Score")
        ax.set_ylabel("Frequency")
        ax.set_title("Distribution of Confidence Scores")
        ax.legend()
        ax.grid(True, alpha=0.3, axis="y")
        
        fig.tight_layout()
        plot_path = Path(plot_path) / "confidence_distribution.png"
        plt.savefig(plot_path, dpi=150, bbox_inches="tight")
        plt.close(fig)