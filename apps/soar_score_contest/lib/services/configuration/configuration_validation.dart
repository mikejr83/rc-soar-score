import 'package:soar_score_core/soar_score_core.dart';

import 'configuration_draft.dart';
import 'setting_def.dart';
import 'setting_keys.dart';
import 'setting_values.dart';

/// The rules a draft must meet before it is saved, one message per setting.
///
/// The messages tell what to enter, not just that something is wrong.
class ConfigurationValidation {
  ConfigurationValidation(this.draft);

  final ConfigurationDraft draft;

  final Map<String, String> _errors = {};

  Map<String, String> validate() {
    _text(SettingKeys.name, 'Enter a contest name.');
    _dates();
    for (final def in draft.catalog.settings) {
      if (def.type.isNumber && draft.isVisible(def.key)) {
        _number(def);
      }
    }
    _landingTable();
    _drops();
    _seeded();
    _teamProtection();
    _errors.removeWhere((key, _) {
      final def = draft.catalog.byKey[key];
      return def == null || !draft.isVisible(key) || draft.effectOf(def).fixed;
    });
    return _errors;
  }

  String _text(String key, String message) {
    if (SettingValues.isBlank(draft[key])) {
      _errors[key] = message;
    }
    return '${draft[key] ?? ''}'.trim();
  }

  void _dates() {
    final start = DateTime.tryParse('${draft[SettingKeys.start] ?? ''}');
    final end = DateTime.tryParse('${draft[SettingKeys.end] ?? ''}');
    if (start == null) {
      _errors[SettingKeys.start] = 'Choose a start date.';
    }
    if (end == null) {
      _errors[SettingKeys.end] = 'Choose an end date.';
    }
    if (start != null && end != null && end.isBefore(start)) {
      _errors[SettingKeys.end] = 'The end date can’t be before the start date.';
    }
  }

  void _number(SettingDef def) {
    final key = def.key;
    final value = draft[key];
    if (SettingValues.isBlank(value)) {
      // Optional numbers may stay empty.
      final optional =
          key == SettingKeys.intendedTotalRounds ||
          (SettingKeys.isDiscipline(key) && !def.required);
      if (!optional) {
        _errors[key] = def.type == SettingType.duration
            ? 'Enter a time, for example 10:00.'
            : key == SettingKeys.teamPilotCount
            ? 'Enter how many pilot scores count, 1 or more.'
            : 'Enter a value.';
      }
      return;
    }
    if (def.type == SettingType.duration) {
      final seconds = SettingValues.parseDuration(value);
      if (seconds == null) {
        _errors[key] =
            'Use minutes and seconds, for example 10:00. Seconds go up to 59.';
      } else if (_outside(def, seconds)) {
        final low = def.min ?? 0;
        final high = def.max;
        _errors[key] = high == null
            ? 'Enter a time of at least ${SettingValues.formatDuration(low.round())}.'
            : 'Enter a time from ${SettingValues.formatDuration(low.round())} '
                  'to ${SettingValues.formatDuration(high.round())}.';
      }
      return;
    }
    final number = SettingValues.parseNumber(value);
    if (number == null || !number.isFinite) {
      _errors[key] = 'Enter a number.';
    } else if (def.type == SettingType.integer && number != number.truncate()) {
      _errors[key] = 'Enter a whole number.';
    } else if (def.min != null &&
        (def.minExclusive ? number <= def.min! : number < def.min!)) {
      _errors[key] = def.minExclusive
          ? 'Must be more than ${_plain(def.min!)}.'
          : 'Must be at least ${_plain(def.min!)}.';
    } else if (def.max != null &&
        (def.maxExclusive ? number >= def.max! : number > def.max!)) {
      _errors[key] = def.maxExclusive
          ? 'Must be less than ${_plain(def.max!)}.'
          : 'Must be ${_plain(def.max!)} or less.';
    }
  }

  bool _outside(SettingDef def, num value) =>
      (def.min != null &&
          (def.minExclusive ? value <= def.min! : value < def.min!)) ||
      (def.max != null &&
          (def.maxExclusive ? value >= def.max! : value > def.max!));

  static String _plain(num value) =>
      value == value.roundToDouble() ? '${value.toInt()}' : '$value';

  void _landingTable() {
    final profile = draft.catalog.profile;
    final needsTable =
        profile != null &&
        profile.configFields.any((f) => f.fieldType == ConfigFieldType.landing);
    if (needsTable && SettingValues.isBlank(draft[SettingKeys.landingTable])) {
      _errors[SettingKeys.landingTable] = 'Choose a landing table.';
    }
  }

  void _drops() {
    final cap = draft.lastDrawnRound;
    for (final key in [SettingKeys.drop1, SettingKeys.drop2]) {
      if (_errors.containsKey(key) || !draft.isVisible(key)) {
        continue;
      }
      final value = SettingValues.parseNumber(draft[key]);
      if (cap != null && value != null && value > cap) {
        _errors[key] = 'Can’t be after round $cap, the last round drawn.';
      }
    }
    final first = SettingValues.parseNumber(draft[SettingKeys.drop1]);
    final second = SettingValues.parseNumber(draft[SettingKeys.drop2]);
    if (draft.isVisible(SettingKeys.drop2) &&
        !_errors.containsKey(SettingKeys.drop1) &&
        !_errors.containsKey(SettingKeys.drop2) &&
        first != null &&
        second != null &&
        second <= first) {
      _errors[SettingKeys.drop2] =
          'Must be later than the first drop (round ${_plain(first)}).';
    }
  }

  void _seeded() {
    final prelim = SettingValues.parseNumber(
      draft[SettingKeys.preliminaryRounds],
    );
    final total = SettingValues.parseNumber(
      draft[SettingKeys.intendedTotalRounds],
    );
    if (draft.isVisible(SettingKeys.intendedTotalRounds) &&
        !_errors.containsKey(SettingKeys.intendedTotalRounds) &&
        !_errors.containsKey(SettingKeys.preliminaryRounds) &&
        prelim != null &&
        total != null &&
        total <= prelim) {
      _errors[SettingKeys.intendedTotalRounds] =
          'Must be more than the ${_plain(prelim)} preliminary rounds.';
    }
  }

  void _teamProtection() {
    if (draft[SettingKeys.teamProtection] == true &&
        draft.isVisible(SettingKeys.teamProtection) &&
        draft[SettingKeys.drawMode] == SettingKeys.seeded) {
      _errors[SettingKeys.teamProtection] =
          'Team protection can’t be used with Seeded Man on Man.';
    }
  }
}
