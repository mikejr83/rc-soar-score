import 'section_id.dart';
import 'setting_kind.dart';

/// How a setting is edited.
enum SettingType {
  text,
  date,
  select,
  toggle,
  segmented,
  radio,
  integer,
  decimal,

  /// Minutes and seconds, stored as seconds.
  duration,
  readOnly;

  bool get isNumber => this == integer || this == decimal || this == duration;
}

/// One choice of a [SettingType.select], [SettingType.segmented] or
/// [SettingType.radio] setting.
class SettingOption {
  const SettingOption(this.value, this.label, {this.help, this.tag});

  final Object value;
  final String label;
  final String? help;

  /// For example `Default`, shown beside the choice that is the default.
  final String? tag;
}

/// The definition of one setting: what it is called, how it is edited and
/// which values it accepts.
class SettingDef {
  const SettingDef({
    required this.key,
    required this.section,
    required this.kind,
    required this.label,
    required this.help,
    required this.type,
    this.unit,
    this.min,
    this.max,
    this.minExclusive = false,
    this.maxExclusive = false,
    this.required = false,
    this.placeholder,
    this.options = const [],
    this.official,
    this.heading,
    this.headingHelp,
    this.readOnlyValue,
    this.readOnlyDetail,
  });

  final String key;
  final SectionId section;
  final SettingKind kind;
  final String label;
  final String help;
  final SettingType type;
  final String? unit;
  final num? min;
  final num? max;
  final bool minExclusive;
  final bool maxExclusive;
  final bool required;
  final String? placeholder;
  final List<SettingOption> options;

  /// The official profile value; a different value is a house rule.
  final Object? official;

  /// A subheading shown above this row.
  final String? heading;
  final String? headingHelp;
  final String? readOnlyValue;

  /// A line under [readOnlyValue].
  final String? readOnlyDetail;

  /// The label of the option whose value is [value], or `null`.
  String? optionLabel(Object? value) {
    for (final option in options) {
      if ('${option.value}' == '$value') {
        return option.label;
      }
    }
    return null;
  }
}
