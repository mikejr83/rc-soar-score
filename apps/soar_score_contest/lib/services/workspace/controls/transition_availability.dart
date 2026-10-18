import 'package:soar_score_core/soar_score_core.dart';

import 'contest_transition.dart';

/// Whether a director can make [transition] on a contest now, and when not,
/// the sentence that goes next to the disabled control.
///
/// The rules mirror `ContestLifecycle.apply`, so the server stays the judge
/// and a disabled control never hides a transition it would accept.
class TransitionAvailability {
  const TransitionAvailability._(this.enabled, this.reason);

  const TransitionAvailability.allowed() : this._(true, null);

  const TransitionAvailability.blocked(String reason) : this._(false, reason);

  final bool enabled;

  /// Why the control is disabled; `null` when it is enabled.
  final String? reason;

  static TransitionAvailability of(
    Contest contest,
    ContestTransition transition,
  ) {
    final completed = contest.lifecycleState == LifecycleState.completed;
    switch (transition) {
      case ContestTransition.openScoring:
        if (completed) {
          return const TransitionAvailability.blocked(
            'A completed contest keeps participant scoring closed.',
          );
        }
        return contest.scoringAccess == ScoringAccess.open
            ? const TransitionAvailability.blocked(
                'Participant scoring is already open.',
              )
            : const TransitionAvailability.allowed();
      case ContestTransition.closeScoring:
        return contest.scoringAccess == ScoringAccess.closed
            ? const TransitionAvailability.blocked(
                'Participant scoring is already closed.',
              )
            : const TransitionAvailability.allowed();
      case ContestTransition.lock:
        return contest.adminLock == AdminLock.locked
            ? const TransitionAvailability.blocked(
                'Administration is already locked.',
              )
            : const TransitionAvailability.allowed();
      case ContestTransition.unlock:
        return contest.adminLock == AdminLock.unlocked
            ? const TransitionAvailability.blocked(
                'Administration is not locked.',
              )
            : const TransitionAvailability.allowed();
      case ContestTransition.complete:
        if (completed) {
          return const TransitionAvailability.blocked(
            'This contest is completed.',
          );
        }
        return contest.lifecycleState == LifecycleState.running
            ? const TransitionAvailability.allowed()
            : TransitionAvailability.blocked(
                'Only a running contest can be completed. This one is '
                '${contest.lifecycleState.name}; it starts running with the '
                'first score.',
              );
    }
  }
}
