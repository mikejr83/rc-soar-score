import 'package:soar_score_core/soar_score_core.dart';

import 'config_impact.dart';

/// The director's unsaved edits to a contest's core options.
///
/// Starts as a copy of the saved [base]; [build] gives the configuration to
/// save. The discipline settings are carried over unchanged.
class ConfigurationDraft {
  ConfigurationDraft(this.base) : _core = Map.of(base.core);

  final ContestConfig base;
  final Map<String, Object?> _core;

  /// The current value of the core option [key], from the saved options when
  /// it was never stored.
  Object? operator [](String key) => _core[key];

  void operator []=(String key, Object? value) {
    _core[key] = value;
  }

  /// The core options whose value differs from the saved ones.
  Set<String> get changedKeys => {
    for (final key in {..._core.keys, ...base.core.keys})
      if (_core[key] != base.core[key]) key,
  };

  bool get changed => changedKeys.isNotEmpty;

  /// The widest impact among the changed options.
  ConfigImpact get impact => changedKeys
      .map(ConfigImpact.ofCoreOption)
      .fold(
        ConfigImpact.none,
        (widest, next) => next.index > widest.index ? next : widest,
      );

  /// Why the options cannot be saved, or `null` when they are valid.
  String? get problem {
    try {
      CoreOptions.fromMap(_core);
      return null;
    } on ArgumentError catch (error) {
      return '${error.message ?? error}';
    }
  }

  ContestConfig build() =>
      ContestConfig(core: _core, discipline: base.discipline);
}
