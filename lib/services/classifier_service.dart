import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';
import 'package:image/image.dart' as img;
import '../models/classification_result.dart';

class ClassifierService {
  static const int imageSize = 224;
  
  Interpreter? _mobileNetV2;
  Interpreter? _efficientNet;
  Interpreter? _mobileNetV3;
  
  List<String> _labels = [];

  // Inicializar modelos
  Future<void> loadModels() async {
    try {
      // Cargar etiquetas
      final labelsData = await rootBundle.loadString('assets/labels/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      // Cargar MobileNet V2
      _mobileNetV2 = await Interpreter.fromAsset('assets/models/mobilenet_v2.tflite');
      print('✅ MobileNet V2 cargado');

      // Cargar EfficientNet
      _efficientNet = await Interpreter.fromAsset('assets/models/efficientnet_lite0.tflite');
      print('✅ EfficientNet cargado');

      // Cargar MobileNet V3
      _mobileNetV3 = await Interpreter.fromAsset('assets/models/mobilenet_v3.tflite');
      print('✅ MobileNet V3 cargado');

    } catch (e) {
      print('❌ Error cargando modelos: $e');
    }
  }

  // Clasificar imagen con los 3 modelos
  Future<List<ClassificationResult>> classifyImage(File imageFile) async {
    List<ClassificationResult> results = [];

    // Preprocesar imagen
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('No se pudo decodificar la imagen');
    }

    // Redimensionar a 224x224
    img.Image resizedImage = img.copyResize(image, width: imageSize, height: imageSize);
    
    // Convertir a input tensor
    var input = _imageToByteListFloat32(resizedImage);

    // Clasificar con MobileNet V2
    if (_mobileNetV2 != null) {
      results.add(await _classify(_mobileNetV2!, input, 'MobileNet V2'));
    }

    // Clasificar con EfficientNet
    if (_efficientNet != null) {
      results.add(await _classify(_efficientNet!, input, 'EfficientNet'));
    }

    // Clasificar con MobileNet V3
    if (_mobileNetV3 != null) {
      results.add(await _classify(_mobileNetV3!, input, 'MobileNet V3'));
    }

    return results;
  }

  // Clasificar con un modelo específico
  Future<ClassificationResult> _classify(
    Interpreter interpreter,
    List<List<List<List<double>>>> input,
    String modelName,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Preparar output - crear lista con la forma correcta
    var output = List.generate(
      1,
      (index) => List.filled(_labels.length, 0.0),
    );

    // Ejecutar inferencia
    interpreter.run(input, output);

    stopwatch.stop();

    // Encontrar la clase con mayor confianza
    List<double> probabilities = output[0];
    
    int maxIndex = 0;
    double maxConfidence = probabilities[0];
    
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        maxIndex = i;
      }
    }

    String label = maxIndex < _labels.length ? _labels[maxIndex] : 'Desconocido';

    return ClassificationResult(
      modelName: modelName,
      label: label,
      confidence: maxConfidence,
      processingTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  // Convertir imagen a formato tensor [1, 224, 224, 3]
  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    // Crear tensor con la forma [1, 224, 224, 3]
    var input = List.generate(
      1,
      (b) => List.generate(
        imageSize,
        (y) => List.generate(
          imageSize,
          (x) => List.generate(
            3,
            (c) => 0.0,
          ),
        ),
      ),
    );

    for (int y = 0; y < imageSize; y++) {
      for (int x = 0; x < imageSize; x++) {
        var pixel = image.getPixel(x, y);
        
        // Normalizar valores RGB a [0, 1]
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }
    
    return input;
  }

  // Cerrar intérpretes
  void dispose() {
    _mobileNetV2?.close();
    _efficientNet?.close();
    _mobileNetV3?.close();
  }
}