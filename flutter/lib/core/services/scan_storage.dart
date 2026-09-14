import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/detection_result.dart';
import 'scan_history_service.dart';
import 'supabase_service.dart';

/// Scan history, local-first.
///
/// Previously this routed signed-in users straight to Supabase and returned an
/// empty list whenever that failed — so a logged-in user with no network saw an
/// empty home screen and lost every scan they took offline.
///
/// Now every scan is written locally first and mirrored to the cloud on a best
/// effort basis. Cloud reads refresh the local cache, and any cloud failure
/// falls back to that cache instead of to nothing.
class ScanStorage {
  ScanStorage._();

  static const String _cacheKey = 'scan_history';
  static const int _maxCached = 200;

  static bool get _useCloud => SupabaseService.isAuthenticated;

  // --- Reads ------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getAll() async {
    if (!_useCloud) return _readCache();

    try {
      final rows = await SupabaseService.getScanHistory(limit: _maxCached);
      final scans = rows.map(_fromCloud).toList();
      await _writeCache(scans);
      return scans;
    } catch (e) {
      // Offline or Supabase is down. The cache is the whole point.
      debugPrint('ScanStorage: cloud read failed, using local cache ($e)');
      return _readCache();
    }
  }

  static Future<List<Map<String, dynamic>>> getRecent(int count) async {
    final all = await getAll();
    return all.take(count).toList();
  }

  // --- Writes -----------------------------------------------------------

  /// Saves a scan. The local write always happens; the cloud mirror is best
  /// effort, so losing the network never loses the scan.
  static Future<void> save(Map<String, dynamic> scanData) async {
    final entry = _normalizeEntry(scanData);
    await _appendToCache(entry);

    if (!_useCloud) return;
    try {
      await _saveCloud(scanData);
    } catch (e) {
      debugPrint('ScanStorage: cloud save failed, kept locally ($e)');
    }
  }

  static Future<void> saveResult(DetectionResult result) =>
      save(result.toStorageJson());

  /// Copies guest-only scans into the signed-in account after login.
  static Future<void> migrateGuestDataToCloud() async {
    if (!_useCloud) return;

    for (final scan in await _readCache()) {
      try {
        await _saveCloud(scan);
      } catch (_) {
        // Best effort; the scan stays in the local cache either way.
      }
    }
  }

  static Future<void> clearGuestCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  static Future<void> clearAll() async {
    await clearGuestCache();
    if (!_useCloud) return;
    try {
      final scans = await SupabaseService.getScanHistory(limit: 500);
      await Future.wait(
        scans
            .map((s) => s['id']?.toString())
            .whereType<String>()
            .map(SupabaseService.deleteScan),
      );
    } catch (e) {
      debugPrint('ScanStorage: cloud clear failed ($e)');
    }
  }

  // --- Local cache ------------------------------------------------------

  static Future<List<Map<String, dynamic>>> _readCache() async {
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

  static Future<void> _writeCache(List<Map<String, dynamic>> scans) async {
    final prefs = await SharedPreferences.getInstance();
    // Stored oldest-first; _readCache reverses to newest-first.
    final ordered = scans.reversed.take(_maxCached).toList();
    await prefs.setStringList(
      _cacheKey,
      ordered.map(jsonEncode).toList(),
    );
  }

  static Future<void> _appendToCache(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = List<String>.from(prefs.getStringList(_cacheKey) ?? const []);
    raw.add(jsonEncode(entry));
    if (raw.length > _maxCached) {
      raw.removeRange(0, raw.length - _maxCached);
    }
    await prefs.setStringList(_cacheKey, raw);
  }

  // --- Shape conversion -------------------------------------------------

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

  static Map<String, dynamic> _fromCloud(Map<String, dynamic> scan) => {
        'id': scan['id']?.toString(),
        'disease': scan['disease_name']?.toString() ?? 'Unknown',
        'plant': scan['plant_name']?.toString() ?? '',
        'confidence': parseConfidenceFraction(scan['confidence']),
        'isHealthy': scan['is_healthy'] == true,
        'isIdentifiable': true,
        'riskLevel': scan['risk_level']?.toString() ?? 'medium',
        'imagePath': scan['image_url'],
        'timestamp': scan['created_at']?.toString(),
      };

  static Future<void> _saveCloud(Map<String, dynamic> scanData) async {
    File? imageFile;
    final imagePath = scanData['imagePath'] as String?;
    // A cloud URL from a previous sync is not a local file to re-upload.
    if (imagePath != null &&
        imagePath.isNotEmpty &&
        !imagePath.startsWith('http')) {
      final file = File(imagePath);
      if (file.existsSync()) imageFile = file;
    }

    await ScanHistoryService.saveScan(
      diseaseName: scanData['disease']?.toString() ?? 'Unknown',
      confidence: parseConfidenceFraction(scanData['confidence']),
      isHealthy: scanData['isHealthy'] == true,
      recommendations: _recommendationsText(scanData),
      imageFile: imageFile,
    );
  }

  static String _recommendationsText(Map<String, dynamic> scan) {
    final parts = <String>[];
    for (final key in ['treatment', 'prevention', 'recommendations']) {
      final raw = scan[key];
      if (raw is List) parts.addAll(raw.map((e) => e.toString()));
      if (raw is String && raw.isNotEmpty) parts.add(raw);
    }
    return parts.where((s) => s.isNotEmpty).join('\n');
  }
}
