import '../models/id.dart';
import '../models/matrix/round_group.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [RoundGroup]s.
abstract interface class RoundGroupRepository {
  Future<RoundGroup?> findById(Id id);

  /// The groups of [roundId], by group number.
  Future<List<RoundGroup>> listForRound(Id roundId);

  /// Every group of [contestId].
  Future<List<RoundGroup>> listForContest(Id contestId);

  /// Inserts [group], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when [group] was read at an older
  /// revision. Returns the group as stored.
  Future<RoundGroup> save(
    RoundGroup group, {
    required MutationMetadata metadata,
  });

  /// Deletes the group with [id]; returns whether a row was removed.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
