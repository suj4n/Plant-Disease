import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Scan history and image management service
class ScanHistoryService {
  /// Save a scan result
  static Future<Map<String, dynamic>> saveScan({
    required String diseaseName,
    required double confidence,
    required bool isHealthy,
    required String recommendations,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      }

      // Save scan to Supabase
      final scan = await SupabaseService.saveScan(
        diseaseName: diseaseName,
        confidence: confidence,
        isHealthy: isHealthy,
        recommendations: recommendations,
        imageUrl: imageUrl,
      );

      return scan;
    } catch (e) {
      throw Exception('Failed to save scan: $e');
    }
  }

  /// Get scan history
  static Future<List<Map<String, dynamic>>> getHistory({
    int limit = 50,
  }) async {
    try {
      return await SupabaseService.getScanHistory(limit: limit);
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  /// Get a specific scan
  static Future<Map<String, dynamic>?> getScan(String scanId) async {
    try {
      return await SupabaseService.getScanById(scanId);
    } catch (e) {
      print('Failed to fetch scan: $e');
      return null;
    }
  }

  /// Delete a scan
  static Future<void> deleteScan(String scanId) async {
    try {
      await SupabaseService.deleteScan(scanId);
    } catch (e) {
      throw Exception('Failed to delete scan: $e');
    }
  }

  /// Upload image to storage
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final url = await SupabaseService.uploadScanImage(
        imageBytes: bytes,
        fileName: fileName,
      );

      return url;
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  /// Get total scan count
  static Future<int> getScanCount() async {
    try {
      final scans = await getHistory(limit: 100);
      return scans.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get statistics for dashboard
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final scans = await getHistory(limit: 100);

      int healthyCount = 0;
      int diseaseCount = 0;
      double avgConfidence = 0;
      Map<String, int> diseaseCounts = {};

      for (var scan in scans) {
        if (scan['is_healthy'] == true) {
          healthyCount++;
        } else {
          diseaseCount++;
        }

        avgConfidence += (scan['confidence'] ?? 0) as double;

        final diseaseName = scan['disease_name'] as String?;
        if (diseaseName != null) {
          diseaseCounts[diseaseName] = (diseaseCounts[diseaseName] ?? 0) + 1;
        }
      }

      if (scans.isNotEmpty) {
        avgConfidence /= scans.length;
      }

      // Most common disease
      String mostCommonDisease = 'None';
      if (diseaseCounts.isNotEmpty) {
        mostCommonDisease = diseaseCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      return {
        'total_scans': scans.length,
        'healthy_count': healthyCount,
        'disease_count': diseaseCount,
        'avg_confidence': avgConfidence,
        'most_common_disease': mostCommonDisease,
        'diseases': diseaseCounts,
      };
    } catch (e) {
      print('Failed to get statistics: $e');
      return {
        'total_scans': 0,
        'healthy_count': 0,
        'disease_count': 0,
        'avg_confidence': 0.0,
        'most_common_disease': 'None',
        'diseases': {},
      };
    }
  }

  /// Search scans by disease
  static Future<List<Map<String, dynamic>>> searchByDisease(
    String diseaseName,
  ) async {
    try {
      final scans = await getHistory(limit: 100);
      return scans
          .where((scan) =>
              (scan['disease_name'] as String?)
                  ?.toLowerCase()
                  .contains(diseaseName.toLowerCase()) ??
              false)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recent scans (last N days)
  static Future<List<Map<String, dynamic>>> getRecentScans(int days) async {
    try {
      final scans = await getHistory();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      return scans.where((scan) {
        final createdAt = scan['created_at'] as String?;
        if (createdAt == null) return false;
        return DateTime.parse(createdAt).isAfter(cutoffDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Export scan data as JSON
  static Future<String> exportAsJson() async {
    try {
      final scans = await getHistory(limit: 1000);
      // Format as JSON string
      return '[${scans.map((s) => '{"id":"${s['id']}","disease":"${s['disease_name']}","confidence":${s['confidence']},"date":"${s['created_at']}"}').join(',')}]';
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Subscribe to scan changes (real-time updates)
  static RealtimeChannel subscribeToChanges({
    required Function(List<Map<String, dynamic>>) onUpdate,
  }) {
    try {
      return SupabaseService.subscribeToScans(onUpdate: onUpdate);
    } catch (e) {
      throw Exception('Failed to subscribe: $e');
    }
  }

  /// Unsubscribe from real-time updates
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await SupabaseService.unsubscribe(channel);
  }
}
