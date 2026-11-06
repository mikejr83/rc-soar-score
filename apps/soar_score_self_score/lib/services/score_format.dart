/// How the API's numbers read on the pages.
abstract final class ScoreFormat {
  /// `962.5`, `863`, `2,184`: one decimal at most, none when whole, and
  /// thousands separated by commas.
  static String score(num value) {
    final rounded = (value * 10).round() / 10;
    final negative = rounded < 0;
    final text = rounded.abs().toStringAsFixed(1);
    final parts = text.split('.');
    final digits = parts[0];
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }
    final fraction = parts[1] == '0' ? '' : '.${parts[1]}';
    return '${negative ? '-' : ''}$grouped$fraction';
  }

  /// `1st`, `2nd`, `3rd`, `4th`, `11th`, `21st`.
  static String ordinal(int place) {
    final lastTwo = place % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${place}th';
    return switch (place % 10) {
      1 => '${place}st',
      2 => '${place}nd',
      3 => '${place}rd',
      _ => '${place}th',
    };
  }
}
