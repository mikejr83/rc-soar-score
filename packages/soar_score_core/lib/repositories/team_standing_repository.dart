import '../models/id.dart';
import '../models/results/team_standing.dart';

/// Abstract persistence contract for [TeamStanding]s.
///
/// Standings are derived data, recomputed by the calculator.
abstract interface class TeamStandingRepository {
  Future<TeamStanding?> findById(Id id);

  /// Every standing of [contestId], by round and then place.
  Future<List<TeamStanding>> listForContest(Id contestId);

  /// The standings of [contestId] after round [asOfRound], by place.
  Future<List<TeamStanding>> listAsOfRound(Id contestId, int asOfRound);

  /// The standings of [teamId], by round.
  Future<List<TeamStanding>> listForTeam(Id teamId);

  /// Replaces every standing of [contestId] with [standings], in one
  /// transaction.
  ///
  /// Throws an `ArgumentError` if a standing belongs to another contest.
  Future<void> replaceForContest(
    Id contestId,
    Iterable<TeamStanding> standings,
  );
}
