# Machine Learning

Dieses Kapitel gibt einen Überblick über die Entwicklung der ML-Modelle zur Klassifikation von Hautläsionen. Es beschreibt Datengrundlagen, Modellansätze, Trainingsprozess und den Exportpfad für die mobile App.

## Entwicklungsumgebung

Die Modellentwicklung erfolgte in Python.

- Erste Baselines wurden mit TensorFlow / Keras umgesetzt.
- Für Transfer Learning und flexible Experimentsteuerung wurde auf PyTorch umgestellt.
- Für die mobile Inferenz wurde ONNX als Austauschformat geprüft; ONNX Runtime wurde als Laufzeitumgebung für die App evaluiert.

## Datensätze

Das Projekt nutzt ISIC-Kontextdaten, insbesondere:

- Segmentierungsdaten für Läsionsmasken.
- HAM10000 für die Klassifikation von Hautläsionen.

Der HAM10000-Datensatz enthält sieben Klassen und ist stark unausgeglichen. Für den klinischen Anwendungskontext der Stakeholderin wurde die Aufgabe auf eine binäre Klassifikation reduziert:

- Melanocytic nevi (nv)
- Melanoma (mel)

Dadurch bleibt ein deutliches Klassenungleichgewicht bestehen, das im Training durch gezielte Maßnahmen adressiert werden muss.

## Klassifikatorentwicklung

### Einfache CNN-Baselines

Zu Beginn wurden einfache CNNs trainiert, um die grundsätzliche Machbarkeit zu prüfen. Diese Baselines zeigten, dass kleine Netze die Komplexität der Aufgabe nicht zuverlässig abbilden.

### Fine-Tuning vortrainierter Modelle

Anschließend wurden vortrainierte Architekturen evaluiert, darunter ResNet, EfficientNet, DenseNet und MobileNet. Transfer Learning erwies sich als robuster Ausgangspunkt gegenüber rein von Grund auf trainierten Modellen, insbesondere bei begrenzter Trainingsdatenmenge.

### Multibranch-Architektur

Als weiterführender Ansatz wurde eine Multibranch-Architektur entwickelt. Mehrere Branches verarbeiten unterschiedliche Datenrepräsentationen und ihre Merkmale werden anschließend zusammengeführt. Technische Details und Ergebnisse sind in der [Multibranch-Architektur](./multibranch_architecture.md) dokumentiert.

## Trainingspipeline und Auditing

Zur Vergleichbarkeit und Reproduzierbarkeit wurde eine modulare Pipeline aufgebaut. Sie standardisiert Daten-Splits, Training, Metrikberechnung, Threshold-Optimierung sowie das Speichern von Artefakten.

- Details zur Pipeline: [Trainingspipeline](./pipeline.md)
- Rückverfolgbarkeit und Artefakte: [Auditing](./auditing.md)

## Modellübertrag in die App

Für den produktiven Inferenzpfad in der App wird ONNX Runtime genutzt. Die Modelle werden in Python exportiert und anschließend in die Flutter-App eingebunden.

Weitere Details zum Export- und Validierungsprozess stehen in [ONNX-Export](./onnx_export.md).

## Experimentergebnisse

Die dokumentierten Zwischenstände und Metriken befinden sich in [Experimentergebnisse](./experiment_results.md). Dort sind Basistests und die fokussierte HAM10000-Modellserie gemeinsam eingeordnet. Da nicht alle Runs unter identischen Voraussetzungen durchgeführt wurden, sind direkte Vergleiche nur eingeschränkt belastbar.

## Fazit

- Transfer Learning und strukturierte Experimentsteuerung sind für die Aufgabe zentral.
- Die Multibranch-Idee ist fachlich vielversprechend, erhöht jedoch Implementierungs- und Portierungsaufwand.
- Die Pipeline verbessert Reproduzierbarkeit und belastbare Modellvergleiche deutlich.
- ONNX-basierter Modellübertrag ist für den mobilen Einsatz praktikabel, erfordert aber systematische Validierung zwischen Python- und App-Laufzeit.

## Siehe auch

- [Multibranch-Architektur](./multibranch_architecture.md)
- [Trainingspipeline](./pipeline.md)
- [ONNX-Export](./onnx_export.md)
- [Experimentergebnisse](./experiment_results.md)
- [Auditing](./auditing.md)
- [ABC-Algorithmen](../abc_algorithms/README.md)