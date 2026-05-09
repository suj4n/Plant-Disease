import 'dart:convert';

class PlantDiseasePrediction {
  const PlantDiseasePrediction({required this.label, required this.probability});

  final String label;
  /// Range: 0..1
  final double probability;

  factory PlantDiseasePrediction.fromJson(Map<String, dynamic> json) {
    final Object? rawP = json['probability'];
    final double p = rawP is num ? rawP.toDouble() : 0.0;
    return PlantDiseasePrediction(
      label: (json['label'] ?? '').toString(),
      probability: p.clamp(0.0, 1.0),
    );
  }
}

class PlantDiseasePredictResponse {
  const PlantDiseasePredictResponse({
    required this.topLabel,
    required this.predictions,
    required this.modelPath,
  });

  final String? topLabel;
  final List<PlantDiseasePrediction> predictions;
  final String? modelPath;

  PlantDiseasePrediction? get topPrediction =>
      predictions.isNotEmpty ? predictions.first : null;

  factory PlantDiseasePredictResponse.fromJson(Map<String, dynamic> json) {
    final Object? preds = json['predictions'];
    final List<PlantDiseasePrediction> parsed = <PlantDiseasePrediction>[];
    if (preds is List) {
      for (final Object? item in preds) {
        if (item is Map) {
          parsed.add(
            PlantDiseasePrediction.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    return PlantDiseasePredictResponse(
      topLabel: json['top_label']?.toString(),
      predictions: parsed,
      modelPath: json['model_path']?.toString(),
    );
  }

  static PlantDiseasePredictResponse fromBody(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return PlantDiseasePredictResponse.fromJson(decoded);
    }
    if (decoded is Map) {
      return PlantDiseasePredictResponse.fromJson(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    throw const FormatException('Unexpected response shape');
  }
}

