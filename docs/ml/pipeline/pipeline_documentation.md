# Pipeline Documentation

## Overview

Die Pipeline ist ein modulares ML-Trainings-Framework für die binäre Klassifikation von Hautläsionen (Melanom vs. Nicht-Melanom) auf Basis des HAM10000-Datensatzes. Sie unterstützt mehrere Torchvision-Architekturen, Transfer Learning und verschiedene Bildfilter-Typen (RGB, Gabor, GLCM, LBP) in konfigurierbaren **Branches**. Die Branches werden aktuell sequentiell ausgeführt.

---

## Architektur

Die Architektur trennt die Pipeline in klar abgegrenzte Verantwortlichkeiten: Datensplitting, Laden und Augmentieren der Daten, Modellaufbau, Training, Evaluation, Visualisierung und Experiment-Tracking. Dadurch können unterschiedliche Modellarchitekturen, Filter-Repräsentationen und Trainingskonfigurationen als unabhängige Branches verglichen werden, ohne den Ablauf der gesamten Pipeline anpassen zu müssen.

Diese Struktur ermöglicht reproduzierbare Experimente, weil Seeds, Konfigurationen, Metriken, Artefakte und Modelle systematisch gespeichert werden. Gleichzeitig bleibt die Pipeline erweiterbar: Neue Filtertypen, Torchvision-Modelle, Optimizer, Scheduler oder Evaluierungslogiken können an den vorgesehenen Stellen ergänzt werden, während der `PipelineOrchestrator` weiterhin den Gesamtprozess koordiniert.

```
PipelineOrchestrator
├── SplitProvider              → erzeugt Train/Val/Test-Split
└── für jeden Branch:
    ├── DataLoaderFactory      → baut PyTorch DataLoader (opt. WeightedRandomSampler)
    │   └── AugmentationBuilder → erzeugt modellabhängige Albumentations-Pipelines
    └── BranchRunner
        ├── ModelFactory       → baut Torchvision-Modell über ModelArchRegistry
        ├── Trainer            → Training, Validierung & Test
        │   └── (train, validate, test)
        ├── MetricsCalculator  → Threshold-Suche & Evaluierungsmetriken
        ├── Plotter            → speichert Plots & Verlaufsgraphen
        └── MLFlowLogger       → tracked Experimente in MLflow
```

---

## Komponenten

### `PipelineOrchestrator`

Einstiegspunkt der Pipeline. Erzeugt das Ausgabeverzeichnis, setzt Seeds, initialisiert MLflow-Tracking mit einer SQLite-Datenbank (`results/mlflow.db`), erzeugt den Datensplit und führt alle konfigurierten Branches sequentiell aus.

**Ausgabe:** `results/<pipeline_id>_YYYY-MM-DD_HH-MM/`

---

### `BranchRunner`

Führt einen einzelnen Branch aus: Modellaufbau → Training → Threshold-Optimierung → Test-Evaluation → Speichern/Logging.

**Ablauf pro Branch:**
1. Branch-Konfiguration speichern und Parameter in MLflow loggen
2. Modell trainieren und bestes Modell nach Val-F1-Macro speichern
3. Bestes Modell auf dem Val-Set mit Threshold `0.5` auswerten
4. Optimalen Threshold über `MetricsCalculator.get_threshold(...)` bestimmen
5. Test-Set mit optimalem Threshold auswerten
6. Metriken, Plots, Artefakte und Modell in MLflow loggen

**Ausgabe pro Branch:** `<pipeline_run_path>/<branch_id>_<filter_name>/`
- `model.pt` - bestes Modell nach Val-F1-Macro
- `branch_config.json`
- `training_history.json`
- `metrics.json`
- `training_history.png`
- `confusion_matrix.png`
- `precision_recall_curve.png`
- `roc_curve.png`
- `confidence_distribution.png`

---

### `ModelFactory` und `model_archs`

