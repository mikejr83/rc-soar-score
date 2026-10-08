import 'package:soar_score_core/soar_score_core.dart';

import 'config_phase.dart';
import 'configuration_validation.dart';
import 'configuration_values.dart';
import 'setting_catalog.dart';
import 'setting_def.dart';
import 'setting_effect.dart';
import 'setting_keys.dart';
import 'setting_values.dart';

/// One setting whose draft value differs from the saved one.
class SettingChange {
  const SettingChange({
    required this.def,
    required this.effect,
    required this.cleared,
  });

  final SettingDef def;
  final SettingEffect effect;

  /// The setting is hidden by another setting and will be cleared on save,
  /// rather than being changed by the director.
  final bool cleared;
}

/// The director's unsaved edits to the contest details and configuration.
///
/// It starts as a copy of the [saved] values; [values] holds what the page
/// shows. The page reads [errors], [changes] and [dirty], and [build] gives
/// what to save.
class ConfigurationDraft {
  ConfigurationDraft({
    required this.catalog,
    required this.phase,
    required Map<String, Object?> saved,
    this.lastDrawnRound,
  }) : saved = Map.unmodifiable(saved),
       _values = Map.of(saved);

  /// The draft for [contest] and its saved [revision].
  factory ConfigurationDraft.fromSaved({
    required Contest contest,
    required ContestConfigurationRevision revision,
    required SettingCatalog catalog,
    required ConfigPhase phase,
    int? lastDrawnRound,
  }) => ConfigurationDraft(
    catalog: catalog,
    phase: phase,
    saved: ConfigurationValues.fromSaved(contest, revision, catalog),
    lastDrawnRound: lastDrawnRound,
  );

  final SettingCatalog catalog;
  final ConfigPhase phase;

  /// The values as saved.
  final Map<String, Object?> saved;

  /// The last round the drawn matrix covers; drops cannot come after it.
  final int? lastDrawnRound;

  final Map<String, Object?> _values;

  Map<String, String>? _errors;
  List<SettingChange>? _changes;

  Map<String, Object?> get values => Map.unmodifiable(_values);

  Object? operator [](String key) => _values[key];

  void set(String key, Object? value) => setAll({key: value});

  void setAll(Map<String, Object?> next) {
    _values.addAll(next);
    _errors = null;
    _changes = null;
  }

  /// Puts every value back to the saved one.
  void discard() {
    _values
      ..clear()
      ..addAll(saved);
    _errors = null;
    _changes = null;
  }

  bool isVisible(String key) =>
      SettingCatalog.isVisible(key, (k) => _values[k]);

  bool get dirty => changes.isNotEmpty;

  /// The settings that differ from the saved values, in page order.
  List<SettingChange> get changes => _changes ??= _computeChanges();

  SettingChange? changeOf(String key) {
    for (final change in changes) {
      if (change.def.key == key) {
        return change;
      }
    }
    return null;
  }

  /// Settings that are being changed and will clear [parentKey]'s children
  /// when saved: the hidden settings that still hold a value.
  List<SettingChange> clearedBy(String parentKey) => [
    for (final change in changes)
      if (change.cleared && SettingKeys.parentOf[change.def.key] == parentKey)
        change,
  ];

  SettingEffect effectOf(SettingDef def) => SettingEffect.of(def, phase);

  List<SettingChange> _computeChanges() {
    final result = <SettingChange>[];
    for (final def in catalog.settings) {
      if (def.type == SettingType.readOnly &&
          def.key != SettingKeys.landingTable) {
        continue;
      }
      final key = def.key;
      final visibleNow = isVisible(key);
      final visibleThen = SettingCatalog.isVisible(key, (k) => saved[k]);
      final now = _values[key];
      final then = saved[key];
      if (visibleNow &&
          SettingValues.canon(def, now) != SettingValues.canon(def, then)) {
        result.add(
          SettingChange(def: def, effect: effectOf(def), cleared: false),
        );
      } else if (!visibleNow &&
          visibleThen &&
          !SettingValues.isBlank(then) &&
          then != false) {
        result.add(
          SettingChange(def: def, effect: effectOf(def), cleared: true),
        );
      }
    }
    return result;
  }

  /// What is wrong with each setting, by key; empty when it can be saved.
  Map<String, String> get errors =>
      _errors ??= ConfigurationValidation(this).validate();

  /// The settings that make a drawn matrix out of date when saved.
  List<SettingChange> get matrixChanges => [
    for (final change in changes)
      if (change.effect.outdatesMatrix) change,
  ];

  /// The settings that recalculate results when saved.
  List<SettingChange> get recalcChanges => [
    for (final change in changes)
      if (change.effect.recalculates) change,
  ];

  /// The changes with no effect on the matrix or results.
  List<SettingChange> get otherChanges => [
    for (final change in changes)
      if (!change.effect.outdatesMatrix && !change.effect.recalculates) change,
  ];

  /// Whether any contest detail (name, dates, venue) changed.
  bool get detailsChanged => changes.any(
    (change) => change.def.section == catalog.byKey[SettingKeys.name]!.section,
  );

  /// Whether anything besides the contest details changed.
  bool get configurationChanged => changes.any(
    (change) => change.def.section != catalog.byKey[SettingKeys.name]!.section,
  );
}
