import 'dart:io';

String platformDefaultBaseUrl() {
  // Android emulator: use 10.0.2.2 to reach host machine.
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://127.0.0.1:8000';
}

