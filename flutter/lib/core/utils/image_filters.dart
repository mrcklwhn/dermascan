import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartcv4/dartcv.dart' as cv;

class ImageFilters {
  static List<_ComplexKernel>? _gaborKernels;
  static List<_ComplexKernelMat>? _gaborKernelMats;

  static Float32List gaborFilter(cv.Mat image) {
    _gaborKernelMats ??= _buildDefaultGaborKernelMats();

    final cv.Mat grayU8 = _toGrayMatU8(image);
    final cv.Mat grayF32 = grayU8.convertTo(cv.MatType.CV_32FC1);

    final int rows = grayF32.rows;
    final int cols = grayF32.cols;
    final int pixels = rows * cols;

    double globalMin = double.infinity;
    double globalMax = -double.infinity;

    final List<cv.Mat> responses = <cv.Mat>[];

    for (final _ComplexKernelMat kernel in _gaborKernelMats!) {
      final cv.Mat filteredReal = cv.filter2D(
        grayF32,
        cv.MatType.CV_32F,
        kernel.real,
      );
      final cv.Mat filteredImag = cv.filter2D(
        grayF32,
        cv.MatType.CV_32F,
        kernel.imag,
      );

      final cv.Mat magnitude = cv.magnitude(filteredReal, filteredImag);

      responses.add(magnitude);

      final (double localMin, double localMax, _, _) = cv.minMaxLoc(magnitude);
      if (localMin < globalMin) {
        globalMin = localMin;
      }
      if (localMax > globalMax) {
        globalMax = localMax;
      }
    }

    final int numChannels = _gaborKernelMats!.length;
    final Float32List gaborMap = Float32List(numChannels * pixels);

    final double invDenom = 1.0 / (globalMax - globalMin + 1e-8);

    // Pass 2: recompute each response map and write normalized values directly.
    for (int c = 0; c < numChannels; c++) {
      final _ComplexKernelMat kernel = _gaborKernelMats![c];
      final cv.Mat filteredReal = cv.filter2D(
        grayF32,
        cv.MatType.CV_32F,
        kernel.real,
      );
      final cv.Mat filteredImag = cv.filter2D(
        grayF32,
        cv.MatType.CV_32F,
        kernel.imag,
      );
      final cv.Mat magnitude = cv.magnitude(filteredReal, filteredImag);

      final Float32List channel = _matF32Data(magnitude);
      final int offset = c * pixels;
      for (int i = 0; i < pixels; i++) {
        gaborMap[offset + i] = ((channel[i] - globalMin) * invDenom);
      }
    }

    return gaborMap;
  }

  static Float32List glcmFilter(cv.Mat image) {
    const int win = 21;
    const int stride = 8;
    const int levels = 8;
    final List<double> distances = <double>[1.0, 3.0];
    final List<double> angles = <double>[
      0.0,
      math.pi / 4.0,
      math.pi / 2.0,
      3.0 * math.pi / 4.0,
    ];
    final List<String> properties = <String>[
      'contrast',
      'homogeneity',
      'energy',
      'correlation',
    ];

    final _GrayImage gray = _toGrayImage(image);
    final int rows = gray.rows;
    final int cols = gray.cols;
    final int pixels = rows * cols;

    final Uint8List q = Uint8List(pixels);
    final double scale = levels / 256.0;
    for (int i = 0; i < pixels; i++) {
      int value = (gray.values[i] * scale).toInt();
      if (value < 0) {
        value = 0;
      }
      if (value > levels - 1) {
        value = levels - 1;
      }
      q[i] = value;
    }

    final int pad = win ~/ 2;
    final Uint8List qpad = _padReflect(q, rows, cols, pad);
    final int paddedCols = cols + (2 * pad);

    final int gh = (rows + stride - 1) ~/ stride;
    final int gw = (cols + stride - 1) ~/ stride;

    final int nChannels = properties.length * angles.length * distances.length;
    final List<Float64List> featMaps = List<Float64List>.generate(
      nChannels,
      (_) => Float64List(gh * gw),
    );

    int iy = 0;
    for (int y = 0; y < rows; y += stride) {
      int ix = 0;
      for (int x = 0; x < cols; x += stride) {
        final Uint8List patch = Uint8List(win * win);
        for (int py = 0; py < win; py++) {
          final int srcOffset = (y + py) * paddedCols + x;
          final int dstOffset = py * win;
          patch.setRange(dstOffset, dstOffset + win, qpad, srcOffset);
        }

        final Float64List glcm = _graycomatrixSkimageCompatible(
          patch,
          win,
          win,
          distances,
          angles,
          levels,
          symmetric: true,
          normed: true,
        );

        int chIdx = 0;
        for (final String prop in properties) {
          final Float64List props = _graycopropsSkimageCompatible(
            glcm,
            levels,
            distances.length,
            angles.length,
            prop,
          );

          for (int i = 0; i < props.length; i++) {
            featMaps[chIdx + i][iy * gw + ix] = props[i];
          }
          chIdx += props.length;
        }

        ix++;
      }
      iy++;
    }

    final List<Float64List> upsampledChannels = <Float64List>[];
    double globalMin = double.infinity;
    double globalMax = -double.infinity;

    for (int ch = 0; ch < nChannels; ch++) {
      final Float64List fullRes = _resizeBilinear(
        featMaps[ch],
        gh,
        gw,
        rows,
        cols,
      );
      upsampledChannels.add(fullRes);

      for (int i = 0; i < pixels; i++) {
        final double value = fullRes[i];
        if (value < globalMin) {
          globalMin = value;
        }
        if (value > globalMax) {
          globalMax = value;
        }
      }
    }

    final Float32List glcmNormalized = Float32List(nChannels * pixels);
    final double denom = (globalMax - globalMin) + 1e-8;

    int writeIdx = 0;
    for (final Float64List channel in upsampledChannels) {
      for (int i = 0; i < pixels; i++) {
        glcmNormalized[writeIdx++] = ((channel[i] - globalMin) / denom)
            .toDouble();
      }
    }

    return glcmNormalized;
  }

