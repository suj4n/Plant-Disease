import 'package:flutter_test/flutter_test.dart';
import 'package:plantdoc/core/utils/formatting.dart';

void main() {
  group('greetingFor', () {
    test('changes with the time of day', () {
      expect(greetingFor(DateTime(2026, 3, 1, 7)), 'Good morning');
      expect(greetingFor(DateTime(2026, 3, 1, 13)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 3, 1, 20)), 'Good evening');
    });

    test('handles the boundaries', () {
      expect(greetingFor(DateTime(2026, 3, 1, 0)), 'Good morning');
      expect(greetingFor(DateTime(2026, 3, 1, 11, 59)), 'Good morning');
      expect(greetingFor(DateTime(2026, 3, 1, 12)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 3, 1, 17)), 'Good evening');
      expect(greetingFor(DateTime(2026, 3, 1, 23, 59)), 'Good evening');
    });
  });

  group('formatRelativeTime', () {
    final now = DateTime(2026, 3, 10, 12, 0);

    test('describes recent times in human units', () {
      expect(formatRelativeTime(now.subtract(const Duration(seconds: 20)), now: now), 'Just now');
      expect(formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
      expect(formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
      expect(formatRelativeTime(now.subtract(const Duration(days: 1)), now: now), 'Yesterday');
      expect(formatRelativeTime(now.subtract(const Duration(days: 4)), now: now), '4 days ago');
    });

    test('falls back to an absolute date beyond a week', () {
      expect(
        formatRelativeTime(DateTime(2026, 2, 1), now: now),
        '1 Feb 2026',
      );
    });

    test('handles null and clock skew without crashing', () {
      expect(formatRelativeTime(null), '');
      expect(formatRelativeTime(now.add(const Duration(hours: 1)), now: now), 'Just now');
    });
  });

  group('formatRelativeTimestamp', () {
    test('parses ISO strings and tolerates junk', () {
      final now = DateTime(2026, 3, 10, 12, 0);
      expect(
        formatRelativeTimestamp(
          DateTime(2026, 3, 10, 9).toIso8601String(),
          now: now,
        ),
        '3h ago',
      );
      expect(formatRelativeTimestamp(null), '');
      expect(formatRelativeTimestamp('not a date'), '');
    });
  });

  group('firstNameFrom', () {
    test('takes the first word', () {
      expect(firstNameFrom('Nayan Pokharel'), 'Nayan');
    });

    test('falls back when the name is missing', () {
      expect(firstNameFrom(null), 'there');
      expect(firstNameFrom('   '), 'there');
    });

    test('never shows a full email address as a name', () {
      expect(firstNameFrom('nayan@example.com'), 'nayan');
    });
  });

  group('firstNameOrNull', () {
    test('returns null rather than a filler word', () {
      // Home greets a signed-out user with "Good evening", not
      // "Good evening, there".
      expect(firstNameOrNull(null), isNull);
      expect(firstNameOrNull('   '), isNull);
    });

    test('still extracts a real name', () {
      expect(firstNameOrNull('Nayan Pokharel'), 'Nayan');
      expect(firstNameOrNull('nayan@example.com'), 'nayan');
    });
  });
}
