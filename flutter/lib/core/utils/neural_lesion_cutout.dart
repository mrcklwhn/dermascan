import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class NeuralLesionCutout {
  OrtSession? _session;
  OrtModelMetadata? _modelMetadata;
  final String modelPath;

  NeuralLesionCutout({this.modelPath = 'assets/models/unet1.onnx'});

  Future<void> initializeModel() async {
    _session ??= await OnnxRuntime().createSessionFromAsset(modelPath);
    _modelMetadata = await _session!.getMetadata();
  }

  Future<OrtModelMetadata> getModelMetadata() async {
    if (_modelMetadata == null) {
      await initializeModel();
    }
    return _modelMetadata!;
  }

  Future<cv.Mat> run(cv.Mat image) async {
    if (_session == null) {
      await initializeModel();
    }

    final Float32List inputData = preprocess(image);

    final OrtValue inputTensor = await OrtValue.fromList(
      inputData,
      <int>[1, 3, 256, 256],
    );

    final String inputName = _session!.inputNames.first;
    final String outputName = _session!.outputNames.first;

    final Map<String, OrtValue> outputs = await _session!.run(<String, OrtValue>{
      inputName: inputTensor,
    });

    final List<double> maskScores = (await outputs[outputName]!.asFlattenedList()).cast<double>();

    final cv.Mat rawMask = postprocess(maskScores);

    await inputTensor.dispose();
    for (final OrtValue output in outputs.values) {
      await output.dispose();
    }

    return rawMask;
  }

  static Float32List preprocess(cv.Mat image) {
    final cv.Mat rgbImage = cv.cvtColor(image, cv.COLOR_BGR2RGB);
    final cv.Mat resized = cv.resize(rgbImage, (256, 256), interpolation: cv.INTER_NEAREST);
    final Float32List tensor = Float32List(1 * 3 * 256 * 256);
    final Uint8List bytes = resized.data;
    for (int y = 0; y < 256; y++) {
      for (int x = 0; x < 256; x++) {
        final int index = (y * 256 + x) * 3;
        tensor[0 * 256 * 256 + y * 256 + x] = bytes[index + 0] / 255.0; 
        tensor[1 * 256 * 256 + y * 256 + x] = bytes[index + 1] / 255.0; 
        tensor[2 * 256 * 256 + y * 256 + x] = bytes[index + 2] / 255.0; 
      }
    }
    return tensor;
  }

  static cv.Mat postprocess(List<double> outputTensor) {
    final List<int> bytes = List<int>.filled(256 * 256, 0);
    const double probThreshold = 0.7;
    for (int i = 0; i < 256 * 256; i++) {
      final double logit = outputTensor[i];
      final double p = 1.0 / (1.0 + math.exp(-logit));
      bytes[i] = p >= probThreshold ? 255 : 0;
    }
    return cv.Mat.fromList(256, 256, cv.MatType.CV_8UC1, bytes);
  }
}
