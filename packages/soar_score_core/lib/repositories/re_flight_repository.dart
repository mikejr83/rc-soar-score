import '../models/id.dart';
import '../models/matrix/re_flight.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ReFlight]s.
abstract interface class ReFlightRepository {
  Future<ReFlight?> findById(Id id);

  /// The re-flights of [contestId], in the order they were created.
  Future<List<ReFlight>> listForContest(Id contestId);

  /// The re-flights awarded for [sourceGroup] of [sourceRoundId], by
  /// sequence.
  Future<List<ReFlight>> listForSourceGroup(Id sourceRoundId, int sourceGroup);

  /// The re-flights flown in [scheduledRoundId], in the order they were
  /// created.
  Future<List<ReFlight>> listForScheduledRound(Id scheduledRoundId);

  /// Inserts [reFlight], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when it was read at an older revision.
  /// Returns the re-flight as stored.
  Future<ReFlight> save(
    ReFlight reFlight, {
    required MutationMetadata metadata,
  });

  /// Deletes the re-flight with [id]; returns whether a row was removed.
  ///
  /// A re-flight that has participants or assignments cannot be deleted.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
