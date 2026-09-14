/// Backend failures translated into something a farmer can act on.
///
/// A user must never see `ClientException: Connection refused`. Every failure
/// path in the app funnels through [ApiError.from] so the message is one of a
/// known, human set.
class ApiError implements Exception {
  const ApiError(this.code, this.message, {this.canRetry = true});

  /// Machine-readable code from the backend envelope, or one of the local
  /// pseudo-codes below.
  final String code;

  /// Ready to display. Already human.
  final String message;

  final bool canRetry;

  static const network = 'NETWORK_UNAVAILABLE';
  static const timeout = 'TIMEOUT';
  static const notConfigured = 'NOT_CONFIGURED';
  static const unknown = 'UNKNOWN';

  /// Backend error codes -> user-facing copy.
  static const Map<String, String> _messages = {
    'INVALID_IMAGE':
        "We couldn't read that photo. Try another one — a clear, well-lit leaf works best.",
    'FILE_TOO_LARGE': 'That photo is too large. Try taking a new one with the camera.',
    'MODEL_UNAVAILABLE': 'PlantDoc AI is still starting up. Try again in a moment.',
    'PREDICTION_FAILED': "We couldn't analyse that photo. Please try again.",
    'UNAUTHORIZED': 'Your session has expired. Please sign in again.',
    'NOT_FOUND': "We couldn't find what you were looking for.",
    'DATABASE_ERROR': 'PlantDoc is having trouble saving right now. Please try again.',
    'VALIDATION_ERROR': "That request wasn't quite right. Please try again.",
    'RATE_LIMITED': "You've scanned a lot in a short time. Please wait a moment.",
    'INTERNAL_ERROR': 'PlantDoc ran into a problem. Please try again.',
    network: 'Unable to connect to PlantDoc.\nCheck your internet connection and try again.',
    timeout: 'That took longer than expected. Check your connection and try again.',
    unknown: 'Something went wrong. Please try again.',
  };

  static String messageFor(String code) => _messages[code] ?? _messages[unknown]!;

  /// Builds an error from a backend response body.
  factory ApiError.fromResponse(Map<String, dynamic> body, int statusCode) {
    final error = body['error'];
    final code = error is Map
        ? error['code']?.toString() ?? _codeForStatus(statusCode)
        : _codeForStatus(statusCode);
    return ApiError(
      code,
      messageFor(code),
      canRetry: code != 'UNAUTHORIZED' && code != 'FILE_TOO_LARGE',
    );
  }

  /// Last line of defence: turns *any* thrown object into displayable copy.
  factory ApiError.from(Object error) {
    if (error is ApiError) return error;

    final text = error.toString();
    if (text.contains('TimeoutException')) {
      return ApiError(timeout, messageFor(timeout));
    }
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection refused') ||
        text.contains('Network is unreachable') ||
        text.contains('Connection closed') ||
        text.contains('HandshakeException')) {
      return ApiError(network, messageFor(network));
    }
    if (error is StateError) {
      return ApiError(notConfigured, error.message, canRetry: false);
    }
    return ApiError(unknown, messageFor(unknown));
  }

  static String _codeForStatus(int status) => switch (status) {
        401 || 403 => 'UNAUTHORIZED',
        404 => 'NOT_FOUND',
        413 => 'FILE_TOO_LARGE',
        422 => 'VALIDATION_ERROR',
        429 => 'RATE_LIMITED',
        503 => 'MODEL_UNAVAILABLE',
        _ => 'INTERNAL_ERROR',
      };

  @override
  String toString() => message;
}