Baut ein Torchvision-Modell anhand einer `ModelConfig`. Die Architektur-spezifischen Details (Builder, Gewichte, Input-Layer, Output-Layer, erwartete Bildgröße) liegen in der `_modelArchRegistry`.

| Unterstützte Architektur | `ModelType`-Wert | Bildgröße |
|---|---|---|
| ResNet-18 | `resnet18` | 224 |
| ResNet-50 | `resnet50` | 224 |
| ResNet-101 | `resnet101` | 224 |
| EfficientNet V2-S | `efficientnet_v2_s` | 384 |
| Inception V3 | `inception_v3` | 299 |
| SqueezeNet 1.1 | `squeezenet_1_1` | 224 |
| MobileNet V3 Small | `mobilenet_v3_small` | 224 |
| MobileNet V3 Large | `mobilenet_v3_large` | 224 |

**Transfer Learning:**
- `pretrained=true` lädt die Default-Gewichte der jeweiligen Torchvision-Architektur
- `freeze_weights=true` friert alle bestehenden Parameter ein; neu gesetzte Output-Layer bleiben trainierbar
- `filter_type != RGB` ersetzt den ersten Conv-Layer durch einen Layer mit passender Kanalanzahl
- Der neue Input-Layer wird per Kaiming-Normal initialisiert; optional reproduzierbar über `seed`
- Der Output-Layer wird auf `num_classes` angepasst
- Bei Inception wird zusätzlich `AuxLogits.fc` angepasst, falls vorhanden
- Bei SqueezeNet wird der finale ReLU-Layer im Classifier deaktiviert (`Identity`), damit Logits nutzbar bleiben

---

### `Trainer`

Trainiert, validiert und testet ein PyTorch-Modell.

**Training:**
- Unterstützt `BCEWithLogitsLoss` und `CrossEntropyLoss`
- Speichert das beste Modell basierend auf dem Val-F1-Macro-Score
- Speichert zusätzlich `best_epoch` in `TrainingHistory`
- Loggt pro Epoch Loss, Accuracy, F1, Learning Rate, `best_epoch` und besten Val-F1 in MLflow
- `ReduceLROnPlateau` steppt mit `val_loss`; andere Scheduler steppern ohne Metrik

**Loss-Funktionen:**

| Loss | `LossType`-Wert | Verwendung |
|---|---|---|
| BCEWithLogitsLoss | `bce_with_logits` | Single-Node Binary Classification; nutzt `pos_weight` |
| CrossEntropyLoss | `cross_entropy` | Multi-Node Binary Classification; nutzt optional `class_weights` |

**Output-/Prediction-Handling:**
- Bei `bce_with_logits` werden Outputs auf eine Logit-Spalte reduziert und per Sigmoid in Wahrscheinlichkeiten umgerechnet
- Bei `cross_entropy` werden Softmax-Wahrscheinlichkeiten der positiven Klasse (`[:, 1]`) genutzt
- Spezielle Output-Typen wie `InceptionOutputs` werden über `.logits` aufgelöst
- `test(..., threshold=...)` erzeugt Preds über den übergebenen Threshold

**Unterstützte Optimizer:**

| Optimizer | Parameter |
|---|---|
| Adam | `weight_decay`, `betas`, `eps` |
| AdamW | `weight_decay`, `betas`, `eps` |
| SGD | `momentum`, `weight_decay`, `nesterov` |

**Unterstützte Scheduler:**

| Scheduler | Parameter |
|---|---|
| ReduceLROnPlateau | `mode`, `factor`, `patience`, `min_lr`, `cooldown` |
| CosineAnnealingLR | `t_max`, `eta_min` |

---

### `SplitProvider`

Erstellt den Train/Val/Test-Split.

| Modus | Beschreibung |
|---|---|
| `ratio` | Automatischer Split nach Verhältnis (`val_ratio`, `test_ratio`) |
| `custom` | Lädt vordefinierte CSV-Dateien (`train_csv_path`, `val_csv_path`, `test_csv_path`) |

