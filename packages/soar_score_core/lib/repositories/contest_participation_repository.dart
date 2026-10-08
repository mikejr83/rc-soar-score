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
  /// Throws a `StaleRevisionError` when it was read at an older revision.
  /// Returns the participation as stored.
  Future<ContestParticipation> save(
    ContestParticipation participation, {
    required MutationMetadata metadata,
  });

  /// Deletes the participation with [id] and its team memberships, in one
  /// transaction; returns whether a row was removed.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
