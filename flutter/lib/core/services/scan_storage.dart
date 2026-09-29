import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/detection_result.dart';

/// Scan history, stored on this phone only.
class ScanStorage {
  ScanStorage._();

  static const String _cacheKey = 'scan_history';
  static const int _maxCached = 200;

  /// Newest first.
  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_cacheKey) ?? const [];
    final scans = <Map<String, dynamic>>[];
    for (final line in raw) {
      try {
        final decoded = jsonDecode(line);
        if (decoded is Map) scans.add(Map<String, dynamic>.from(decoded));
      } catch (_) {
        // Skip a corrupt row rather than losing the whole history.
      }
    }
    return scans.reversed.toList();
  }

  static Future<List<Map<String, dynamic>>> getRecent(int count) async {
    final all = await getAll();
    return all.take(count).toList();
  }

  static Future<void> save(Map<String, dynamic> scanData) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = List<String>.from(prefs.getStringList(_cacheKey) ?? const []);
    raw.add(jsonEncode(_normalizeEntry(scanData)));
    if (raw.length > _maxCached) {
      raw.removeRange(0, raw.length - _maxCached);
    }
    await prefs.setStringList(_cacheKey, raw);
  }

  static Future<void> saveResult(DetectionResult result) =>
      save(result.toStorageJson());

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  static Map<String, dynamic> _normalizeEntry(Map<String, dynamic> scan) => {
        'id': scan['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'disease': scan['disease']?.toString() ?? 'Unknown',
        'plant': scan['plant']?.toString() ?? '',
        'confidence': parseConfidenceFraction(scan['confidence']),
        'isHealthy': scan['isHealthy'] == true,
        'isIdentifiable': scan['isIdentifiable'] as bool? ?? true,
        'riskLevel': scan['riskLevel']?.toString() ?? 'medium',
        'imagePath': scan['imagePath'],
        'timestamp': scan['timestamp']?.toString() ??
            DateTime.now().toIso8601String(),
      };
}
