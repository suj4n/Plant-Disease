import 'package:shared_preferences/shared_preferences.dart';

import 'backend_settings_platform.dart';

class BackendSettings {
  BackendSettings._();

  static const String _prefsKeyBaseUrl = 'plantdoc_backend_base_url';

  /// Default depends on platform.
  ///
  /// - Android emulator: use 10.0.2.2 to reach host machine
  /// - Everything else (iOS simulator, desktop, web): 127.0.0.1
  static String defaultBaseUrl() {
    return platformDefaultBaseUrl();
  }

  static Future<String> getBaseUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKeyBaseUrl);
    final String base = (saved == null || saved.trim().isEmpty)
        ? defaultBaseUrl()
        : saved.trim();
    return _normalizeBaseUrl(base);
  }

  static Future<void> setBaseUrl(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyBaseUrl, _normalizeBaseUrl(value));
  }

  static String _normalizeBaseUrl(String raw) {
    var s = raw.trim();
    if (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}

