from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List, Mapping, Optional, Tuple

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import (
    accuracy_score,
    average_precision_score,
    balanced_accuracy_score,
    confusion_matrix,
    f1_score,
    precision_recall_curve,
    precision_score,
    roc_auc_score,
    roc_curve,
)

from ensemble_voting.voter import EnsembleOutput, EnsembleVoter


# ===============================
# Helper functions for metrics and plotting
# ===============================

def _extract_binary_cm_values(cm: np.ndarray) -> Tuple[int, int, int, int]:
    if cm.shape == (2, 2):
        tn, fp, fn, tp = cm.ravel()
        return int(tn), int(fp), int(fn), int(tp)

    if cm.size == 1:
        only_value = int(cm.ravel()[0])
        return only_value, 0, 0, 0

    padded = np.zeros((2, 2), dtype=int)
    padded[: cm.shape[0], : cm.shape[1]] = cm
    tn, fp, fn, tp = padded.ravel()
    return int(tn), int(fp), int(fn), int(tp)

def plot_model_diagnostics(model_name: str, artifacts: Dict[str, Any], output_dir: Path | str, labels: List[str]) -> None:
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))

    axes[0].plot(artifacts["fpr"], artifacts["tpr"], linewidth=2)
    axes[0].plot([0, 1], [0, 1], color="black", linestyle=":", linewidth=1)
    axes[0].set_title("ROC Curve")
    axes[0].set_xlabel("False Positive Rate")
    axes[0].set_ylabel("True Positive Rate")
    axes[0].grid(alpha=0.3)

    axes[1].plot(artifacts["recall"], artifacts["precision"], linewidth=2)
    axes[1].set_title("PR Curve")
    axes[1].set_xlabel("Recall")
    axes[1].set_ylabel("Precision")
    axes[1].grid(alpha=0.3)

    confusion = np.asarray(artifacts["confusion_matrix"], dtype=int)
    tn, fp, fn, tp = _extract_binary_cm_values(confusion)
    heatmap_matrix = np.array([[tn, fp], [fn, tp]], dtype=int)
    image = axes[2].imshow(heatmap_matrix, cmap="Blues")
    axes[2].set_title("Confusion Matrix")
    axes[2].set_xlabel("Predicted Label")
    axes[2].set_ylabel("True Label")
    axes[2].set_xticks([0, 1], labels=labels)
    axes[2].set_yticks([0, 1], labels=labels)

    confusion_labels = [["TN", "FP"], ["FN", "TP"]]
    for row_index in range(2):
        for col_index in range(2):
            value = heatmap_matrix[row_index, col_index]
            label = confusion_labels[row_index][col_index]
            axes[2].text(
                col_index,
                row_index,
                f"{label}\n{value}",
                ha="center",
                va="center",
                color="black",
                fontsize=10,
                fontweight="bold",
            )

    fig.colorbar(image, ax=axes[2], fraction=0.046, pad=0.04)
    fig.suptitle(f"Diagnostics: {model_name}", fontsize=14)
    fig.tight_layout(rect=[0, 0.05, 1, 0.92])

    filename = f"model_{model_name}_diagnostics.png"
    fig.savefig(output_dir / filename, dpi=150)
    plt.close(fig)


def plot_model_confidence_boxplot(model_name: str, artifacts: Dict[str, Any], output_dir: Path | str, labels: List[str]) -> None:
    y_pred = np.asarray(artifacts["y_pred"], dtype=int)
    y_score = np.asarray(artifacts["y_score"], dtype=float)

    label_names = [labels[i] if i < len(labels) else str(i) for i in [0, 1]]
    confidence_distributions: List[np.ndarray] = []
    tick_labels: List[str] = []
    medians: List[float] = []

    for label_idx, label_name in enumerate(label_names):
        mask = y_pred == label_idx
        confidences = y_score[mask] if label_idx == 1 else (1.0 - y_score[mask])
        confidence_distributions.append(confidences if confidences.size > 0 else np.array([np.nan]))
        tick_labels.append(f"{label_name}\n(n={int(mask.sum())})")
        medians.append(float(np.nanmedian(confidences)) if confidences.size > 0 else float("nan"))

    fig, ax = plt.subplots(figsize=(7, 5))
    ax.boxplot(
        confidence_distributions,
        tick_labels=tick_labels,
        showmeans=True,
        widths=0.55,
        patch_artist=True,
    )
    ax.set_title("Prediction Confidence by Predicted Label")
    ax.set_ylabel("Confidence Score")
    ax.set_ylim(0.0, 1.0)
    ax.grid(alpha=0.3, axis="y")

    fig.suptitle(f"Confidence Boxplot: {model_name}", fontsize=13)
    fig.tight_layout(rect=[0, 0, 1, 0.95])

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    filename = f"model_{model_name}_confidence_boxplot.png"
    fig.savefig(output_path / filename, dpi=150)
    plt.close(fig)



# ===============================
# Main class for ensemble analysis
# ===============================

