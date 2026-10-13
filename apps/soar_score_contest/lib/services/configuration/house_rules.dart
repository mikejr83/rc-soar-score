import 'package:soar_score_core/soar_score_core.dart';

import 'setting_catalog.dart';
import 'setting_def.dart';
import 'setting_keys.dart';
import 'setting_values.dart';

/// Which discipline options are house rules: options whose value differs from
/// the official profile's.
abstract final class HouseRules {
  /// Whether [value] makes [def] a house rule. A setting with no official
  /// value is never one.
  static bool isHouseRule(SettingDef def, Object? value) =>
      def.official != null &&
      SettingValues.canon(def, value) != SettingValues.canon(def, def.official);

  /// How many of [defs] are house rules, reading each value with [valueOf].
  static int count(
    Iterable<SettingDef> defs,
    Object? Function(SettingDef def) valueOf,
  ) => defs.where((def) => isHouseRule(def, valueOf(def))).length;

  /// How many discipline options of the saved [revision] differ from
  /// [profile]'s official values. An option the revision does not store is the
  /// official value. Zero without a revision or a known profile.
  static int ofRevision(
    ContestConfigurationRevision? revision,
    DisciplineProfileWithRules? profile,
  ) {
    if (revision == null || profile == null) {
      return 0;
    }
    final discipline = revision.config.discipline;
    return count(
      SettingCatalog.forProfile(profile).disciplineSettings,
      (def) =>
          discipline[def.key.substring(SettingKeys.disciplinePrefix.length)] ??
          def.official,
    );
  }
}
