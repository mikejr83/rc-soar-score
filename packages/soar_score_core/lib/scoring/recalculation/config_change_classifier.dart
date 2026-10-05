import '../../enums/lifecycle_state.dart';
import 'config_change.dart';
import 'option_group.dart';

/// Compares two resolved configurations and says what the change means in
/// [state].
///
/// Both configurations hold the full resolved settings (see
/// `plan/data-model/contest-options.md`), so a key missing on one side counts
/// as a difference. The landing table is a column on the revision, not part
/// of the JSON, so it is passed separately.
///
/// Lifecycle rules: `Running` means the first score has been entered. The
/// structural and scoring-rule groups are free until the draw, allowed with a
/// redraw offer (structural) after it, and fixed once running. The
/// recalculating and presentation groups are free until the contest is
/// completed, after which nothing changes. Presentation changes never need a
/// recalculation.
ConfigChange classifyConfigChange({
  required Map<String, Object?> beforeCore,
  required Map<String, Object?> afterCore,
  required Map<String, Object?> beforeDiscipline,
  required Map<String, Object?> afterDiscipline,
  Object? beforeLandingTableId,
  Object? afterLandingTableId,
  required LifecycleState state,
}) {
  final changes = <ChangedOption>[
    for (final key in _differingKeys(beforeCore, afterCore))
      ChangedOption(key, coreOptionGroups[key] ?? OptionGroup.recalculating),
    for (final key in _differingKeys(beforeDiscipline, afterDiscipline))
      ChangedOption('discipline.$key', OptionGroup.scoringRules),
    if (beforeLandingTableId != afterLandingTableId)
      const ChangedOption('landing_table', OptionGroup.scoringRules),
  ];

  final rejected = <RejectedChange>[];
  var offerRedraw = false;
  for (final change in changes) {
    final reason = _rejection(change.group, state);
    if (reason != null) rejected.add(RejectedChange(change, reason));
    if (change.group == OptionGroup.structural &&
        state == LifecycleState.ready) {
      offerRedraw = true;
    }
  }
  return ConfigChange(
    changes: changes,
    rejected: rejected,
    offerRedraw: offerRedraw && rejected.isEmpty,
  );
}

String? _rejection(OptionGroup group, LifecycleState state) {
  switch (state) {
    case LifecycleState.completed:
      return 'the contest is completed';
    case LifecycleState.running:
      return switch (group) {
        OptionGroup.structural => 'fixed once scoring has started',
        OptionGroup.scoringRules => 'fixed once scoring has started',
        _ => null,
      };
    case LifecycleState.created:
    case LifecycleState.configuring:
    case LifecycleState.ready:
      return null;
  }
}

List<String> _differingKeys(Map<String, Object?> a, Map<String, Object?> b) {
  final keys = {...a.keys, ...b.keys}.toList()..sort();
  return [
    for (final key in keys)
      if (!a.containsKey(key) ||
          !b.containsKey(key) ||
          !_deepEquals(a[key], b[key]))
        key,
  ];
}

bool _deepEquals(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}
