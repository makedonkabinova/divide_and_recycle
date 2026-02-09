import 'dart:io';
import 'dart:io' as io;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

Future<Uint8List> loadModelBytes(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return data.buffer.asUint8List();
}

class WasteClassifier {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const int INPUT_SIZE = 224;

  Future<void> loadModel(Uint8List bytes) async {
    try {

      final options = InterpreterOptions()
        ..useNnApiForAndroid = false;
      _interpreter =  Interpreter.fromBuffer(bytes, options: options);
      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      print('Model loaded successfully');
      print('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter?.getOutputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<Map<String, dynamic>> classifyImage(String imagePath) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('Model not loaded');
    }

    // Load and preprocess image
    final imageData = File(imagePath).readAsBytesSync();
    img.Image? image = img.decodeImage(imageData);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to 224x224
    img.Image resizedImage = img.copyResize(image, width: INPUT_SIZE, height: INPUT_SIZE);

    // Convert to input tensor (normalized float values)
    var input = _imageToByteListFloat32(resizedImage);

    // Prepare output tensor
    var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

    // Run inference
    _interpreter!.run(input, output);

    // Get predictions
    List<double> probabilities = output[0].cast<double>();

    // Find the class with highest probability
    int maxIndex = 0;
    double maxProb = probabilities[0];

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    return {
      'class': _labels![maxIndex],
      'confidence': maxProb,
      'allProbabilities': Map.fromIterables(_labels!, probabilities),
    };
  }

  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    var convertedBytes = List.generate(
      1,
          (index) => List.generate(
        INPUT_SIZE,
            (y) => List.generate(
          INPUT_SIZE,
              (x) {
            final pixel = image.getPixel(x, y);
            // Normalize to [-1, 1] for MobileNetV3
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );
    return convertedBytes;
  }

  void dispose() {
    _interpreter?.close();
  }
}