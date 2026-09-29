import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../data/models/detection_result.dart';

/// Runs the disease model on the phone, so a scan needs no network.
///
/// The model and knowledge base are the backend's own, exported by
/// `scripts/export_tflite.py`. The result is built in the backend's
/// `/api/v1/detect` shape, so [DetectionResult.fromJson] parses both alike.
class OnDeviceClassifier {
  OnDeviceClassifier._();

  static const _modelAsset = 'assets/models/plant_model.tflite';
  static const _infoAsset = 'assets/models/disease_info.json';

  /// Matches the backend's MAX_ALTERNATIVES.
  static const _maxAlternatives = 4;

  static Interpreter? _interpreter;
  static Map<String, dynamic>? _info;

  static Future<DetectionResult> classify(File image) async {
    final stopwatch = Stopwatch()..start();
    final info = _info ??=
        jsonDecode(await rootBundle.loadString(_infoAsset)) as Map<String, dynamic>;
    final interpreter = _interpreter ??= await Interpreter.fromAsset(_modelAsset);

    final input = await _pixels(await image.readAsBytes(), info['input_size'] as int);
    final probs = Float32List((info['class_names'] as List).length);
    interpreter.run(input.buffer.asUint8List(), probs.buffer);

    return DetectionResult.fromJson(
        buildResponse(probs, info, stopwatch.elapsedMilliseconds));
  }

  /// Decodes and resizes with the engine's native codec, then drops alpha.
  /// The model takes raw RGB 0-255; its own first layer does the scaling.
  static Future<Float32List> _pixels(Uint8List bytes, int size) async {
    final codec = await ui.instantiateImageCodec(bytes,
        targetWidth: size, targetHeight: size);
    final frame = await codec.getNextFrame();
    final rgba = (await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    frame.image.dispose();
    codec.dispose();

    final rgb = Float32List(size * size * 3);
    for (var i = 0, j = 0; i < rgba.length; i += 4) {
      rgb[j++] = rgba[i].toDouble();
      rgb[j++] = rgba[i + 1].toDouble();
      rgb[j++] = rgba[i + 2].toDouble();
    }
    return rgb;
  }

  /// Class probabilities -> the backend's `/api/v1/detect` response body.
  @visibleForTesting
  static Map<String, dynamic> buildResponse(
      List<double> probs, Map<String, dynamic> info, int elapsedMs) {
    final names = (info['class_names'] as List).cast<String>();
    final classes = info['classes'] as Map<String, dynamic>;
    Map<String, dynamic> meta(int i) =>
        Map<String, dynamic>.from(classes[names[i]] as Map);

    final ranked = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));
    final top = ranked.first;
    final best = meta(top);

    return {
      'prediction': {...best, 'confidence': probs[top], 'class_label': names[top]},
      'alternatives': [
        for (final i in ranked.skip(1).take(_maxAlternatives))
          {
            'disease': meta(i)['disease'],
            'plant': meta(i)['plant'],
            'confidence': probs[i],
            'class_label': names[i],
          },
      ],
      'information': {
        for (final k in ['description', 'symptoms', 'treatment', 'prevention'])
          k: best[k],
      },
      'metadata': {
        'model_version': info['model_version'],
        'processing_time_ms': elapsedMs,
      },
    };
  }
}
