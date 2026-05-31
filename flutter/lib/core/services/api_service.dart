import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Centralized backend API service for plant disease analysis.
///
/// ML runs on your **cloud FastAPI server** (not on the phone). Configure the URL via:
/// - `flutter/.env` → `API_BASE_URL=https://your-api.example.com` (bundled in APK), or
/// - `flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com`
class ApiService {
  ApiService._();

  /// PC LAN address when phone and PC share the same network (dev only).
  static const lanBaseUrl = 'http://192.168.1.75:8000';

  /// Use with `adb reverse tcp:8000 tcp:8000` during USB debugging.
  static const usbBaseUrl = 'http://127.0.0.1:8000';

  static const _analyzePath = '/predict';
  static const _detectPath = '/api/v1/detect';

  static String? _baseUrl;

  /// Resolved backend URL (set in [configure] from main.dart).
  static String get baseUrl => _baseUrl ?? usbBaseUrl;

  static bool get isConfiguredForProduction {
    final url = baseUrl;
    return url.isNotEmpty &&
        !url.contains('your-domain.com') &&
        !url.contains('127.0.0.1') &&
        !url.startsWith('http://192.168.');
  }

  /// Call once after `dotenv.load()` in [main].
  static void configure({String? apiBaseUrlFromEnv}) {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      _baseUrl = _normalizeBaseUrl(fromDefine);
      debugPrint('ApiService: using API_BASE_URL from --dart-define: $_baseUrl');
      return;
    }

    final fromEnv = apiBaseUrlFromEnv?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      _baseUrl = _normalizeBaseUrl(fromEnv);
      debugPrint('ApiService: using API_BASE_URL from .env: $_baseUrl');
      return;
    }

    _baseUrl = kDebugMode ? usbBaseUrl : usbBaseUrl;
    debugPrint('ApiService: using default dev URL: $_baseUrl');
  }

  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

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
    _ensureReachableUrl();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$_analyzePath?top_k=5'),
    );

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

  /// Structured `/api/v1/detect` response.
  static Future<Map<String, dynamic>> detectPlant(File image) async {
    _ensureReachableUrl();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$_detectPath'),
    );

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

  static void _ensureReachableUrl() {
    if (baseUrl.contains('your-domain.com')) {
      throw StateError(
        'API_BASE_URL is not configured. Set it in flutter/.env or rebuild with '
        '--dart-define=API_BASE_URL=https://your-cloud-server.com',
      );
    }
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
        } else if (err is Map && err['detail'] != null) {
          message = err['detail'].toString();
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

  /// User-friendly message when the inference server cannot be reached.
  static String connectionErrorMessage(Object error) {
    final err = error.toString();
    if (err.contains('SocketException') ||
        err.contains('Failed host lookup') ||
        err.contains('Connection refused') ||
        err.contains('Network is unreachable')) {
      return 'Cannot reach the analysis server at $baseUrl.\n\n'
          'For a release APK, set API_BASE_URL in flutter/.env to your cloud backend '
          '(HTTPS), then rebuild the APK.\n\n'
          'For USB dev: start the backend and run: adb reverse tcp:8000 tcp:8000';
    }
    if (error is StateError) {
      return error.message;
    }
    if (error is HttpException) {
      return error.message;
    }
    return err.replaceFirst('HttpException: ', '');
  }
}
