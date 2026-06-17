# Pipeline Quickstart

Diese Datei gibt eine kurze Übersicht für Personen, die die ML-Pipeline noch nicht kennen und sie schnell starten möchten.

## Was kann die Pipeline?

Die Pipeline trainiert und bewertet Modelle zur binären Klassifikation von Hautläsionen: Melanom vs. Nicht-Melanom. Sie kann mehrere Trainingsvarianten als sogenannte Branches ausführen. Ein Branch beschreibt jeweils eine Kombination aus Modell, Eingabedaten, Loss-Funktion, Optimizer, Scheduler und Augmentierungen.

Damit lassen sich zum Beispiel folgende Fragen vergleichen:

- Welches Torchvision-Modell funktioniert besser, z.B. ResNet oder EfficientNet?

- Sind RGB-Bilder oder vorberechnete Filterdaten wie Gabor, GLCM oder LBP besser geeignet?

- Wie wirken sich Transfer Learning, eingefrorene Gewichte, Augmentierungen oder Sampling auf die Ergebnisse aus?

- Welcher Threshold ist für die Melanom-Erkennung auf dem Validierungsset sinnvoll?

Nach jedem Lauf speichert die Pipeline Modell, Konfiguration, Metriken, Plots und MLflow-Trackingdaten im `results/`-Ordner.

## Wichtige Dateien

| Datei | Zweck |
|---|---|
| `docs/ml/pipeline/pipeline_config.json` | Beispielkonfiguration für einen Pipeline-Lauf |
| `docs/ml/pipeline/pipeline_documentation.md` | Ausführliche technische Dokumentation |
| `python/pipeline/pipeline_orchestrator.py` | Startpunkt der Pipeline im Code |
| `python/pipeline/pipeline_test.ipynb` | Notebook zum Ausführen und Testen der Pipeline |
| `python/pipeline/run_experiments.ipynb` | Notebook für Experimentläufe |

## Vor dem Start

1. Python-Umgebung vorbereiten.

2. Abhängigkeiten aus `python/requirements.txt` installieren.

3. Sicherstellen, dass der Datensatz vorhanden ist.

4. Pfade an die eigene Umgebung anpassen, vor allem `data_path` und bei Custom-Splits die CSV-Pfade.

5. Prüfen, ob die gewählten Filterdaten vorhanden sind, wenn `dataset_loader="filter"` genutzt wird.

## Minimaler Start im Notebook

Die einfachste Variante ist das Notebook `python/pipeline/pipeline_test.ipynb`. Dort wird die Konfiguration geladen und an den `PipelineOrchestrator` übergeben.

Der Kernaufruf sieht so aus:

```python
from pathlib import Path

from pipeline.dataclasses.pipeline_config import PipelineConfig
from pipeline.pipeline_orchestrator import PipelineOrchestrator

raw_json = Path("../../docs/ml/pipeline/pipeline_config.json").read_text()
config = PipelineConfig.model_validate_json(raw_json)
config = config.model_copy(update={"data_path": Path("../../data")})

orchestrator = PipelineOrchestrator(config, project_root_path=Path("../.."))
results = orchestrator.run()
```

## Was muss in der Config angepasst werden?

Die wichtigsten Stellen sind:

- `pipeline_id`: Name des Laufs, erscheint im Ergebnisordner.

- `data_path`: Pfad zum Datensatz.

- `split_config`: Entweder automatischer Split über Ratios oder feste CSV-Dateien für Train, Val und Test.

- `branches`: Liste der Trainingsvarianten.

- `branch_model_config.model_type`: Modellarchitektur, z.B. `resnet18` oder `efficientnet_v2_s`.

- `branch_model_config.filter_type`: Eingabetyp und Kanalzahl, z.B. `["rgb", 3]`.

- `trainer_config`: Batch-Größe, Epochen, Learning Rate, Loss, Optimizer und Scheduler.

- `dataset_loader`: `rgb` für Bilddateien oder `filter` für vorberechnete Feature-Maps.

- `augmentation`: Augmentierungen für Training und Validierung.

## Ergebnis nach dem Lauf

Die Ergebnisse liegen unter:

```text
results/<pipeline_id>_<timestamp>/
```

Pro Branch werden unter anderem gespeichert:

- `model.pt`: bestes Modell

- `branch_config.json`: verwendete Branch-Konfiguration

- `training_history.json`: Trainingsverlauf

- `metrics.json`: finale Testmetriken

- `training_history.png`: Loss- und Metrikverlauf

- `confusion_matrix.png`, `precision_recall_curve.png`, `roc_curve.png`: Evaluierungsplots

Zusätzlich werden Parameter, Metriken, Artefakte und Modelle in MLflow geloggt. Die lokale Tracking-Datenbank liegt unter `results/mlflow.db`.