  static _GrayImage _toGrayImage(cv.Mat image) {
    final cv.Mat grayU8 = _toGrayMatU8(image);
    final Uint8List bytes = grayU8.data;
    final Float64List values = Float64List(grayU8.rows * grayU8.cols);
    for (int i = 0; i < values.length; i++) {
      values[i] = bytes[i].toDouble();
    }

    return _GrayImage(grayU8.rows, grayU8.cols, values);
  }

  static cv.Mat _toGrayMatU8(cv.Mat image) {
    cv.Mat gray = image;
    final int pixels = image.rows * image.cols;
    if (pixels > 0 && image.data.length ~/ pixels > 1) {
      gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
    }
    return gray.convertTo(cv.MatType.CV_8UC1);
  }

  static List<_ComplexKernel> _buildDefaultGaborKernels() {
    final List<double> frequencies = <double>[0.05, 0.1, 0.2, 0.3, 0.4];
    final List<double> thetas = List<double>.generate(
      8,
      (int i) => i * (math.pi / 8.0),
    );

    final List<_ComplexKernel> kernels = <_ComplexKernel>[];
    for (final double freq in frequencies) {
      for (final double theta in thetas) {
        kernels.add(
          _buildGaborKernelSkimageCompatible(frequency: freq, theta: theta),
        );
      }
    }
    return kernels;
  }

  static List<_ComplexKernelMat> _buildDefaultGaborKernelMats() {
    _gaborKernels ??= _buildDefaultGaborKernels();
    return _gaborKernels!
        .map(
          (_ComplexKernel kernel) => _ComplexKernelMat(
            cv.Mat.fromList(
              kernel.height,
              kernel.width,
              cv.MatType.CV_32FC1,
              kernel.real,
            ),
            cv.Mat.fromList(
              kernel.height,
              kernel.width,
              cv.MatType.CV_32FC1,
              kernel.imag,
            ),
          ),
        )
        .toList(growable: false);
  }

  static Float32List _matF32Data(cv.Mat mat) {
    return Float32List.view(
      mat.data.buffer,
      mat.data.offsetInBytes,
      mat.rows * mat.cols * mat.channels,
    );
  }

