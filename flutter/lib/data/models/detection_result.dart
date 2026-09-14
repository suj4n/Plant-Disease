import '../../core/widgets/diagnosis_widgets.dart' show HealthStatus;

/// One lower-ranked class the model also considered.
class AlternativeMatch {
  const AlternativeMatch({
    required this.disease,
    required this.plant,
    required this.confidence,
  });

  final String disease;
  final String plant;

  /// 0-1.
  final double confidence;

  int get confidencePercent => (confidence * 100).round();

  static AlternativeMatch? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final disease = raw['disease']?.toString();
    if (disease == null || disease.isEmpty) return null;
    return AlternativeMatch(
      disease: disease,
      plant: raw['plant']?.toString() ?? '',
      confidence: parseConfidenceFraction(raw['confidence']),
    );
  }
}

/// A parsed detection, from either `/api/v1/detect` or the legacy `/predict`.
///
/// The UI reads this, never a raw `Map<String, dynamic>`, so a backend shape
/// change surfaces here once instead of in every widget.
class DetectionResult {
  const DetectionResult({
    required this.disease,
    required this.plant,
    required this.confidence,
    required this.isHealthy,
    required this.isIdentifiable,
    required this.riskLevel,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    required this.alternatives,
    this.imagePath,
    this.timestamp,
    this.processingTimeMs,
    this.modelVersion,
  });

  final String disease;
  final String plant;

  /// 0-1.
  final double confidence;
  final bool isHealthy;

  /// False when the model saw no leaf. The UI must show a recovery prompt
  /// rather than a diagnosis, and must never print the raw class label.
  final bool isIdentifiable;

  /// 'low' | 'medium' | 'high' — disease severity, not model certainty.
  final String riskLevel;

  final String description;
  final List<String> symptoms;
  final List<String> treatment;
  final List<String> prevention;
  final List<AlternativeMatch> alternatives;

  final String? imagePath;
  final DateTime? timestamp;
  final int? processingTimeMs;
  final String? modelVersion;

  int get confidencePercent => (confidence * 100).round();

  HealthStatus get status {
    if (!isIdentifiable) return HealthStatus.unidentified;
    return isHealthy ? HealthStatus.healthy : HealthStatus.diseased;
  }

  /// Alternatives worth showing: meaningfully probable, and at most four.
  List<AlternativeMatch> get meaningfulAlternatives =>
      alternatives.where((a) => a.confidence >= 0.05).take(4).toList();

  /// Everything useful for a user in one list, for the compact legacy view.
  List<String> get recommendations => [...treatment, ...prevention];

  DetectionResult copyWith({String? imagePath, DateTime? timestamp}) {
    return DetectionResult(
      disease: disease,
      plant: plant,
      confidence: confidence,
      isHealthy: isHealthy,
      isIdentifiable: isIdentifiable,
      riskLevel: riskLevel,
      description: description,
      symptoms: symptoms,
      treatment: treatment,
      prevention: prevention,
      alternatives: alternatives,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      processingTimeMs: processingTimeMs,
      modelVersion: modelVersion,
    );
  }

  /// Accepts both response shapes:
  /// - `/api/v1/detect`: `{prediction, alternatives, information, metadata}`
  /// - `/predict` (legacy): flat, with `recommendations` and `top_predictions`.
  factory DetectionResult.fromJson(Map<String, dynamic> body) {
    final prediction = body['prediction'] is Map
        ? Map<String, dynamic>.from(body['prediction'] as Map)
        : body;
    final information = body['information'] is Map
        ? Map<String, dynamic>.from(body['information'] as Map)
        : prediction;
    final metadata = body['metadata'] is Map
        ? Map<String, dynamic>.from(body['metadata'] as Map)
        : const <String, dynamic>{};

    final treatment = _stringList(information['treatment']);
    final prevention = _stringList(information['prevention']);
    final recommendations = _stringList(prediction['recommendations']);

    final classLabel = prediction['class_label']?.toString() ?? '';
    final disease =
        prediction['disease']?.toString() ?? prediction['disease_name']?.toString() ?? 'Unknown';

    // Legacy /predict has no is_identifiable flag, so infer it the only way
    // available: the backend renders this class as "No leaf detected".
    final isIdentifiable = prediction['is_identifiable'] as bool? ??
        !(classLabel == 'Background_without_leaves' ||
            disease.toLowerCase() == 'no leaf detected');

    final rawAlternatives = body['alternatives'] ?? prediction['top_predictions'];
    final alternatives = <AlternativeMatch>[];
    if (rawAlternatives is List) {
      for (final entry in rawAlternatives) {
        final parsed = AlternativeMatch.tryParse(entry);
        if (parsed == null) continue;
        // The legacy endpoint includes the winner in top_predictions.
        if (parsed.disease == disease) continue;
        alternatives.add(parsed);
      }
    }

    return DetectionResult(
      disease: disease,
      plant: prediction['plant']?.toString() ?? prediction['plant_name']?.toString() ?? '',
      confidence: parseConfidenceFraction(prediction['confidence']),
      isHealthy: prediction['is_healthy'] as bool? ?? prediction['isHealthy'] as bool? ?? false,
      isIdentifiable: isIdentifiable,
      riskLevel: prediction['risk_level']?.toString() ?? 'medium',
      description: information['description']?.toString() ??
          prediction['description']?.toString() ??
          '',
      symptoms: _stringList(information['symptoms']),
      treatment: treatment.isNotEmpty ? treatment : recommendations,
      prevention: prevention,
      alternatives: alternatives,
      processingTimeMs: (metadata['processing_time_ms'] as num?)?.toInt(),
      modelVersion: metadata['model_version']?.toString(),
    );
  }

  /// Compact form for local history storage.
  Map<String, dynamic> toStorageJson() => {
        'disease': disease,
        'plant': plant,
        'confidence': confidence,
        'isHealthy': isHealthy,
        'isIdentifiable': isIdentifiable,
        'riskLevel': riskLevel,
        'description': description,
        'symptoms': symptoms,
        'treatment': treatment,
        'prevention': prevention,
        'imagePath': imagePath,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      };

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
}

/// Normalises confidence to a 0-1 fraction.
///
/// The backend sends 0-1, older stored records sometimes hold 0-100, and cloud
/// rows can arrive as strings. Anything above 1 is treated as a percentage.
double parseConfidenceFraction(Object? raw) {
  final value = switch (raw) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0.0,
  };
  if (value <= 0) return 0;
  return (value > 1 ? value / 100 : value).clamp(0.0, 1.0);
}

/// Whole-percent form for display. Never show raw float precision to a user.
int confidencePercentOf(Object? raw) => (parseConfidenceFraction(raw) * 100).round();
