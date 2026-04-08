import numpy as np

from pipeline.pipeline_dataclasses import EvalResult, MetricsResult
from pipeline.json_dataclasses import MetricsType

from sklearn.metrics import (
    f1_score, roc_auc_score, accuracy_score, confusion_matrix, precision_score, matthews_corrcoef
)

class MetricsCalculator:
    def calculate(self, eval_metrics: list[MetricsType],  eval_results: EvalResult):
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

        auc = roc_auc_score(y_true, all_probs[:, 1])

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