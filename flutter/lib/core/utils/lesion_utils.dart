import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartcv4/dartcv.dart' as cv;

class LesionUtils {
  // Score calculation
  static double calculateAsymmetryRatio(cv.Mat rotatedMask) {
    final int cx = rotatedMask.cols ~/ 2;
    final int cy = rotatedMask.rows ~/ 2;

    cv.Mat leftHalf = rotatedMask.colRange(0, cx);
    leftHalf = cv.flip(leftHalf, 1);
    final cv.Mat rightHalf = rotatedMask.colRange(cx, rotatedMask.cols);

    final cv.Mat intersectionLR = cv.bitwiseAND(leftHalf, rightHalf);
    final cv.Mat unionLR = cv.bitwiseOR(leftHalf, rightHalf);

    final double asymmetryLR =
        cv.countNonZero(intersectionLR) / cv.countNonZero(unionLR) + 1e-12;

    cv.Mat topHalf = rotatedMask.rowRange(0, cy);
    topHalf = cv.flip(topHalf, 0);
    final cv.Mat bottomHalf = rotatedMask.rowRange(cy, rotatedMask.rows);

    final cv.Mat intersectionTB = cv.bitwiseAND(topHalf, bottomHalf);
    final cv.Mat unionTB = cv.bitwiseOR(topHalf, bottomHalf);

    final double asymmetryTB =
        cv.countNonZero(intersectionTB) / cv.countNonZero(unionTB) + 1e-12;

    return 1.0 - ((asymmetryLR + asymmetryTB) / 2.0);
  }

  static double calculateBorderRatio(cv.Mat concavityMask, cv.Mat lesionMask) {
    final int concavityPixels = cv.countNonZero(concavityMask);
    final int totalLesionPixels = cv.countNonZero(lesionMask);
    if (totalLesionPixels == 0) return 0.0;
    return concavityPixels / totalLesionPixels;
  }

  // Mask processing for Inference
  static cv.Mat cleanLesionMask(cv.Mat rawMask, List<int> originalSize) {
    final cv.Mat largest = getLargestConnectedArea(rawMask);
    final cv.Mat filled = fillHolesInMask(largest);
    final cv.Mat resized = resizeMask(filled, <int>[
      originalSize.first,
      originalSize.last,
    ]);
    final cv.Mat smoothed = smoothMaskEdges(resized);
    return smoothed;
  }

  static cv.Mat getLargestConnectedArea(cv.Mat rawMask) {
    final cv.Mat labels = cv.Mat.empty();
    final cv.Mat stats = cv.Mat.empty();
    final cv.Mat centroids = cv.Mat.empty();

    final int numLabels = cv.connectedComponentsWithStats(
      rawMask,
      labels,
      stats,
      centroids,
      8,
      cv.MatType.CV_32S,
      cv.CCL_SAUF,
    );
    if (numLabels <= 1) {
      return cv.Mat.zeros(rawMask.rows, rawMask.cols, cv.MatType.CV_8UC1);
    }

    int maxArea = 0;
    int largestLabel = 1;
    for (int i = 1; i < numLabels; i++) {
      final int area = stats.at<int>(i, cv.CC_STAT_AREA);
      if (area > maxArea) {
        maxArea = area;
        largestLabel = i;
      }
    }
    final cv.Mat target = cv.Mat.zeros(
      labels.rows,
      labels.cols,
      labels.type,
    ).setTo(cv.Scalar.all(largestLabel.toDouble()));
    return cv.compare(labels, target, cv.CMP_EQ);
  }

  static cv.Mat fillHolesInMask(cv.Mat largestMask) {
    final cv.Mat maskU8 = largestMask.convertTo(cv.MatType.CV_8UC1);
    final cv.Mat flood = maskU8.clone();
    final cv.Mat floodFillBuffer = cv.Mat.zeros(
      maskU8.rows + 2,
      maskU8.cols + 2,
      cv.MatType.CV_8UC1,
    );

    final (int, cv.Mat, cv.Mat, cv.Rect) floodResult = cv.floodFill(
      flood,
      cv.Point(0, 0),
      cv.Scalar.all(255.0),
      mask: floodFillBuffer,
    );
    final cv.Mat holes = cv.bitwiseNOT(floodResult.$2);
    return cv.bitwiseOR(maskU8, holes);
  }

  static cv.Mat resizeMask(cv.Mat filledMask, List<int> size) {
    return cv.resize(filledMask, (
      size[1],
      size[0],
    ), interpolation: cv.INTER_NEAREST);
  }

