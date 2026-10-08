import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Publication identities in the database; backend only, so written without a
/// mutation.
class PublicationIdentityRepository extends DriftRepository
    implements core.PublicationIdentityRepository {
  PublicationIdentityRepository(super.db, {super.stores});

  late final _store = store<core.PublicationIdentity>('PublicationIdentity');

  @override
  Future<core.PublicationIdentity?> findById(core.Id id) => _store.find(id);

  @override
  Future<core.PublicationIdentity?> findForContest(core.Id contestId) async {
    final found = await _store.whereId('contest_id', contestId, orderBy: 'id');
    return found.isEmpty ? null : found.first;
  }

  @override
  Future<List<core.PublicationIdentity>> listForOwner(
    core.Id ownerPublicProfileId,
  ) => _store.whereId(
    'owner_public_profile_id',
    ownerPublicProfileId,
    orderBy: 'id',
  );

  @override
  Future<core.PublicationIdentity> save(core.PublicationIdentity identity) =>
      db.transaction(() async {
        final stored = await _store.findJson(identity.id);
        final storedRevision = stored?['revision'] as int?;
        if (storedRevision != null && storedRevision != identity.revision) {
          throw core.StaleRevisionError(
            entityType: _store.entityType,
            entityId: identity.id,
            expectedRevision: identity.revision,
            storedRevision: storedRevision,
          );
        }
        final json = _store.encode(identity);
        json['revision'] = storedRevision == null
            ? identity.revision
            : storedRevision + 1;
        final saved = _store.decode(json);
        await _store.upsertJson(_store.encode(saved));
        return saved;
      });
}
