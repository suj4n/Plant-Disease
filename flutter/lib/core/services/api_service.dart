import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/detection_result.dart';
import 'api_error.dart';
import 'auth_service.dart';
import 'image_validation.dart';

/// The only place in the app that talks HTTP to the PlantDoc backend.
///
/// Widgets never call this directly — they go through a repository or provider.
/// Every failure leaves here as an [ApiError] carrying displayable copy.
///
/// ML runs on the FastAPI server, not on the phone. Configure the URL via:
/// - `flutter/.env` -> `API_BASE_URL=https://your-api.example.com`, or
/// - `flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com`
class ApiService {
  ApiService._();

  /// Use with `adb reverse tcp:8000 tcp:8000` during USB debugging.
  static const usbBaseUrl = 'http://127.0.0.1:8000';

  static const _detectPath = '/api/v1/detect';
  static const _requestTimeout = Duration(seconds: 60);

  static String? _baseUrl;

  static String get baseUrl => _baseUrl ?? usbBaseUrl;

  static bool get isConfiguredForProduction {
    final url = baseUrl;
    return url.isNotEmpty &&
        !url.contains('your-domain.com') &&
        !url.contains('127.0.0.1') &&
        !url.startsWith('http://192.168.');
  }

  /// Call once after `dotenv.load()` in `main`.
  static void configure({String? apiBaseUrlFromEnv}) {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      _baseUrl = _normalizeBaseUrl(fromDefine);
      return;
    }

    final fromEnv = apiBaseUrlFromEnv?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      _baseUrl = _normalizeBaseUrl(fromEnv);
      return;
    }

    _baseUrl = usbBaseUrl;
    debugPrint('ApiService: API_BASE_URL not set, using dev default $_baseUrl');
  }

  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static Map<String, String> get _authHeaders {
    final token = AuthService.getAccessToken();
    if (token == null) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  /// Analyses a leaf photo. Validates the file locally first so an obviously
  /// unusable image fails instantly instead of after a 60-second round trip.
  static Future<DetectionResult> detect(File image) async {
    _ensureReachableUrl();

    final validation = await validateImageFile(image);
    if (!validation.isValid) {
      throw ApiError('INVALID_IMAGE', validation.message!, canRetry: true);
    }

    final uri = Uri.parse('$baseUrl$_detectPath');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders)
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final streamed = await request.send().timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamed);
      final body = _decode(response);
      return DetectionResult.fromJson(body).copyWith(
        imagePath: image.path,
        timestamp: DateTime.now(),
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  static void _ensureReachableUrl() {
    if (baseUrl.contains('your-domain.com')) {
      throw StateError(
        'PlantDoc is not configured to reach a server yet. '
        'Set API_BASE_URL in flutter/.env and rebuild.',
      );
    }
  }

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      body = {};
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiError.fromResponse(body, response.statusCode);
    }
    return body;
  }
}