Im `ratio`-Modus werden über den `DatasetManager` nur melanoma-relevante Samples geladen (`filter_melanoma_only=True`). Wenn ein `seed` gesetzt ist, wird er als `random_state` für den Split verwendet.

---

### `DataLoaderFactory` und `AugmentationBuilder`

Die `DataLoaderFactory` ist die zentrale Erzeugungsstelle für PyTorch-`DataLoader`. Sie übersetzt die Pipeline-Konfiguration in konkrete Loader für Train-, Val- und Test-Daten und sorgt dafür, dass Batch-Größe, Worker-Konfiguration, Sampler, Transformationspipeline und Dataset-Typ zusammenpassen. Dadurch muss der restliche Trainingscode nicht wissen, ob ein Branch direkt RGB-Bilder oder vorberechnete Feature-Maps wie Gabor-, GLCM- oder LBP-Dateien verarbeitet.

Der `AugmentationBuilder` erstellt die passenden Albumentations-Pipelines für den jeweiligen Branch. Die Zielgröße orientiert sich am gewählten Modell, weil verschiedene Architekturen unterschiedliche Eingabegrößen erwarten. Train-, Val- und Test-Transformationen werden getrennt behandelt, sodass Augmentierungen nur dort eingesetzt werden, wo sie sinnvoll sind, während Evaluationen deterministisch bleiben.

| Loader-Typ | Beschreibung |
|---|---|
| `rgb` | Lädt JPEG-Bilder aus `image_path` als RGB-Tensoren |
| `filter` | Lädt vorberechnete Feature-Maps aus `data_path/filtered/<filter_name>/<image_id>.npy` |

**DataLoader-Defaults:**

| Parameter | Wert |
|---|---|
| `num_workers` | 4 |
| `pin_memory` | `True`, wenn CUDA verfügbar |
| `prefetch_factor` | 2 |
| `persistent_workers` | `True` |

**Augmentierungen und Normalisierung:**
- Augmentierungen werden über Albumentations gebaut
- Die Zielgröße kommt aus `_modelArchRegistry` und hängt vom `model_type` ab
- RGB wird mit ImageNet-Mean/-Std normalisiert
- Gabor, GLCM und LBP werden kanalweise mit `mean=0.5`, `std=0.5`, `max_pixel_value=1.0` normalisiert
- `ToTensorV2()` wird immer am Ende der Transform-Pipeline angehängt
- Wenn eine `augmentation`-Config gesetzt ist, erhält das Test-Set nur Normalisierung und Tensor-Konvertierung

**WeightedRandomSampler:** Der `WeightedRandomSampler` ist ein PyTorch-Sampler, der Trainingsbeispiele nicht gleichverteilt, sondern anhand definierter Gewichte zieht. Das ist bei unausgeglichenen Klassen wichtig, weil Melanom-Samples im HAM10000-Datensatz deutlich seltener vorkommen können als Nicht-Melanom-Samples. Wenn `sampler_weights` in der `BranchConfig` gesetzt ist, erhält jede Klasse ein Gewicht, zum Beispiel ein höheres Gewicht für die positive Melanom-Klasse. Der Train-Loader verwendet dann `replacement=True` und `num_samples=len(train_df)`, sodass eine Epoche weiterhin die gleiche Anzahl an Samples enthält, seltene Klassen aber häufiger gezogen werden. Ohne `sampler_weights` wird der Train-Loader klassisch mit `shuffle=True` gebaut.

**Seed-Support:** Der `seed`-Parameter steuert den `torch.Generator`, Albumentations und eine Worker-Initialisierung (`base_seed + worker_id`).

---

### `MetricsCalculator`

