import '../models/id.dart';
import '../models/matrix/round.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [Round]s.
abstract interface class RoundRepository {
  Future<Round?> findById(Id id);

  /// The rounds of [matrixRevisionId], by ordinal.
  Future<List<Round>> listForRevision(Id matrixRevisionId);

  /// Every round of [contestId], by ordinal and then creation.
  Future<List<Round>> listForContest(Id contestId);

  /// Inserts [round], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when [round] was read at an older
  /// revision. Returns the round as stored.
  Future<Round> save(Round round, {required MutationMetadata metadata});

  /// Deletes the round with [id] and its groups, in one transaction; returns
  /// whether a row was removed.
  ///
  /// A round that assignments or results refer to cannot be deleted.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
