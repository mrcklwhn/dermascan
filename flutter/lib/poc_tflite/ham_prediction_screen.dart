import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'ham_image_classifier.dart'; 

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final ImageClassifier _classifier = ImageClassifier();
  
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  
  Map<String, double>? _predictions;
  
  bool _isLoading = false;
  
  String? _topClass;
  
  @override
  void initState() {
    super.initState();
    _loadModel();
  }
  
  Future<void> _loadModel() async {
    await _classifier.loadModel();
  }
  
  // Function that picks an image and runs prediction
  Future<void> _pickAndPredict() async {
    // Open image picker - returns XFile? (nullable)
    // ImageSource.gallery opens the photo gallery
    //final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    // Load image from assets
    final XFile? image = await _picker.pickImage(source: ImageSource.asset('assets/sample.jpg'));
    
    // Check if user actually selected an image (didn't cancel)
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isLoading = true;
      });
      
      // Read image as bytes (Uint8List) - required for ML model
      final imageBytes = await image.readAsBytes();
      
      // Run prediction - returns Map<String, double> with class probabilities
      final predictions = _classifier.predict(imageBytes);
      
      // Find the class with highest probability
      // .entries gives us key-value pairs: MapEntry(key: "Class 0", value: 0.15)
      // .reduce() compares all entries and returns the one with max value
      var maxEntry = predictions.entries.reduce(
        (a, b) => a.value > b.value ? a : b
      );
      
      // Update UI with results
      setState(() {
        _predictions = predictions;
        _topClass = maxEntry.key;
        _isLoading = false;
      });
    }
  }
  
  // build() is called every time setState() is called
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar is the top bar of the screen
      appBar: AppBar(title: Text('Image Classification')),
      
      // SingleChildScrollView makes content scrollable if it overflows screen
      body: SingleChildScrollView(
        // Add padding around all content
        padding: EdgeInsets.all(16),
        
        // Column arranges children vertically (top to bottom)
        child: Column(
          children: [
            if (_selectedImage != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  // Add gray border around image
                  border: Border.all(color: Colors.grey),
                ),
                child: Image.file(_selectedImage!, fit: BoxFit.contain),
              ),
            
            // SizedBox creates empty space (20 pixels vertical gap)
            SizedBox(height: 20),
            
            // ElevatedButton.icon creates a button with an icon and text
            ElevatedButton.icon(
              onPressed: _pickAndPredict,
              icon: Icon(Icons.image),
              label: Text('Pick Image & Predict'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            
            // Spread operator '...' adds multiple widgets from a list
            if (_topClass != null) ...[
              SizedBox(height: 20),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Top Prediction',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _topClass!, // '!' asserts it's not null
                        style: TextStyle(fontSize: 24, color: Colors.green[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Show all predictions only when _predictions is not null
            if (_predictions != null) ...[
              SizedBox(height: 20),
              Text(
                'All Predictions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              
              // .map() transforms each entry into a widget
              ..._predictions!.entries.map((e) => 
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // e.key is the class name (e.g., "Class 0")
                      Text(e.key),
                      Text(
                        '${(e.value * 100).toStringAsFixed(2)}%',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // dispose() is called when widget is removed from the tree permanently
  // Used to clean up resources (close files, cancel timers, etc.)
  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}
