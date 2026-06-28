# Glossar

Diese Seite definiert zentrale Begriffe und Abkurzungen der Dermascan-Dokumentation einheitlich.

## Medizin und Klassifikation

- **ABCDE-Regel**: Klinisches Schema zur Ersteinschatzung von Hautlasionen.
- **A (Asymmetrie)**: Bewertung, ob zwei Halften einer Läsion in Form und Struktur voneinander abweichen.
- **B (Begrenzung / Border)**: Bewertung der Randstruktur (regelmäßig vs. unregelmäßig).
- **C (Color / Farbe)**: Bewertung der Farbvielfalt und Farbverteilung innerhalb der äsion.
- **D (Diameter / Durchmesser)**: Bewertung der Größe einer Läsion (klinisch oft > 6 mm als Signal).
- **E (Evolution / Entwicklung)**: Zeitliche Veränderung einer Läsion (Form, Farbe, Größe, Symptome).
- **Melanom**: bösartiger Hauttumor mit hoher klinischer Relevanz.
- **Navus (Leberfleck)**: Meist gutartige melanozytare Hautveränderung.

## Machine Learning und Metriken

- **CNN (Convolutional Neural Network)**: Neuronales Netz für Bilddaten mit Faltungsoperationen.
- **Transfer Learning**: Nutzung vortrainierter Modelle als Ausgangspunkt für neue Aufgaben.
- **Ensemble Voting**: Kombination mehrerer Modelle zu einer gemeinsamen Vorhersage.
- **AUC (Area Under the ROC Curve)**: Schwellenwertunabhängiges Maß der Trennfähigkeit.
- **ROC (Receiver Operating Characteristic)**: Kurve von Sensitivität gegen Falsch-Positiv-Rate.
- **F1-Score**: Harmonisches Mittel aus Precision und Recall.
- **MCC (Matthews Correlation Coefficient)**: Robuste Gesamtmetrik für unausgeglichene Klassen.
- **Sensitivität (Recall für positive Klasse)**: Anteil korrekt erkannter Melanome.
- **Spezifität**: Anteil korrekt erkannter gutartiger Läsionen.
- **Threshold**: Entscheidungsgrenze, ab der eine Wahrscheinlichkeit als positive Klasse gilt.
- **Cross Entropy (CE)**: Verlustfunktion für 

## Plattform und Deployment

- **ONNX (Open Neural Network Exchange)**: Framework-unabhängiges Modellformat für Inferenz.
- **ONNX Runtime**: Laufzeitumgebung zur Ausführung von ONNX-Modellen.
- **On-Device-Inferenz**: Ausführung der Modellvorhersage direkt auf dem Endgerät.
- **Edge Function (Supabase)**: Serverseitige Funktion für validierte, autorisierte Backend-Operationen.
- **RLS (Row Level Security)**: Datenbank-/Storage-Regeln, die Zugriffe auf Zeilenebene erzwingen.
- **JWT (JSON Web Token)**: Signiertes Token zur Authentifizierung und Autorisierung.

## Bildverarbeitung

- **Otsu-Thresholding**: Verfahren zur automatischen Schwellenwertwahl für binäre Segmentierung.
- **U-Net**: Segmentierungsarchitektur mit Encoder-Decoder-Struktur.
- **IoU (Intersection over Union)**: Überschneidungsmetrik zweier Masken.
- **GLCM (Gray Level Co-occurrence Matrix)**: Texturmerkmale aus Grauwerte-Nachbarschaften.
- **LBP (Local Binary Patterns)**: Lokaler Texturdeskriptor auf Basis von Helligkeitsvergleichen.
- **Gabor-Filter**: Filter zur Hervorhebung von Richtungen, Frequenzen und Texturstrukturen.