Der `MetricsCalculator` bündelt die finale Bewertung eines Branches. Er nimmt die tatsächlichen Labels, die vorhergesagten Labels und die vorhergesagten Wahrscheinlichkeiten entgegen und berechnet daraus die zentralen Klassifikationsmetriken. Damit bleibt die Auswertung unabhängig vom konkreten Modell oder Loss-Typ, solange am Ende Wahrscheinlichkeiten für die positive Klasse vorliegen.

Ein wichtiger Teil ist die Threshold-Suche. Bei binärer Klassifikation entscheidet der Threshold, ab welcher vorhergesagten Wahrscheinlichkeit ein Sample als Melanom klassifiziert wird. Der Standardwert `0.5` ist nicht immer optimal, insbesondere bei medizinischen Klassifikationsproblemen mit unausgeglichenen Klassen und unterschiedlich hohen Fehlerkosten. Deshalb sucht die Pipeline auf dem Validierungsset einen Threshold, der eine Mindest-Specificity einhält und dabei die Sensitivity maximiert.

**Threshold-Suche:**
- Prüft Thresholds von `0.10` bis `0.90` in `0.05`-Schritten
- Ignoriert Thresholds, deren Specificity unter `min_specificity` liegt
- Wählt unter den verbleibenden Thresholds den mit der höchsten Sensitivity
- Fallback ist `0.5`

**Metriken:**

| Metrik | Beschreibung |
|---|---|
| `accuracy` | Trefferquote |
| `precision` | Macro-Precision |
| `f1_macro` | F1-Score (Macro) |
| `f1_weighted` | F1-Score (Weighted) |
| `sensitivity` | True Positive Rate (Recall für Melanom) |
| `specificity` | True Negative Rate |
| `auc` | Area Under ROC Curve |
| `mcc` | Matthews Correlation Coefficient |

---

### `Plotter`

Speichert Visualisierungen zu Training und Evaluation.

Die erzeugten Grafiken umfassen Trainingsverläufe, Confusion Matrix, Precision-Recall-Kurve, ROC-Kurve und die Verteilung der Modellkonfidenzen. Sie werden im Branch-Ausgabeverzeichnis gespeichert und zusätzlich als Artefakte im jeweiligen MLflow-Run abgelegt.

---

### `MLFlowLogger`

MLflow ist ein Tool zum Nachverfolgen und Vergleichen von Machine-Learning-Experimenten. Es speichert Parameter, Metriken, Artefakte und Modelle pro Run, sodass spätere Experimente nachvollzogen und miteinander verglichen werden können. In dieser Pipeline wird MLflow mit einer lokalen SQLite-Datenbank unter `results/mlflow.db` verwendet.

Der `MLFlowLogger` kapselt alle MLflow-Logging-Operationen und wird von `PipelineOrchestrator`, `BranchRunner` und `Trainer` genutzt. Er loggt Branch-Parameter, Trainingsmetriken pro Epoche, finale Evaluierungsmetriken, Plots, Konfigurationsdateien, den optimalen Threshold und das trainierte PyTorch-Modell. Dadurch bleibt das eigentliche Training frei von wiederholtem Tracking-Code.

> MLflow-Runs sind verschachtelt: Der Pipeline-Run ist der Eltern-Run, jeder Branch-Run ein Kind-Run.

---

## Konfiguration

Die Pipeline wird über ein `PipelineConfig`-Objekt gesteuert oder aus JSON geladen.

### `PipelineConfig`

```json
{
  "pipeline_id": "test_pipeline",
  "data_path": "/absolute/path/to/data",
  "split_config": {
    "split_type": "ratio",
    "val_ratio": 0.15,
    "test_ratio": 0.15
  },
  "branches": [ ... ],
  "seed": 42
}
```

> `seed` ist optional. Wenn gesetzt, wird er an Split, DataLoader, Augmentationen und Modellinitialisierung weitergegeben.

### `BranchConfig`

