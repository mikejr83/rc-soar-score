import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Publication participants in the database; backend only, so written without
/// a mutation.
class PublicationParticipantRepository extends DriftRepository
    implements core.PublicationParticipantRepository {
  PublicationParticipantRepository(super.db, {super.stores});

  late final _store = store<core.PublicationParticipant>(
    'PublicationParticipant',
  );

  @override
  Future<core.PublicationParticipant?> findById(core.Id id) => _store.find(id);

  @override
  Future<core.PublicationParticipant?> findByPilotKey(
    core.Id publicationId,
    String pilotKey,
  ) async {
    final participants = await listForPublication(publicationId);
    return participants.where((p) => p.pilotKey == pilotKey).firstOrNull;
  }

  @override
  Future<List<core.PublicationParticipant>> listForPublication(
    core.Id publicationId,
  ) => _store.whereId('publication_id', publicationId, orderBy: 'id');

  @override
  Future<core.PublicationParticipant> save(
    core.PublicationParticipant participant,
  ) async {
    await _store.upsertJson(_store.encode(participant));
    return participant;
  }
}
