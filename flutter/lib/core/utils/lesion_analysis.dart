import 'dart:math' as math;

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:dermascan/core/utils/lesion_utils.dart';
import 'package:dermascan/core/utils/neural_lesion_classification.dart';
import 'package:dermascan/core/utils/neural_lesion_cutout.dart';
import 'package:dermascan/core/utils/otsus_lesion_cutout.dart';

class LesionAnalysis {
  late cv.Mat rawLesionMask;
  late cv.Mat cleanedLesionMask;
  cv.Mat image;

  // Cache scores and masks
  double asymmetryScore = 0.0;
  double borderScore = 0.0;
  double colorUniformityScore = 0.0;

  cv.Mat? _lesionContourMask;
  cv.Mat? _rotatedMask;
  cv.Mat? _convexHullMask;
  cv.Mat? _concavityMask;

  cv.Mat? get rotatedMask => _rotatedMask;

  // Cache classification
  int? labelIdx;
  double? labelConfidence;
  String? labelText;

  late NeuralLesionCutout _neuralCutout;
  late NeuralLesionClassification _neuralLesionClassification;

  LesionAnalysis(this.image) {
    _neuralCutout = NeuralLesionCutout();
    _neuralLesionClassification = NeuralLesionClassification();
  }

  Future<void> runLesionAnalysis({
    bool useNeuralModel = false,
    String modelType = 'RGB',
  }) async {
    if (useNeuralModel) {
      await _neuralCutout.initializeModel();
      rawLesionMask = await _neuralCutout.run(image);
      rawLesionMask = cv.resize(rawLesionMask, (
        image.cols,
        image.rows,
      ), interpolation: cv.INTER_NEAREST);
    } else {
      rawLesionMask = OtsusLesionCutout().run(image);
    }

    // Classification
    Map<String, dynamic> inferenceResult = <String, dynamic>{};
    if (modelType == 'Gabor') {
      inferenceResult = await _neuralLesionClassification.runGabor(image);
    } else if (modelType == 'GLCM') {
      inferenceResult = await _neuralLesionClassification.runGLCM(image);
    } else if (modelType == 'SoftEnsemble') {
      inferenceResult = await _neuralLesionClassification.runEnsemble(image);
    } else if (modelType == 'HardEnsemble') {
      inferenceResult = await _neuralLesionClassification.runEnsemble(
        image,
        useSoftVoting: false,
      );
    } else {
      inferenceResult = await _neuralLesionClassification.runRGB(image);
    }

    labelIdx = inferenceResult['label_int'] as int?;
    labelConfidence = inferenceResult['confidence'] as double?;
    labelText = inferenceResult['label_text'] as String?;

    // Masks for ABC Algos
    if (rawLesionMask.isEmpty) return;

    cleanedLesionMask = LesionUtils.cleanLesionMask(rawLesionMask, <int>[
      image.rows,
      image.cols,
    ]);

    // Align mask for asymmetry
    _rotatedMask = LesionUtils.alignMaskByDominantAxis(rawLesionMask);
    // Contour and hulls
    _lesionContourMask = LesionUtils.getLesionContourMask(rawLesionMask);
    _convexHullMask = LesionUtils.getConvexHullMask(rawLesionMask);
    _concavityMask = LesionUtils.getConcavityMask(
      rawLesionMask,
      _convexHullMask!,
    );
  }

  double getAsymmetryScore() {
    if (_rotatedMask == null) return 0.0;
    asymmetryScore = LesionUtils.calculateAsymmetryRatio(_rotatedMask!);
    return asymmetryScore;
  }

  double getBorderScore() {
    if (_concavityMask == null) return 0.0;
    borderScore = LesionUtils.calculateBorderRatio(
      _concavityMask!,
      rawLesionMask,
    );
    return borderScore;
  }

  double getColorUniformityScore() {
    final List<double> avgSkin = LesionUtils.getAvgSkinColor(
      image,
      rawLesionMask,
    );
    final cv.Mat imageFloat = LesionUtils.transformImageToFloat(image);

    final List<List<double>> relColors = LesionUtils.transformImageToRelColors(
      imageFloat,
      rawLesionMask,
      avgSkin,
    );
    final List<List<int>> quantColors = LesionUtils.quantizeRelativeColors(
      relColors,
    );
    final List<double> histogram = LesionUtils.getRelColorHistogram(
      quantColors,
    );
    final List<double> filteredHistogram = LesionUtils.filterSkinInHistogram(
      histogram,
      avgSkin,
    );

    final double entropy = LesionUtils.getHistogramEntropy(filteredHistogram);
    final int effColorCount = LesionUtils.getEffColorCount(
      filteredHistogram,
      1e-4,
    );

    final double maxEntropy =
        (math.log(math.max(effColorCount, 1)) / math.log(2));

    if (maxEntropy > 0.0) {
      colorUniformityScore = 1.0 - math.min(entropy / (maxEntropy + 5.0), 1.0);
    } else {
      colorUniformityScore = 1.0;
    }
    return 1 - colorUniformityScore;
  }

  cv.Mat getLesionContourOverlay() {
    if (_lesionContourMask == null || _lesionContourMask!.isEmpty) return image;
    final cv.Mat overlay = image.clone();
    overlay.setTo(cv.Scalar.fromRgb(0, 255, 0), mask: _lesionContourMask);
    return overlay;
  }

  cv.Mat getConcavityOverlay() {
    if (_concavityMask == null || _concavityMask!.isEmpty) return image;
    final cv.Mat overlay = image.clone();
    overlay.setTo(cv.Scalar.fromRgb(255, 0, 0), mask: _concavityMask);
    final cv.Mat hullOutlineMask = LesionUtils.getLesionContourMask(
      _convexHullMask!,
    );
    overlay.setTo(cv.Scalar.fromRgb(0, 255, 0), mask: hullOutlineMask);
    return overlay;
  }

  cv.Mat getConvexHullOverlay() {
    if (_convexHullMask == null || _convexHullMask!.isEmpty) return image;
    final cv.Mat overlay = image.clone();
    overlay.setTo(cv.Scalar.fromRgb(0, 0, 255), mask: _convexHullMask);
    return overlay;
  }
}
