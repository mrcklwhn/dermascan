# Algorithmen fuer Laesionsmasken

Die Segmentierung einer Hautlaesion ist ein zentraler Vorverarbeitungsschritt fuer die ABC-Algorithmen. Ziel ist es, die relevante Laesion vom Hintergrund zu trennen, damit Form-, Rand- und Farbmerkmale belastbar berechnet werden koennen.

Da Laesionen sich in Form, Textur, Beleuchtung und Bildqualitaet stark unterscheiden, ist eine robuste Segmentierung anspruchsvoll. Im Projekt wurden deshalb ein klassischer und ein neuronaler Ansatz untersucht.

## Segmentierungsansaetze

### Otsu-Thresholding

Otsu-Thresholding ist ein klassisches Schwellenwertverfahren. Es sucht automatisch einen Grauwert, der Vordergrund und Hintergrund moeglichst gut trennt. Das Ergebnis ist eine binaere Maske.

Vorteile:

- Einfach umzusetzen
- Keine Trainingsdaten erforderlich

Nachteile:

- Sensibel gegen ungleichmaessige Beleuchtung
- Kann Haare und Artefakte nicht immer ausreichend trennen

### U-Net-basierte Segmentierung

Als Alternative wurde ein U-Net-Modell eingesetzt, das fuer die Segmentierung trainiert wurde. Das Modell lernt komplexe Muster und kann in schwierigen Faellen robustere Masken liefern.

Vorteile:

- Potenziell praezisere Segmentierung bei komplexen Bildern

Nachteile:

- Hoeherer Rechenaufwand
- Abhaengigkeit von Trainingsdaten und Modellqualitaet

## Vorverarbeitung

Die Vorverarbeitung unterscheidet sich je nach Ansatz:

### Vorverarbeitung fuer Otsu

1. Das RGB-Bild wird in ein Graustufenbild umgewandelt.
2. Das Graustufenbild wird fuer die Schwellenwertanalyse vorbereitet.

### Vorverarbeitung fuer U-Net

1. Das Bild wird auf die feste Eingabegroesse des Modells (256 x 256) skaliert.
2. Die Pixelwerte werden normalisiert.
3. Die Farbkanalstruktur bleibt erhalten, da das Modell auf RGB-Eingaben trainiert wurde.

## Nachverarbeitung

### Nachverarbeitung fuer Otsu

Der Otsu-Ansatz kann Artefakte wie Haare oder Reflexionen in die Maske aufnehmen. Morphologische Operationen (Closing/Opening) koennen Locher fuellen und kleine Stoerbereiche entfernen. Gleichzeitig besteht dabei die Gefahr, die tatsaechliche Laesionsform zu veraendern.

Im Projekt wurde daher je nach Auswertungskontext sorgfaeltig entschieden, ob eine morphologische Nachbearbeitung angewendet wird.

### Nachverarbeitung fuer U-Net

1. Die Modell-Logits werden mit Sigmoid in Wahrscheinlichkeiten ueberfuehrt.
2. Ein empirisch gewaehlter Threshold (0.7) erzeugt eine binaere Maske.
3. Die Maske wird auf die Originalgroesse zurueckskaliert (`INTER_NEAREST`).

So bleibt die Maskenkante moeglichst stabil und fuer nachgelagerte Analysen nutzbar.

![Segmentierungsbeispiel](../images/neural_lesion_cutout.png)

## Vergleich beider Methoden

Beide Methoden haben unterschiedliche Staerken:

- Otsu ist leichtgewichtig und schnell, aber weniger robust bei schwierigen Aufnahmen.
- U-Net ist oft praeziser, aber modell- und datenabhaengig.

![Maskenvergleich](../images/binary_mask_examples.png)

In der Praxis zeigt sich, dass je nach Bildqualitaet entweder der klassische oder der neuronale Ansatz bessere Ergebnisse liefern kann. Deshalb ist die Bereitstellung beider Verfahren im Prototyp sinnvoll.

## Siehe auch

- [ABC-Algorithmen](./README.md)
- [Machine Learning](../ml/README.md)