  static _ComplexKernel _buildGaborKernelSkimageCompatible({
    required double frequency,
    double theta = 0.0,
    double bandwidth = 1.0,
    double? sigmaX,
    double? sigmaY,
    int nStds = 3,
    double offset = 0.0,
  }) {
    final double sx = sigmaX ?? _sigmaPrefactor(bandwidth) / frequency;
    final double sy = sigmaY ?? _sigmaPrefactor(bandwidth) / frequency;

    final double ct = math.cos(theta);
    final double st = math.sin(theta);

    final int x0 = math.max(
      1,
      math.max((nStds * sx * ct).abs().ceil(), (nStds * sy * st).abs().ceil()),
    );
    final int y0 = math.max(
      1,
      math.max((nStds * sy * ct).abs().ceil(), (nStds * sx * st).abs().ceil()),
    );

    final int width = (2 * x0) + 1;
    final int height = (2 * y0) + 1;

    final double lambd = 1.0 / frequency;
    final double gamma = sx / sy;
    final double gamma2 = gamma * gamma;
    final double sigma2 = sx * sx;

    final Float64List real = Float64List(width * height);
    final Float64List imag = Float64List(width * height);

    int idx = 0;
    for (int y = -y0; y <= y0; y++) {
      for (int x = -x0; x <= x0; x++) {
        final double xTheta = (x * ct) + (y * st);
        final double yTheta = (-x * st) + (y * ct);

        final double gaussian = math.exp(
          -0.5 * ((xTheta * xTheta + gamma2 * yTheta * yTheta) / sigma2),
        );
        final double phase = (2.0 * math.pi * xTheta / lambd);

        real[idx] = gaussian * math.cos(phase + offset);
        imag[idx] = gaussian * math.cos(phase + offset - (math.pi / 2.0));
        idx++;
      }
    }

    final double norm = 1.0 / (2.0 * math.pi * sx * sy);
    for (int i = 0; i < real.length; i++) {
      real[i] *= norm;
      imag[i] *= norm;
    }

    return _ComplexKernel(width, height, real, imag);
  }

  static double _sigmaPrefactor(double bandwidth) {
    final double b = bandwidth;
    return (1.0 / math.pi) *
        math.sqrt(math.log(2.0) / 2.0) *
        (((math.pow(2.0, b) as double) + 1.0) /
            ((math.pow(2.0, b) as double) - 1.0));
  }

  static int _roundHalfAwayFromZero(double value) {
    if (value > 0.0) {
      return (value + 0.5).floor();
    }
    return (value - 0.5).ceil();
  }

  static Float64List _graycomatrixSkimageCompatible(
    Uint8List image,
    int rows,
    int cols,
    List<double> distances,
    List<double> angles,
    int levels, {
    bool symmetric = false,
    bool normed = false,
  }) {
    final int numDist = distances.length;
    final int numAngle = angles.length;
    Float64List out = Float64List(levels * levels * numDist * numAngle);

    for (int aIdx = 0; aIdx < numAngle; aIdx++) {
      final double angle = angles[aIdx];
      for (int dIdx = 0; dIdx < numDist; dIdx++) {
        final double distance = distances[dIdx];
        final int offsetRow = _roundHalfAwayFromZero(
          math.sin(angle) * distance,
        );
        final int offsetCol = _roundHalfAwayFromZero(
          math.cos(angle) * distance,
        );

        final int startRow = math.max(0, -offsetRow);
        final int endRow = math.min(rows, rows - offsetRow);
        final int startCol = math.max(0, -offsetCol);
        final int endCol = math.min(cols, cols - offsetCol);

        if (startRow >= endRow || startCol >= endCol) {
          continue;
        }

        for (int r = startRow; r < endRow; r++) {
          final int srcBase = r * cols;
          final int dstBase = (r + offsetRow) * cols;
          for (int c = startCol; c < endCol; c++) {
            final int src = image[srcBase + c];
            final int dst = image[dstBase + c + offsetCol];

            if (src < 0 || src >= levels || dst < 0 || dst >= levels) {
              continue;
            }

            final int idx = _glcmIndex(
              src,
              dst,
              dIdx,
              aIdx,
              levels,
              numDist,
              numAngle,
            );
            out[idx] += 1.0;
          }
        }
      }
    }

    if (symmetric) {
      final Float64List sym = Float64List(out.length);
      for (int i = 0; i < levels; i++) {
        for (int j = 0; j < levels; j++) {
          for (int d = 0; d < numDist; d++) {
            for (int a = 0; a < numAngle; a++) {
              final int idx = _glcmIndex(i, j, d, a, levels, numDist, numAngle);
              final int tIdx = _glcmIndex(
                j,
                i,
                d,
                a,
                levels,
                numDist,
                numAngle,
              );
              sym[idx] = out[idx] + out[tIdx];
            }
          }
        }
      }
      out = sym;
    }

    if (normed) {
      for (int d = 0; d < numDist; d++) {
        for (int a = 0; a < numAngle; a++) {
          double sum = 0.0;
          for (int i = 0; i < levels; i++) {
            for (int j = 0; j < levels; j++) {
              sum += out[_glcmIndex(i, j, d, a, levels, numDist, numAngle)];
            }
          }
          if (sum == 0.0) {
            sum = 1.0;
          }
          final double inv = 1.0 / sum;
          for (int i = 0; i < levels; i++) {
            for (int j = 0; j < levels; j++) {
              final int idx = _glcmIndex(i, j, d, a, levels, numDist, numAngle);
              out[idx] *= inv;
            }
          }
        }
      }
    }

    return out;
  }

