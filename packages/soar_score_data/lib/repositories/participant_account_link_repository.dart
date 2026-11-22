import 'package:drift/drift.dart' show UpdateKind, Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../schema/guest_account_references.dart';
import '../sync/sql_placeholders.dart';
import 'drift_repository.dart';

/// Participant account links in the database; backend only, so written
/// without a mutation.
class ParticipantAccountLinkRepository extends DriftRepository
    implements core.ParticipantAccountLinkRepository {
  ParticipantAccountLinkRepository(super.db, {super.stores});

  late final _store = backendStore<core.ParticipantAccountLink>(
    'ParticipantAccountLink',
  );

  @override
  Future<core.ParticipantAccountLink?> findById(core.Id id) async =>
      _store.find(id);

  @override
  Future<core.ParticipantAccountLink?> find({
    required core.Id participantProfileId,
    required core.Id accountId,
  }) async {
    final links = await listForProfile(participantProfileId);
    return links.where((l) => l.accountId == accountId).firstOrNull;
  }

  @override
  Future<core.ParticipantAccountLink?> findConfirmedForProfile(
    core.Id participantProfileId,
  ) async {
    final links = await listForProfile(participantProfileId);
    return links
        .where((l) => l.status == core.ParticipantLinkStatus.confirmed)
        .firstOrNull;
  }

  @override
  Future<List<core.ParticipantAccountLink>> listForProfile(
    core.Id participantProfileId,
  ) async => _store.whereId(
    'participant_profile_id',
    participantProfileId,
    orderBy: 'id',
  );

  @override
  Future<List<core.ParticipantAccountLink>> listForAccount(
    core.Id accountId,
  ) async => _store.whereId('account_id', accountId, orderBy: 'id');

  @override
  Future<List<core.ParticipantAccountLink>> listForProfiles(
    Iterable<core.Id> participantProfileIds,
  ) async =>
      (await _store.whereIdIn('participant_profile_id', participantProfileIds))
        ..sort((a, b) => a.id.value.compareTo(b.id.value));

  @override
  Future<core.ParticipantAccountLink> saveClaimingGuests(
    core.ParticipantAccountLink link, {
    required Iterable<core.Id> guestAccountIds,
  }) => db.transaction(() async {
    final saved = await save(link);
    for (final guest in guestAccountIds.toSet()) {
      if (guest == link.accountId) continue;
      for (final MapEntry(key: table, value: columns)
          in guestAccountReferences.entries) {
        for (final column in columns) {
          await _repoint(
            table,
            'UPDATE $table SET $column = ? WHERE $column = ?',
            [
              Variable<String>(link.accountId.value),
              Variable<String>(guest.value),
            ],
          );
        }
      }
    }
    return saved;
  });

  @override
  Future<core.ParticipantAccountLink> saveReleasingInvitations(
    core.ParticipantAccountLink link, {
    required Map<core.Id, core.Id?> invitationToGuest,
  }) => db.transaction(() async {
    final saved = await save(link);
    for (final MapEntry(key: invitationId, value: guest)
        in invitationToGuest.entries) {
      await _repoint(
        'invitations',
        'UPDATE invitations SET redeemed_by_account_id = ? '
            'WHERE id = ? AND redeemed_by_account_id = ?',
        [
          Variable<String>(guest?.value),
          Variable<String>(invitationId.value),
          Variable<String>(link.accountId.value),
        ],
      );
    }
    return saved;
  });

  Future<void> _repoint(
    String table,
    String sql,
    List<Variable<String>> variables,
  ) => db.customUpdate(
    portableSql(db, sql),
    variables: variables,
    updates: {db.allTables.firstWhere((t) => t.actualTableName == table)},
    updateKind: UpdateKind.update,
  );

  @override
  Future<core.ParticipantAccountLink> save(core.ParticipantAccountLink link) =>
      db.transaction(() async {
        final stored = await _store.findJson(link.id);
        final storedRevision = stored?['revision'] as int?;
        if (storedRevision != null && storedRevision != link.revision) {
          throw core.StaleRevisionError(
            entityType: _store.entityType,
            entityId: link.id,
            expectedRevision: link.revision,
            storedRevision: storedRevision,
          );
        }
        final json = _store.encode(link);
        json['revision'] = storedRevision == null
            ? link.revision
            : storedRevision + 1;
        final saved = _store.decode(json);
        await _store.upsertJson(_store.encode(saved));
        return saved;
      });
}