class EnsembleAnalyser:
    def __init__(
        self,
        label_column: str = "lesion_idx",
        positive_label: int = 1,
        labels: List[str] = ["nv", "mel"],
    ) -> None:
        self.label_column = label_column
        self.positive_label = positive_label
        self.labels = labels

    def compare_voters(
        self,
        voters: Mapping[str, EnsembleVoter],
        data_df: pd.DataFrame,
        label_column: Optional[str] = None,
        output_dir: Optional[Path | str] = None,
    ) -> Dict[str, Any]:
        """
        Evaluate multiple voters on a dataset and return only per-model metrics and artifacts.

        Args:
            voters: Mapping of model names to EnsembleVoter instances.
            data_df: Evaluation DataFrame.
            label_column: Label column name in data_df.
            output_dir: Optional output directory for per-model diagnostic plots.

        Returns:
            dict:
                - "summary_df": DataFrame with one row of metrics per model.
                - "artifacts_by_model": Mapping of model names to artifacts.
        """

        active_label_column = label_column or self.label_column

        if active_label_column not in data_df.columns:
            raise ValueError(f"Missing label column '{active_label_column}' in evaluation dataframe")

        y_true = data_df[active_label_column].astype(int).to_numpy()

        summary_rows: List[Dict[str, Any]] = []
        artifacts_by_model: Dict[str, Dict[str, Any]] = {}

        for idx, (model_name, voter) in enumerate(voters.items()):
            print(f"Evaluating model {idx + 1}/{len(voters)}: {model_name}")
            y_preds, y_scores, outputs = self._run_voter(voter=voter, evaluation_df=data_df)
            metrics, artifacts = self._compute_metrics_and_artifacts(
                y_true=y_true,
                y_pred=y_preds,
                y_score=y_scores,
            )

            metrics["model_name"] = model_name
            artifacts["model_name"] = model_name
            artifacts["outputs"] = outputs

            summary_rows.append(metrics)
            artifacts_by_model[model_name] = artifacts

        summary_df = pd.DataFrame(summary_rows)

        if output_dir is not None:
            for model_name, artifacts in artifacts_by_model.items():
                plot_model_diagnostics(model_name, artifacts, output_dir, self.labels)
                plot_model_confidence_boxplot(model_name, artifacts, output_dir, self.labels)

        return {
            "summary_df": summary_df,
            "artifacts_by_model": artifacts_by_model,
        }

    def _run_voter(
        self,
        voter: EnsembleVoter,
        evaluation_df: pd.DataFrame,
    ) -> Tuple[np.ndarray, np.ndarray, List[EnsembleOutput]]:
        """
        Runs the specified voter on the evaluation DataFrame and returns the predicted labels, probabilities for the positive class, and outputs.

        Args:
            voter: The EnsembleVoter instance to run.
            evaluation_df: A pandas DataFrame containing the evaluation data.

        Returns:
            Tuple containing:
                - predicted_labels: A numpy array of predicted class labels (0 or 1).
                - positive_scores: A numpy array of predicted probabilities for the positive class.
                - outputs: A list of EnsembleOutput objects containing detailed results for each sample.       
        """
        predicted_labels: List[int] = []
        positive_scores: List[float] = []
        outputs: List[EnsembleOutput] = []

        previous_verbose = voter.verbose
        voter.verbose = False

        try:
            for _, sample_row in evaluation_df.iterrows():
                output = voter.run(sample_row)
                outputs.append(output)
                predicted_labels.append(int(output.label))

                if self.positive_label >= len(output.probs):
                    raise ValueError(
                        f"positive_label={self.positive_label} is out of bounds for model output with "
                        f"{len(output.probs)} classes"
                    )
                positive_scores.append(float(output.probs[self.positive_label]))
        finally:
            voter.verbose = previous_verbose

        return np.asarray(predicted_labels, dtype=int), np.asarray(positive_scores, dtype=float), outputs

    def _compute_metrics_and_artifacts(
        self,
        y_true: np.ndarray,
        y_pred: np.ndarray,
        y_score: np.ndarray,
    ) -> Tuple[Dict[str, Any], Dict[str, Any]]:
        """
        Computes evaluation metrics and artifacts for the given true and predicted values.

        Args:
            y_true: A numpy array of true class labels.
            y_pred: A numpy array of predicted class labels.
            y_score: A numpy array of predicted probabilities for the positive class.

        Returns:
            Tuple containing:
                - metrics: A dictionary of evaluation metrics.
                - artifacts: A dictionary of evaluation artifacts.
        """


        roc_auc = float(roc_auc_score(y_true, y_score))
        fpr, tpr, roc_thresholds = roc_curve(y_true, y_score)

        average_precision = float(average_precision_score(y_true, y_score))
        precision_values, recall_values, pr_thresholds = precision_recall_curve(y_true, y_score)

        cm = confusion_matrix(y_true, y_pred, labels=[0, 1])
        tn, fp, fn, tp = _extract_binary_cm_values(cm)

        sensitivity = float(tp / (tp + fn)) if (tp + fn) > 0 else 0.0
        specificity = float(tn / (tn + fp)) if (tn + fp) > 0 else 0.0
        accuracy = float(accuracy_score(y_true, y_pred))
        balanced_accuracy = float(balanced_accuracy_score(y_true, y_pred))
        precision_metric = float(precision_score(y_true, y_pred, pos_label=1, zero_division=0))
        f1_binary = float(f1_score(y_true, y_pred, pos_label=1, zero_division=0, average="binary"))
        f1_macro = float(f1_score(y_true, y_pred, pos_label=1, zero_division=0, average="macro"))

        metrics = {
            "roc_auc": roc_auc,
            "average_precision": average_precision,
            "sensitivity": sensitivity,
            "specificity": specificity,
            "accuracy": accuracy,
            "balanced_accuracy": balanced_accuracy,
            "precision": precision_metric,
            "f1_binary": f1_binary,
            "f1_macro": f1_macro,
            "tn": tn,
            "fp": fp,
            "fn": fn,
            "tp": tp,
        }

        artifacts = {
            "fpr": fpr,
            "tpr": tpr,
            "roc_thresholds": roc_thresholds,
            "precision": precision_values,
            "recall": recall_values,
            "pr_thresholds": pr_thresholds,
            "confusion_matrix": cm,
            "roc_auc": roc_auc,
            "average_precision": average_precision,
            "y_true": y_true,
            "y_pred": y_pred,
            "y_score": y_score,
        }

        return metrics, artifacts

