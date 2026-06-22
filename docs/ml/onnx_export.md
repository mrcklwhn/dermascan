# Uebertrag von PyTorch-Modellen nach Flutter/Dart

Die in Python trainierten Modelle werden fuer die App in ein plattformunabhaengiges Format exportiert. Hierfuer wird ONNX (Open Neural Network Exchange) genutzt.

Fuer die mobile Inferenz in Flutter wird ONNX Runtime ueber das Paket `flutter_onnxruntime` eingebunden.

## Vorteile des ONNX-Pfads

- Klare Trennung zwischen Training (PyTorch/Python) und Inferenz (Flutter/ONNX Runtime)
- Einheitliches Modellformat fuer Android und iOS
- Reproduzierbarer Exportprozess mit festen Input-/Output-Signaturen
- Gute Wartbarkeit durch versionierbare Modellartefakte

## Exportprozess

Unabhaengig vom Modelltyp umfasst der Export folgende Schritte:

1. Finale Modellarchitektur definieren und trainierte Gewichte laden.
2. Dummy-Input mit korrekter Form und Datentyp festlegen.
3. ONNX-Export mit expliziten Ein- und Ausgaben ausfuehren.
4. ONNX-Ausgabe in Python gegen PyTorch-Ausgabe validieren.
5. Modell in Flutter integrieren und erneute Laufzeitvalidierung durchfuehren.

Modelltypspezifische Unterschiede liegen in der Nachverarbeitung:

- Segmentierung: Logits/Maskenscores werden per Sigmoid und Threshold zu binaeren Masken.
- Klassifikation: Klassenlogits werden in Label und Konfidenz ueberfuehrt.

## Wichtige Beobachtung beim Export

Im Projekt zeigte sich, dass der Dynamo-Export in Einzelfaellen inkonsistente Ergebnisse erzeugen kann. Die stabilste Variante war der Export mit `dynamo=False`.

## Integration in Flutter

Dart ist strikt typisiert. Deshalb muessen Tensorformate und Datentypen exakt zu Python passen:

- Eingaben als `Float32List`
- Korrekte Tensorformen gemaess ONNX-Signatur
- Identische Vor- und Nachverarbeitung wie in Python

Zur Absicherung wurde ein direkter Inferenzvergleich mit identischen Testinputs durchgefuehrt.

- Segmentierungsmodelle zeigten sehr kleine numerische Abweichungen.
- Bei einzelnen Klassifikationsmodellen traten groessere Differenzen auf und mussten gesondert analysiert werden.

## Hindernis Filter-Branch

Die gefilterten Branches basieren in Python auf Scikit-Image. Fuer diese Filter existiert in Dart/Flutter nicht fuer alle Faelle eine direkt aequivalente Implementierung.

- Gabor- und GLCM-Filter konnten in Dart naeherungsweise abgebildet werden.
- Fuer LBP liegt aktuell keine ausreichend robuste Portierung vor.

Da fuer Filter-Branches in Flutter bislang keine vollstaendig konsistente Reproduktion erreicht wurde, werden diese Branches derzeit nicht produktiv verwendet. RGB-basierte Modelle liefern bereits tragfaehige Ergebnisse.

## Siehe auch

- [Machine Learning](./README.md)
- [Trainingsergebnisse](./training_results.md)
