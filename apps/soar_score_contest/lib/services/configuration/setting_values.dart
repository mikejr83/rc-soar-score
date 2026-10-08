import 'setting_def.dart';

/// Reading, comparing and showing the raw values of the draft.
///
/// A number field keeps what was typed (a `String`) until it is saved, so a
/// half-typed value is not lost; a saved value is a `num`.
abstract final class SettingValues {
  static final _minutesOnly = RegExp(r'^\d{1,3}$');
  static final _minutesSeconds = RegExp(r'^(\d{1,3}):([0-5]\d)$');

  /// Seconds for `10:00`, or `8` (minutes); `null` when [value] is neither.
  /// A number is already seconds.
  static int? parseDuration(Object? value) {
    if (value is num) {
      return value.round();
    }
    final text = '${value ?? ''}'.trim();
    if (_minutesOnly.hasMatch(text)) {
      return int.parse(text) * 60;
    }
    final match = _minutesSeconds.firstMatch(text);
    return match == null
        ? null
        : int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }

  /// `10:00` for 600 seconds.
  static String formatDuration(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  static bool isBlank(Object? value) =>
      value == null || '$value'.trim().isEmpty;

  /// The number [value] stands for, or `null` when it is blank or not one.
  static num? parseNumber(Object? value) =>
      value is num ? value : num.tryParse('${value ?? ''}'.trim());

  /// A form of [value] that is equal for equal settings, however typed.
  static String canon(SettingDef def, Object? value) {
    if (isBlank(value)) {
      return '';
    }
    return switch (def.type) {
      SettingType.duration => '${parseDuration(value)}',
      SettingType.integer ||
      SettingType.decimal => '${parseNumber(value)?.toDouble()}',
      SettingType.toggle => '${value == true}',
      _ => '$value'.trim(),
    };
  }

  /// [value] as the page shows it in a summary or a `Saved:` note.
  static String display(SettingDef def, Object? value) {
    if (isBlank(value) && def.type != SettingType.toggle) {
      return 'Not set';
    }
    switch (def.type) {
      case SettingType.duration:
        final seconds = parseDuration(value);
        return seconds == null ? '$value' : formatDuration(seconds);
      case SettingType.toggle:
        return value == true ? 'On' : 'Off';
      case SettingType.radio || SettingType.segmented || SettingType.select:
        return def.optionLabel(value) ?? '$value';
      default:
        final text = value is double && value == value.roundToDouble()
            ? '${value.toInt()}'
            : '$value';
        return def.unit == null ? text : '$text ${def.unit}';
    }
  }

  /// The text a field starts with for [value].
  static String fieldText(SettingDef def, Object? value) {
    if (value == null) {
      return '';
    }
    if (def.type == SettingType.duration && value is num) {
      return formatDuration(value.round());
    }
    if (value is double && value == value.roundToDouble()) {
      return '${value.toInt()}';
    }
    return '$value';
  }
}
