import '../models/id.dart';
import '../models/matrix/re_flight_participant.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for [ReFlightParticipant]s.
abstract interface class ReFlightParticipantRepository {
  Future<ReFlightParticipant?> findById(Id id);

  /// The participants of [reFlightId], in the order they were created.
  Future<List<ReFlightParticipant>> listForReFlight(Id reFlightId);

  /// The re-flight parts of [contestParticipationId], in the order they were
  /// created.
  Future<List<ReFlightParticipant>> listForParticipation(
    Id contestParticipationId,
  );

  /// Inserts [participant], or updates the stored row with the same id.
  ///
  /// Throws a `StaleRevisionError` when it was read at an older revision.
  /// Returns the participant as stored.
  Future<ReFlightParticipant> save(
    ReFlightParticipant participant, {
    required MutationMetadata metadata,
  });

  /// Deletes the participant with [id]; returns whether a row was removed.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
