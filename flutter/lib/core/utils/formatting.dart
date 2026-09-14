/// Small pure helpers kept out of `build()` so they can be unit tested.

/// Time-of-day greeting. Was hardcoded to "Good morning" at any hour.
String greetingFor(DateTime time) {
  final hour = time.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Human relative time: "Just now", "2h ago", "3 days ago", "12 Mar 2025".
String formatRelativeTime(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time);

  if (diff.isNegative) return 'Just now';
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return formatDate(time);
}

/// Parses a stored timestamp, tolerating nulls and malformed values.
String formatRelativeTimestamp(Object? raw, {DateTime? now}) {
  if (raw == null) return '';
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) return '';
  return formatRelativeTime(parsed, now: now);
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// First name for greetings, falling back to something friendly rather than
/// showing an empty space or an email address.
String firstNameFrom(String? fullName, {String fallback = 'there'}) =>
    firstNameOrNull(fullName) ?? fallback;

/// First name, or null when there is no usable one.
///
/// Callers that read better without a name at all — "Good evening" rather than
/// "Good evening, there" for a signed-out user — use this instead.
String? firstNameOrNull(String? fullName) {
  final trimmed = fullName?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final first = trimmed.split(RegExp(r'\s+')).first;
  // An email slipped in where a name was expected.
  if (first.contains('@')) return first.split('@').first;
  return first;
}
