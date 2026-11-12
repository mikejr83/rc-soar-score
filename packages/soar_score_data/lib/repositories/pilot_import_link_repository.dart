import 'dart:convert';

import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';
import '../sync/drift_sync_store.dart';
import '../sync/sql_placeholders.dart';

import 'package:drift/drift.dart' show Variable;

class PilotImportLinkRepository extends DriftRepository
    implements core.PilotImportLinkRepository {
  PilotImportLinkRepository(super.db, {super.stores});
  late final _links = store<core.PilotImportLink>('PilotImportLink');
  late final _profiles = store<core.ParticipantProfile>('ParticipantProfile');
  @override
  Future<List<core.PilotImportLink>> listForOwner(core.Id ownerAccountId) =>
      _links.whereId('owner_account_id', ownerAccountId);
  @override
  Future<core.PilotImportLink> save(
    core.PilotImportLink link, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    final profile = await _profiles.find(link.participantProfileId);
    if (profile == null || profile.ownerAccountId != link.ownerAccountId)
      throw ArgumentError(
        'Pilot import link target must exist and belong to its owner',
      );
    return context.save(link, metadata: metadata);
  });
  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final link = await _links.find(id);
        if (link == null) return false;
        await context.delete(link, metadata: metadata);
        return true;
      });
  Future<List<core.ParticipantProfile>> saveImport(
    List<core.ParticipantProfile> profiles,
    List<core.PilotImportLink> links, {
    required core.MutationMetadata metadata,
    core.Id? reviewedOwner,
    Map<core.Id, int>? reviewedLinks,
    Set<int>? reviewedPilotNumbers,
  }) => unitOfWork.run((context) async {
    if (reviewedOwner != null) {
      final conflicts = await DriftSyncStore(db)
          .conflictsNeedingAction(core.DirectorScopeKey(reviewedOwner));
      final displaced = await db
          .customSelect(
            portableSql(
              db,
              "SELECT m.payload FROM mutation_records m WHERE m.owner_account_id = ? AND m.entity_type = 'PilotImportLink' AND m.outcome = 'Pending' AND NOT EXISTS (SELECT 1 FROM pilot_import_links l WHERE l.id = m.entity_id)",
            ),
            variables: [Variable<String>(reviewedOwner.value)],
          )
          .get();
      final blocked = <Object?>{
        for (final conflict in conflicts)
          if (conflict.entityType == 'PilotImportLink')
            conflict.acceptedPayload?['source_pilot_no'],
      };
      for (final row in displaced) {
        final payload = jsonDecode(row.read<String>('payload')) as Map;
        final data = payload['data'] as Map?;
        final entity = data?['entity'];
        blocked.add(entity is Map ? entity['source_pilot_no'] : null);
      }
      if (blocked.contains(null) ||
          (reviewedPilotNumbers == null
              ? blocked.isNotEmpty
              : blocked.any(reviewedPilotNumbers.contains))) {
        throw StateError(
          'Review competing pilot links in Account sync before importing pilots.',
        );
      }
    }
    if (reviewedOwner != null && reviewedLinks != null) {
      final current = await listForOwner(reviewedOwner);
      final revisions = {for (final link in current) link.id: link.revision};
      final changed = <core.Id>{
        for (final entry in revisions.entries)
          if (reviewedLinks[entry.key] != entry.value) entry.key,
        for (final id in reviewedLinks.keys)
          if (!revisions.containsKey(id)) id,
      };
      if (changed.isNotEmpty) {
        throw core.PilotImportReviewChangedError(changed.toList());
      }
    }
    final saved = <core.ParticipantProfile>[];
    for (final profile in profiles) {
      saved.add(
        await context.save(
          profile,
          metadata: metadata.forPart('profile-${profile.id.value}'),
        ),
      );
    }
    for (final link in links) {
      final target = await _profiles.find(link.participantProfileId);
      if (target == null || target.ownerAccountId != link.ownerAccountId)
        throw ArgumentError(
          'Pilot import link target must exist and belong to its owner',
        );
      await context.save(
        link,
        metadata: metadata.forPart('pilot-link-${link.id.value}'),
      );
    }
    return saved;
  });
}
