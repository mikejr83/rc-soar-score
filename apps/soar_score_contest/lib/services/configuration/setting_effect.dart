import 'config_phase.dart';
import 'setting_def.dart';
import 'setting_keys.dart';
import 'setting_kind.dart';

/// What the contest's phase does to one setting.
class SettingEffect {
  const SettingEffect({
    this.fixed = false,
    this.reason,
    this.outdatesMatrix = false,
    this.recalculates = false,
  });

  /// The setting cannot change.
  final bool fixed;

  /// Why it is [fixed]; `null` when the whole page is read-only.
  final String? reason;

  /// Saving a change makes the drawn matrix out of date.
  final bool outdatesMatrix;

  /// Saving a change recalculates all results.
  final bool recalculates;

  static const none = SettingEffect();

  static const _runningReason = 'Fixed once scoring has started.';

  /// The rules of `ContestConfigurationRules` as they apply to [def].
  static SettingEffect of(SettingDef def, ConfigPhase phase) {
    final key = def.key;
    if (phase == ConfigPhase.completed) {
      return const SettingEffect(fixed: true);
    }
    if (def.kind == SettingKind.details) {
      return none;
    }
    final matrix = SettingKeys.matrixKeys.contains(key);
    final fixedWhenRunning =
        matrix ||
        SettingKeys.fixedWhenRunning.contains(key) ||
        SettingKeys.isDiscipline(key) ||
        key == SettingKeys.landingTable;
    if (phase.isRunning && fixedWhenRunning) {
      return const SettingEffect(fixed: true, reason: _runningReason);
    }
    if (matrix && phase.isDrawn) {
      return const SettingEffect(outdatesMatrix: true);
    }
    if (def.kind == SettingKind.recalc && phase.isRunning) {
      return const SettingEffect(recalculates: true);
    }
    return none;
  }
}