  static Float64List _graycopropsSkimageCompatible(
    Float64List p,
    int numLevel,
    int numDist,
    int numAngle,
    String prop,
  ) {
    final Set<String> supported = <String>{
      'contrast',
      'dissimilarity',
      'homogeneity',
      'ASM',
      'energy',
      'correlation',
      'entropy',
      'variance',
      'mean',
      'std',
    };
    if (!supported.contains(prop)) {
      throw ArgumentError('$prop is an invalid property');
    }

    final Float64List pn = Float64List(p.length);
    pn.setAll(0, p);

    for (int d = 0; d < numDist; d++) {
      for (int a = 0; a < numAngle; a++) {
        double sum = 0.0;
        for (int i = 0; i < numLevel; i++) {
          for (int j = 0; j < numLevel; j++) {
            sum += pn[_glcmIndex(i, j, d, a, numLevel, numDist, numAngle)];
          }
        }
        if (sum == 0.0) {
          sum = 1.0;
        }
        final double inv = 1.0 / sum;
        for (int i = 0; i < numLevel; i++) {
          for (int j = 0; j < numLevel; j++) {
            final int idx = _glcmIndex(i, j, d, a, numLevel, numDist, numAngle);
            pn[idx] *= inv;
          }
        }
      }
    }

    final Float64List results = Float64List(numDist * numAngle);

    for (int d = 0; d < numDist; d++) {
      for (int a = 0; a < numAngle; a++) {
        final int outIdx = d * numAngle + a;

        if (prop == 'energy' || prop == 'ASM') {
          double asm = 0.0;
          for (int i = 0; i < numLevel; i++) {
            for (int j = 0; j < numLevel; j++) {
              final double v =
                  pn[_glcmIndex(i, j, d, a, numLevel, numDist, numAngle)];
              asm += v * v;
            }
          }
          results[outIdx] = prop == 'energy' ? math.sqrt(asm) : asm;
          continue;
        }

        if (prop == 'mean' || prop == 'variance' || prop == 'std') {
          double mean = 0.0;
          for (int i = 0; i < numLevel; i++) {
            for (int j = 0; j < numLevel; j++) {
              mean +=
                  i * pn[_glcmIndex(i, j, d, a, numLevel, numDist, numAngle)];
            }
          }

          if (prop == 'mean') {
            results[outIdx] = mean;
          } else {
            double variance = 0.0;
            for (int i = 0; i < numLevel; i++) {
              final double di = i - mean;
              final double di2 = di * di;
              for (int j = 0; j < numLevel; j++) {
                variance +=
                    pn[_glcmIndex(i, j, d, a, numLevel, numDist, numAngle)] *
                    di2;
              }
            }
            results[outIdx] = prop == 'std' ? math.sqrt(variance) : variance;
          }
          continue;
        }

        if (prop == 'entropy') {
          double entropy = 0.0;
          for (int i = 0; i < numLevel; i++) {
            for (int j = 0; j < numLevel; j++) {
              final double v =
                  pn[_glcmIndex(i, j, d, a, numLevel, numDist, numAngle)];
              if (v != 0.0) {
                entropy += v * (-math.log(v));
              }
            }
          }
          results[outIdx] = entropy;
          continue;
        }

        if (prop == 'correlation') {
          double meanI = 0.0;
          double meanJ = 0.0;
          for (int i = 0; i < numLevel; i++) {
            for (int j = 0; j < numLevel; j++) {
              final double v =
                  pn[_glcmIndex(i, j, d, a, numLevel, numDist, numAngle)];
              meanI += i * v;
              meanJ += j * v;
            }
          }

          double stdI = 0.0;
          double stdJ = 0.0;
          double cov = 0.0;
          for (int i = 0; i < numLevel; i++) {
            final double di = i - meanI;
            for (int j = 0; j < numLevel; j++) {
              final double dj = j - meanJ;
              final double v =
                  pn[_glcmIndex(i, j, d, a, numLevel, numDist, numAngle)];
              stdI += v * di * di;
              stdJ += v * dj * dj;
              cov += v * di * dj;
            }
          }

          stdI = math.sqrt(stdI);
          stdJ = math.sqrt(stdJ);

          if (stdI < 1e-15 || stdJ < 1e-15) {
            results[outIdx] = 1.0;
          } else {
            results[outIdx] = cov / (stdI * stdJ);
          }
          continue;
        }

        double acc = 0.0;
        for (int i = 0; i < numLevel; i++) {
          for (int j = 0; j < numLevel; j++) {
            final double v =
                pn[_glcmIndex(i, j, d, a, numLevel, numDist, numAngle)];
            final int diff = i - j;
            if (prop == 'contrast') {
              acc += v * diff * diff;
            } else if (prop == 'dissimilarity') {
              acc += v * diff.abs();
            } else {
              acc += v * (1.0 / (1.0 + (diff * diff)));
            }
          }
        }
        results[outIdx] = acc;
      }
    }

    return results;
  }

