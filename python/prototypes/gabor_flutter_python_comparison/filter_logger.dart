import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:intl/intl.dart';

/// Detailed logging utility for filter implementations.
///
/// This logger streams JSON directly to disk entry-by-entry, so very large
/// arrays are never materialized as one giant in-memory JSON object.
class FilterLogger {
  late final File _logFile;
  late final IOSink _sink;
  final String _filterName;
  final String _startTime;

  int _entryCount = 0;
  bool _hasWrittenEntry = false;
  bool _isClosed = false;
  static const int _defaultSampleCount = 64;

  FilterLogger({required String filterName})
      : _filterName = filterName,
        _startTime = DateTime.now().toIso8601String() {
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final Directory directory = Directory('${Directory.systemTemp.path}/dermascan_logs');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    _logFile = File('${directory.path}/${_filterName}_$timestamp.json');
    print(_logFile.toString());
    _sink = _logFile.openWrite(mode: FileMode.writeOnly);

    // Keep the entries array open and append entries incrementally.
    _sink.write('{"timestamp":');
    _sink.write(jsonEncode(_startTime));
    _sink.write(',"filter":');
    _sink.write(jsonEncode(_filterName));
    _sink.write(',"entries":[');
  }

  /// Log Float32List using summary statistics and sampled values only.
  /// This keeps memory and file size bounded on mobile devices.
  Map<String, dynamic> logFloat32List(String name, Float32List array, {int sampleCount = _defaultSampleCount}) {
    double min = double.infinity;
    double max = double.negativeInfinity;
    double sum = 0.0;

    for (final double value in array) {
      if (value < min) {
        min = value;
      }
      if (value > max) {
        max = value;
      }
      sum += value;
    }

    final double mean = array.isNotEmpty ? sum / array.length : 0.0;
    final double std = _calculateStd(array, mean: mean);

    _beginEntry();
    _sink.write('{"name":');
    _sink.write(jsonEncode(name));
    _sink.write(',"type":"float32_list","dtype":"float32","shape":[');
    _sink.write(array.length.toString());
    _sink.write('],"size":');
    _sink.write(array.length.toString());
    _sink.write(',"min":');
    _writeDouble(min.isInfinite ? 0.0 : min);
    _sink.write(',"max":');
    _writeDouble(max.isInfinite ? 0.0 : max);
    _sink.write(',"mean":');
    _writeDouble(mean);
    _sink.write(',"std":');
    _writeDouble(std);
    _sink.write(',"sample_count":');
    final int cappedSampleCount = sampleCount <= 0 ? 0 : (sampleCount > array.length ? array.length : sampleCount);
    _sink.write(cappedSampleCount.toString());
    _sink.write(',"data":[');
    if (cappedSampleCount > 0) {
      final int lastIndex = array.length - 1;
      for (int i = 0; i < cappedSampleCount; i++) {
        if (i > 0) {
          _sink.write(',');
        }
        final int idx = cappedSampleCount == 1
            ? 0
            : ((i * lastIndex) ~/ (cappedSampleCount - 1));
        _writeDouble(array[idx]);
      }
    }
    _sink.write('],"sample_indices":[');
    if (cappedSampleCount > 0) {
      final int lastIndex = array.length - 1;
      for (int i = 0; i < cappedSampleCount; i++) {
        if (i > 0) {
          _sink.write(',');
        }
        final int idx = cappedSampleCount == 1
            ? 0
            : ((i * lastIndex) ~/ (cappedSampleCount - 1));
        _sink.write(idx.toString());
      }
    }
    _sink.write(']');
    _sink.write('}');

    return <String, dynamic>{
      'name': name,
      'type': 'float32_list',
      'dtype': 'float32',
      'shape': <int>[array.length],
      'size': array.length,
      'sample_count': cappedSampleCount,
      'min': min.isInfinite ? 0.0 : min,
      'max': max.isInfinite ? 0.0 : max,
      'mean': mean,
      'std': std,
    };
  }

