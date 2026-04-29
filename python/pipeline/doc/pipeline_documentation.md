# Pipeline Documentation

## Overview

Die Pipeline ist ein modulares ML-Trainings-Framework für die binäre Klassifikation von Hautläsionen (Melanom vs. Nicht-Melanom) auf Basis des HAM10000-Datensatzes. Sie unterstützt Transfer Learning mit ResNet-Architekturen und verschiedene Bildfilter-Typen (RGB, Gabor, GLCM, LBP) in parallelen **Branches**.

---

## Architektur

```
PipelineOrchestrator
├── SplitProvider              → erzeugt Train/Val/Test-Split
└── für jeden Branch:
    ├── DataLoaderFactory      → baut PyTorch DataLoader
    └── BranchRunner
        ├── ModelFactory       → baut ResNet-Modell
        ├── Trainer            → Training & Test
        │   └── (train, validate, test)
        ├── MetricsCalculator  → berechnet Metriken
        └── Plotter            → speichert Plots & Verlaufsgraphen
```

---

## Komponenten

### `PipelineOrchestrator`

Einstiegspunkt der Pipeline. Lädt die Konfiguration, erzeugt den Datensplit und führt alle konfigurierten Branches sequentiell aus.

| Methode | Beschreibung |
|---|---|
| `__init__(pipeline_config, project_root_path)` | Initialisiert die Pipeline und erstellt das Ausgabeverzeichnis |
| `run()` | Führt alle Branches aus, gibt `list[BranchResult]` zurück |
| `_get_pipeline_output_path(...)` | Erstellt Ausgabepfad `results/<pipeline_id>_<timestamp>/` |

**Ausgabe:** `results/<pipeline_id>_YYYY-MM-DD_HH-MM/`

---

### `BranchRunner`

Führt einen einzelnen Branch aus: Modellaufbau → Training → Evaluation → Speichern.

| Methode | Beschreibung |
|---|---|
| `__init__(branch_config, data_loaders, pipeline_run_path)` | Initialisiert Modell, Trainer und Ausgabepfad |
| `run()` | Trainiert, evaluiert, speichert Ergebnisse und gibt `BranchResult` zurück |
| `_save_training_history(history)` | Speichert `training_history.json` |
| `_save_metrics(metrics)` | Speichert `metrics.json` |
| `_get_device()` | CUDA falls verfügbar, sonst CPU |

**Ausgabe pro Branch:** `<pipeline_run_path>/<branch_id>_<filter_name>/`
- `model.pt` – bestes Modell (nach Val-F1 Macro)
- `training_history.json`
- `metrics.json`
- Trainingsplots (Loss/Accuracy-Kurven)
- Konfusionsmatrix

---

### `ModelFactory`

Baut ein ResNet-Modell anhand einer `ModelConfig`.

| Unterstützte Architekturen | `ModelType`-Wert |
|---|---|
| ResNet-18 | `resnet18` |
| ResNet-50 | `resnet50` |
| ResNet-101 | `resnet101` |

**Transfer Learning:**
- `pretrained=true` → lädt ImageNet-Gewichte
- `freeze_weights=true` → friert alle Parameter ein (nur Output-Layer wird trainiert)
- `filter_type != RGB` → ersetzt `conv1` durch einen `Conv2d` mit der passenden Kanalanzahl (keine vortrainierten Gewichte für den Input-Layer)
- Output-Layer (`fc`) wird immer auf `num_classes` angepasst

---

### `Trainer`

Trainiert und evaluiert ein PyTorch-Modell.

**Training:**
- Nutzt `CrossEntropyLoss` mit optionalen Klassengewichten (`criterion_weights`)
- Speichert das **beste Modell** basierend auf dem Val-F1-Macro-Score
- Gibt `TrainingHistory` zurück (Loss, Accuracy, F1-Macro pro Epoch)

**Unterstützte Optimizer:**

| Optimizer | Parameter |
|---|---|
| Adam | `weight_decay`, `betas`, `eps` |
| SGD | `momentum`, `weight_decay`, `nesterov` |

**Unterstützte Scheduler:**

| Scheduler | Parameter |
|---|---|
| ReduceLROnPlateau | `mode`, `factor`, `patience`, `min_lr`, `cooldown` |

> Der Scheduler wird mit dem **Val-Loss** nach jeder Epoch aufgerufen.

---

### `SplitProvider`