```json
{
  "branch_id": "efficientnet_rgb_bce",
  "branch_model_config": {
    "model_type": "efficientnet_v2_s",
    "filter_type": ["rgb", 3],
    "num_classes": 1,
    "pretrained": true,
    "freeze_weights": false
  },
  "trainer_config": {
    "batch_size": 16,
    "num_epochs": 30,
    "learning_rate": 0.0001,
    "loss_type": "bce_with_logits",
    "pos_weight": 8.0,
    "class_weights": null,
    "optimizer": {
      "optimizer_type": "adamw",
      "weight_decay": 0.0001
    },
    "scheduler": {
      "scheduler_type": "cosine_annealing",
      "t_max": 30,
      "eta_min": 0.00001
    }
  },
  "dataset_loader": "rgb",
  "sampler_weights": null,
  "augmentation": {
    "train": ["random_horizontal_flip", "random_resize_crop"],
    "val": ["resize"]
  }
}
```

> Bei `loss_type="bce_with_logits"` sollte `num_classes=1` gesetzt werden. Bei `loss_type="cross_entropy"` wird typischerweise `num_classes=2` genutzt.

> `filter_type` wird als Tupel `["<filter_name>", <channels>]` serialisiert, z.B. `["rgb", 3]` oder `["gabor", 40]`.

> `sampler_weights` ist optional. Wenn gesetzt (z.B. `[1.5, 8.0]`), wird ein `WeightedRandomSampler` für den Train-Loader verwendet (`class_0_weight`, `class_1_weight`).

### Verfügbare Enum-Werte

**`model_type`:**
`resnet18`, `resnet50`, `resnet101`, `efficientnet_v2_s`, `inception_v3`, `squeezenet_1_1`, `mobilenet_v3_small`, `mobilenet_v3_large`

**`loss_type`:**
`bce_with_logits`, `cross_entropy`

**`optimizer_type`:**
`adam`, `adamw`, `sgd`

**`scheduler_type`:**
`reduce_on_plateau`, `cosine_annealing`

**`dataset_loader`:**
`rgb`, `filter`

**`filter_type`** (beeinflusst Kanalanzahl des Input-Layers):

| JSON-Wert | Kanäle | Loader-Typ |
|---|---|---|
| `["rgb", 3]` | 3 | `rgb` |
| `["gabor", 40]` | 40 | `filter` |
| `["glcm", 32]` | 32 | `filter` |
| `["lbp", 1]` | 1 | `filter` |

**`augmentation` (train/val):**
`random_horizontal_flip`, `random_vertical_flip`, `random_rotation`, `color_jitter`, `random_erasing`, `random_resize_crop`, `resize`, `center_crop`

---

## Ausgabestruktur

```
results/
├── mlflow.db                          ← MLflow Tracking-Datenbank (SQLite)
└── <pipeline_id>_<timestamp>/
    ├── <branch_id>_<filter_name>/
    │   ├── model.pt
    │   ├── branch_config.json
    │   ├── training_history.json
    │   ├── metrics.json
    │   ├── training_history.png
    │   ├── confusion_matrix.png
    │   ├── precision_recall_curve.png
    │   ├── roc_curve.png
    │   └── confidence_distribution.png
    └── <branch_id>_<filter_name>/
        └── ...
```

Zusätzlich werden Branch-Konfigurationen, Metriken, Plots, der optimale Threshold und das geloggte PyTorch-Modell im jeweiligen MLflow-Run gespeichert.

---

## Verwendung (Notebook)

```python
from pathlib import Path

from pipeline.dataclasses.pipeline_config import PipelineConfig
from pipeline.pipeline_orchestrator import PipelineOrchestrator

# Konfiguration laden
raw_json = Path("../../docs/ml/pipeline/pipeline_config.json").read_text()
config = PipelineConfig.model_validate_json(raw_json)
config = config.model_copy(update={"data_path": Path("../../data")})

# Pipeline starten
orchestrator = PipelineOrchestrator(config, project_root_path=Path("../.."))
results = orchestrator.run()
```

Siehe auch: `pipeline_test.ipynb` und `run_experiments.ipynb`.
