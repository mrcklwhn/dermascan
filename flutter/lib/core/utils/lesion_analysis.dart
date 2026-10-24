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
    required bool useNeuralModel,
    required bool onlyMask,
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

    if (!onlyMask) {
      final Map<String, dynamic> inferenceResult =
          await _neuralLesionClassification.run(image: image);

      labelIdx = inferenceResult['label_int'] as int?;
      labelConfidence = inferenceResult['confidence'] as double?;
      labelText = inferenceResult['label_text'] as String?;
    }

    if (rawLesionMask.isEmpty) return;

    cleanedLesionMask = LesionUtils.cleanLesionMask(
      rawMask: rawLesionMask,
      originalSize: <int>[image.rows, image.cols],
    );

    _rotatedMask = LesionUtils.alignMaskByDominantAxis(binaryMask: rawLesionMask);
    _lesionContourMask = LesionUtils.getLesionContourMask(binaryMask: rawLesionMask);
    _convexHullMask = LesionUtils.getConvexHullMask(binaryMask: rawLesionMask);
    _concavityMask = LesionUtils.getConcavityMask(
      binaryMask: rawLesionMask,
      hullMask: _convexHullMask!,
    );
  }

  double getAsymmetryScore() {
    if (_rotatedMask == null) return 0.0;
    asymmetryScore = LesionUtils.calculateAsymmetryRatio(
      rotatedMask: _rotatedMask!,
    );
    return asymmetryScore;
  }

  double getBorderScore() {
    if (_concavityMask == null) return 0.0;
    borderScore = LesionUtils.calculateBorderRatio(
      concavityMask: _concavityMask!,
      lesionMask: rawLesionMask,
    );
    return borderScore;
  }

  double getColorUniformityScore() {
    final List<double> avgSkin = LesionUtils.getAvgSkinColor(
      image: image,
      lesionMask: rawLesionMask,
    );
    final cv.Mat imageFloat = LesionUtils.transformImageToFloat(image: image);

    final List<List<double>> relColors = LesionUtils.transformImageToRelColors(
      imageFloat: imageFloat,
      lesionMask: rawLesionMask,
      avgSkin: avgSkin,
    );
    final List<List<int>> quantColors = LesionUtils.quantizeRelativeColors(
      imageRelColors: relColors,
    );
    final List<double> histogram = LesionUtils.getRelColorHistogram(
      binIndices: quantColors,
    );
    final List<double> filteredHistogram = LesionUtils.filterSkinInHistogram(
      histogram: histogram,
      avgSkin: avgSkin,
    );

    final double entropy = LesionUtils.getHistogramEntropy(
      histogram: filteredHistogram,
    );
    final int effColorCount = LesionUtils.getEffColorCount(
      histogram: filteredHistogram,
      threshold: 1e-4,
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
      binaryMask: _convexHullMask!,
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
