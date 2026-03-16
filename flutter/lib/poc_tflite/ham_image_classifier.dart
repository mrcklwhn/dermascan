import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageClassifier {
  late Interpreter _interpreter;
  
  final List<String> _labels = [
    'Melanocytic nevi',
    'Melanoma',
    'Benign keratosis-like lesions',
    'Basal cell carcinoma',
    'Actinic keratoses',
    'Vascular lesions',
    'Dermatofibroma'
  ];
  
  Future<void> loadModel() async {
    final options = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset(
      'assets/ham10000.tflite',
      options: options
    );
    
    // Debug: Print tensor details
    print('Input tensor: ${_interpreter.getInputTensor(0).shape}');
    print('Output tensor: ${_interpreter.getOutputTensor(0).shape}');
  }
  
  Map<String, double> predict(Uint8List imageBytes) {
    // Preprocess image
    final input = _preprocessImage(imageBytes);
    
    // Create output buffer for 7 classes
    final output = List.filled(1 * 7, 0.0).reshape([1, 7]);
    
    // Run inference
    _interpreter.run(input, output);
    
    // Extract probabilities
    final probabilities = output[0] as List<double>;
    
    // Debug: print raw probabilities
    print('Raw probabilities: $probabilities');
    
    // Create result map
    Map<String, double> results = {};
    for (int i = 0; i < _labels.length; i++) {
      results[_labels[i]] = probabilities[i];
    }
    
    return results;
  }
  
  List<List<List<List<double>>>> _preprocessImage(Uint8List imageBytes) {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    print('Original image dimensions: ${image.width}x${image.height}');
    
    // Resize to match model input (200x150 - width x height)
    // This prevents out of memory errors with large images
    final resized = img.copyResize(
      image,
      width: 200,
      height: 150,
      interpolation: img.Interpolation.linear
    );
    
    print('Resized image dimensions: ${resized.width}x${resized.height}');
    
    // Create input tensor [1, 150, 200, 3]
    // Normalize pixel values to [0, 1] by dividing by 255.0
    List<List<List<List<double>>>> input = List.generate(
      1,
      (_) => List.generate(
        150,  // height
        (y) => List.generate(
          200,  // width
          (x) {
            final pixel = resized.getPixel(x, y);
            // Normalize to [0, 1] - matches Jupyter preprocessing
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    
    return input;
  }
  
  void dispose() {
    _interpreter.close();
  }
}

