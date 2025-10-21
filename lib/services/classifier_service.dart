import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

enum ModelType {
  efficientNetLite0,
  mobileNetV2,
  mobileNetV3,
}

class ClassificationResult {
  final String label;
  final double confidence;
  final ModelType modelUsed;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.modelUsed,
  });
}

class ClassifierService {
  Interpreter? _efficientNetInterpreter;
  Interpreter? _mobileNetV2Interpreter;
  Interpreter? _mobileNetV3Interpreter;
  List<String> _labels = [];
  static const int inputSize = 224;

  static final ClassifierService _instance = ClassifierService._internal();
  factory ClassifierService() => _instance;
  ClassifierService._internal();

  Future<void> loadModels() async {
    try {
      print('📦 Cargando modelos...');
      await _loadLabels();

      _efficientNetInterpreter = await Interpreter.fromAsset(
        'assets/models/efficientnet_lite0.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print('  ✅ EfficientNet Lite0 cargado');

      _mobileNetV2Interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet_v2.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print('  ✅ MobileNet V2 cargado');

      _mobileNetV3Interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet_v3.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print('  ✅ MobileNet V3 cargado');

      print('✅ Todos los modelos cargados');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  Future<void> _loadLabels() async {
    final labelsData = await rootBundle.loadString('assets/labels/labels.txt');
    _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    print('  ✅ ${_labels.length} etiquetas');
  }

  Future<ClassificationResult> classifyImage(File imageFile, ModelType modelType) async {
    Interpreter? interpreter;
    switch (modelType) {
      case ModelType.efficientNetLite0:
        interpreter = _efficientNetInterpreter;
      case ModelType.mobileNetV2:
        interpreter = _mobileNetV2Interpreter;
      case ModelType.mobileNetV3:
        interpreter = _mobileNetV3Interpreter;
    }

    if (interpreter == null) throw Exception('Modelo no cargado');

    // Leer imagen
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Error al decodificar imagen');

    // Redimensionar
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Preparar input según tipo
    final inputTensor = interpreter.getInputTensor(0);
    final inputType = inputTensor.type;
    
    Object input;
    if (inputType.toString().contains('uint8')) {
      // Para uint8: valores 0-255
      input = _imageToUint8List(resized);
    } else {
      // Para float32: valores 0.0-1.0
      input = _imageToFloat32List(resized);
    }

    // Output
    final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    // Inferencia
    interpreter.run(input, output);

    // Resultado
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
      modelUsed: modelType,
    );
  }

  // Convertir a uint8 (0-255)
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

  // Convertir a float32 (0.0-1.0)
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

  Future<List<ClassificationResult>> classifyWithAllModels(File imageFile) async {
    final results = <ClassificationResult>[];
    for (final modelType in ModelType.values) {
      try {
        results.add(await classifyImage(imageFile, modelType));
      } catch (e) {
        print('❌ Error con $modelType: $e');
      }
    }
    return results;
  }

  void dispose() {
    _efficientNetInterpreter?.close();
    _mobileNetV2Interpreter?.close();
    _mobileNetV3Interpreter?.close();
  }

  bool get isModelLoaded =>
      _efficientNetInterpreter != null &&
      _mobileNetV2Interpreter != null &&
      _mobileNetV3Interpreter != null;
}