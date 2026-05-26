import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Centralized backend API service for plant disease analysis.
class ApiService {
  ApiService._();

  static const baseUrl = 'https://your-api-url.onrender.com';
  static const _analyzePath = '/predict';

  static Future<Map<String, dynamic>> analyzePlant(File image) async {
    if (baseUrl.contains('your-api')) {
      throw StateError(
        'Please configure ApiService.baseUrl with your backend endpoint for analysis.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$_analyzePath'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw HttpException(
        'Analysis failed with status ${response.statusCode}',
        uri: Uri.parse('$baseUrl$_analyzePath'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'result': decoded};
  }
}
