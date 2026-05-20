# Auditing

Auditing beschreibt den Prozess der Nachverfolgung und Überprüfung von Entscheidungen. In diesem Zusammenhang bezieht es sich auf die Fähigkeit für gegebenes Modell nachzuverfolgen, auf welchen Hyperparametern und Eingangsdaten das Training basiert, um das gleiche Modell mit den gleichen Ergebnissen reproduzieren zu können. Diese Fähigkeit bietet Transparenz in Bezug auf die Trainingsdaten, die Modellarchitektur, die Hyperparameter und die Trainingsprozedur. Es ermöglicht auch die Identifikation von Fehlern oder Inkonsistenzen im Trainingsprozess und unterstützt die Reproduzierbarkeit und Optimierung von Modellen.

>Hinweis: Für exakten Reproduktion muss während des Trainings der `seed`-Parameter in der `PipelineConfig` gesetzt werden, damit die Zufallsprozesse (z.B. Datenaugmentation, Initialisierung der Modellgewichte) deterministisch sind.

## Rückverfolgungsprozess

Die Eingabedaten wurden vorab explizit in Dateien (`train_df.csv`, `val_df.csv`, `test_df.csv`) gespeichert, um die Rückverfolgung zu erleichtern. Diese Dateien enthalten die Pfade zu den Bildern und die entsprechenden Labels. Insofern ist der Datensplit in der [FAUBox](https://faubox.rrze.uni-erlangen.de/getlink/fiBdx9pHi9z1Qo3cPAcJmh/Dermascan) im Verzeichnis `data` abgelegt (Achtung: Der Pfad muss angepasst werden).

### Trainingsausgabe

Die Ausgabe unserer Trainingspipeline enthält alle Informationen, die für die Rückverfolgung eines Modells notwendig sind.
Es werden innerhalb eines Durchlaufs immer mindestens ein Branch trainiert. Das Ergebnis eines Branches sind folgende Dateien:

- `model.pt` – bestes Modell (nach Val-F1 Macro)
- `training_history.json` – Trainingsverlauf (Loss, Accuracy, F1-Macro) pro Epoche
- `training_history.png` – Trainingsverlauf als Plot
- `metrics.json` – finale Metriken auf Testset
- `confusion_matrix.png` – Konfusionsmatrix auf Testset
- `branch_config.json` – Konfiguration des Branches (Filter, Hyperparameter, etc.)

Damit ergibt sich für einen Durchlauf der Pipeline folgende Ordnerstruktur:

```
results/
└── <pipeline_id>_<timestamp>/
    ├── <branch_id>_<filter_name>/
    │   ├── model.pt
    │   ├── training_history.json
    │   ├── training_history.png
    │   ├── metrics.json
    │   └── confusion_matrix.png
    |   └── branch_config.json
    └── <branch_id>_<filter_name>/
        └── ...
```


### Reproduzierbarkeit

Ein später verwendetes Modell kann somit über die Kombination aus `timestamp`, `branch_id` und `filter_name` eindeutig identifiziert und zurückverfolgt werden. Alle notwendigen Informationen für die Reproduktion des Modells sind in den gespeicherten Dateien enthalten.

Zur Wiederherstellung eines Modells aus der gespeicherten Konfiguration muss die `branch_config.json` geladen werden:

```python
# Konfiguration laden
raw_json = Path("results/<pipeline_id>_<timestamp>/<branch_id>_<filter_name>/branch_config.json").read_text()
config = PipelineConfig.model_validate_json(raw_json)
config = config.model_copy(update={"data_path": Path("../../data")})

# Pipeline starten
orchestrator = PipelineOrchestrator(config, project_root_path=Path("../.."))
results = orchestrator.run()
```