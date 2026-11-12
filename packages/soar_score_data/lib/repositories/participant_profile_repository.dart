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
  Future<Map<core.Id, core.ParticipantProfile>> findByIds(
    Iterable<core.Id> ids,
  ) async => {
    for (final profile in await _store.whereIdIn('id', ids))
      profile.id: profile,
  };

  @override
  Future<List<core.ParticipantProfile>> listForOwner(core.Id accountId) =>
      _store.whereId('owner_account_id', accountId, orderBy: 'created_at, id');

  @override
  Future<core.ParticipantProfile> save(
    core.ParticipantProfile profile, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(profile, metadata: metadata));

  @override
  Future<List<core.ParticipantProfile>> saveAll(
    List<core.ParticipantProfile> profiles, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    final saved = <core.ParticipantProfile>[];
    for (final profile in profiles) {
      saved.add(
        await context.save(
          profile,
          metadata: metadata.forPart(profile.id.value),
        ),
      );
    }
    return saved;
  });

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final profile = await _store.find(id);
        if (profile == null) return false;
        final links = await store<core.PilotImportLink>('PilotImportLink')
            .whereId('participant_profile_id', id);
        for (final link in links) {
          await context.delete(
            link,
            metadata: metadata.forPart('pilot-link-${link.id.value}'),
          );
        }
        await context.delete(profile, metadata: metadata);
        return true;
      });
}
