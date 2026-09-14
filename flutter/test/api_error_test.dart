import 'package:flutter_test/flutter_test.dart';
import 'package:plantdoc/core/services/api_error.dart';

void main() {
  group('ApiError.fromResponse', () {
    test('reads the backend error code and maps it to human copy', () {
      final error = ApiError.fromResponse({
        'success': false,
        'error': {'code': 'INVALID_IMAGE', 'message': 'nope'},
      }, 400);

      expect(error.code, 'INVALID_IMAGE');
      expect(error.message, contains("couldn't read that photo"));
    });

    test('falls back to the status code when no envelope is present', () {
      expect(ApiError.fromResponse({}, 404).code, 'NOT_FOUND');
      expect(ApiError.fromResponse({}, 413).code, 'FILE_TOO_LARGE');
      expect(ApiError.fromResponse({}, 503).code, 'MODEL_UNAVAILABLE');
      expect(ApiError.fromResponse({}, 500).code, 'INTERNAL_ERROR');
    });

    test('marks unrecoverable failures as non-retryable', () {
      expect(ApiError.fromResponse({}, 401).canRetry, isFalse);
      expect(ApiError.fromResponse({}, 500).canRetry, isTrue);
    });
  });

  group('ApiError.from', () {
    test('turns a socket failure into connection guidance', () {
      final error = ApiError.from(
        Exception('SocketException: Connection refused'),
      );
      expect(error.code, ApiError.network);
      expect(error.message, contains('Unable to connect'));
    });

    test('recognises a timeout', () {
      final error = ApiError.from(Exception('TimeoutException after 0:01:00'));
      expect(error.code, ApiError.timeout);
    });

    test('keeps a configuration message the user can act on', () {
      final error = ApiError.from(StateError('PlantDoc is not configured'));
      expect(error.code, ApiError.notConfigured);
      expect(error.message, contains('not configured'));
      expect(error.canRetry, isFalse);
    });

    test('passes an existing ApiError through unchanged', () {
      const original = ApiError('INVALID_IMAGE', 'custom');
      expect(identical(ApiError.from(original), original), isTrue);
    });

    test('never leaks a raw exception string to the user', () {
      final error = ApiError.from(
        Exception('ClientException: Connection refused, uri=http://10.0.0.1'),
      );
      expect(error.message, isNot(contains('Exception')));
      expect(error.message, isNot(contains('uri=')));
      expect(error.message, isNot(contains('10.0.0.1')));
    });

    test('an entirely unknown failure still produces readable copy', () {
      final error = ApiError.from(Object());
      expect(error.code, ApiError.unknown);
      expect(error.message, 'Something went wrong. Please try again.');
    });
  });

  test('every documented backend code has a mapping', () {
    const codes = [
      'INVALID_IMAGE',
      'FILE_TOO_LARGE',
      'MODEL_UNAVAILABLE',
      'PREDICTION_FAILED',
      'UNAUTHORIZED',
      'NOT_FOUND',
      'DATABASE_ERROR',
      'VALIDATION_ERROR',
      'RATE_LIMITED',
      'INTERNAL_ERROR',
    ];
    for (final code in codes) {
      final message = ApiError.messageFor(code);
      expect(message, isNotEmpty, reason: code);
      expect(
        message,
        isNot('Something went wrong. Please try again.'),
        reason: '$code fell through to the generic fallback',
      );
    }
  });
}
