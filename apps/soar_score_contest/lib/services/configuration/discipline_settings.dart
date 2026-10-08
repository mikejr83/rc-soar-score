import 'package:soar_score_core/soar_score_core.dart';

import 'section_id.dart';
import 'setting_def.dart';
import 'setting_keys.dart';
import 'setting_kind.dart';

/// The settings a discipline profile defines, as page settings.
abstract final class DisciplineSettings {
  /// The profile's configuration fields in display order. The landing table
  /// is chosen on its own, and fields of other types are not editable here.
  static List<SettingDef> of(DisciplineProfileWithRules profile) {
    final fields = [
      for (final field in profile.configFields)
        if (field.fieldType != ConfigFieldType.landing) field,
    ];
    return [
      for (final (index, field) in fields.indexed)
        _setting(field, first: index == 0),
    ];
  }

  /// Whether [field] is a time in seconds, which is entered as minutes and
  /// seconds.
  static bool _isDuration(DisciplineConfigField field) =>
      field.fieldType == ConfigFieldType.int &&
      field.fieldKey.endsWith('_time');

  static SettingDef _setting(
    DisciplineConfigField field, {
    required bool first,
  }) {
    final validation = field.validation ?? const {};
    num? bound(String key) =>
        validation[key] is num ? validation[key] as num : null;
    final min = bound('gte') ?? bound('gt') ?? bound('min');
    final max = bound('lte') ?? bound('lt') ?? bound('max');
    final type = _isDuration(field)
        ? SettingType.duration
        : switch (field.fieldType) {
            ConfigFieldType.int => SettingType.integer,
            ConfigFieldType.float => SettingType.decimal,
            ConfigFieldType.bool => SettingType.toggle,
            ConfigFieldType.enumeration => SettingType.radio,
            _ => SettingType.text,
          };
    return SettingDef(
      key: '${SettingKeys.disciplinePrefix}${field.fieldKey}',
      section: SectionId.discipline,
      kind: SettingKind.rules,
      label: field.name,
      help: field.description ?? '',
      type: type,
      unit: field.unit,
      min: min,
      max: max,
      minExclusive: bound('gte') == null && bound('gt') != null,
      maxExclusive: bound('lte') == null && bound('lt') != null,
      required: field.required,
      official: field.defaultValue,
      options: [
        for (final option in field.options ?? const <Object?>[])
          if (option is Map)
            SettingOption(
              '${option['value']}',
              '${option['label'] ?? option['value']}',
              tag: '${option['value']}' == '${field.defaultValue}'
                  ? 'Official'
                  : null,
            ),
      ],
      heading: first ? 'Discipline options' : null,
      headingHelp: first
          ? 'From the discipline profile. A value that differs from the '
                'official default is a house rule.'
          : null,
    );
  }
}
