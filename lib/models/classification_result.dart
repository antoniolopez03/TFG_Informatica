class ClassificationResult {
  final String modelName;
  final String label;
  final double confidence;
  final int processingTimeMs;

  ClassificationResult({
    required this.modelName,
    required this.label,
    required this.confidence,
    required this.processingTimeMs,
  });

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(2)}%';
}