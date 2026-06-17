# Übertrag von PyTorch-Modellen zu Flutter/Dart

Die in Python trainierten Modelle sollen in der App genutzt werden, was eine Portierung der Modelle von Python/PyTorch zu Dart/Flutter erfordert.
Hierfür wird **[ONNX](https://onnx.ai/)** (Open Neural Network Exchange) verwendet. ONNX ermöglicht den Export von Modellen aus Trainingsframeworks wie PyTorch in ein plattformunabhängiges Austauschformat, das in verschiedenen Laufzeitumgebungen ausgeführt werden kann.

Für die mobile Inferenz wird in Flutter eine Runtime wie **[flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)** eingesetzt. Dadurch lassen sich ONNX-Modelle direkt in der App ausführen und je nach Zielplattform mit nativer Beschleunigung nutzen (z.B. CoreML auf iOS oder NNAPI auf Android).

Der Einsatz von ONNX bringt dabei mehrere Vorteile:

- Trennung von Training und Inferenz-Laufzeit (PyTorch in Python, ONNX Runtime in Flutter)
- Einheitliches Modellformat für unterschiedliche Plattformen
- reproduzierbarer Exportprozess durch feste Input-Signaturen und deklarierte Ausgabe-Tensoren
- gute Wartbarkeit, da Modellversionierung und App-Integration klar entkoppelt sind



## Export der Modelle

Unabhängig vom konkreten Modelltyp (Segmentierung oder Klassifikation) folgt der Porting-Prozess denselben Grundschritten:

1. Definition der finalen Modellarchitektur in PyTorch und Laden der trainierten Gewichte
2. Festlegen eines passenden Beispiel-Inputs (Dummy-Tensor) mit korrektem Datentyp und korrekter Form
3. Export in das ONNX-Format inklusive Input-/Output-Namen und Export-Parameter
4. Validierung in Python durch direkten Vergleich von PyTorch- und ONNX-Ausgaben auf identischen Inputs
5. Integration in Flutter und erneuter Inferenzvergleich zwischen Python und App-Laufzeit

Die modelltypspezifischen Unterschiede liegen vor allem in der Nachverarbeitung:

- **Segmentierungsmodelle** liefern typischerweise Logits oder Masken-Scores pro Pixel, die anschließend z.B. per Sigmoid/Threshold in eine binäre Maske überführt werden.
- **Klassifikationsmodelle** liefern Klassen-Logits oder Klassenwahrscheinlichkeiten, die zu Labels und Konfidenzen zusammengefasst werden.


Bei unserem Export hat sich zudem gezeigt, dass der moderne PyTorch Dynamo-Export Probleme verursachen kann. 
Der Dynamo-Export ist eine neuere Methode, die versucht, den Exportprozess zu optimieren, indem er Teile des Modells dynamisch analysiert und optimiert. In einigen Fällen kann dies jedoch zu unerwarteten Problemen führen, insbesondere wenn das Modell komplexe oder nicht-standardmäßige Operationen enthält.
Dies zeigte sich darin, dass für die gleiche Modellkonfiguration und identischen Eingabetensor ein unterschiedlicher Wertebereich der Logits zwischen der Python- und Dart-Umgebung auftrat.
Die stabilste Lösung bestand daher schlicht darin, den Export-Parameter `dynamo=False` zu setzen.

## Integration in Flutter

Nach dem Export eines Modells kann dieses in Flutter integriert werden, indem die ONNX-Datei in das Projekt eingebunden und die `flutter_onnxruntime`-Bibliothek verwendet wird, um die Inferenz durchzuführen.

Im Unterschied zu Python ist Dart eine typisierte Sprache, weshalb die Eingabe- und Ausgabe-Tensoren explizit typisiert und korrekt geformt werden müssen. Als Konsequenz daraus ist zu beachten, dass Python intern mit 32-Bit Fließkommazahlen (float32) arbeitet, während Dart standardmäßig 64-Bit Fließkommazahlen (double) verwendet.
Daher ist es wichtig, die Eingabetensoren in Dart explizit als `Float32List` zu deklarieren, um sicherzustellen, dass die Inferenz mit den richtigen Datentypen durchgeführt wird und die Ergebnisse mit der Python-Implementierung übereinstimmen.

Außerdem müssen die notwendigen Vor- und Nachverarbeitungsschritte, die in Python durchgeführt werden, auch in Dart korrekt implementiert werden, um sicherzustellen, dass die Inferenz-Ergebnisse vergleichbar sind.

Zur Validierung der Inferenzergebnisse zwischen Python und Flutter diente ein Vergleichstest mit identischen Eingabetensoren. Dabei erfolgte ein direkter Vergleich der Logits aus der Python-Implementierung mit jenen aus der Flutter-Implementierung, um deren Übereinstimmung sicherzustellen.

Die Tests zeigen, dass die Logits für das Lesionsmasken-Modell nahezu identisch sind, was auf einen erfolgreichen Export und eine korrekte Integration in Flutter schließen lässt. Die Abweichungen lagen im Bereich von 1e-8, was auf numerische Unterschiede zwischen den Laufzeitumgebungen zurückzuführen sein könnte, aber insgesamt als sehr gut angesehen werden kann.

Bei den Klassifikationsmodellen gab es jedoch teilweise größere Abweichungen, insbesondere bei EfficientNet-Varianten, was auf mögliche Unterschiede in der Implementierung oder numerischen Stabilität der Bibliotheken hinweisen könnte. Daher ist es generell wichtig, vor dem produktiven Einsatz eines exportierten Modells einen expliziten Inferenzvergleich mit identischen Testinputs durchzuführen, um sicherzustellen, dass die Ergebnisse zwischen Python und Flutter konsistent sind.


## Hinderniss Filter-Branch

Die Vorverarbeitung der gefilterten Bilddaten basiert im Trainingsprozess auf der Python-Bibliothek **Scikit-Image** (skimage), für die in der Dart-/Flutter-Umgebung keine native Äquivalenz existiert.
Da einige Modelle mit gefilterten Bildern trainiert sind und die Kombination von RGB- und gefilterten Bildern einen positiven Effekt auf die Performance zeigt (siehe [Zwischenergebnisse](./training_results.md) des Trainings), stellt dies eine Herausforderung für die Portierung dar.

Ein direkter Rückfall auf die bei den [ABC-Algorithmen](../abc_algorithms/README.md) genutzte OpenCV-Bibliothek war aufgrund der fehlenden Entsprechungen für alle Skimage-Filter nicht möglich, weshalb ein Portierungsversuch der Algorithmen durch KI-gestützte Code-Übersetzungen in Dart unternommen wurde:

- **Gabor- und GLCM-Filter**: Es konnte eine mathematisch äquivalente Implementierung in Dart erstellt werden, die in der App genutzt werden kann.
- **LBP-Filter**: Es konnte bisher keine zufriedenstellende Übersetzung gefunden werden, die aber aufgrund der hohen Performance der Modelle ohne LBP vorerst nicht weiter verfolgt wird.

Die Verifikation der Filtermethoden in Flutter gestaltet sich als schwierig, da Flutter selbst im Debugging-Modus nicht die Möglichkeit bietet, ganze Arrays von Bildpixeln zu inspizieren, um die Abweichungen zwischen den gefilterten Bildern in Python und Dart zu validieren. Daher musste hier zunächst auf die Validierung durch Vergleich der Inferenz-Ergebnisse, also konkreten Klassen bzw. Wahrscheinlichkeiten des Klassifikationsmodells, zurückgegriffen werden. Dabei zeichnete sich jedoch ab, dass die Modelle mit gefilterten Bildern in Flutter deutliche Abweichungen in den Klassifikationsergebnissen zeigten, was auf mögliche Unterschiede in der Filterimplementierung oder der Vorverarbeitung hindeuten könnte. 

Da bislang also kein vollständig konsistenter Übertrag der Filtermethoden möglich war, wird die Nutzung der Filter-Branches in der App vorerst nicht weiter verfolgt. Ohnehin bieten die Modelle auf RGB-Basis bereits eine gute Performance.


## Siehe auch
- [Machine Learning](./README.md)
- [Trainingsergebnisse](./training_results.md)