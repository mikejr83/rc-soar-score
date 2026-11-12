import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';
import '../sync/drift_sync_store.dart';
import '../sync/table_mapper.dart';

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
  Future<Set<int>> pilotsUnderReview(core.Id ownerAccountId) async {
    final numbers = <int>{};
    void add(Object? payload) {
      final number = payload is Map ? payload['source_pilot_no'] : null;
      if (number is int) numbers.add(number);
    }

    // Both sides of every review that waits for the director.
    final scope = core.DirectorScopeKey(ownerAccountId);
    for (final conflict in await DriftSyncStore(
      db,
    ).conflictsNeedingAction(scope)) {
      if (conflict.entityType == 'PilotImportLink' &&
          conflict.reasonCode == core.SyncReasonCode.uniqueViolation.code) {
        add(conflict.acceptedPayload);
        add(conflict.competingPayload);
      }
    }
    // This installation's own link when the collision is not yet reviewable
    // here: set aside for the service's link but not sent yet, or sent and
    // answered with a conflict that has not come down yet.
    final here = {
      for (final link in await listForOwner(ownerAccountId))
        link.id.value: link.revision,
    };
    final mutations =
        await TableMapper(
          db,
          db.mutationRecords,
          jsonColumns: {'payload'},
        ).where(
          "owner_account_id = ? AND entity_type = 'PilotImportLink' AND "
          "(outcome = 'Pending' OR "
          "(outcome = 'Conflict' AND reason_code = 'unique_violation'))",
          [Variable<String>(ownerAccountId.value)],
        );
    // A link removed on purpose (deleted, or gone with its participant) is not
    // set aside for the service's: only the director's choice is worth a
    // review, and it names a participant this installation still has.
    final deleted = {
      for (final row in mutations)
        if (_operation(row) == 'delete') row['entity_id'],
    };
    for (final row in mutations) {
      if (_operation(row) != 'save' || deleted.contains(row['entity_id'])) {
        continue;
      }
      final stored = here.containsKey(row['entity_id']);
      final data = (row['payload'] as Map?)?['data'];
      final entity = data is Map ? data['entity'] : null;
      if (entity is! Map) continue;
      // A refused edit of a link both devices hold stays on record; it is
      // over once the service's choice replaced this installation's link.
      final replaced =
          stored &&
          entity['revision'] is int &&
          here[row['entity_id']]! > (entity['revision'] as int);
      final waiting = row['outcome'] == 'Pending'
          ? !stored
          : stored && !replaced;
      if (!waiting) continue;
      final target = entity['participant_profile_id'];
      if (target is String &&
          await _profiles.find(core.Id.parse(target)) == null) {
        continue;
      }
      add(entity);
    }
    return numbers;
  }

  static Object? _operation(Map<String, Object?> row) {
    final data = (row['payload'] as Map?)?['data'];
    return data is Map ? data['operation'] : null;
  }

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
      final held = await pilotsUnderReview(reviewedOwner);
      final touched = reviewedPilotNumbers == null
          ? held
          : held.where(reviewedPilotNumbers.contains).toSet();
      if (touched.isNotEmpty) {
        throw core.PilotImportLinkReviewError(touched);
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
