# Machine learning
Die grundlegende Eignung und Funktionsfähigkeit unseres Klassifikationsansatzes wurde in Python implementiert, trainiert und getestet.


## Python Umgebung
Zum Ausführen ist Version 3.13.11 zu empfohlen.
Alle nötigen Bibliotheken sind in [`/python/requirements.txt`](/python/requirements.txt) aufgelistet.
Für pyTorch mit GPU Beschleunigung sollte die [Installationsbeschreibung](https://pytorch.org/get-started/locally/) auf der offiziellen Webseite befolgt werden. 
Die python Umgebung wurde ausschließlich für die Modellentwicklung und Evaluation genutzt.

### Projektstruktur

```
python/
├── requirements.txt
├── ham10000_overview.ipynb       # Datensatzübersicht und -analyse
├── dataset_manager.py            # Manager für Datensatz (Laden, Augmentieren, Aufteilen)
├── abcd_algorithms/              # Deterministische ABC-Kriterien
│   ├── enhanced_lesion_cutout/   # Neuronale Segmentierung der Läsionsmaske
│   └── ...                       # Notizbücher und Skripte für die Implementierung der ABC-Kriterien
├── dualbranch/                   # Implementierung der Trainingspipeline für die Multibranch Architektur
├── ensemble_voting/              # Implementerung des Ensemble Voting Moduls
├── onnx_porting/                 # Skript und Notizbuch zur Konvertierung von PyTorch Modellen in ONNX Format
├── pipeline/                     # Ablage für ML-Pipeline Komponenten
├── preprocessing/                # Ablage für Vorverarbeitungs- und Augmentierungsfunktionen
├── prototypes/
|   ├── simple_cnn_training/      # Primitive CNN-Modelle
|   │   └── simple_resnet_finetuning.ipynb
|   └── resnet_finetuning/        # Transfer Learning mit ResNet50
|       └── simple_resnet_finetuning.ipynb
└── results/                      # Diagramme und Metriken der Trainingsläufe

```

## Datensätze
Für das Training des Klassifikators und eines neuronalen Segmentierungsmodells wurde der [ISIC2018 Datensatz](https://challenge.isic-archive.com/landing/2018/) verwendet. Dieser Datensatz wurde im Rahmen eines internationalen Wettbewerbs zur Hautläsionserkennung erstellt, wobei 3 Teilaufgaben definiert wurden: Lesionssegmentierung, Erkennung von Läsionsattributen und Klassifikation von Hautläsionen. 

Letzteres ist ein Subset, dass auch als [HAM10000 Datensatz](https://www.kaggle.com/datasets/kmader/skin-cancer-mnist-ham10000) bekannt ist und 10015 Bilder von Hautläsionen enthält, die in 7 Klassen kategorisiert sind. Aufgrund der Anforderungen durch unsere Kundin, werden nur die zwei Klassen Melanom und Melanocytic Nevi klassifiziert.

Dieser Datensatz wurde unsererseits durch die Anwendung verschiedener Bildfilter (z.B. LBP, Gabor und GLCM) augmentiert, um die Relevanz von Texturmerkmalen zu analysieren.

Eine detaillierte Übersicht über die Datenanalyse und -vorbereitung findet sich in [`ham10000_overview.ipynb`](/python/ham10000_overview.ipynb). Eine Kernaussage des Notizbuchs ist, dass es ein hohes Ungleichgewicht zwischen den Klassen gibt, was durch gezielte Augmentation und Sampling-Strategien adressiert werden muss.

## Klassifikatorentwicklung
Hauptziel ist die Entwicklung eines Klassifikators, der auf mobilen Endgeräten lauffähig ist.
Dafür wurden verschiedene Ansätze evaluiert, darunter einfache CNN-Architekturen, Transfer Learning mit vortrainierten Modellen und eine eigens entwickelte `Multibranch`-Architektur. 

Das Training wurde in Python mit der `PyTorch`-Bibliothek durchgeführt. Eine weitere Herausforderung bestand insofern im Übertrag der Modelle auf die Flutter Umgebung und der Evaluierung der Inferenzgeschwindigkeit und -genauigkeit auf dieser Plattform.

### Einfache CNNs

Als Basis wurden einfache CNN-Modelle mit wenigen Schichten implementiert und trainiert.
Diese Modelle dienten als Ausgangspunkt, um die grundsätzliche Machbarkeit der Klassifikation auf mobilen Geräten zu testen. Zum Aufbau der Modelle wurde die TensorFlow Keras API verwendet, da es in unserem Team bereits Berührungspunkte mit dieser Bibliothek gab.

Zum Zeitpunkt der Erstellung waren noch alle 7 Klassen des HAM10000 Datensatzes in der Klassifikation relevant, weshalb die Modelle auf diesen 7 Klassen trainiert wurden.
Wie im [Notizbuch zum Training eines einfachen CNNs](/python/prototypes/simple_cnn/simple_resnet_finetuning.ipynb) beschrieben, ist ein händisch aufgebautes CNN mit wenigen Schichten nicht in der Lage, die Komplexität von Hautläsionen ausreichend zu erfassen und ist damit ungeeignet für die Klassifikation von Läsionen.

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
Die zugehörigen Artefakte sind in `/python/prototypes/resnet_finetuning/` dokumentiert.
Insofern ist ein Wechsel der Bibliothek von TensorFlow Keras zu PyTorch erfolgt, da PyTorch als flexibler und benutzerfreundlicher für die Implementierung von Transfer Learning gilt. Weiterhin bietet PyTorch breitere Anbindung an Bibliotheken für die Modellkonvertierung zu mobilen Formaten.



### Multibranch Architektur

Als besondere Aufgabe wurde eine eigene CNN-Architektur entwickelt, die mehrere spezialisierte Branches kombiniert, um verschiedene Merkmale der Hautläsion zu analysieren.

Nähere Informationen zur Multibranch Architektur finden sich in der [zugehörigen Beschreibung](multibranch_architecture.md).


## Anwendung von ABCDE-Kriterien

Ein klassischer Arbeitsschritt von Dermatologen bei der Analyse von Hautläsionen ist die Anwendung der sogenannten [ABCDE-Kriterien](https://www.aad.org/public/diseases/skin-cancer/find/at-risk/abcdes), die verschiedene visuelle Merkmale einer Läsion bewerten.

Diese Kriterien sind:

- **A**: Asymmetry (Asymmetrie)
- **B**: Border (Grenzziehung)
- **C**: Color (Farbvarianz)
- **D**: Diameter (Durchmesser)
- **E**: Evolution (Veränderung über die Zeit)

Da die Kriterien als weit verbreitet und klinisch relevant gelten, sollten sie in unserem Projekt ebenfalls berücksichtigt werden. Allerdings ist die direkte Implementierung von Evolution (D) und Diameter (E) aufgrund der fehlenden zeitlichen Daten und der Skalierungsproblematik nicht trivial, weshalb der Fokus auf die Kriterien A, B und C gelegt wurde.

Die Algorithmen sind als deterministisch zu betrachten und dienen im Vergleich zum CNN-Klassifikator nicht der eigentlichen Klassifikation, sondern vielmehr der Merkmalsextraktion und -quantifizierung. Damit sollen erklärbare Informationen über die Läsion bereitgestellt werden, die für den Arzt nachvollziehbar sind und die Entscheidungsfindung unterstützen können.

Nähere Informationen zu den implementierten Algorithmen zur Merkmalsextraktion in Anlehnung an die ABCD-Kriterien finden sich in der [zugehörigen Beschreibung](abc_algorithms.md).

### Segmentierungsalgorithmen

Für die Berechnung zu den ABC-Kriterien muss die eigentliche Läsion von ihrem Hintergrund getrennt werden. Die Segmentierung wird in Form einer sogennanten binären Maske durchgeführt, die für jedes Pixel angibt, ob es zur Läsion gehört oder nicht.

Details zu den beiden getesteten Ansätzen finden sich in der [zugehörigen Beschreibung](lesion_cutout.md). Darin sind auch die Vor- und Nachverarbeitungsschritte beschrieben, die für beide Ansätze notwendig sind, um die Qualität der Segmentierungsergebnisse zu verbessern.

## Konvertierung für mobile Endgeräte

Im Zuge des Aufbaus einer einfachenn CNN-Architektur wurde durch prototypischer Implementierung evaluiert, ob die Modelle auf mobilen Endgeräten lauffähig sind.
Dafür wurde ein trainiertes Keras Modell in das TFLite Format konvertiert und auf einem virtuellen Android Gerät getestet. Zur Inferenz dient die [TFLite Bibliothek](https://pub.dev/packages/tflite_flutter).

Durch den Wechsel zu PyTorch sollte eine alternative Konvertierung evaluiert werden, um die Modelle auf mobilen Endgeräten lauffähig zu machen. Dafür bietet sich die [ONNX Runtime Mobile](https://onnxruntime.ai/docs/) an, die eine breite Unterstützung für verschiedene Plattformen und eine gute Performance verspricht. 
Wichtig zu beachten ist dabei, dass es für Flutter selbst keine offizielle ONNX Runtime Unterstützung gibt. Stattdessen wurde durch die Flutter Community eine Wrapper-Bibliothek namens [onnxruntime_flutter](https://pub.dev/packages/flutter_onnxruntime) entwickelt.

Weitere Details sind in der [zugehörigen Beschreibung](onnx_export.md) zu finden.
