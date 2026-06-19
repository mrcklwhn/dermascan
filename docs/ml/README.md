# Machine Learning

Dieses Kapitel gibt einen Ueberblick ueber die Entwicklung der ML-Modelle zur Klassifikation von Hautlaesionen. Es beschreibt Datengrundlagen, Modellansaetze, Trainingsprozess und den Exportpfad fuer die mobile App.

## Entwicklungsumgebung

Die Modellentwicklung erfolgte in Python.

- Erste Baselines wurden mit TensorFlow/Keras umgesetzt.
- Fuer Transfer Learning und flexible Experimentsteuerung wurde auf PyTorch umgestellt.
- Fuer die mobile Inferenz wurde ONNX als Austauschformat mit ONNX Runtime evaluiert.

## Datensaetze

Das Projekt nutzt den ISIC-2018-Kontext, insbesondere:

- Segmentierungsdaten fuer Laesionsmasken
- HAM10000 fuer die Klassifikation von Hautlaesionen

Der HAM10000-Datensatz enthaelt sieben Klassen und ist stark unausgeglichen. Fuer den klinischen Anwendungskontext der Stakeholderin wurde die Aufgabe auf eine binaere Klassifikation reduziert:

- Melanocytic nevi (nv)
- Melanoma (mel)

Damit entsteht weiterhin ein deutliches Klassenungleichgewicht, das im Training gezielt behandelt werden muss.

## Klassifikatorentwicklung

### Einfache CNN-Baselines

Zu Beginn wurden einfache CNNs trainiert, um die grundsaetzliche Machbarkeit zu pruefen. Die Ergebnisse zeigten, dass kleine, manuell entworfene Netze die Komplexitaet der Aufgabe nicht robust abbilden.

### Finetuning vortrainierter Modelle

Anschliessend wurden vortrainierte Architekturen evaluiert (u. a. ResNet, EfficientNet, DenseNet, MobileNet). Transfer Learning erwies sich als robusterer Ausgangspunkt als rein von Grund auf trainierte Baselines.

### Multibranch-Architektur

Als weiterfuehrender Ansatz wurde eine Multibranch-Architektur entwickelt. Mehrere Branches verarbeiten unterschiedliche Datenrepraesentationen und werden anschliessend kombiniert. Die Ergebnisse und technischen Hintergruende sind in der [Multibranch-Architektur](./multibranch_architecture.md) dokumentiert.

## Trainingspipeline und Auditing

Zur Vergleichbarkeit und Reproduzierbarkeit wurde eine modulare Pipeline aufgebaut. Sie standardisiert Splits, Training, Metrikberechnung, Threshold-Optimierung und Artefaktspeicherung.

- Details zur Pipeline: [Trainingspipeline](./pipeline.md)
- Rueckverfolgbarkeit und Artefakte: [Auditing](./auditing.md)

## Modelluebertrag in die App

Fuer den produktiven Inferenzpfad in der App wird ONNX Runtime genutzt. Die Modelle werden in Python exportiert und anschliessend in Flutter eingebunden.

Weitere Details zum Export- und Validierungsprozess stehen in [ONNX-Export](./onnx_export.md).

## Trainingsergebnisse

Die dokumentierten Zwischenstaende und Metriken befinden sich in [Trainingsergebnisse](./training_results.md). Da nicht alle Runs auf identischen Voraussetzungen basieren, sind Ergebnisse nur eingeschraenkt direkt vergleichbar.

## Fazit

- Transfer Learning und strukturierte Experimentsteuerung sind fuer die Aufgabe zentral.
- Die Multibranch-Idee ist fachlich vielversprechend, erhoeht aber Implementierungs- und Portierungsaufwand.
- Die Pipeline verbessert Reproduzierbarkeit und belastbare Modellvergleiche deutlich.
- ONNX-basierter Modelluebertrag ist fuer den mobilen Einsatz praktikabel, erfordert aber systematische Validierung zwischen Python und App-Laufzeit.

## Siehe auch

- [Multibranch-Architektur](./multibranch_architecture.md)
- [Trainingspipeline](./pipeline.md)
- [ONNX-Export](./onnx_export.md)
- [Trainingsergebnisse](./training_results.md)
- [Auditing](./auditing.md)
- [ABC-Algorithmen](../abc_algorithms/README.md)
