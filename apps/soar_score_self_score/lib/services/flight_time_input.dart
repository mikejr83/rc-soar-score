/// Reads the compact time a pilot types on the entry form.
///
/// `630` is 6:30 and `630.4` is 6:30.4: the digits left of the point are
/// minutes then two-digit seconds, and one decimal of tenths may follow.
class FlightTimeInput {
  const FlightTimeInput._(this.seconds, this.error);

  /// The time in seconds, or null when the text is empty or rejected.
  final double? seconds;

  /// Why the text was rejected, or null when it is empty or valid.
  final String? error;

  bool get isValid => seconds != null;

  static final _pattern = RegExp(r'^(\d{1,4})(?:\.(\d))?$');

  static FlightTimeInput parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const FlightTimeInput._(null, null);
    final match = _pattern.firstMatch(trimmed);
    if (match == null) {
      return const FlightTimeInput._(
        null,
        'Type the time as digits, for example 630 for 6:30.',
      );
    }
    final whole = int.parse(match.group(1)!);
    final tenths = int.parse(match.group(2) ?? '0');
    final minutes = whole ~/ 100;
    final secs = whole % 100;
    if (secs > 59) {
      return const FlightTimeInput._(
        null,
        'The last two digits are seconds, so they must be 00 to 59.',
      );
    }
    return FlightTimeInput._(minutes * 60 + secs + tenths / 10, null);
  }

  /// The digits a pilot would type for [seconds]: `630.4` for 6:30.4. The
  /// inverse of [parse], for filling the field with a stored time.
  static String typed(double seconds) {
    final total = (seconds * 10).round();
    final whole = (total ~/ 600) * 100 + (total % 600) ~/ 10;
    final tenths = total % 10;
    return tenths == 0 ? '$whole' : '$whole.$tenths';
  }

  /// `6:30.4`, or `6:30` when there are no tenths.
  static String format(double seconds) {
    final total = (seconds * 10).round();
    final minutes = total ~/ 600;
    final secs = (total % 600) ~/ 10;
    final tenths = total % 10;
    final base = '$minutes:${secs.toString().padLeft(2, '0')}';
    return tenths == 0 ? base : '$base.$tenths';
  }
}