Erstellt den Train/Val/Test-Split.

| Modus | Beschreibung |
|---|---|
| `ratio` | Automatischer Split nach Verhältnis (`val_ratio`, `test_ratio`) |
| `custom` | Lädt vordefinierte CSV-Dateien (`train_csv_path`, `val_csv_path`, `test_csv_path`) |

Im `ratio`-Modus werden nur Melanom-relevante Samples geladen (binäre Klassifikation).

---

### `DataLoaderFactory`

Erstellt PyTorch `DataLoader`-Instanzen für alle drei Splits.

| Loader-Typ | Beschreibung |
|---|---|
| `rgb` | Lädt JPEG-Bilder als RGB-Tensoren |
| `filter` | Lädt vorberechnete Feature-Maps aus `.npy`-Dateien |

**DataLoader-Defaults:**

| Parameter | Wert |
|---|---|
| `num_workers` | 4 |
| `pin_memory` | `True` wenn CUDA verfügbar |
| `prefetch_factor` | 2 |
| `persistent_workers` | `True` |

Augmentierungen werden nur auf Train- und Val-Set angewandt; das Test-Set erhält ausschließlich Normalisierung.

---

### `MetricsCalculator`

Berechnet alle Evaluierungsmetriken aus `EvalResult` (y_true, y_pred, y_prob).

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

## Konfiguration

Die Pipeline wird über ein `PipelineConfig`-Objekt gesteuert (oder aus einer JSON-Datei geladen).

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
  "branches": [ ... ]
}
```

### `BranchConfig`

```json
{
  "branch_id": "first_test_branch",
  "branch_model_config": {
    "model": "resnet18",
    "filter_type": "RGB",
    "num_classes": 2,
    "pretrained": true,
    "freeze_weights": true
  },
  "trainer_config": {
    "batch_size": 32,
    "num_epochs": 20,
    "learning_rate": 0.001,
    "criterion_weights": [0.87, 0.13],
    "optimizer": { "optimizer_type": "adam" },
    "scheduler": { "scheduler_type": "reduce_on_plateau" }
  },
  "dataset_loader": "rgb",
  "augmentation": {
    "train": ["random_horizontal_flip", "random_resize_crop"],
    "val": []
  }
}
```

### Verfügbare Enum-Werte

**`filter_type`** (beeinflusst Kanalanzahl des Input-Layers):

| Wert | Kanäle | Loader-Typ |
|---|---|---|
| `RGB` | 3 | `rgb` |
| `GABOR` | 40 | `filter` |
| `GLCM` | 32 | `filter` |
| `LBP` | 1 | `filter` |

**`augmentation` (train/val):**
`random_horizontal_flip`, `random_vertical_flip`, `random_rotation`, `color_jitter`, `random_erasing`, `random_resize_crop`, `resize`, `center_crop`

---

## Datenklassen (Runtime)

| Klasse | Felder |
|---|---|
| `TrainValTestSplit` | `train_df`, `val_df`, `test_df` |
| `TrainValTestDataLoaders` | `train_loader`, `val_loader`, `test_loader` |
| `TrainingHistory` | `train_loss`, `val_loss`, `train_accuracy`, `val_accuracy`, `val_f1_macro` |
| `EvalResult` | `y_true`, `y_pred`, `y_prob` |
| `MetricsResult` | `f1_macro`, `f1_weighted`, `accuracy`, `precision`, `sensitivity`, `specificity`, `auc`, `mcc` |
| `BranchResult` | `branch_id`, `training_history`, `metrics_result` |

---

## Ausgabestruktur

```
results/
└── <pipeline_id>_<timestamp>/
    ├── <branch_id>_<filter_name>/
    │   ├── model.pt
    │   ├── training_history.json
    │   ├── metrics.json
    │   ├── training_history.png
    │   └── confusion_matrix.png
    └── <branch_id>_<filter_name>/
        └── ...
```

---

## Verwendung (Notebook)

```python

# Konfiguration laden
raw_json = Path("doc/pipeline_config.json").read_text()
config = PipelineConfig.model_validate_json(raw_json)
config = config.model_copy(update={"data_path": Path("../../data")})

# Pipeline starten
orchestrator = PipelineOrchestrator(config, project_root_path=Path("../.."))
results = orchestrator.run()
```

Siehe auch: `pipeline_test.ipynb` und `pipeline_resnet_finetuning.ipynb`.
