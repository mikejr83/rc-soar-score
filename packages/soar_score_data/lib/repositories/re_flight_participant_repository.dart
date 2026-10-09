import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Re-flight participants in the database.
class ReFlightParticipantRepository extends DriftRepository
    implements core.ReFlightParticipantRepository {
  ReFlightParticipantRepository(super.db, {super.stores});

  late final _store = store<core.ReFlightParticipant>('ReFlightParticipant');

  @override
  Future<core.ReFlightParticipant?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ReFlightParticipant>> listForReFlight(core.Id reFlightId) =>
      _store.whereId('re_flight_id', reFlightId, orderBy: 'id');

  @override
  Future<List<core.ReFlightParticipant>> listForParticipation(
    core.Id contestParticipationId,
  ) => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'id',
  );

  @override
  Future<core.ReFlightParticipant> save(
    core.ReFlightParticipant participant, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run(
    (context) => context.save(participant, metadata: metadata),
  );

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final participant = await _store.find(id);
        if (participant == null) return false;
        await context.delete(participant, metadata: metadata);
        return true;
      });
}
