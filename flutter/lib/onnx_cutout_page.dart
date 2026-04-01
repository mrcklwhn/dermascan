import 'dart:async';
import 'dart:typed_data';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:dermascan/core/utils/lesion.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OnnxCutoutPage extends StatefulWidget {
  const OnnxCutoutPage({super.key});


  @override
  State<OnnxCutoutPage> createState() => _OnnxCutoutPageState();
}

class _OnnxCutoutPageState extends State<OnnxCutoutPage> {
  bool _isProcessing = false;
  bool _isInitialized = false;

  Uint8List? _selectedImageData;
  cv.Mat? _selectedImageMat;
  Map<String, cv.Mat>? _lesionMasks;
  Map<String, double>? abcScores;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      final cv.Mat mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      
      setState(() {
        _selectedImageData = bytes;
        _selectedImageMat = mat;
        _lesionMasks = null;
        abcScores = null;
      });
    }
  }

  Future<void> _runInference() async {
    if (_selectedImageMat == null) return;

    setState(() {
      _isProcessing = true;
    });

    final Lesion lesion = Lesion(_selectedImageMat!);
    await lesion.runLesionAnalysis(useNeuralModel: false);

    final cv.Mat rawMask = lesion.rawLesionMask;
    final cv.Mat cleanedMask = lesion.cleanedLesionMask;
    
    final cv.Mat contourOverlay = lesion.getLesionContourOverlay();
    final cv.Mat concavityOverlay = lesion.getConcavityOverlay();
    
    lesion.getAsymmetryScore();
    lesion.getBorderScore();
    lesion.getColorUniformityScore();

    setState(() {
      _lesionMasks = <String, cv.Mat>{
        'Raw Mask': rawMask,
        'Cleaned Mask': cleanedMask,
        'Rotated Mask': lesion.rotatedMask!,
        'Contour Overlay': contourOverlay,
        'Concavity Overlay': concavityOverlay,
      };
      abcScores = <String, double>{
        'Asymmetry Score': lesion.asymmetryScore,
        'Border Score': lesion.borderScore,
        'Color Uniformity Score': lesion.colorUniformityScore,
      };
    });

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Choose input image
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image from Gallery'),
            ),
            if (_selectedImageData != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Image.memory(_selectedImageData!, height: 200, fit: BoxFit.contain)
              ),

            // Display generated mask
            if (_lesionMasks != null && _lesionMasks!.isNotEmpty)
              SizedBox(
                height: 256,
                child: PageView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _lesionMasks!.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MapEntry<String, cv.Mat> entry = _lesionMasks!.entries.elementAt(index);
                    final String maskName = entry.key;
                    final cv.Mat maskMat = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(maskName),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Image.memory(
                              cv.imencode('.png', maskMat).$2,
                              width: 256,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Display Model Info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: (_isProcessing || _selectedImageMat == null) ? null : _runInference,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                  child:
                  _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0))
                      : const Text('Predict', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
              abcScores == null || abcScores!.isEmpty
                  ? const Center(child: Text('Run prediction to see ABC scores'))
                  : ListView.builder(
                itemCount: abcScores!.length,
                itemBuilder: (BuildContext context, int index) {
                  final String key = abcScores!.keys.elementAt(index);
                  final double value = abcScores![key]!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(flex: 2, child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text(value.toStringAsFixed(4))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
