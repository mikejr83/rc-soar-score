import 'package:soar_score_core/soar_score_core.dart' as core;

import '../sync/unscored_matrix_rows.dart';
import 'audit_event_repository.dart';
import 'drift_repository.dart';

/// Contest participations in the database.
class ContestParticipationRepository extends DriftRepository
    implements core.ContestParticipationRepository {
  ContestParticipationRepository(super.db, {super.stores});

  late final _audits = AuditEventRepository(db, stores: stores);
  late final _store = store<core.ContestParticipation>('ContestParticipation');
  late final _memberships = store<core.TeamMembership>('TeamMembership');
  late final _modelLinks = store<core.ContestModelLink>('ContestModelLink');

  /// Removes the model links of [participationId]; only a pilot has any.
  Future<void> _removeModelLinks(
    core.WriteContext context,
    core.Id participationId,
    core.MutationMetadata metadata,
  ) async {
    for (final link in await _modelLinks.whereId(
      'contest_participation_id',
      participationId,
    )) {
      await context.delete(link, metadata: metadata.forPart(link.id.value));
    }
  }

  @override
  Future<core.ContestParticipation?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ContestParticipation>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<List<core.ContestParticipation>> listForProfile(
    core.Id participantProfileId,
  ) => _store.whereId(
    'participant_profile_id',
    participantProfileId,
    orderBy: 'id',
  );

  @override
  Future<List<core.ContestParticipation>> listForRole(core.Id roleId) =>
      _store.whereId('role_id', roleId, orderBy: 'id');

  @override
  Future<core.ContestParticipation> save(
    core.ContestParticipation participation, {
    required core.MutationMetadata metadata,
    core.AuditEvent? audit,
  }) => unitOfWork.run((context) async {
    final saved = await context.save(participation, metadata: metadata);
    if (audit != null) await _audits.append(audit);
    return saved;
  });

  @override
  Future<({core.ContestParticipation participation, int matrixRowsRemoved})>
  saveRemovingMatrixRows(
    core.ContestParticipation participation, {
    required core.MutationMetadata metadata,
    core.AuditEvent? audit,
  }) => unitOfWork.run((context) async {
    final removed = await removeUnscoredMatrixRows(
      context,
      stores,
      participation.id,
      metadata,
    );
    await _removeModelLinks(context, participation.id, metadata);
    final saved = await context.save(participation, metadata: metadata);
    if (audit != null) await _audits.append(audit);
    return (participation: saved, matrixRowsRemoved: removed);
  });

  @override
  Future<bool> delete(
    core.Id id, {
    required core.MutationMetadata metadata,
  }) async => (await deleteRemovingMatrixRows(id, metadata: metadata)).deleted;

  @override
  Future<({bool deleted, int matrixRowsRemoved})> deleteRemovingMatrixRows(
    core.Id id, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    final participation = await _store.find(id);
    if (participation == null) return (deleted: false, matrixRowsRemoved: 0);
    final removed = await removeUnscoredMatrixRows(
      context,
      stores,
      id,
      metadata,
    );
    for (final membership in await _memberships.whereId(
      'contest_participation_id',
      id,
    )) {
      await context.delete(
        membership,
        metadata: metadata.forPart(membership.id.value),
      );
    }
    await _removeModelLinks(context, id, metadata);
    await context.delete(participation, metadata: metadata);
    return (deleted: true, matrixRowsRemoved: removed);
  });
}
