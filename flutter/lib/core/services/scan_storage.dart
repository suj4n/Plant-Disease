import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'scan_history_service.dart';
import 'supabase_service.dart';

/// Scan history: device cache for guests, Supabase for signed-in users.
class ScanStorage {
  ScanStorage._();

  static const String _guestKey = 'scan_history';

  static bool get _useCloud => SupabaseService.isAuthenticated;

  static Future<List<Map<String, dynamic>>> getAll() async {
    if (_useCloud) {
      try {
        final rows = await SupabaseService.getScanHistory(limit: 200);
        return rows.map(_fromCloud).toList();
      } catch (_) {
        return [];
      }
    }
    return _getAllGuest();
  }

  static Future<void> save(Map<String, dynamic> scanData) async {
    if (_useCloud) {
      await _saveCloud(scanData);
      return;
    }
    await _saveGuest(scanData);
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

  /// Moves guest-only scans to the signed-in account, then clears local cache.
  static Future<void> migrateGuestDataToCloud() async {
    if (!_useCloud) return;

    final guestScans = await _getAllGuest();
    for (final scan in guestScans) {
      try {
        await _saveCloud({
          'disease': scan['disease'],
          'confidence': scan['confidence'],
          'isHealthy': scan['isHealthy'],
          'recommendations': <String>[],
          'timestamp': scan['timestamp'],
        });
      } catch (_) {}
    }
    await clearGuestCache();
  }

  static Future<void> clearGuestCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
  }

  static Future<void> clearAll() async {
    if (_useCloud) {
      try {
        final scans = await SupabaseService.getScanHistory(limit: 500);
        for (final scan in scans) {
          final id = scan['id']?.toString();
          if (id != null) {
            await SupabaseService.deleteScan(id);
          }
        }
      } catch (_) {}
      return;
    }
    await clearGuestCache();
  }

  static const List<String> weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Scan counts for each day of the current week (Monday–Sunday).
  static List<int> scanCountsForCurrentWeek(List<Map<String, dynamic>> scans) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));

    final counts = List<int>.filled(7, 0);
    for (final scan in scans) {
      final raw = scan['timestamp'];
      if (raw == null) continue;
      try {
        final dt = DateTime.parse(raw.toString());
        final day = DateTime(dt.year, dt.month, dt.day);
        final index = day.difference(monday).inDays;
        if (index >= 0 && index < 7) counts[index]++;
      } catch (_) {}
    }
    return counts;
  }

  static Future<List<Map<String, dynamic>>> _getAllGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_guestKey) ?? [];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  static Future<void> _saveGuest(Map<String, dynamic> scanData) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_guestKey) ?? [];
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
    await prefs.setStringList(_guestKey, raw);
  }

  static Future<void> _saveCloud(Map<String, dynamic> scanData) async {
    final disease = scanData['disease']?.toString() ?? 'Unknown';
    final confidence = _confidenceAsFraction(scanData['confidence']);
    final isHealthy = scanData['isHealthy'] as bool? ?? false;
    final recommendations = _recommendationsText(scanData['recommendations']);

    File? imageFile;
    final imagePath = scanData['imagePath'] as String?;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) imageFile = file;
    }

    await ScanHistoryService.saveScan(
      diseaseName: disease,
      confidence: confidence,
      isHealthy: isHealthy,
      recommendations: recommendations,
      imageFile: imageFile,
    );
  }

  static Map<String, dynamic> _fromCloud(Map<String, dynamic> scan) {
    return {
      'id': scan['id']?.toString(),
      'disease': scan['disease_name'] ?? 'Unknown',
      'confidence': _normalizeConf(scan['confidence']),
      'isHealthy': scan['is_healthy'] == true,
      'imagePath': scan['image_url'],
      'timestamp': scan['created_at']?.toString(),
    };
  }

  static String _recommendationsText(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).join('\n');
    }
    if (raw is String) return raw;
    return '';
  }

  static double _confidenceAsFraction(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) {
      final v = raw.toDouble();
      return v > 1.0 ? (v / 100).clamp(0, 1) : v.clamp(0, 1);
    }
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed == null) return 0;
      return parsed > 1.0 ? (parsed / 100).clamp(0, 1) : parsed.clamp(0, 1);
    }
    return 0;
  }

  static int _normalizeConf(dynamic raw) {
    if (raw == null) return 0;
    if (raw is double) return raw <= 1.0 ? (raw * 100).round() : raw.round();
    if (raw is int) return raw > 1 ? raw : (raw * 100).round();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }
}
