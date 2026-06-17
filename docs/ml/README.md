# Machine learning

Dieses Kapitel gibt Überblick in die Entwicklung eines Machine Learning Modells zur Klassifikation von Hautläsionen, das in die mobile App integriert werden soll. Es werden die verwendeten Datensätze, die verschiedenen Modellarchitekturen und die Konvertierung der Modelle für die Ausführung auf mobilen Endgeräten erläutert.

## Entwicklungsumgebung

Die Entwicklung der Modelle und der zugehörigen Trainingspipeline erfolgte in Python. Zu Beginn wurden einfache CNN-Modelle in der **[TensorFlow Keras API](https://www.tensorflow.org/guide/keras)** implementiert, um die grundsätzliche Machbarkeit der Klassifikation zu testen. Da dieser Ansatz jedoch nicht die gewünschte Flexibilität bot, wurde ein Wechsel zu **[PyTorch](https://pytorch.org/)** vollzogen, um die Implementierung von Transfer Learning und der Multibranch Architektur zu erleichtern. Die Konvertierung der Modelle für die mobile Ausführung wurde mit der **[ONNX Mobile Runtime](https://onnx.ai/)** evaluiert, da diese eine breite Unterstützung für verschiedene Plattformen bietet.

## Datensätze

Das Projekt stützt sich auf den [ISIC2018 Datensatz](https://challenge.isic-archive.com/landing/2018/). Dieser Datensatz wurde im Rahmen eines internationalen Wettbewerbs zur Hautläsionserkennung erstellt, wobei 3 Teilaufgaben definiert wurden: Lesionssegmentierung, Erkennung von Läsionsattributen und Klassifikation von Hautläsionen. 

Für uns relevant sind dabei die Teildatensätze für die Lesionssegmentierung und die Klassifikation. 
Die Segmentierung ist bietet neben den rund 10.000 Bildern von Hautläsionen auch die zugehörigen Segmentierungsmasken, welche die Regionen in den Bildern markieren, die die tatsächliche Läsion darstellen. Diese Masken wurden von Experten manuell erstellt und dienen als Ground Truth für die Entwicklung von Segmentierungsmodellen.
Diese Segmentierungsmaske wurde im Zuge der [ABC-Algorithmen](../abc_algorithms/README.md) als Alternativansatz zur klassischen Bildverarbeitung evaluiert, um die relevanten Läsionsregionen zu extrahieren.

Weiterhin enthält der ISIC2018 Datensatz einen Teildatensatz für die Klassifikation, der auch als [HAM10000 Datensatz](https://www.kaggle.com/datasets/kmader/skin-cancer-mnist-ham10000) bekannt ist. Da die Entwicklung eines Klassifikators ein Hauptziel des Projekts ist, sollen zunächst einige Eckdaten zum HAM10000 Datensatz gegeben werden:

Der Datensatz besteht aus ca. 10.000 dermatologischen Bildern von Hautläsionen, die in 7 Klassen kategorisiert sind. Davon bilden die Klasse "Melanocytic nevi" (nv) mit ca. 6700 Bildern die größte Klasse, gefolgt von "Melanoma" (mel) mit ca. 1100 Bildern und "Benign keratosis-like lesions" (bkl) mit ca. 1000 Bildern. Diese Klassen machen rund 89% der Daten aus, während die restlichen Klassen deutlich unterrepräsentiert sind. Der Datensatz stellt weiterhin Informationen zum Alter, Geschlecht und der Lokalisation der Läsionen bereit, welche als zusätzliche Merkmale für ein Late-Fusion Modell genutzt werden können.

Da für unsere Stakeholderin nur die Unterscheidung zwischen gutartigen und bösartigen Läsionen als Verwendungszweck relevant ist, wurden für die Entwicklung der Modelle nur die beiden Klassen "Melanocytic nevi" (nv) und "Melanoma" (mel) berücksichtigt. Dadurch ergibt sich eine binäre Klassifikationsaufgabe, die allerdings von einem starken Ungleichgewicht von 85:15 geprägt ist, was die Entwicklung eines robusten Modells erschwert.

Insofern wurden verschiedene Strategien evaluiert, um mit diesem Ungleichgewicht umzugehen.


## Klassifikatorentwicklung

Zum Einsatz kamen verschiedene Ansätze, darunter einfache CNN-Architekturen, Transfer Learning mit vortrainierten Modellen und eine eigens konzipierte `Multibranch`-Architektur. 


### Einfache CNNs

Als Basis wurden einfache CNN-Modelle mit wenigen Schichten implementiert und trainiert.
Diese Modelle dienten als Ausgangspunkt, um die grundsätzliche Machbarkeit der Klassifikation auf mobilen Geräten zu testen. Zum Aufbau der Modelle wurde die **TensorFlow Keras API** verwendet, da es in unserem Team bereits Berührungspunkte mit dieser Bibliothek gab.

Zum Zeitpunkt der Erstellung waren noch alle 7 Klassen des HAM10000 Datensatzes in der Klassifikation relevant, weshalb die Modelle auf diesen 7 Klassen trainiert wurden.
Als Ergebnis ist festzuhalten, dass ein händisch aufgebautes CNN mit wenigen Schichten nicht in der Lage, die Komplexität von Hautläsionen ausreichend zu erfassen und ist damit ungeeignet für die Klassifikation von Läsionen.

Die konkrete Schwäche lässt sich aus den Ergebnismetriken des 5. Trainingslaufs ableiten:
```
Class 0: F1 = 0.0000 # Actinic keratoses and intraepithelial carcinoma (akiec)
Class 1: F1 = 0.0278 # Basal cell carcinoma (bcc)
Class 2: F1 = 0.0990 # Benign keratosis-like lesions (bkl)
Class 3: F1 = 0.0000 # Dermatofibroma (df)
Class 4: F1 = 0.7218 # Melanocytic nevi (nv)
Class 5: F1 = 0.1198 # Vascular lesions (vasc)
Class 6: F1 = 0.0000 # Melanoma (mel)

Weighted F1 Score: 0.5089
Macro F1 Score: 0.1383
```

Der Macro F1 Score beschreibt eindeutig, dass das Modell fast ausschließlich die Klasse 4 korrekt klassifiziert, aber in allen anderen Klassen versagt. Dies ist ein klares Indiz für Underfitting, was durch die geringe Anzahl an Schichten und Parametern des Modells zu erklären ist.

### Finetuning vortrainierter Modelle

Nach Vorbild der Literatur wurde als nächster Schritt die Verwendung von vortrainierter Modellen evaluiert. Dazu diente die ResNet-Architekturfamilie als Ausgangspunkt, da diese in der Bildklassifikation weit verbreitet und gut erforscht ist.
Als weiterhin interessante Modelle sind EfficientNet, DenseNet und MobileNet zu nennen, welche ebenfalls in der Literatur häufig für die Klassifikation von Hautläsionen eingesetzt werden und gerade aufgrund ihrer Effizienz und Modellgröße für die mobile Ausführung interessant sind.

Es erfolgte ein Wechsel der Bibliothek von **TensorFlow Keras** zu **PyTorch** erfolgt, da PyTorch als flexibler und benutzerfreundlicher für die Implementierung von Transfer Learning gilt. 

### Multibranch Architektur

Als besondere Aufgabe wurde eine eigene CNN-Architektur entwickelt, die mehrere spezialisierte Branches kombiniert, um verschiedene Merkmale der Hautläsion zu analysieren.
Im Grunde werden dazu mehrere Modelle auf unterschiedlich vorverarbeiteten Versionen der Bilder trainiert, um verschiedene Aspekte der Läsion zu erfassen. Anschließend werden die Vorhersagen der Einzelmodelle kombiniert, um dadurch eine robustere und genauere Klassifikation zu ermöglichen.

Die [Multibranch-Architektur](./multibranch_architecture.md) verspricht eine gesteigerte Performance, indem sie die Stärken verschiedener Modelle und Vorverarbeitungsstrategien kombiniert. Die Implementierung und das Training gestalten sich jedoch komplex. Herausforderungen entstehen insbesondere durch variierende Eingabedaten, Hyperparameter und Modellstrukturen. Daher wurde eine eigenständige Trainingspipeline entwickelt. Diese ermöglicht es, die Vielzahl an Modellen effizient zu trainieren und zu bewerten.

Durch systematisches [Auditing](./pipeline/README.md) sowie die Erfassung von Metriken und Diagrammen sichert die Pipeline zudem die Nachvollziehbarkeit und Reproduzierbarkeit der Ergebnisse. Dies erlaubt einen direkten Vergleich zwischen den Vorhersagen des In-App-Modells und den Resultaten der Trainingsläufe. Die Modellperformance lässt sich somit präzise nachverfolgen, auch nachdem die Modelle in der App deployed wurden.

## Konvertierung für mobile Endgeräte

Im Zuge des Aufbaus einer einfachen CNN-Architektur wurde durch prototypischer Implementierung evaluiert, ob die Modelle auf mobilen Endgeräten lauffähig sind.
Dafür wurde ein trainiertes Keras Modell in das TFLite Format konvertiert und auf einem virtuellen Android Gerät getestet. Zur Inferenz dient die [TFLite Bibliothek](https://pub.dev/packages/tflite_flutter).

Durch die Entwicklung der [Trainingspipeline](./pipeline/README.md) und einen Wechsel zu PyTorch wurde die [ONNX Runtime Mobile](https://onnxruntime.ai/docs/) bewertet, die eine breite Unterstützung für verschiedene Plattformen und eine gute Performance verspricht. 
Wichtig zu beachten ist dabei, dass es für Flutter selbst keine offizielle ONNX Runtime Unterstützung gibt. Stattdessen wurde durch die Flutter Community eine Wrapper-Bibliothek namens [onnxruntime_flutter](https://pub.dev/packages/flutter_onnxruntime) entwickelt, welche die tatsächlich native ONNX Runtime für Android/iOS kapselt.

Weitere Details sind in der [zugehörigen Beschreibung](onnx_export.md) zu finden.

## Trainingsergebnisse

Die Entwicklung der Modelle ist ein iterativer Prozess, bei dem verschiedene Ansätze evaluiert und optimiert werden. In der [Trainingsdokumentation](./training_results.md) werden die Ergebnisse verschiedener Trainingsläufe dokumentiert, um die Entwicklung der Modelle nachvollziehbar zu machen und wertvolle Einblicke in die Auswirkungen von Designentscheidungen zu gewinnen.

## Fazit

- late fusion interessant, aber sprengt zeitrahmen
- Multibranch verspricht gute Performance nach oben genannten Ergebnissen und ist relativ einfach zu implementieren, aber porting auf mobile Platform ist durch nicht-vorhandensein der notwendigen Filter eine Herausforderung
- konstruierte Trainingspipeline ist erwachsener Ansatz um große Mengen an Modellen zu trainieren und zu evaluieren, aber die Implementierung ist aufwendig und erfordert viel Zeit die schon mit der Entwicklung der Modelle verbracht werden könnte
- Training großer Modelle angesichts der begrenzten Ressourcen eine große Herausforderung, die mit einfacher Consumer-Hardware kaum möglich ist. Alternative Cloud-Dienste wurden angedacht, aber aufgrund des hohen Speicheraufwands für die Filter der Multibranch Architektur und der damit verbundenen Kosten nicht weiter verfolgt. Zugriff auf die Hochschulressourcen im Endeffekt optimalste Lösung, aber leider erst sehr spät im Projektverlauf möglich und erfordert eine gewisse Einarbeitungszeit, weshalb die Entwicklung der Modelle bis dahin auf einem lokalen Rechner mit begrenzten Ressourcen erfolgen musste.
- Porting der PyTorch Modelle über ONNX sehr tauglicher Ansatz

## Siehe auch
- [Multibranch Architektur](./multibranch_architecture.md)
- [Trainingspipeline](./pipeline/README.md)
- [Modell Export](./onnx_export.md)
- [Trainingsergebnisse](./training_results.md)
- [Auditierung](./auditing.md)
- [ABC Algorithmen](../abc_algorithms/README.md)
