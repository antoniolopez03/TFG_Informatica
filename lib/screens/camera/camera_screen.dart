import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/classifier_service.dart';  // ← Importar nuestro servicio

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;  // La imagen seleccionada
  final ImagePicker _picker = ImagePicker();
  final ClassifierService _classifier = ClassifierService();  // ← Nuestro servicio
  
  bool _isClassifying = false;  // ¿Está clasificando ahora?
  List<ClassificationResult>? _results;  // Los resultados de los 3 modelos
  String? _errorMessage;  // Si hay algún error

  @override
  void initState() {
    super.initState();
    _loadModels();  // Cargar modelos al iniciar
  }

  // Cargar los modelos cuando abre la pantalla
  Future<void> _loadModels() async {
    try {
      print('🔄 Iniciando carga de modelos...');
      await _classifier.loadModels();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Modelos cargados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      print('✅ Modelos listos para usar');
    } catch (e) {
      print('❌ Error al cargar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar modelos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Seleccionar imagen de galería o cámara
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _results = null;  // Limpiar resultados anteriores
          _errorMessage = null;
        });
        print('📸 Imagen seleccionada: ${pickedFile.path}');
      }
    } catch (e) {
      print('❌ Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ¡CLASIFICAR LA IMAGEN!
  Future<void> _classifyImage() async {
    if (_image == null) return;

    setState(() {
      _isClassifying = true;
      _errorMessage = null;
    });

    try {
      print('🚀 Iniciando clasificación...');
      
      // Clasificar con los 3 modelos
      final results = await _classifier.classifyWithAllModels(_image!);
      
      setState(() {
        _results = results;
        _isClassifying = false;
      });
      
      print('✅ Clasificación completada: ${results.length} resultados');
    } catch (e) {
      print('❌ Error en clasificación: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isClassifying = false;
      });
    }
  }

  // Obtener nombre legible del modelo
  String _getModelName(ModelType modelType) {
    switch (modelType) {
      case ModelType.efficientNetLite0:
        return 'EfficientNet Lite0';
      case ModelType.mobileNetV2:
        return 'MobileNet V2';
      case ModelType.mobileNetV3:
        return 'MobileNet V3';
    }
  }

  // Obtener color para cada modelo
  Color _getModelColor(ModelType modelType) {
    switch (modelType) {
      case ModelType.efficientNetLite0:
        return Colors.purple;
      case ModelType.mobileNetV2:
        return Colors.blue;
      case ModelType.mobileNetV3:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clasificador de Imágenes'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SECCIÓN 1: MOSTRAR LA IMAGEN
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 80, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'No hay imagen seleccionada',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // SECCIÓN 2: BOTONES DE GALERÍA Y CÁMARA
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // SECCIÓN 3: BOTÓN CLASIFICAR
            if (_image != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isClassifying ? null : _classifyImage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isClassifying
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Clasificando...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Text(
                          'Clasificar con los 3 modelos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            
            const SizedBox(height: 30),
            
            // SECCIÓN 4: MOSTRAR ERRORES
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            // SECCIÓN 5: MOSTRAR RESULTADOS
            if (_results != null && _results!.isNotEmpty) ...[
              const Divider(thickness: 2),
              const SizedBox(height: 10),
              const Text(
                '📊 Resultados de Clasificación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Mostrar cada resultado en una tarjeta
              ...(_results!.map((result) => _buildResultCard(result)).toList()),
            ],
          ],
        ),
      ),
    );
  }

  // Crear tarjeta bonita para cada resultado
  Widget _buildResultCard(ClassificationResult result) {
    final modelColor = _getModelColor(result.modelUsed);
    final confidencePercentage = (result.confidence * 100).toStringAsFixed(1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [modelColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del modelo con color
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: modelColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getModelName(result.modelUsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Objeto detectado
              Row(
                children: [
                  const Icon(Icons.label, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Barra de confianza
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Confianza:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '$confidencePercentage%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: modelColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: result.confidence,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(modelColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}