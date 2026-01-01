import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'classifier.dart';

void main() {
  runApp(const DivideAndRecycle());
}

class DivideAndRecycle extends StatelessWidget {
  const DivideAndRecycle({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divide & Recycle',
      theme: ThemeData(
        // primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: .fromSeed(seedColor: Colors.green),
      ),
      home: WasteClassifierScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WasteClassifierScreen extends StatefulWidget {
  const WasteClassifierScreen({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  // final String title;

  @override
  State<WasteClassifierScreen> createState() => _WasteClassifierScreenState();
}

class _WasteClassifierScreenState extends State<WasteClassifierScreen> {
  final WasteClassifier _classifier = WasteClassifier();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModel();
    });
  }

  Future<void> _loadModel() async {
    await _classifier.loadModel();
    setState(() {
      _modelLoaded = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isLoading = true;
          _result = null;
        });

        // Classify the image
        final result = await _classifier.classifyImage(pickedFile.path);

        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Classifier'),
        centerTitle: true,
      ),
      body: !_modelLoaded
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image display
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, fit: BoxFit.cover),
                )
                    : Center(
                  child: Icon(
                    Icons.delete_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: Icon(Icons.camera_alt),
                      label: Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: Icon(Icons.photo_library),
                      label: Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),

              // Results
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_result != null)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Classification Result',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildResultRow(
                          'Category:',
                          _result!['class'].toString().toUpperCase(),
                          Colors.green,
                        ),
                        SizedBox(height: 8),
                        _buildResultRow(
                          'Confidence:',
                          '${(_result!['confidence'] * 100).toStringAsFixed(1)}%',
                          Colors.blue,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'All Probabilities:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        ..._buildProbabilityBars(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildProbabilityBars() {
    Map<String, double> probs = Map<String, double>.from(_result!['allProbabilities']);

    return probs.entries.map((entry) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: entry.value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}
