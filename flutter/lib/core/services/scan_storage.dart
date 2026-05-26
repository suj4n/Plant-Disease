import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for scan history and stats (SharedPreferences).
class ScanStorage {
  ScanStorage._();

  static const String _key = 'scan_history';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  static Future<void> save(Map<String, dynamic> scanData) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'disease': scanData['disease'] ?? 'Unknown',
      'confidence': _normalizeConf(scanData['confidence']),
      'isHealthy': scanData['isHealthy'] ?? false,
      'imagePath': scanData['imagePath'],
      'timestamp':
          scanData['timestamp'] ?? DateTime.now().toIso8601String(),
    };
    raw.add(jsonEncode(entry));
    await prefs.setStringList(_key, raw);
  }

  static Future<Map<String, int>> getStats() async {
    final all = await getAll();
    final healthy = all.where((s) => s['isHealthy'] == true).length;
    return {
      'total': all.length,
      'healthy': healthy,
      'diseased': all.length - healthy,
    };
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static int _normalizeConf(dynamic raw) {
    if (raw == null) return 0;
    if (raw is double) return raw <= 1.0 ? (raw * 100).round() : raw.round();
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }
}
