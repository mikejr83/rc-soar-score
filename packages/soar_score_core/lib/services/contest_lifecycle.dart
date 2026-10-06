import '../enums/admin_lock.dart';
import '../enums/contest_action.dart';
import '../enums/lifecycle_state.dart';
import '../enums/scoring_access.dart';
import '../errors/contest_state_error.dart';
import '../models/contest/contest.dart';

/// The rules for the director actions on a [Contest], from
/// `plan/architecture-requirements/contest-state-and-transitions.md`.
///
/// Pure: it returns the changed contest and never stores it.
abstract final class ContestLifecycle {
  /// [contest] after [action], stamped [now].
  ///
  /// Throws a [ContestStateError] when the contest's state does not allow
  /// [action].
  static Contest apply(Contest contest, ContestAction action, DateTime now) {
    switch (action) {
      case ContestAction.complete:
        // Completion closes participant scoring and ends results hiding.
        if (contest.lifecycleState != LifecycleState.running) {
          throw ContestStateError.invalidTransition(
            'only a Running contest can be completed, this one is '
            '${contest.lifecycleState.name}',
          );
        }
        return contest.copyWithState(
          lifecycleState: LifecycleState.completed,
          scoringAccess: ScoringAccess.closed,
          clearResultsHiding: true,
          updatedAt: now,
        );
      case ContestAction.openScoring:
        if (contest.lifecycleState == LifecycleState.completed) {
          throw ContestStateError.invalidTransition(
            'a Completed contest keeps participant scoring closed',
          );
        }
        if (contest.scoringAccess == ScoringAccess.open) {
          throw ContestStateError.invalidTransition('scoring is already open');
        }
        return contest.copyWithState(
          scoringAccess: ScoringAccess.open,
          updatedAt: now,
        );
      case ContestAction.closeScoring:
        if (contest.scoringAccess == ScoringAccess.closed) {
          throw ContestStateError.invalidTransition(
            'scoring is already closed',
          );
        }
        return contest.copyWithState(
          scoringAccess: ScoringAccess.closed,
          updatedAt: now,
        );
      case ContestAction.lock:
        if (contest.adminLock == AdminLock.locked) {
          throw ContestStateError.invalidTransition(
            'the contest is already locked',
          );
        }
        return contest.copyWithState(
          adminLock: AdminLock.locked,
          updatedAt: now,
        );
      case ContestAction.unlock:
        if (contest.adminLock == AdminLock.unlocked) {
          throw ContestStateError.invalidTransition(
            'the contest is not locked',
          );
        }
        return contest.copyWithState(
          adminLock: AdminLock.unlocked,
          updatedAt: now,
        );
    }
  }
}
