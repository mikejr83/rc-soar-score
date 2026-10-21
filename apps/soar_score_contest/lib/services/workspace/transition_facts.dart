import 'package:equatable/equatable.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// What the audit trail says about when the contest was completed and who
/// locked administration, for the next-step card.
///
/// A fact the trail does not hold stays `null`: a contest completed or locked
/// before the trail recorded transitions has no event, and the time is never
/// guessed from `Contest.updatedAt`.
class TransitionFacts extends Equatable {
  const TransitionFacts({this.completedAt, this.lockedAt, this.lockedBy});

  /// The audit read failed or was not made.
  static const unknown = TransitionFacts();

  /// Reads [events] (newest first, as the API returns them) for [contest].
  ///
  /// The completion time counts only while the contest is Completed, and the
  /// lock time and actor only while administration is Locked. [lockedBy] is
  /// `'you'` when [actingAccountId] is the actor; another actor's name is not
  /// known here, so it stays `null`.
  factory TransitionFacts.of(
    Contest contest,
    List<AuditEventDto> events, {
    String? actingAccountId,
  }) {
    AuditEventDto? latest(ContestAction action) {
      for (final event in events) {
        if (event.transition == action) {
          return event;
        }
      }
      return null;
    }

    final completed = contest.lifecycleState == LifecycleState.completed
        ? latest(ContestAction.complete)
        : null;
    final locked = contest.adminLock == AdminLock.locked
        ? latest(ContestAction.lock)
        : null;
    final actor = locked?.actorId?.value;
    return TransitionFacts(
      completedAt: completed?.serverTimestamp,
      lockedAt: locked?.serverTimestamp,
      lockedBy: actor != null && actor == actingAccountId ? 'you' : null,
    );
  }

  final DateTime? completedAt;
  final DateTime? lockedAt;
  final String? lockedBy;

  @override
  List<Object?> get props => [completedAt, lockedAt, lockedBy];
}
