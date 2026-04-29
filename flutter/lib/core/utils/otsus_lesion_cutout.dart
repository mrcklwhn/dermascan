import 'dart:math' as math;

import 'package:dartcv4/dartcv.dart' as cv;

class OtsusLesionCutout {

  cv.Mat run(cv.Mat image) {
    // 1. Convert to grayscale
    final cv.Mat gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);

    // 2. Otsu's thresholding
    final (double, cv.Mat) thresholdResult = cv.threshold(gray, 0, 255, cv.THRESH_BINARY + cv.THRESH_OTSU);
    cv.Mat mask = thresholdResult.$2;

    // 3. Invert mask so the lesion is white
    mask = cv.bitwiseNOT(mask);

    // 4. Morphological operations
    final cv.Mat kernel = cv.Mat.ones(5, 5, cv.MatType.CV_8UC1);
    mask = cv.morphologyEx(mask, cv.MORPH_CLOSE, kernel);
    mask = cv.morphologyEx(mask, cv.MORPH_OPEN, kernel);

    // 5. Find contours
    final (cv.Contours, cv.VecVec4i) contoursResult = cv.findContours(mask, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
    final cv.Contours contours = contoursResult.$1;
    
    if (contours.isNotEmpty) {
      final double imageCenterY = image.rows / 2.0;
      final double imageCenterX = image.cols / 2.0;

      int bestContourIdx = -1;
      double minScore = double.infinity;

      for (int i = 0; i < contours.length; i++) {
        final cv.VecPoint contour = contours[i];
        final cv.Moments m = cv.moments(cv.Mat.fromVec(contour));
        
        double score;
        if (m.m00 == 0) {
          score = double.infinity;
        } else {
          final double cx = m.m10 / m.m00;
          final double cy = m.m01 / m.m00;
          
          final double distance = math.sqrt(math.pow(cx - imageCenterX, 2) + math.pow(cy - imageCenterY, 2));
          final double area = cv.contourArea(contour);
          
          score = distance - area / 1000.0;
        }

        if (score < minScore) {
          minScore = score;
          bestContourIdx = i;
        }
      }

      if (bestContourIdx != -1) {
        mask = cv.Mat.zeros(mask.rows, mask.cols, cv.MatType.CV_8UC1);
        cv.drawContours(mask, contours, bestContourIdx, cv.Scalar.all(255), thickness: cv.FILLED);
      }
    }

    return mask;
  }
}