  static int _glcmIndex(
    int i,
    int j,
    int d,
    int a,
    int levels,
    int numDist,
    int numAngle,
  ) {
    return (((i * levels) + j) * numDist + d) * numAngle + a;
  }

  static Uint8List _padReflect(Uint8List image, int rows, int cols, int pad) {
    if (pad == 0) {
      return Uint8List.fromList(image);
    }

    final int paddedRows = rows + (2 * pad);
    final int paddedCols = cols + (2 * pad);
    final Uint8List out = Uint8List(paddedRows * paddedCols);

    for (int y = 0; y < paddedRows; y++) {
      final int srcY = _reflectIndex(y - pad, rows);
      for (int x = 0; x < paddedCols; x++) {
        final int srcX = _reflectIndex(x - pad, cols);
        out[y * paddedCols + x] = image[srcY * cols + srcX];
      }
    }

    return out;
  }

  static int _reflectIndex(int index, int size) {
    if (size <= 1) {
      return 0;
    }

    int idx = index;
    while (idx < 0 || idx >= size) {
      if (idx < 0) {
        idx = -idx;
      }
      if (idx >= size) {
        idx = (2 * size) - 2 - idx;
      }
    }
    return idx;
  }

  static Float64List _resizeBilinear(
    Float64List src,
    int srcRows,
    int srcCols,
    int dstRows,
    int dstCols,
  ) {
    final Float64List dst = Float64List(dstRows * dstCols);
    if (srcRows == 0 || srcCols == 0 || dstRows == 0 || dstCols == 0) {
      return dst;
    }

    final double scaleY = srcRows / dstRows;
    final double scaleX = srcCols / dstCols;

    for (int y = 0; y < dstRows; y++) {
      final double fy = ((y + 0.5) * scaleY) - 0.5;
      int y0 = fy.floor();
      int y1 = y0 + 1;
      double wy = fy - y0;

      if (y0 < 0) {
        y0 = 0;
        y1 = 0;
        wy = 0.0;
      } else if (y0 >= srcRows - 1) {
        y0 = srcRows - 1;
        y1 = srcRows - 1;
        wy = 0.0;
      } else if (y1 >= srcRows) {
        y1 = srcRows - 1;
      }

      for (int x = 0; x < dstCols; x++) {
        final double fx = ((x + 0.5) * scaleX) - 0.5;
        int x0 = fx.floor();
        int x1 = x0 + 1;
        double wx = fx - x0;

        if (x0 < 0) {
          x0 = 0;
          x1 = 0;
          wx = 0.0;
        } else if (x0 >= srcCols - 1) {
          x0 = srcCols - 1;
          x1 = srcCols - 1;
          wx = 0.0;
        } else if (x1 >= srcCols) {
          x1 = srcCols - 1;
        }

        final double v00 = src[y0 * srcCols + x0];
        final double v01 = src[y0 * srcCols + x1];
        final double v10 = src[y1 * srcCols + x0];
        final double v11 = src[y1 * srcCols + x1];

        final double top = (1.0 - wx) * v00 + wx * v01;
        final double bottom = (1.0 - wx) * v10 + wx * v11;
        dst[y * dstCols + x] = (1.0 - wy) * top + wy * bottom;
      }
    }

    return dst;
  }
}

class _GrayImage {
  const _GrayImage(this.rows, this.cols, this.values);

  final int rows;
  final int cols;
  final Float64List values;
}

class _ComplexKernel {
  const _ComplexKernel(this.width, this.height, this.real, this.imag);

  final int width;
  final int height;
  final Float64List real;
  final Float64List imag;
}

class _ComplexKernelMat {
  const _ComplexKernelMat(this.real, this.imag);

  final cv.Mat real;
  final cv.Mat imag;
}
