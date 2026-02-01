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
├── preprocessing/
│   ├── image_filters.py          # 3D RGB → 3D B/W Filter
│   ├── pipeline_resnet_finetuning.ipynb
│   └── resnet_finetune_train.py
├── abcd_algorithms/              # Deterministische ABCD-Kriterien
│   ├── asymmetry_analysis.ipynb
│   ├── asymmetry_scorer.py
│   ├── border_analysis.ipynb
│   ├── border_scorer.py
│   ├── color_analysis.ipynb
│   ├── color_scorer.py
│   └── mask_utils.py             # Hilfsfunktionen für Segmentierungsmasken
├── pipeline/                                   # Ablage für ML-Pipeline Komponenten
│   ├── dataset_loader.py                       # lädt Daten (Filter/RGB) beim Training in das Model 
│   ├── resnet_finetune_train.py                # Model Training und Evaluation
│   └── pipeline_resnet_finetuning.ipynb        # Test für Model Traing
└── prototypes/
    ├── simple_cnn_training/      # Primitive CNN-Modelle
    │   └── simple_resnet_finetuning.ipynb
    └── resnet_finetuning/        # Transfer Learning mit ResNet50
        └── simple_resnet_finetuning.ipynb
```

## Datensätze
Hauptsächlich wurde der [HAM10000 Datensatz](https://www.kaggle.com/datasets/kmader/skin-cancer-mnist-ham10000) zum Training verwendet.
Alle Originalbilder wurden in `/data/raw` und die Metadaten in `/data/HAM10000_metadata.csv` abgelegt.
Dieser Datensatz wurde künstlich augmentiert, wobei diese Bilddaten ebenfalls in `/data/` liegen.

Aufgrund der gegebenen Anforderungen durch unsere Kundin, werden nur die zwei Klassen Melanom und Melanocytic Nevi klassifiziert.

## Klassifikatorentwicklung
Hauptziel ist die Entwicklung eines Klassifikators, der auf mobilen Endgeräten lauffähig ist.
Dafür wurden verschiedene Ansätze evaluiert, darunter einfache CNN-Architekturen, Transfer Learning mit vortrainierten Modellen und eine eigens entwickelte `Multibranch`-Architektur.

### Einfache CNNs

Als Basis wurden einfache CNN-Modelle mit wenigen Schichten implementiert und trainiert.
Diese Modelle dienten als Ausgangspunkt, um die grundsätzliche Machbarkeit der Klassifikation auf mobilen Geräten zu testen.
Der zugehörigen Artefakte sind in `/python/prototypes/simple_cnn/` dokumentiert.

### Finetuning vortrainierter Modelle

Als realistischere Lösung wurden vortrainierte Modelle wie `ResNet50` nachtrainiert.
Die zugehörigen Artefakte sind in `/python/prototypes/resnet_finetuning/` dokumentiert.

### Multibranch Architektur

Als besondere Aufgabe wurde eine eigene CNN-Architektur entwickelt, die mehrere spezialisierte Branches kombiniert, um verschiedene Merkmale der Hautläsion zu analysieren.
Nähere Informationen zur Multibranch Architektur finden sich in der [zugehörigen Beschreibung](/docs/ml/multibranch_architecture.md).

### Deterministische ABCD-Kriterien

Die Nachvollziehbarkeit der Klassifikationsentscheidung ist im medizinischen Kontext von großer Bedeutung.
Insofern wurden deterministische Algorithmen zur Merkmalsextraktion implementiert, die auf den ABCD-Kriterien basieren.
Diese dienen in erster Linie dazu dem Arzt weitere erklärbare Informationen zur Verfügung zu stellen, unabhängig von der eigentlichen Klassifikation durch das CNN.

Nähere Informationen zu den implementierten Algorithmen zur Merkmalsextraktion in Anlehnung an die ABCD-Kriterien finden sich in der [zugehörigen Beschreibung](/docs/ml/abc_algorithms.md).

### Konvertierung für mobile Endgeräte

Es wurde per prototypischer Implementierung evaluiert, ob die Modelle auf mobilen Endgeräten lauffähig sind.
Dafür wurde ein Keras Modell in das TFLite Format konvertiert und auf einem virtuellen Android Gerät getestet.
Zur Inferenz wurde die [TFLite Bibliothek](https://pub.dev/packages/tflite_flutter) in Flutter verwendet.
Weiterhin getestet werden soll die [ONNX Runtime Mobile](https://onnxruntime.ai/docs/) für iOS und Android.