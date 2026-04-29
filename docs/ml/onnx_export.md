# Übertrag von Pytorch Modellen zu Flutter/Dart

## Export des Lesionsmasken-Modells

Im Notebook [lesion_cutout_model_export](../../python/onnx_porting/lesion_cutout_model_export.ipynb) soll das fertig trainierte UNet-Modell in die plattformübergreifend kompatible ONNX-Bibliothek (Open Neural Network Exchange) exportiert werden, um es auf mobilen Endgeräten nutzen zu können. Hierfür ist es notwendig, sowohl die genaue Modellarchitektur zu definieren als auch einen passenden Beispiel-Tensor. Die ONNX Bibliothek erstellt einen sogenannten Execution-Graph, der die inneren Rechenoperationen des Modells aufzeichnet. Dieser Graph ist eine unabhängige Darstellung des Modells, die von verschiedenen Frameworks und Plattformen interpretiert werden kann. Aus diesem Grund ist ein typisierter Bespiel-Tensor zwingend erforderlich, damit der Execution-Graph durch einen dynamischen Durchlauf (Trace) des Modells erstellt werden kann. 

Bei unserem Export hat sich zudem gezeigt, dass der moderne PyTorch Dynamo-Export Probleme verursachen kann. Das wurde daran festgestellt, dass für die gleiche Modellkonfiguration und identischem Eingabetensor ein unterschiedlicher Wertebereich der Logits entstanden ist. 
Die stabilste Lösung bestand daher schlicht darin, den Export-Parameter `dynamo=False` zu setzen.

### Datenformate: Inputs und Logits
Eingabe-Daten (Inputs): Das Modell erwartet in diesem Fall einen Daten-Tensor vom Typ `float32`. Die Eingabedimensionen lauten `[1, 3, 256, 256]` (entspricht: Batch-Size 1, 3 Farbkanäle für RGB, 256 Pixel Höhe, 256 Pixel Breite). Die Bildwerte sind dabei auf ein Intervall zwischen `0.0` und `1.0` skaliert.

Ausgabe-Daten (Logits): Die vom Modell zurückkommenden Werte sind unskalierte und nicht-normalisierte Aktivierungswerte (die Logits) vom Typ `float32`. Je nach Eingabebedienungen und Gewichten können diese nach außen ausgegebenen Modell-Logits beispielhaft Werte zwischen `-7.42` und `8.89` annehmen. Zur tatsächlichen Interpretation als Lesionsmaske müssen die Logits nachverarbeitet werden, u.a. durch Anwendung einer Sigmoid-Funktion. Diese Nachverarbeitung ist für Python und Dart identisch.

## Integration in Flutter

Um die Modelle in der App zu betreiben, wird das Flutter-Paket [`flutter_onnxruntime`](https://pub.dev/packages/flutter_onnxruntime) herangezogen. Bei dieser Bibliothek handelt es sich eigentlich "nur" um eine Wrapper-Schnittstelle. Unter der Haube kommuniziert dieser Wrapper direkt mit den offiziell unterstützten, nativen C/C++ ONNX-Builds der jeweiligen Entwicklungsumgebungen (Apple CoreML für iOS oder NNAPI für Android). Dies garantiert maximale Hardware-Beschleunigung bei gleichzeitiger plattformunabhängiger Syntax.

### Inferenz in Dart
Dank der Abkapselung ist die eigentliche Inferenz-Ausführung in Dart unkompliziert:

```dart
Future<Uint8List> runInference() async {
  final Float32List inputData = _preprocess(_cachedImage!);

  OrtValue inputTensor = await OrtValue.fromList(
    inputData,
    [1, 3, 256, 256],
  );

  final String inputName = _session!.inputNames.first;
  final String outputName = _session!.outputNames.first;

  final outputs = await _session!.run({
    inputName: inputTensor,
  });

  final List<double> maskScores = (await outputs[outputName]!.asFlattenedList()).cast<double>();

  return _postprocess(maskScores);
}
```

Das ONNX Model rechnet im 32-Bit Fließkommazahlen (`float32`). In Dart gibt es allerdings keinen primitiven Datentypen dafür, zwingend ein cast zu 64-Bit `double` notwendig ist.

**Verarbeitung & Aufbereitung der Daten:**
Die im Code-Snippet ersichtlichen Methoden `_preprocess` und `_postprocess` sind Teil des [Läsionsmaskenmodells](./lesion_cutout.md) und werden dort näher erklärt.
Für das Klassifikationsmodell sind die Schritte ähnlich, allerdings mit einem anderen Ausgabeformat und einer anderen Nachverarbeitung der Logits.

## Ergebnisse

Wie im bereits genannten Notebook nachzulesen ist, sind die Ausgaben der PyTorch und ONNX-Modelle identisch, was die Korrektheit des Exports bestätigt. Auch bei Inferenz in Dart mit der `flutter_onnxruntime` Bibliothek konnten die gleichen Wertebereiche der Logits beobachtet werden, was auf eine erfolgreiche Integration hindeutet.