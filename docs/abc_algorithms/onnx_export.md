# Übertrag von PyTorch-Modellen nach Flutter/Dart

Die in Python trainierten Modelle werden für die App in ein plattformunabhängiges Format exportiert. Hierfür wird ONNX (Open Neural Network Exchange) genutzt.

Für die mobile Inferenz in Flutter wird ONNX Runtime über das Paket `flutter_onnxruntime` eingebunden.

## Vorteile des ONNX-Pfads

- Klare Trennung zwischen dem Training in PyTorch/Python und der Inferenz in Flutter mit ONNX Runtime.
- Einheitliches Modellformat für Android und iOS.
- Reproduzierbarer Exportprozess mit festen Eingabe- und Ausgabesignaturen.
- Gute Wartbarkeit durch versionierbare Modellartefakte.

## Exportprozess

Unabhängig vom Modelltyp umfasst der Export die folgenden Schritte:

1. Die finale Modellarchitektur definieren und die trainierten Gewichte laden.
2. Einen Dummy-Input mit der korrekten Form und dem passenden Datentyp festlegen.
3. Den ONNX-Export mit expliziten Ein- und Ausgaben ausführen.
4. Die ONNX-Ausgabe in Python gegen die PyTorch-Ausgabe validieren.
5. Das Modell in Flutter integrieren und eine erneute Laufzeitvalidierung durchführen.

Modelltypspezifische Unterschiede liegen in der Nachverarbeitung:

- Segmentierung: Die Logits oder Maskenscores werden per Sigmoid und Threshold in binäre Masken überführt.
- Klassifikation: Die Klassenlogits werden in ein Label und eine Konfidenz überführt.

## Wichtige Beobachtung beim Export

Im Projekt zeigte sich, dass der Dynamo-Export in Einzelfällen inkonsistente Ergebnisse erzeugen kann. Die stabilste Variante war der Export mit `dynamo=False`.

## Integration in Flutter

Dart ist strikt typisiert. Deshalb müssen Tensorformate und Datentypen exakt zu Python passen:

- Eingaben als `Float32List`.
- Korrekte Tensorformen gemäß der ONNX-Signatur.
- Identische Vor- und Nachverarbeitung wie in Python.

Zur Absicherung wurde ein direkter Inferenzvergleich mit identischen Testinputs durchgeführt.

- Die Segmentierungsmodelle zeigten sehr kleine numerische Abweichungen.
- Bei einzelnen Klassifikationsmodellen traten größere Differenzen auf und mussten gesondert analysiert werden.

## Hindernis: Filter-Branch

Die gefilterten Branches basieren in Python auf Scikit-Image. Für diese Filter existiert in Dart/Flutter nicht in allen Fällen eine direkt äquivalente Implementierung.

- Die Gabor- und GLCM-Filter konnten in Dart näherungsweise abgebildet werden.
- Für den LBP-Filter liegt aktuell keine ausreichend robuste Portierung vor.

Da für die Filter-Branches in Flutter bislang keine vollständig konsistente Reproduktion erreicht wurde, werden diese Branches derzeit nicht produktiv verwendet. Die RGB-basierten Modelle liefern bereits tragfähige Ergebnisse.

## Siehe auch

- [Machine Learning](./README.md)
- [Experimentergebnisse](./experiment_results.md)