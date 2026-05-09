import 'backend_settings_platform_stub.dart'
    if (dart.library.io) 'backend_settings_platform_io.dart'
    if (dart.library.html) 'backend_settings_platform_web.dart' as platform;

String platformDefaultBaseUrl() => platform.platformDefaultBaseUrl();

