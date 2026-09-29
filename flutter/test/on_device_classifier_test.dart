import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantdoc/core/services/on_device_classifier.dart';
import 'package:plantdoc/data/models/detection_result.dart';

/// The on-device path must produce what the backend produces, from the
/// knowledge base the export script actually shipped.
void main() {
  final info = jsonDecode(File('assets/models/disease_info.json').readAsStringSync())
      as Map<String, dynamic>;
  final names = (info['class_names'] as List).cast<String>();

  List<double> peakAt(String label, {double p = 0.9}) {
    final probs = List<double>.filled(names.length, (1 - p) / (names.length - 1));
    probs[names.indexOf(label)] = p;
    return probs;
  }

  DetectionResult run(List<double> probs) =>
      DetectionResult.fromJson(OnDeviceClassifier.buildResponse(probs, info, 42));

  test('shipped class order matches the deployed model', () {
    final deployed = jsonDecode(File('../Resources/class_names.json').readAsStringSync());
    expect(names, deployed);
    expect(info['classes'].keys, containsAll(names));
  });

  test('a diseased leaf carries the full knowledge base', () {
    final r = run(peakAt('Tomato___Early_blight'));
    expect(r.plant, 'Tomato');
    expect(r.disease, 'Early blight');
    expect(r.confidence, closeTo(0.9, 1e-9));
    expect(r.isHealthy, isFalse);
    expect(r.isIdentifiable, isTrue);
    expect(r.symptoms, isNotEmpty);
    expect(r.treatment, isNotEmpty);
    expect(r.prevention, isNotEmpty);
    expect(r.processingTimeMs, 42);
    expect(r.modelVersion, info['model_version']);
  });

  test('alternatives are ranked, exclude the winner, and cap at four', () {
    final probs = List<double>.filled(names.length, 0.0);
    for (var i = 0; i < names.length; i++) {
      probs[i] = (i + 1) / 210; // sums to 1, highest is the last class
    }
    final r = run(probs);
    expect(r.alternatives.length, 4);
    expect(r.alternatives.map((a) => a.disease), isNot(contains(r.disease)));
    final confs = r.alternatives.map((a) => a.confidence).toList();
    expect(confs, [...confs]..sort((a, b) => b.compareTo(a)));
  });

  test('background is not identifiable', () {
    expect(run(peakAt('Background_without_leaves')).isIdentifiable, isFalse);
  });

  test('healthy leaves are flagged healthy', () {
    expect(run(peakAt('Apple___healthy')).isHealthy, isTrue);
  });
}
