import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Centralized backend API service for plant disease analysis.
///
/// **USB debugging:** run `adb reverse tcp:8000 tcp:8000` and use [usbBaseUrl].
/// **Wi‑Fi:** set [lanBaseUrl] to your PC's IPv4 from `ipconfig` / `ifconfig`.
/// **Production:** set [cloudBaseUrl] to your cloud server URL.
class ApiService {
  ApiService._();

  /// PC LAN address when phone and PC share the same network.
  static const lanBaseUrl = 'http://192.168.1.75:8000';

  /// Use with `adb reverse tcp:8000 tcp:8000` during USB debugging.
  static const usbBaseUrl = 'http://127.0.0.1:8000';

  /// Production cloud backend URL
  static const cloudBaseUrl = 'https://your-domain.com';

  /// Set at build time via `--dart-define=API_BASE_URL=...` (see `scripts/dev-usb.ps1`).
  /// Falls back to [usbBaseUrl] when not defined.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: usbBaseUrl,
  );

  static const _analyzePath = '/predict';
  static const _detectPath = '/api/v1/detect';

  static String? _accessToken;

  static void setAccessToken(String? token) => _accessToken = token;

  static Map<String, String> get _authHeaders {
    final token = _accessToken ?? AuthService.getAccessToken();
    if (token == null) return {};
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Legacy `/predict` endpoint (matches existing [ScanResultScreen] fields).
  static Future<Map<String, dynamic>> analyzePlant(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$_analyzePath?top_k=5'),
    );
    
    // Add auth headers if user is authenticated
    request.headers.addAll(_authHeaders);
    
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final body = await _parseJsonResponse(response, '$baseUrl$_analyzePath');
    return normalizeScanResult(body);
  }

  /// Maps `/predict` or `/api/v1/detect` JSON into [ScanResultScreen] fields.
  static Map<String, dynamic> normalizeScanResult(Map<String, dynamic> body) {
    var raw = body;

    if (raw['prediction'] is Map) {
      raw = Map<String, dynamic>.from(raw['prediction'] as Map);
    } else if (raw['result'] is Map) {
      raw = Map<String, dynamic>.from(raw['result'] as Map);
    }

    final treatment = (raw['treatment'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final prevention = (raw['prevention'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final recommendations = (raw['recommendations'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [...treatment, ...prevention];

    final isHealthy = raw['isHealthy'] == true ||
        raw['is_healthy'] == true ||
        (raw['disease']?.toString().toLowerCase().contains('healthy') ?? false);

    return {
      'disease': raw['disease']?.toString() ??
          raw['disease_name']?.toString() ??
          'Unknown',
      'confidence': raw['confidence'] ?? 0,
      'plant': raw['plant']?.toString() ?? raw['plant_name']?.toString(),
      'isHealthy': isHealthy,
      'recommendations': recommendations,
      'description': raw['description']?.toString(),
      'top_predictions': raw['top_predictions'],
    };
  }

  /// Structured `/api/v1/detect` response.
  static Future<Map<String, dynamic>> detectPlant(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$_detectPath'),
    );
    
    // Add auth headers (required for /api/v1/detect)
    request.headers.addAll(_authHeaders);
    
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final body = await _parseJsonResponse(response, '$baseUrl$_detectPath');
    return normalizeScanResult(body);
  }

  static Future<Map<String, dynamic>> _parseJsonResponse(
    http.Response response,
    String uri,
  ) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final err = jsonDecode(response.body);
        if (err is Map && err['message'] != null) {
          message = err['message'].toString();
        }
      } catch (_) {}
      throw HttpException(message, uri: Uri.parse(uri));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{'result': decoded};
  }
}
