import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:dermascan/core/utils/image_filters.dart';
import 'package:dermascan/core/utils/lesion_utils.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class NeuralLesionClassification {
  RGBModel? rgbModel;
  GaborModel? gaborModel;
  GLCMModel? glcmModel;

  NeuralLesionClassification() {
    rgbModel = RGBModel();
    gaborModel = GaborModel();
    glcmModel = GLCMModel();
  }

  List<double> _extractProbs(Map<String, dynamic> inferenceResult) {
    final double confidence = inferenceResult['confidence'] as double;
    final int labelIdx = inferenceResult['label_int'] as int;
    final List<double> probs = labelIdx == 0
        ? <double>[confidence, 1 - confidence]
        : <double>[1 - confidence, confidence];
    return probs;
  }

  Future<Map<String, dynamic>> run(cv.Mat image) async {
    return rgbModel!.run(image);
  }

  Future<Map<String, dynamic>> runRGB(cv.Mat image) async {
    return rgbModel!.run(image);
  }

  Future<Map<String, dynamic>> runGabor(cv.Mat image) async {
    return gaborModel!.run(image);
  }

  Future<Map<String, dynamic>> runGLCM(cv.Mat image) async {
    return glcmModel!.run(image);
  }

  Future<Map<String, dynamic>> runEnsemble(
    cv.Mat image, {
    double rgbWeight = 0.5,
    double gaborWeight = 0.25,
    double glcmWeight = 0.25,
    bool useSoftVoting = true,
  }) async {
    final List<Map<String, dynamic>> ensembleOutputs = await Future.wait(
      <Future<Map<String, dynamic>>>[
        rgbModel!.run(image),
        gaborModel!.run(image),
        glcmModel!.run(image),
      ],
    );
    final List<double> rgbProbs = _extractProbs(ensembleOutputs[0]);
    final List<double> gaborProbs = _extractProbs(ensembleOutputs[1]);
    final List<double> glcmProbs = _extractProbs(ensembleOutputs[2]);

    if (useSoftVoting) {
      final double nevProb =
          rgbProbs[0] * rgbWeight +
          gaborProbs[0] * gaborWeight +
          glcmProbs[0] * glcmWeight;
      final double melProb =
          rgbProbs[1] * rgbWeight +
          gaborProbs[1] * gaborWeight +
          glcmProbs[1] * glcmWeight;
      final int labelIdx = melProb > nevProb ? 1 : 0;
      final double confidence = labelIdx == 0 ? nevProb : melProb;
      final String labelText = labelIdx == 0 ? 'nev' : 'mel';
      return <String, dynamic>{
        'label_int': labelIdx,
        'label_text': labelText,
        'confidence': confidence,
      };
    } else {
      // Hard voting
      final List<int> votes = <int>[
        ensembleOutputs[0]['label_int'] as int,
        ensembleOutputs[1]['label_int'] as int,
        ensembleOutputs[2]['label_int'] as int,
      ];
      final int nevVotes = votes.where((int v) => v == 0).length;
      final int melVotes = votes.where((int v) => v == 1).length;
      final int labelIdx = melVotes > nevVotes ? 1 : 0;
      final String labelText = labelIdx == 0 ? 'nev' : 'mel';
      return <String, dynamic>{
        'label_int': labelIdx,
        'label_text': labelText,
        'confidence': (melVotes > nevVotes)
            ? (melVotes / votes.length)
            : (nevVotes / votes.length),
      };
    }
  }
}

abstract class NeuralModel {
  OrtSession? _session;
  OrtModelMetadata? _modelMetadata;

  String get modelPath;

  int get inputDims;

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

  Future<Map<String, dynamic>> run(cv.Mat image) async {
    if (_session == null) {
      await initializeModel();
    }

    final Float32List inputData = _preprocess(image);

    final OrtValue inputTensor = await OrtValue.fromList(inputData, <int>[
      1,
      inputDims,
      224,
      224,
    ]);

    final String inputName = _session!.inputNames.first;
    final String outputName = _session!.outputNames.first;

    final Map<String, OrtValue> outputs = await _session!.run(
      <String, OrtValue>{inputName: inputTensor},
    );

    final List<double> logits = (await outputs[outputName]!.asFlattenedList())
        .cast<double>();

    final Map<String, dynamic> result = _postprocess(logits);

    await inputTensor.dispose();
    for (final OrtValue output in outputs.values) {
      await output.dispose();
    }

    return result;
  }

