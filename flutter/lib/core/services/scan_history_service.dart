import 'dart:io';

import 'supabase_service.dart';

/// Cloud persistence for scans. [ScanStorage] owns the local-first policy and
/// is the only caller — this layer just does the Supabase round trip.
///
/// Trimmed from ten methods to three: the other seven had no call sites, and
/// one of them built JSON by string concatenation.
class ScanHistoryService {
  ScanHistoryService._();

  static Future<Map<String, dynamic>> saveScan({
    required String diseaseName,
    required double confidence,
    required bool isHealthy,
    required String recommendations,
    File? imageFile,
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    return SupabaseService.saveScan(
      diseaseName: diseaseName,
      confidence: confidence,
      isHealthy: isHealthy,
      recommendations: recommendations,
      imageUrl: imageUrl,
    );
  }

  static Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) =>
      SupabaseService.getScanHistory(limit: limit);

  static Future<void> deleteScan(String scanId) =>
      SupabaseService.deleteScan(scanId);

  /// Uploads the scan photo. Returns null on failure — a scan is still worth
  /// saving without its image.
  static Future<String?> uploadImage(File imageFile) async {
    try {
      return await SupabaseService.uploadScanImage(
        imageBytes: await imageFile.readAsBytes(),
        fileName: 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    } catch (_) {
      return null;
    }
  }
}
