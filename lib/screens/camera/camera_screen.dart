import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/classifier_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final ClassifierService _classifier = ClassifierService();
  
  bool _isClassifying = false;
  ClassificationResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      print('🔄 Iniciando carga del modelo...');
      await _classifier.loadModels();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Modelo cargado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      print('✅ Modelo listo para usar');
    } catch (e) {
      print('❌ Error al cargar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar modelo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = null;
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

  Future<void> _classifyImage() async {
    if (_image == null) return;

    setState(() {
      _isClassifying = true;
      _errorMessage = null;
    });

    try {
      print('🚀 Iniciando clasificación...');
      
      final result = await _classifier.classifyImage(_image!);
      
      setState(() {
        _result = result;
        _isClassifying = false;
      });
      
      print('✅ Clasificación completada');
    } catch (e) {
      print('❌ Error en clasificación: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isClassifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clasificador de Imágenes'),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // MOSTRAR LA IMAGEN
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
            
            // BOTONES DE GALERÍA Y CÁMARA
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.teal[600],
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
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // BOTÓN CLASIFICAR
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
                          'Clasificar Imagen',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            
            const SizedBox(height: 30),
            
            // MOSTRAR ERRORES
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
            
            // MOSTRAR RESULTADO
            if (_result != null) ...[
              const Divider(thickness: 2),
              const SizedBox(height: 10),
              const Text(
                '📊 Resultado de Clasificación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildResultCard(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ClassificationResult result) {
    final confidencePercentage = (result.confidence * 100).toStringAsFixed(1);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.teal.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del modelo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MobileNet V3',
                  style: TextStyle(
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
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