  Float32List _preprocess(cv.Mat image) {
    final cv.Mat rgbImage = cv.cvtColor(image, cv.COLOR_BGR2RGB);
    final cv.Mat resized = cv.resize(rgbImage, (
      224,
      224,
    ), interpolation: cv.INTER_NEAREST);
    final Float32List tensor = Float32List(1 * inputDims * 224 * 224);
    final Uint8List bytes = resized.data;

    final List<double> mean = <double>[0.485, 0.456, 0.406];
    final List<double> std = <double>[0.229, 0.224, 0.225];

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final int index = (y * 224 + x) * inputDims;
        for (int c = 0; c < inputDims; c++) {
          final double normalized =
              (bytes[index + c] / 255.0 - mean[c]) / std[c];
          tensor[c * 224 * 224 + y * 224 + x] = normalized;
        }
      }
    }
    return tensor;
  }

  static Map<String, dynamic> _postprocess(List<double> outputTensor) {
    // outputTensor contains logits for [nv, mel]
    final double logit0 = outputTensor[0];
    final double logit1 = outputTensor[1];

    // Softmax implementation
    final double maxLogit = math.max(logit0, logit1);
    final double exp0 = math.exp(logit0 - maxLogit);
    final double exp1 = math.exp(logit1 - maxLogit);
    final double sumExp = exp0 + exp1;

    final double prob0 = exp0 / sumExp;
    final double prob1 = exp1 / sumExp;

    final int labelIdx = prob1 > prob0 ? 1 : 0;
    final double confidence = labelIdx == 1 ? prob1 : prob0;
    final String labelText = labelIdx == 0 ? 'nev' : 'mel';

    return <String, dynamic>{
      'label_int': labelIdx,
      'label_text': labelText,
      'confidence': confidence,
    };
  }
}

class RGBModel extends NeuralModel {
  @override
  String get modelPath => 'assets/models/resnet18rgb.onnx';

  @override
  int get inputDims => 3;
}

class GaborModel extends NeuralModel {
  @override
  String get modelPath => 'assets/models/resnet18gabor.onnx';

  @override
  int get inputDims => 40;

  @override
  Float32List _preprocess(cv.Mat image) {
    final cv.Mat grayImage = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
    final Float32List filteredImage = ImageFilters.gaborFilter(grayImage);
    final Float32List resizedImage = LesionUtils.multidimResize(
      inputDims,
      224,
      224,
      filteredImage,
      sourceRows: grayImage.rows,
      sourceCols: grayImage.cols,
    );
    final Float32List tensor = Float32List(1 * inputDims * 224 * 224);

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        for (int c = 0; c < inputDims; c++) {
          tensor[c * 224 * 224 + y * 224 + x] =
              resizedImage[c * 224 * 224 + y * 224 + x] / 255.0;
        }
      }
    }
    return tensor;
  }
}

class GLCMModel extends NeuralModel {
  @override
  String get modelPath => 'assets/models/resnet18glcm.onnx';

  @override
  int get inputDims => 32;

  @override
  Float32List _preprocess(cv.Mat image) {
    final cv.Mat grayImage = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
    final Float32List filteredImage = ImageFilters.glcmFilter(grayImage);
    final Float32List resizedImage = LesionUtils.multidimResize(
      inputDims,
      224,
      224,
      filteredImage,
      sourceRows: grayImage.rows,
      sourceCols: grayImage.cols,
    );
    final Float32List tensor = Float32List(1 * inputDims * 224 * 224);

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        for (int c = 0; c < inputDims; c++) {
          tensor[c * 224 * 224 + y * 224 + x] =
              resizedImage[c * 224 * 224 + y * 224 + x] / 255.0;
        }
      }
    }
    return tensor;
  }
}
