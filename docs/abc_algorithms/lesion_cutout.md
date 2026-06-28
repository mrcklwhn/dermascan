# Algorithmen für Läsionsmasken

Die Segmentierung einer Hautläsion ist ein zentraler Vorverarbeitungsschritt für die ABC-Algorithmen. Ziel ist es, die relevante Läsion vom Hintergrund zu trennen, damit Form-, Rand- und Farbmerkmale belastbar berechnet werden können.

Da Läsionen sich in Form, Textur, Beleuchtung und Bildqualität stark unterscheiden, ist eine robuste Segmentierung anspruchsvoll. Im Projekt wurden deshalb ein klassischer und ein neuronaler Ansatz untersucht.

## Segmentierungsansätze

### Otsu-Thresholding

Otsu-Thresholding ist ein klassisches Schwellenwertverfahren. Es sucht automatisch einen Grauwert, der Vordergrund und Hintergrund möglichst gut trennt. Das Ergebnis ist eine binäre Maske.

Vorteile:

- Einfach umzusetzen
- Keine Trainingsdaten erforderlich

Nachteile:

- Sensibel gegen ungleichmässige Beleuchtung
- Kann Haare und Artefakte nicht immer ausreichend trennen

### U-Net-basierte Segmentierung

Als Alternative wurde ein U-Net-Modell eingesetzt, das für die Segmentierung trainiert wurde. Das Modell lernt komplexe Muster und kann in schwierigen Fällen robustere Masken liefern.

Vorteile:

- Potenziell präzisere Segmentierung bei komplexen Bildern

Nachteile:

- Höherer Rechenaufwand
- Abhängigkeit von Trainingsdaten und Modellqualität

## Vorverarbeitung

Die Vorverarbeitung unterscheidet sich je nach Ansatz:

### Vorverarbeitung für Otsu

1. Das RGB-Bild wird in ein Graustufenbild umgewandelt.
2. Das Graustufenbild wird für die Schwellenwertanalyse vorbereitet.

### Vorverarbeitung für U-Net

1. Das Bild wird auf die feste Eingabegrösse des Modells (256 x 256) skaliert.
2. Die Pixelwerte werden normalisiert.
3. Die Farbkanalstruktur bleibt erhalten, da das Modell auf RGB-Eingaben trainiert wurde.

## Nachverarbeitung

### Nachverarbeitung für Otsu

Der Otsu-Ansatz kann Artefakte wie Haare oder Reflexionen in die Maske aufnehmen. Morphologische Operationen (Closing/Opening) können Locher füllen und kleine Störbereiche entfernen. Gleichzeitig besteht dabei die Gefahr, die tatsächliche Läsionsform zu verändern.

Im Projekt wurde daher je nach Auswertungskontext sorgfältig entschieden, ob eine morphologische Nachbearbeitung angewendet wird.

### Nachverarbeitung für U-Net

1. Die Modell-Logits werden mit Sigmoid in Wahrscheinlichkeiten überführt.
2. Ein empirisch gewählter Threshold (0.7) erzeugt eine binäre Maske.
3. Die Maske wird auf die Originalgrösse zurückskaliert (`INTER_NEAREST`).

So bleibt die Maskenkante möglichst stabil und für nachgelagerte Analysen nutzbar.

![Segmentierungsbeispiel](../images/neural_lesion_cutout.png)

## Vergleich beider Methoden

Beide Methoden haben unterschiedliche Stärken:

- Otsu ist leichtgewichtig und schnell, aber weniger robust bei schwierigen Aufnahmen.
- U-Net ist oft präziser, aber modell- und datenabhängig.

![Maskenvergleich](../images/binary_mask_examples.png)

In der Praxis zeigt sich, dass je nach Bildqualität entweder der klassische oder der neuronale Ansatz bessere Ergebnisse liefern kann. Deshalb ist die Bereitstellung beider Verfahren im Prototyp sinnvoll.

## Siehe auch

- [ABC-Algorithmen](./README.md)
- [Machine Learning](../ml/README.md)
