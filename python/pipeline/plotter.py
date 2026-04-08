from pathlib import Path

from matplotlib import pyplot as plt
from matplotlib import ticker
from sklearn.metrics import confusion_matrix
import seaborn as sns

from python.pipeline.pipeline_dataclasses import EvalResult, TrainingHistory

class Plotter:
    @staticmethod
    def plot_training_history(training_history: TrainingHistory, plot_path: Path):
        epochs = range(1, len(training_history.train_loss) + 1)

        fig, (ax_loss, ax_acc) = plt.subplots(1, 2, figsize=(12, 4))

        # Loss
        ax_loss.plot(epochs, training_history.train_loss, label="Train Loss", linewidth=2)
        ax_loss.plot(epochs, training_history.val_loss, label="Val Loss", linewidth=2, linestyle="--")
        ax_loss.set_title("Validation Loss")
        ax_loss.set_xlabel("Epoch")
        ax_loss.set_ylabel("Loss")
        ax_loss.legend()
        ax_loss.xaxis.set_major_locator(ticker.MaxNLocator(integer=True))

        # Accuracy
        ax_acc.plot(epochs, training_history.train_accuracy, label="Train Acc", linewidth=2)
        ax_acc.plot(epochs, training_history.val_accuracy, label="Val Acc", linewidth=2, linestyle="--")
        ax_acc.set_title("Validation Accuracy")
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
    def plot_confusion_matrix(eval_result: EvalResult, plot_path: Path, class_names: list[str] = ["nv", "mel"]):
        # var1
        labels = eval_result.y_true
        preds = eval_result.y_pred
        num_classes = len(class_names)
        
        cm = confusion_matrix(labels, preds, labels=list(range(num_classes)))
        cm_normalized = cm.astype(float) / cm.sum(axis=1, keepdims=True).clip(min=1)

        fig, (ax_raw, ax_norm) = plt.subplots(1, 2, figsize=(14, 5))

        sns.heatmap(cm, 
                    annot=True, fmt="d", cmap="Blues", ax=ax_raw, 
                    xticklabels=class_names, yticklabels=class_names)
        ax_raw.set_title("Confusion Matrix (Counts)")
        ax_raw.set_xlabel("Predicted Label")
        ax_raw.set_ylabel("True Label")

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