  /// Log a List<List<double>> matrix (2D) with summary and sampled rows.
  Map<String, dynamic> logMatrix2D(String name, List<List<double>> matrix) {
    final int rows = matrix.length;
    final int cols = rows > 0 ? matrix[0].length : 0;

    double min = double.infinity;
    double max = double.negativeInfinity;
    double sum = 0.0;
    int count = 0;

    for (final List<double> row in matrix) {
      for (final double value in row) {
        if (value < min) {
          min = value;
        }
        if (value > max) {
          max = value;
        }
        sum += value;
        count++;
      }
    }

    final double mean = count > 0 ? sum / count : 0.0;

    _beginEntry();
    _sink.write('{"name":');
    _sink.write(jsonEncode(name));
    _sink.write(',"type":"matrix_2d","dtype":"float64","shape":[');
    _sink.write(rows.toString());
    _sink.write(',');
    _sink.write(cols.toString());
    _sink.write('],"size":');
    _sink.write((rows * cols).toString());
    _sink.write(',"min":');
    _writeDouble(min.isInfinite ? 0.0 : min);
    _sink.write(',"max":');
    _writeDouble(max.isInfinite ? 0.0 : max);
    _sink.write(',"mean":');
    _writeDouble(mean);
    const int sampleRows = 8;
    final int sampledRowCount = rows < sampleRows ? rows : sampleRows;
    _sink.write(',"sampled_row_count":');
    _sink.write(sampledRowCount.toString());
    _sink.write(',"data":[');
    for (int s = 0; s < sampledRowCount; s++) {
      final int r = sampledRowCount == 1 ? 0 : ((s * (rows - 1)) ~/ (sampledRowCount - 1));
      if (r > 0) {
        _sink.write(',');
      }
      _sink.write('[');
      final List<double> row = matrix[r];
      for (int c = 0; c < row.length; c++) {
        if (c > 0) {
          _sink.write(',');
        }
        _writeDouble(row[c]);
      }
      _sink.write(']');
    }
    _sink.write(']}');

    return <String, dynamic>{
      'name': name,
      'type': 'matrix_2d',
      'dtype': 'float64',
      'shape': <int>[rows, cols],
      'size': rows * cols,
      'min': min.isInfinite ? 0.0 : min,
      'max': max.isInfinite ? 0.0 : max,
      'mean': mean,
    };
  }

  /// Log a 3D array with summary and sampled planes/rows only.
  Map<String, dynamic> logMatrix3D(String name, List<List<List<double>>> matrix) {
    final int depth = matrix.length;
    final int rows = depth > 0 ? matrix[0].length : 0;
    final int cols = rows > 0 ? matrix[0][0].length : 0;

    double min = double.infinity;
    double max = double.negativeInfinity;
    double sum = 0.0;
    int count = 0;

    for (final List<List<double>> layer in matrix) {
      for (final List<double> row in layer) {
        for (final double value in row) {
          if (value < min) {
            min = value;
          }
          if (value > max) {
            max = value;
          }
          sum += value;
          count++;
        }
      }
    }

    final double mean = count > 0 ? sum / count : 0.0;

    _beginEntry();
    _sink.write('{"name":');
    _sink.write(jsonEncode(name));
    _sink.write(',"type":"matrix_3d","dtype":"float64","shape":[');
    _sink.write(depth.toString());
    _sink.write(',');
    _sink.write(rows.toString());
    _sink.write(',');
    _sink.write(cols.toString());
    _sink.write('],"size":');
    _sink.write((depth * rows * cols).toString());
    _sink.write(',"min":');
    _writeDouble(min.isInfinite ? 0.0 : min);
    _sink.write(',"max":');
    _writeDouble(max.isInfinite ? 0.0 : max);
    _sink.write(',"mean":');
    _writeDouble(mean);
    const int sampleDepth = 4;
    const int sampleRows = 6;
    final int sampledDepthCount = depth < sampleDepth ? depth : sampleDepth;
    _sink.write(',"sampled_depth_count":');
    _sink.write(sampledDepthCount.toString());
    _sink.write(',"data":[');
    for (int s = 0; s < sampledDepthCount; s++) {
      final int d = sampledDepthCount == 1 ? 0 : ((s * (depth - 1)) ~/ (sampledDepthCount - 1));
      if (d > 0) {
        _sink.write(',');
      }
      _sink.write('[');
      final List<List<double>> layer = matrix[d];
      final int sampledRowCount = layer.length < sampleRows ? layer.length : sampleRows;
      for (int sr = 0; sr < sampledRowCount; sr++) {
        final int r = sampledRowCount == 1 ? 0 : ((sr * (layer.length - 1)) ~/ (sampledRowCount - 1));
        if (r > 0) {
          _sink.write(',');
        }
        _sink.write('[');
        final List<double> row = layer[r];
        for (int c = 0; c < row.length; c++) {
          if (c > 0) {
            _sink.write(',');
          }
          _writeDouble(row[c]);
        }
        _sink.write(']');
      }
      _sink.write(']');
    }
    _sink.write(']}');

    return <String, dynamic>{
      'name': name,
      'type': 'matrix_3d',
      'dtype': 'float64',
      'shape': <int>[depth, rows, cols],
      'size': depth * rows * cols,
      'min': min.isInfinite ? 0.0 : min,
      'max': max.isInfinite ? 0.0 : max,
      'mean': mean,
    };
  }

  /// Log a scalar value.
  Map<String, dynamic> logScalar(String name, double value) {
    final Map<String, dynamic> entry = <String, dynamic>{
      'name': name,
      'type': 'scalar',
      'value': value,
    };
    _writeSmallEntry(entry);
    return entry;
  }

