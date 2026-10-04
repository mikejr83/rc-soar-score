/// Parses a wire timestamp, which must be ISO 8601 in UTC.
///
/// Throws [FormatException] for a malformed value or any non-UTC offset.
DateTime parseUtcTimestamp(String raw) {
  // DateTime.parse silently converts other offsets to UTC, so the suffix has
  // to be checked on the text.
  if (!_utcSuffix.hasMatch(raw)) {
    throw FormatException('timestamp must be UTC (end with Z or +00:00)', raw);
  }
  return DateTime.parse(raw);
}

final RegExp _utcSuffix = RegExp(r'(Z|[+-]00(:?00)?)$', caseSensitive: false);

/// Formats [value] as a UTC ISO 8601 string, converting first if needed.
String formatUtcTimestamp(DateTime value) => value.toUtc().toIso8601String();
