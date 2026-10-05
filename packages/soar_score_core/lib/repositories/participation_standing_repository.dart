import '../models/id.dart';
import '../models/results/participation_standing.dart';

/// Abstract persistence contract for [ParticipationStanding]s.
///
/// Standings are derived data, recomputed by the calculator.
abstract interface class ParticipationStandingRepository {
  Future<ParticipationStanding?> findById(Id id);

  /// Every standing of [contestId], by round and then place.
  Future<List<ParticipationStanding>> listForContest(Id contestId);

  /// The standings of [contestId] after round [asOfRound], by place.
  Future<List<ParticipationStanding>> listAsOfRound(
    Id contestId,
    int asOfRound,
  );

  /// The standings of [contestParticipationId], by round.
  Future<List<ParticipationStanding>> listForParticipation(
    Id contestParticipationId,
  );

  /// Replaces every standing of [contestId] with [standings], in one
  /// transaction.
  ///
  /// Throws an `ArgumentError` if a standing belongs to another contest.
  Future<void> replaceForContest(
    Id contestId,
    Iterable<ParticipationStanding> standings,
  );
}
