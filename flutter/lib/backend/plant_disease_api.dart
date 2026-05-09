import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_settings.dart';
import 'plant_disease_models.dart';

class PlantDiseaseApi {
  PlantDiseaseApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() => _client.close();

  Future<bool> health({Duration timeout = const Duration(seconds: 4)}) async {
    final String baseUrl = await BackendSettings.getBaseUrl();
    final Uri url = Uri.parse(baseUrl).replace(path: '/health');
    try {
      final http.Response res = await _client.get(url).timeout(timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<PlantDiseasePredictResponse> predictLeafImage({
    required File imageFile,
    int topK = 5,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final String baseUrl = await BackendSettings.getBaseUrl();
    final Uri url = Uri.parse(baseUrl).replace(
      path: '/predict',
      queryParameters: <String, String>{'top_k': topK.toString()},
    );

    final http.MultipartRequest req = http.MultipartRequest('POST', url);
    req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(req).timeout(timeout);
    } on TimeoutException {
      throw const PlantDiseaseApiException(
        'Request timed out. Is the backend running?',
      );
    } on SocketException catch (e) {
      throw PlantDiseaseApiException(
        'Network error: ${e.message}. Check base URL and connectivity.',
      );
    } catch (e) {
      throw PlantDiseaseApiException('Request failed: $e');
    }

    final String body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw PlantDiseaseApiException(
        _extractError(body) ?? 'Backend error (${streamed.statusCode}).',
      );
    }

    try {
      return PlantDiseasePredictResponse.fromBody(body);
    } catch (e) {
      throw PlantDiseaseApiException('Invalid response from backend: $e');
    }
  }

  String? _extractError(String body) {
    // FastAPI returns {"detail": "..."} for many errors.
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail']?.toString();
      }
    } catch (_) {
      // Fall back to plain text / regex extraction below.
    }

    final detail = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(body);
    return detail?.group(1);
  }
}

class PlantDiseaseApiException implements Exception {
  const PlantDiseaseApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

