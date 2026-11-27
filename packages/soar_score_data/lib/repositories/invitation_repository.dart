import 'dart:convert';

import 'package:drift/drift.dart' show Variable, UpdateKind;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'audit_event_repository.dart';
import '../sync/sql_placeholders.dart';
import 'drift_repository.dart';
import 'latest_timestamps.dart';

/// Invitations in the database; backend only, so written without a
/// mutation.
class InvitationRepository extends DriftRepository
    implements core.InvitationRepository {
  InvitationRepository(super.db, {super.stores});

  late final _store = backendStore<core.Invitation>('Invitation');
  late final _audits = AuditEventRepository(db, stores: stores);

  @override
  Future<core.Invitation?> findById(core.Id id) async => _store.find(id);

  @override
  Future<core.Invitation?> findByClientMutationId({
    required core.Id contestId,
    required String clientMutationId,
  }) async {
    final found = await _store.whereText(
      'client_mutation_id',
      clientMutationId,
      orderBy: 'id',
    );
    return found.where((i) => i.contestId == contestId).firstOrNull;
  }

  @override
  Future<core.Invitation?> findByProtectedCredential(String credential) async {
    final found = await _store.whereText(
      'protected_credential',
      credential,
      orderBy: 'id',
    );
    return found.firstOrNull;
  }

  static final _messageId = RegExp(r'^[A-Za-z0-9-]{1,128}$');

  @override
  Future<core.Id?> findIdByDeliveryMessageId(String messageId) async {
    if (!_messageId.hasMatch(messageId)) return null;
    final table = db.allTables.firstWhere(
      (t) => t.actualTableName == 'invitations',
    );
    // The outcomes are JSON text written by `jsonEncode`, so an entry's id is
    // always the exact text `"message_id":"<id>"`; the id has no LIKE
    // wildcards (letters, digits and hyphens only).
    final rows = await db
        .customSelect(
          portableSql(
            db,
            'SELECT id FROM invitations WHERE delivery_outcomes LIKE ? '
            'ORDER BY id',
          ),
          variables: [Variable<String>('%"message_id":"$messageId"%')],
          readsFrom: {table},
        )
        .get();
    return rows.isEmpty ? null : core.Id.parse(rows.first.read<String>('id'));
  }

  @override
  Future<List<core.Id>> listIdsWithSendingEmail() async {
    final table = db.allTables.firstWhere(
      (t) => t.actualTableName == 'invitations',
    );
    final rows = await db
        .customSelect(
          portableSql(
            db,
            'SELECT id FROM invitations WHERE delivery_outcomes LIKE ? '
            'ORDER BY id',
          ),
          variables: [Variable<String>('%"status":"sending"%')],
          readsFrom: {table},
        )
        .get();
    return [for (final row in rows) core.Id.parse(row.read<String>('id'))];
  }

  @override
  Future<List<core.Invitation>> listForParticipation(
    core.Id contestParticipationId,
  ) async => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'invitation_revision',
  );

  @override
  Future<core.Invitation?> findActiveForParticipation(
    core.Id contestParticipationId,
  ) async {
    final all = await listForParticipation(contestParticipationId);
    return all.where((i) => i.isActive).firstOrNull;
  }

  @override
  Future<List<core.Invitation>> listForContest(core.Id contestId) async =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<Map<core.Id, DateTime>> latestIssuedAtForContests(
    Iterable<core.Id> contestIds,
  ) => latestTimestampByContest(
    db,
    table: 'invitations',
    column: 'issued_at',
    contestIds: contestIds,
  );

  @override
  Future<core.Invitation> save(core.Invitation invitation) async {
    await _store.upsertJson(_store.encode(invitation));
    return invitation;
  }

  @override
  Future<bool> redeem(
    core.Id invitationId, {
    required core.Id? expectedRedeemer,
    required core.Id newRedeemer,
    required DateTime usedAt,
  }) async {
    final stamp = const core.UtcTimestampConverter().toJson(usedAt.toUtc());
    // `IS ?` is not portable to PostgreSQL, so a missing redeemer is its own
    // condition.
    final expected = expectedRedeemer == null
        ? 'redeemed_by_account_id IS NULL'
        : 'redeemed_by_account_id = ?';
    final changed = await db.customUpdate(
      portableSql(
        db,
        'UPDATE invitations SET redeemed_by_account_id = ?, '
        'first_used_at = COALESCE(first_used_at, ?), last_used_at = ? '
        "WHERE id = ? AND state = 'Active' AND $expected",
      ),
      variables: [
        Variable<String>(newRedeemer.value),
        Variable<String>(stamp),
        Variable<String>(stamp),
        Variable<String>(invitationId.value),
        if (expectedRedeemer != null) Variable<String>(expectedRedeemer.value),
      ],
      updates: {
        db.allTables.firstWhere((t) => t.actualTableName == 'invitations'),
      },
      updateKind: UpdateKind.update,
    );
    return changed > 0;
  }

  @override
  Future<List<Map<String, Object?>>?> updateDeliveryOutcomes(
    core.Id invitationId,
    List<Map<String, Object?>>? Function(List<Map<String, Object?>> current)
    change, {
    core.AuditEvent? audit,
  }) async {
    final table = db.allTables.firstWhere(
      (t) => t.actualTableName == 'invitations',
    );
    // Compare and swap on the stored text: writers that race re-read and
    // decide again, and nothing but this column is ever written.
    for (var attempt = 0; attempt < 8; attempt++) {
      final rows = await db
          .customSelect(
            portableSql(
              db,
              'SELECT delivery_outcomes FROM invitations WHERE id = ?',
            ),
            variables: [Variable<String>(invitationId.value)],
            readsFrom: {table},
          )
          .get();
      if (rows.isEmpty) return null;
      final stored = rows.single.read<String>('delivery_outcomes');
      final current = [
        for (final item in jsonDecode(stored) as List)
          Map<String, Object?>.from(item as Map),
      ];
      final next = change(current);
      if (next == null) return current;
      final applied = await db.transaction(() async {
        final changed = await db.customUpdate(
          portableSql(
            db,
            'UPDATE invitations SET delivery_outcomes = ? '
            'WHERE id = ? AND delivery_outcomes = ?',
          ),
          variables: [
            Variable<String>(jsonEncode(next)),
            Variable<String>(invitationId.value),
            Variable<String>(stored),
          ],
          updates: {table},
          updateKind: UpdateKind.update,
        );
        if (changed == 0) return false;
        if (audit != null) await _audits.append(audit);
        return true;
      });
      if (applied) return next;
    }
    throw StateError('the delivery outcomes kept changing');
  }

  @override
  Future<void> saveIssued(
    List<core.Invitation> invitations,
    List<core.AuditEvent> audits,
  ) => db.transaction(() async {
    for (final invitation in invitations) {
      await _store.upsertJson(_store.encode(invitation));
    }
    for (final audit in audits) {
      await _audits.append(audit);
    }
  });
}
