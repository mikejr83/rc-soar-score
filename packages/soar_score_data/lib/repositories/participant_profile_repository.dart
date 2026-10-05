import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Participant profiles in the database.
class ParticipantProfileRepository extends DriftRepository
    implements core.ParticipantProfileRepository {
  ParticipantProfileRepository(super.db, {super.stores});

  late final _store = store<core.ParticipantProfile>('ParticipantProfile');

  @override
  Future<core.ParticipantProfile?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ParticipantProfile>> listForOwner(core.Id accountId) =>
      _store.whereId('owner_account_id', accountId, orderBy: 'created_at, id');

  @override
  Future<core.ParticipantProfile> save(
    core.ParticipantProfile profile, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(profile, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final profile = await _store.find(id);
        if (profile == null) return false;
        await context.delete(profile, metadata: metadata);
        return true;
      });
}
