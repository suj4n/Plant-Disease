import 'package:flutter_test/flutter_test.dart';
import 'package:plantdoc/core/widgets/diagnosis_widgets.dart';
import 'package:plantdoc/data/models/detection_result.dart';

void main() {
  group('parseConfidenceFraction', () {
    test('passes a 0-1 fraction through', () {
      expect(parseConfidenceFraction(0.87), closeTo(0.87, 1e-9));
    });

    test('treats values above 1 as percentages', () {
      expect(parseConfidenceFraction(87), closeTo(0.87, 1e-9));
      expect(parseConfidenceFraction(92.5), closeTo(0.925, 1e-9));
    });

    test('parses string forms from cloud rows', () {
      expect(parseConfidenceFraction('0.87'), closeTo(0.87, 1e-9));
      expect(parseConfidenceFraction('87'), closeTo(0.87, 1e-9));
    });

    test('is safe on null, junk and negatives', () {
      expect(parseConfidenceFraction(null), 0);
      expect(parseConfidenceFraction('not a number'), 0);
      expect(parseConfidenceFraction(-5), 0);
    });

    test('clamps above 100', () {
      expect(parseConfidenceFraction(150), 1.0);
    });
  });

  group('confidencePercentOf', () {
    test('rounds to a whole percent rather than showing raw precision', () {
      expect(confidencePercentOf(0.87324829), 87);
      expect(confidencePercentOf(0.995), 100);
    });
  });

  group('DetectionResult.fromJson - structured /api/v1/detect', () {
    final body = {
      'success': true,
      'prediction': {
        'disease': 'Early blight',
        'plant': 'Tomato',
        'confidence': 0.8712,
        'is_healthy': false,
        'is_identifiable': true,
        'risk_level': 'medium',
        'class_label': 'Tomato___Early_blight',
      },
      'alternatives': [
        {'disease': 'Late blight', 'plant': 'Tomato', 'confidence': 0.08},
        {'disease': 'Target Spot', 'plant': 'Tomato', 'confidence': 0.01},
      ],
      'information': {
        'description': 'A fungal disease.',
        'symptoms': ['Target-like spots.'],
        'treatment': ['Remove affected leaves.'],
        'prevention': ['Rotate crops.'],
      },
      'metadata': {
        'model_version': 'mobilenetv2-20c-v1',
        'processing_time_ms': 123,
      },
    };

    test('reads every section', () {
      final result = DetectionResult.fromJson(body);
      expect(result.disease, 'Early blight');
      expect(result.plant, 'Tomato');
      expect(result.confidencePercent, 87);
      expect(result.riskLevel, 'medium');
      expect(result.symptoms, ['Target-like spots.']);
      expect(result.treatment, ['Remove affected leaves.']);
      expect(result.prevention, ['Rotate crops.']);
      expect(result.processingTimeMs, 123);
      expect(result.modelVersion, 'mobilenetv2-20c-v1');
      expect(result.status, HealthStatus.diseased);
    });

    test('hides alternatives below the 5% usefulness floor', () {
      final result = DetectionResult.fromJson(body);
      expect(result.alternatives.length, 2);
      expect(
        result.meaningfulAlternatives.map((a) => a.disease),
        ['Late blight'],
      );
    });
  });

  group('DetectionResult.fromJson - legacy /predict', () {
    test('maps the flat shape, including isHealthy and recommendations', () {
      final result = DetectionResult.fromJson({
        'disease': 'Healthy Tomato',
        'plant': 'Tomato',
        'confidence': 0.94,
        'isHealthy': true,
        'recommendations': ['Keep watering evenly.'],
        'description': 'No symptoms detected.',
        'top_predictions': [
          {'disease': 'Healthy Tomato', 'plant': 'Tomato', 'confidence': 0.94},
          {'disease': 'Leaf Mold', 'plant': 'Tomato', 'confidence': 0.03},
        ],
      });

      expect(result.isHealthy, isTrue);
      expect(result.status, HealthStatus.healthy);
      expect(result.treatment, ['Keep watering evenly.']);
      // The winner must not be repeated as one of its own alternatives.
      expect(result.alternatives.map((a) => a.disease), ['Leaf Mold']);
    });
  });

  group('no-leaf handling', () {
    test('structured response is marked unidentifiable', () {
      final result = DetectionResult.fromJson({
        'prediction': {
          'disease': 'No leaf detected',
          'plant': 'Unknown',
          'confidence': 0.97,
          'is_healthy': false,
          'is_identifiable': false,
          'risk_level': 'low',
          'class_label': 'Background_without_leaves',
        },
        'information': {'description': 'No clear plant leaf was detected.'},
        'metadata': {'model_version': 'v1', 'processing_time_ms': 90},
      });

      expect(result.isIdentifiable, isFalse);
      expect(result.status, HealthStatus.unidentified);
    });

    test('legacy response is inferred from the class label', () {
      final result = DetectionResult.fromJson({
        'disease': 'No leaf detected',
        'confidence': 0.97,
        'class_label': 'Background_without_leaves',
      });
      expect(result.isIdentifiable, isFalse);
    });

    test('the raw class label never becomes the displayed disease name', () {
      final result = DetectionResult.fromJson({
        'prediction': {
          'disease': 'No leaf detected',
          'plant': 'Unknown',
          'confidence': 0.97,
          'is_identifiable': false,
          'class_label': 'Background_without_leaves',
        },
        'information': {'description': ''},
        'metadata': {'model_version': 'v1', 'processing_time_ms': 1},
      });
      expect(result.disease, isNot(contains('Background')));
      expect(result.disease, isNot(contains('_')));
    });
  });

  test('a malformed body degrades instead of throwing', () {
    final result = DetectionResult.fromJson({});
    expect(result.disease, 'Unknown');
    expect(result.confidence, 0);
    expect(result.symptoms, isEmpty);
  });
}
