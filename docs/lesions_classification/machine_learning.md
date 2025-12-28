# Machine learning
Die grundlegende Eignung und Funktionsfähigkeit unseres Klassifikationsansatzes wurde in Python implementiert, trainiert und getestet.


## Python Umgebung
Zum Ausführen ist Version 3.13.11 zu empfohlen.
Alle nötigen Bibliotheken sind in [`/python/requirements.txt`](/python/requirements.txt) aufgelistet.
Für pyTorch mit GPU Beschleunigung sollte die [Installationsbeschreibung](https://pytorch.org/get-started/locally/) auf der offiziellen Webseite befolgt werden. 


## Datensätze
Hauptsächlich wurde der [HAM10000 Datensatz](https://www.kaggle.com/datasets/kmader/skin-cancer-mnist-ham10000) zum Training verwendet.
Alle Originalbilder liegen in `/data/raw` und die Metadaten in `/data/HAM10000_metadata.csv`.
Dieser Datensatz wurde künstlich augmentiert, wobei diese Bilddaten ebenfalls in `/data/` liegen.

## Überblick
- Klassifikation der zwei Läsionstypen Melanom und Melanocytic Nevi
- Entwicklung: Training mit PyTorch (Desktop), Inferenz auf Mobilgeräten
- Vergleich von einfachen CNNs, Transfer Learning und [eigener Architektur](/docs/machine_learning/multibranch_architecture.md)
- Evaluation mobiler Bibliotheken: TFLite, ONNX
- Berechnung deterministischer Scores in Ahnlehnung an die [ABCDE-Kritierien](https://www.aad.org/public/diseases/skin-cancer/find/at-risk/abcdes)