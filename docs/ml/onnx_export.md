# Übertrag von Pytorch Modellen zu Flutter/Dart

## Export des Klassifikations-Modells


## Export des Lesionsmasken-Modells

Im Notebook `lesion_cutout_model_export` soll das fertig trainierte UNet-Modell in die plattformübergreifend kompatible ONNX-Bibliothek (Open Neural Network Exchange) exportiert werden, um es nahtlos auf Endgeräten nutzen zu können. Hierfür ist es notwendig, sowohl die genaue Modellarchitektur zu definieren als auch einen passenden Beispiel-Tensor bereitzustellen. Letzteres ist beim Export besonders wichtig und hat einen simplen Grund: 

**ONNX benötigt den typisierten Beispiel-Tensor zwingend dazu, um den sogenannten Execution-Graph des Modells einmal dynamisch zu durchlaufen (Trace) und dabei alle inneren Dimensionen und Rechenoperationen aufzuzeichnen.**

*Hinweis:* Bei unserem Export hat sich gezeigt, dass der moderne PyTorch Dynamo-Export Probleme verursachen kann. Die stabilste Lösung bestand daher schlicht darin, den Export-Parameter `dynamo=False` zu setzen.

### Datenformate: Inputs und Logits
* **Eingabe-Daten (Inputs):** Das Modell erwartet in diesem Fall einen Daten-Tensor vom Typ `float32`. Die Eingabedimensionen lauten `[1, 3, 256, 256]` (entspricht: Batch-Size 1, 3 Farbkanäle für RGB, 256 Pixel Höhe, 256 Pixel Breite). Die Bildwerte sind dabei auf ein Intervall zwischen `0.0` und `1.0` skaliert.
* **Ausgabe-Daten (Logits):** Die vom Modell zurückkommenden Werte sind unskalierte und nicht-normalisierte Aktivierungswerte (die Logits) vom Typ `float32`. Je nach Eingabebedienungen und Gewichten können diese nach außen ausgegebenen Modell-Logits bei einem voll trainierten Netz beispielhaft Werte zwischen `-7.4` und `+8.8` umfassen.

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
Die im Code-Snippet ersichtlichen Methoden `_preprocess` und `_postprocess` sind Teil der [Neural Lesion Cutout Model](./neural_lesion_cutout.md) und werden dort näher erklärt.