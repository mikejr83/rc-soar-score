import '../enums/lifecycle_state.dart';
import '../models/id.dart';
import '../repositories/repository.dart';

/// How long a contest may go without activity before it reads as finished.
///
/// One platform value for every 48-hour rule: the completion reminder the
/// director sees, the Completed status the public and participants see (#454),
/// and the time after which results become public by themselves (#463). It
/// is not configurable. See `plan/architecture-requirements/contest-state-and-transitions.md`.
const Duration contestInactivityPeriod = Duration(hours: 48);

/// What the public and participants are told about how far a contest is.
///
/// A display rule worked out when the contest is read, never a stored state:
/// the lifecycle state stays `Running` until the director accepts completion.
enum ContestDisplayStatus {
  upcoming('upcoming'),
  inProgress('in_progress'),
  completed('completed');

  const ContestDisplayStatus(this.wireName);

  /// The value in API payloads.
  final String wireName;
}

/// The status to show for a contest in [lifecycleState] that starts at
/// [startsAt] and whose last activity was at [lastActivityAt] (null when it
/// has none), as of [now].
///
/// Completed when the director completed it. Upcoming before [startsAt],
/// however early it was published or invitations went out. Otherwise, for a
/// Ready or Running contest, Completed once more than
/// [contestInactivityPeriod] has passed since the later of [startsAt] and the
/// last activity, and in progress until then. Scoring again moves the
/// activity forward, so the contest reads as in progress again.
ContestDisplayStatus contestDisplayStatus({
  required LifecycleState lifecycleState,
  required DateTime startsAt,
  required DateTime? lastActivityAt,
  required DateTime now,
}) {
  if (lifecycleState == LifecycleState.completed) {
    return ContestDisplayStatus.completed;
  }
  if (now.isBefore(startsAt)) return ContestDisplayStatus.upcoming;
  final live =
      lifecycleState == LifecycleState.ready ||
      lifecycleState == LifecycleState.running;
  if (live) {
    final clock = lastActivityAt != null && lastActivityAt.isAfter(startsAt)
        ? lastActivityAt
        : startsAt;
    if (now.difference(clock) > contestInactivityPeriod) {
      return ContestDisplayStatus.completed;
    }
  }
  return ContestDisplayStatus.inProgress;
}

/// The live facts about a contest that the display status needs, read from
/// the repositories.
class ContestActivity {
  ContestActivity(this.repository);

  final Repository repository;

  /// When each of [contestIds] last had activity: its latest official score,
  /// or, while it has no score, the latest invitation sent. A contest with
  /// neither is absent. Two reads for any number of contests.
  Future<Map<Id, DateTime>> lastActivityAtFor(Iterable<Id> contestIds) async {
    final ids = contestIds.toSet();
    final scored = await repository.officialScoreRepository
        .latestSetAtForContests(ids);
    final unscored = ids.where((id) => !scored.containsKey(id));
    final invited = await repository.invitationRepository
        .latestIssuedAtForContests(unscored);
    return {...invited, ...scored};
  }

  /// [lastActivityAtFor] for one contest.
  Future<DateTime?> lastActivityAt(Id contestId) async =>
      (await lastActivityAtFor([contestId]))[contestId];
}