  static cv.Mat smoothMaskEdges(cv.Mat resizedMask) {
    final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (7, 7));
    cv.Mat cleaned = cv.morphologyEx(resizedMask, cv.MORPH_CLOSE, kernel);
    cleaned = cv.morphologyEx(cleaned, cv.MORPH_OPEN, kernel);
    final cv.Mat blurred = cv.gaussianBlur(cleaned, (9, 9), 0.0);
    return cv.threshold(blurred, 127.0, 255.0, cv.THRESH_BINARY).$2;
  }

  // Misc
  static List<int> getCentroid(cv.Mat binaryMask) {
    final cv.Moments m = cv.moments(binaryMask);
    if (m.m00 == 0) return <int>[0, 0];
    return <int>[(m.m10 / m.m00).toInt(), (m.m01 / m.m00).toInt()];
  }

  static List<double> getAvgSkinColor(cv.Mat image, cv.Mat lesionMask) {
    final cv.Mat skinMask = cv.bitwiseNOT(lesionMask);
    final cv.Scalar avgSkinColor = cv.mean(image, mask: skinMask);
    return <double>[
      avgSkinColor.val3 / 255.0,
      avgSkinColor.val2 / 255.0,
      avgSkinColor.val1 / 255.0,
    ];
  }

  static List<List<double>> transformImageToRelColors(
    cv.Mat imageFloat,
    cv.Mat lesionMask,
    List<double> avgSkin,
  ) {
    final List<List<double>> relColors = <List<double>>[];
    final cv.VecMat channels = cv.split(imageFloat);
    final cv.Mat bChan = channels[0];
    final cv.Mat gChan = channels[1];
    final cv.Mat rChan = channels[2];

    for (int y = 0; y < imageFloat.rows; y++) {
      for (int x = 0; x < imageFloat.cols; x++) {
        if (lesionMask.at<int>(y, x) > 127) {
          final double r = rChan.at<double>(y, x);
          final double g = gChan.at<double>(y, x);
          final double b = bChan.at<double>(y, x);
          relColors.add(<double>[
            r - avgSkin[0],
            g - avgSkin[1],
            b - avgSkin[2],
          ]);
        }
      }
    }
    return relColors;
  }

  static List<List<int>> quantizeRelativeColors(
    List<List<double>> imageRelColors,
  ) {
    return imageRelColors.map((List<double> relColor) {
      return relColor
          .map((double v) => (((v + 1.0) / 2.0).clamp(0.0, 1.0) * 31).floor())
          .toList();
    }).toList();
  }

  static List<double> getRelColorHistogram(List<List<int>> binIndices) {
    final int maxIndex = 32 * 32 * 32;
    final List<double> hist = List<double>.filled(maxIndex, 0.0);

    for (final List<int> bin in binIndices) {
      final int rBin = bin[0], gBin = bin[1], bBin = bin[2];
      final int flatIdx = rBin * 32 * 32 + gBin * 32 + bBin;
      if (flatIdx >= 0 && flatIdx < maxIndex) hist[flatIdx] += 1.0;
    }

    final double total = binIndices.length.toDouble() + 1e-12;
    for (int i = 0; i < maxIndex; i++) {
      hist[i] /= total;
    }
    return hist;
  }

  static List<double> filterSkinInHistogram(
    List<double> histogram,
    List<double> avgSkin,
  ) {
    final List<int> skinBin = avgSkin
        .map((double c) => (c.clamp(0.0, 1.0) * 31).round())
        .toList();
    final List<double> histFiltered = List<double>.from(histogram);
    final int r0 = skinBin[0], g0 = skinBin[1], b0 = skinBin[2];

    for (int dr = -1; dr <= 1; dr++) {
      for (int dg = -1; dg <= 1; dg++) {
        for (int db = -1; db <= 1; db++) {
          final int rr = r0 + dr, gg = g0 + dg, bb = b0 + db;
          if (rr >= 0 && rr < 32 && gg >= 0 && gg < 32 && bb >= 0 && bb < 32) {
            histFiltered[rr * 32 * 32 + gg * 32 + bb] = 0.0;
          }
        }
      }
    }

    final double sum = histFiltered.fold(0.0, (double p, double e) => p + e);
    final double norm = sum + 1e-12;
    for (int i = 0; i < histFiltered.length; i++) {
      histFiltered[i] /= norm;
    }
    return histFiltered;
  }

  static double getHistogramEntropy(List<double> histogram) {
    double entropy = 0.0;
    for (final double p in histogram) {
      if (p > 0.0) entropy -= p * (math.log(p) / math.log(2));
    }
    return entropy;
  }

  static int getEffColorCount(List<double> histogram, double threshold) {
    return histogram.where((double p) => p > threshold).length;
  }

  // Transforms
  static cv.Mat alignMaskByDominantAxis(cv.Mat binaryMask) {
    final cv.Moments m = cv.moments(binaryMask);
    if (m.m00 == 0) return binaryMask;
    final double angleRad = 0.5 * math.atan2(2 * m.mu11, m.mu20 - m.mu02);
    final double angleDeg = angleRad * 180 / math.pi;

    final List<int> center = getCentroid(binaryMask);
    final cv.Point2f centerPt = cv.Point2f(
      center[0].toDouble(),
      center[1].toDouble(),
    );
    final cv.Mat rotMat = cv.getRotationMatrix2D(centerPt, angleDeg, 1.0);

    final double cosA = rotMat.at<double>(0, 0).abs();
    final double sinA = rotMat.at<double>(0, 1).abs();
    int newWidth = (binaryMask.rows * sinA + binaryMask.cols * cosA).ceil();
    int newHeight = (binaryMask.rows * cosA + binaryMask.cols * sinA).ceil();

    if (newWidth % 2 != 0) newWidth++;
    if (newHeight % 2 != 0) newHeight++;

    final double tx = rotMat.at<double>(0, 2) + (newWidth / 2.0) - centerPt.x;
    final double ty = rotMat.at<double>(1, 2) + (newHeight / 2.0) - centerPt.y;
    rotMat.set<double>(0, 2, tx);
    rotMat.set<double>(1, 2, ty);

    return cv.warpAffine(binaryMask, rotMat, (newWidth, newHeight));
  }

  static cv.Mat getConvexHullMask(cv.Mat binaryMask) {
    final (cv.Contours, cv.VecVec4i) records = cv.findContours(
      binaryMask,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );
    final cv.VecVecPoint contours = records.$1;
    final cv.Mat hullMask = cv.Mat.zeros(
      binaryMask.rows,
      binaryMask.cols,
      cv.MatType.CV_8UC1,
    );

    if (contours.isNotEmpty) {
      double maxArea = 0;
      int maxIndex = 0;
      for (int i = 0; i < contours.length; i++) {
        final double area = cv.contourArea(contours[i]);
        if (area > maxArea) {
          maxArea = area;
          maxIndex = i;
        }
      }
      final cv.Mat hullPoints = cv.convexHull(
        contours[maxIndex],
        clockwise: false,
        returnPoints: true,
      );
      final cv.VecPoint hullVec = cv.VecPoint.fromMat(hullPoints);
      cv.drawContours(
        hullMask,
        cv.VecVecPoint.fromVecPoint(hullVec),
        0,
        cv.Scalar.all(255),
        thickness: cv.FILLED,
      );
    }
    return hullMask;
  }

  static cv.Mat getLesionContourMask(cv.Mat binaryMask) {
    final cv.Mat dilatedMask = cv.dilate(
      binaryMask,
      cv.getStructuringElement(cv.MORPH_ELLIPSE, (3, 3)),
      iterations: 2,
    );
    return cv.subtract(dilatedMask, binaryMask);
  }

  static cv.Mat getConcavityMask(cv.Mat binaryMask, cv.Mat hullMask) {
    return cv.subtract(hullMask, binaryMask);
  }

  static cv.Mat transformImageToFloat(cv.Mat image) {
    return image.convertTo(cv.MatType.CV_32FC3, alpha: 1.0 / 255.0);
  }

  static Float32List multidimResize(
    int dims,
    int rows,
    int columns,
    Float32List data, {
    int? sourceRows,
    int? sourceCols,
  }) {
    if (dims <= 0 || rows <= 0 || columns <= 0) {
      throw ArgumentError('dims, rows and columns must all be positive.');
    }
    if (data.length % dims != 0) {
      throw ArgumentError('Data length must be divisible by dims.');
    }

    final int srcArea = data.length ~/ dims;
    if (srcArea == rows * columns) {
      return Float32List.fromList(data);
    }

    int srcRows;
    int srcCols;

    if (sourceRows != null && sourceCols != null) {
      if (sourceRows <= 0 || sourceCols <= 0) {
        throw ArgumentError(
          'sourceRows and sourceCols must be positive when provided.',
        );
      }
      if (sourceRows * sourceCols != srcArea) {
        throw ArgumentError(
          'sourceRows*sourceCols must equal per-channel input area (data.length/dims).',
        );
      }
      srcRows = sourceRows;
      srcCols = sourceCols;
    } else {
      srcRows = math.sqrt(srcArea).round();
      srcCols = srcRows;
      if (srcRows * srcCols != srcArea) {
        final double targetAspect = columns / rows;
        int bestRows = 1;
        int bestCols = srcArea;
        double bestError = double.infinity;

        final int limit = math.sqrt(srcArea).floor();
        for (int r = 1; r <= limit; r++) {
          if (srcArea % r != 0) {
            continue;
          }
          final int c = srcArea ~/ r;

          final double errA = (c / r - targetAspect).abs();
          if (errA < bestError) {
            bestError = errA;
            bestRows = r;
            bestCols = c;
          }

          final double errB = (r / c - targetAspect).abs();
          if (errB < bestError) {
            bestError = errB;
            bestRows = c;
            bestCols = r;
          }
        }

        srcRows = bestRows;
        srcCols = bestCols;
      }
    }

    final Float32List resized = Float32List(dims * rows * columns);
    final int dstArea = rows * columns;

    for (int c = 0; c < dims; c++) {
      final int srcOffset = c * srcArea;
      final Float32List channel = Float32List(srcArea);
      channel.setRange(0, srcArea, data, srcOffset);

      // Mirror Python exporter behavior: resize every channel independently with INTER_NEAREST.
      final cv.Mat channelMat = cv.Mat.fromList(
        srcRows,
        srcCols,
        cv.MatType.CV_32FC1,
        channel,
      );
      final cv.Mat resizedMat = cv.resize(channelMat, (
        columns,
        rows,
      ), interpolation: cv.INTER_NEAREST);

      final int dstOffset = c * dstArea;
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
          resized[dstOffset + y * columns + x] = resizedMat
              .at<double>(y, x)
              .toDouble();
        }
      }
    }

    return resized;
  }
}
