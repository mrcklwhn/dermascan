import numpy as np
from sklearn.metrics import (
    f1_score, roc_auc_score, accuracy_score, confusion_matrix, precision_score, matthews_corrcoef
)

from pipeline.dataclasses.pipeline_runtime import EvalResult, MetricsResult

class MetricsCalculator:
    """
    MetricsCalculator class responsible for calculating evaluation metrics based on the true labels, predicted labels, and predicted probabilities.
    It calculates:
    - Accuracy
    - Precision
    - F1 Score (macro and weighted)
    - Sensitivity and Specificity
    - AUC
    - Matthews Correlation Coefficient (MCC)
    """
    def calculate(self, eval_results: EvalResult) -> MetricsResult:
        """
        Calculates the specified evaluation metrics based on the evaluation results.

        Args:
            eval_results (EvalResult): Evaluation results containing true labels, predicted labels, and predicted probabilities.

        Returns:
            MetricsResult: Calculated evaluation metrics.
        """
        y_true = eval_results.y_true
        y_pred = eval_results.y_pred
        all_probs = np.array(eval_results.y_prob)

        f1_macro = f1_score(y_true, y_pred, average="macro", zero_division=0)
        f1_weighted = f1_score(y_true, y_pred, average="weighted", zero_division=0)
        accuracy = accuracy_score(y_true, y_pred)
        precision = precision_score(y_true, y_pred, average="macro", zero_division=0)
        mcc = matthews_corrcoef(y_true, y_pred)

        tn, fp, fn, tp = confusion_matrix(y_true, y_pred, labels=[0, 1]).ravel()
        sensitivity = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        specificity = tn / (tn + fp) if (tn + fp) > 0 else 0.0

        if all_probs.ndim == 2 and all_probs.shape[1] == 2:
            positive_probs = all_probs[:, 1]
        elif all_probs.ndim == 2 and all_probs.shape[1] == 1:
            positive_probs = all_probs[:, 0]
        else:
            positive_probs = all_probs.reshape(-1)

        auc = roc_auc_score(y_true, positive_probs)

        return MetricsResult(
            f1_macro=f1_macro,
            f1_weighted=f1_weighted,
            accuracy=accuracy,
            precision=precision,
            sensitivity=sensitivity,
            specificity=specificity,
            auc=auc,
            mcc=mcc
        )