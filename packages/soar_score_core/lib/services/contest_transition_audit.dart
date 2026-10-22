import '../enums/contest_action.dart';
import '../models/contest/contest.dart';
import '../models/sync/audit_event.dart';

/// The audit text of a director action on a contest.
///
/// An [AuditEvent] has no field for the action name or for the old and new
/// value, so both travel in `reason` as `lock: AdminLock Unlocked → Locked`:
/// the [ContestAction] name, a colon, then each changed field with its old
/// and new value, separated by `; `. Completing a contest also lifts results
/// hiding, which shows as `ResultsHidden through round 3 → none`.
abstract final class ContestTransitionAudit {
  /// The `reason` of the event for [action] taking [before] to [after].
  static String reason(ContestAction action, Contest before, Contest after) {
    final changes = [
      if (before.lifecycleState != after.lifecycleState)
        'LifecycleState ${_text(before.lifecycleState)}'
            ' → ${_text(after.lifecycleState)}',
      if (before.scoringAccess != after.scoringAccess)
        'ScoringAccess ${_text(before.scoringAccess)}'
            ' → ${_text(after.scoringAccess)}',
      if (before.adminLock != after.adminLock)
        'AdminLock ${_text(before.adminLock)}'
            ' → ${_text(after.adminLock)}',
      if (before.resultsHiddenThroughRound != after.resultsHiddenThroughRound)
        'ResultsHidden ${_hiding(before.resultsHiddenThroughRound)}'
            ' → ${_hiding(after.resultsHiddenThroughRound)}',
    ];
    return '${action.name}: ${changes.join('; ')}';
  }

  /// "through round 3", or "none" when results are not hidden.
  static String _hiding(int? throughRound) =>
      throughRound == null ? 'none' : 'through round $throughRound';

  /// The action [event] records, or `null` when it is not a contest action
  /// event written by [reason].
  static ContestAction? actionOf(AuditEvent event) {
    final reason = event.reason;
    final colon = reason?.indexOf(':') ?? -1;
    if (reason == null || colon < 0) return null;
    final name = reason.substring(0, colon);
    for (final action in ContestAction.values) {
      if (action.name == name) return action;
    }
    return null;
  }

  /// The data-model text of [value]: each of these enums serializes as its
  /// name with a capital first letter (`Locked`).
  static String _text(Enum value) =>
      value.name[0].toUpperCase() + value.name.substring(1);
}