  /// Log a step marker.
  Map<String, dynamic> logStep(String stepName, {String? description}) {
    final Map<String, dynamic> entry = <String, dynamic>{
      'step': stepName,
      'type': 'step_marker',
      if (description != null) 'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _writeSmallEntry(entry);
    return entry;
  }

  /// Log text information.
  Map<String, dynamic> logText(String name, String text) {
    final Map<String, dynamic> entry = <String, dynamic>{
      'name': name,
      'type': 'text',
      'text': text,
    };
    _writeSmallEntry(entry);
    return entry;
  }

  /// Log a kernel pair (real and imaginary components) using sampled values.
  void logComplexKernel(
    String name,
    List<double> realValues,
    List<double> imagValues,
    int width,
    int height,
  ) {
    logText(
      '${name}_kernel_shape',
      'width: $width, height: $height, total_elements: ${realValues.length}',
    );

    _writeVectorEntry(
      name: '${name}_real',
      type: 'complex_kernel_real',
      dtype: 'float64',
      shape: <int>[height, width],
      values: realValues,
      width: width,
      height: height,
      sampleCount: 128,
    );

    _writeVectorEntry(
      name: '${name}_imag',
      type: 'complex_kernel_imag',
      dtype: 'float64',
      shape: <int>[height, width],
      values: imagValues,
      width: width,
      height: height,
      sampleCount: 128,
    );
  }

  /// Finalize and close the streamed JSON file.
  Future<String> save({String? outputDir}) async {
    if (_isClosed) {
      return _logFile.path;
    }

    _sink.write('],"num_entries":');
    _sink.write(_entryCount.toString());
    _sink.write('}');
    await _sink.flush();
    await _sink.close();
    _isClosed = true;

    print('Filter log saved: ${_logFile.path}');
    return _logFile.path;
  }

  double _calculateStd(Float32List array, {double? mean}) {
    if (array.isEmpty) {
      return 0.0;
    }

    final double m = mean ?? (array.reduce((a, b) => a + b) / array.length);
    double sum = 0.0;
    for (final double value in array) {
      final double diff = value - m;
      sum += diff * diff;
    }
    return sqrt(sum / array.length);
  }

  void _beginEntry() {
    if (_hasWrittenEntry) {
      _sink.write(',');
    }
    _hasWrittenEntry = true;
    _entryCount++;
  }

  void _writeSmallEntry(Map<String, dynamic> entry) {
    _beginEntry();
    _sink.write(jsonEncode(entry));
  }

  void _writeVectorEntry({
    required String name,
    required String type,
    required String dtype,
    required List<int> shape,
    required List<double> values,
    int sampleCount = _defaultSampleCount,
    int? width,
    int? height,
  }) {
    double min = double.infinity;
    double max = double.negativeInfinity;
    double sum = 0.0;

    for (final double value in values) {
      if (value < min) {
        min = value;
      }
      if (value > max) {
        max = value;
      }
      sum += value;
    }

    final double mean = values.isNotEmpty ? sum / values.length : 0.0;

    _beginEntry();
    _sink.write('{"name":');
    _sink.write(jsonEncode(name));
    _sink.write(',"type":');
    _sink.write(jsonEncode(type));
    _sink.write(',"dtype":');
    _sink.write(jsonEncode(dtype));
    if (width != null) {
      _sink.write(',"width":');
      _sink.write(width.toString());
    }
    if (height != null) {
      _sink.write(',"height":');
      _sink.write(height.toString());
    }
    _sink.write(',"shape":[');
    for (int i = 0; i < shape.length; i++) {
      if (i > 0) {
        _sink.write(',');
      }
      _sink.write(shape[i].toString());
    }
    _sink.write('],"size":');
    _sink.write(values.length.toString());
    _sink.write(',"min":');
    _writeDouble(min.isInfinite ? 0.0 : min);
    _sink.write(',"max":');
    _writeDouble(max.isInfinite ? 0.0 : max);
    _sink.write(',"mean":');
    _writeDouble(mean);
    final int cappedSampleCount = sampleCount <= 0 ? 0 : (sampleCount > values.length ? values.length : sampleCount);
    _sink.write(',"sample_count":');
    _sink.write(cappedSampleCount.toString());
    _sink.write(',"data_sampled":[');
    for (int i = 0; i < cappedSampleCount; i++) {
      if (i > 0) {
        _sink.write(',');
      }
      final int idx = cappedSampleCount == 1
          ? 0
          : ((i * (values.length - 1)) ~/ (cappedSampleCount - 1));
      _writeDouble(values[idx]);
    }
    _sink.write('],"sample_indices":[');
    for (int i = 0; i < cappedSampleCount; i++) {
      if (i > 0) {
        _sink.write(',');
      }
      final int idx = cappedSampleCount == 1
          ? 0
          : ((i * (values.length - 1)) ~/ (cappedSampleCount - 1));
      _sink.write(idx.toString());
    }
    _sink.write(']}');
  }

  void _writeDouble(double value) {
    if (value.isFinite) {
      _sink.write(value.toString());
    } else {
      _sink.write('null');
    }
  }
}
