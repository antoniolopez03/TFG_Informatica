import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassificationResult {
  final String label;
  final double confidence;

  ClassificationResult({
    required this.label,
    required this.confidence,
  });
}

class ClassifierService {
  Interpreter? _mobileNetV3Interpreter;
  List<String> _labels = [];
  static const int inputSize = 224;

  static final ClassifierService _instance = ClassifierService._internal();
  factory ClassifierService() => _instance;
  ClassifierService._internal();

  Future<void> loadModels() async {
    try {
      print('📦 Cargando modelo MobileNet V3...');
      await _loadLabels();

      _mobileNetV3Interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet_v3.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print('✅ MobileNet V3 cargado correctamente');
    } catch (e) {
      print('❌ Error al cargar modelo: $e');
      rethrow;
    }
  }

  Future<void> _loadLabels() async {
    final labelsData = await rootBundle.loadString('assets/labels/labels.txt');
    _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    print('  ✅ ${_labels.length} etiquetas cargadas');
  }

  Future<ClassificationResult> classifyImage(File imageFile) async {
    if (_mobileNetV3Interpreter == null) {
      throw Exception('Modelo no cargado. Llama a loadModels() primero.');
    }

    // Leer y decodificar imagen
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Error al decodificar imagen');

    // Redimensionar a 224x224
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Preparar input según tipo del modelo
    final inputTensor = _mobileNetV3Interpreter!.getInputTensor(0);
    final inputType = inputTensor.type;
    
    Object input;
    if (inputType.toString().contains('uint8')) {
      input = _imageToUint8List(resized);
    } else {
      input = _imageToFloat32List(resized);
    }

    // Preparar output
    final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    // Ejecutar inferencia
    _mobileNetV3Interpreter!.run(input, output);

    // Encontrar la clase con mayor probabilidad
    final probabilities = output[0] as List<double>;
    int maxIndex = 0;
    double maxScore = probabilities[0];
    
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxScore) {
        maxScore = probabilities[i];
        maxIndex = i;
      }
    }

    return ClassificationResult(
      label: _labels[maxIndex],
      confidence: maxScore,
    );
  }

  // Convertir imagen a uint8 (0-255)
  List<List<List<List<int>>>> _imageToUint8List(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
            ];
          },
        ),
      ),
    );
  }

  // Convertir imagen a float32 (0.0-1.0)
  List<List<List<List<double>>>> _imageToFloat32List(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
  }

  void dispose() {
    _mobileNetV3Interpreter?.close();
    _mobileNetV3Interpreter = null;
  }

  bool get isModelLoaded => _mobileNetV3Interpreter != null;
}