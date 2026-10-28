import '../models/id.dart';
import '../models/participants/contest_participation.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ContestParticipation]s.
abstract interface class ContestParticipationRepository {
  Future<ContestParticipation?> findById(Id id);

  /// The participations of [contestId], in the order they were created.
  Future<List<ContestParticipation>> listForContest(Id contestId);

  /// Every participation of the profile [participantProfileId].
  Future<List<ContestParticipation>> listForProfile(Id participantProfileId);

  /// Every participation that was assigned the role [roleId].
  Future<List<ContestParticipation>> listForRole(Id roleId);

  /// Inserts [participation], or updates the stored row with the same id.
  ///
  /// With [removeMatrixRows] the pilot's matrix rows go in the same
  /// transaction, so a stale revision removes nothing: every assignment of
  /// the participation, its empty score slot and the results derived from
  /// them, each with a tombstone; no matrix revision changes. Throws a
  /// `ContestStateError` (`has_scores`), changing nothing, when a slot holds a
  /// score.
  ///
  /// Throws a `StaleRevisionError` when it was read at an older revision.
  /// Returns the participation as stored.
  Future<ContestParticipation> save(
    ContestParticipation participation, {
    required MutationMetadata metadata,
    bool removeMatrixRows = false,
  });

  /// Deletes the participation with [id], its team memberships and its matrix
  /// rows (as with `save`'s `removeMatrixRows`), in one transaction; returns
  /// whether a row was removed. Throws a `ContestStateError` (`has_scores`)
  /// when a slot holds a score.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
