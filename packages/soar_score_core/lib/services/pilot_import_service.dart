import '../errors/entity_not_found_error.dart';
import '../models/id.dart';
import '../models/imports/pilot_import_draft.dart';
import '../models/imports/pilot_import_outcome.dart';
import '../models/participants/participant_profile.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/participant_profile_repository.dart';
import '../repositories/stale_revision_error.dart';
import 'pilot_import_matcher.dart';

/// The participants differ from the list the import was reviewed against:
/// one was added, removed or edited, whether or not the import touches it.
class PilotImportReviewChangedError extends Error {
  PilotImportReviewChangedError(this.changedIds);

  /// The participants that were added, removed or changed since the review.
  final List<Id> changedIds;

  @override
  String toString() =>
      'PilotImportReviewChangedError: ${changedIds.length} participant(s) '
      'changed since the review';
}

/// Stores the pilots a director chose to import from GliderScore.
///
/// New profiles and updates are written in one transaction through the
/// ordinary profile repository, so revisions, audit and sync behave as for a
/// profile edited by hand. A failure part-way stores nothing.
///
/// Retrying with the same selections is safe: a new profile keeps the id its
/// selection was given, and a profile already stored under it is not written
/// again. An update is refused when the stored profile changed since the
/// review. This guards a retry of one operation; re-importing a file is the
/// matcher's job.
///
/// When [apply] is given the revisions the review saw, the whole list must
/// still match them, so an edit to a participant the import does not touch
/// (which could turn a "new" pilot into a duplicate) also refuses the import.
class PilotImportService {
  PilotImportService(
    this.profiles, {
    DateTime Function()? clock,
    this.saveImport,
  }) : _clock = clock ?? DateTime.now;

  final ParticipantProfileRepository profiles;

  /// Optional atomic persistence for both profiles and remembered links.
  final Future<List<ParticipantProfile>> Function(
    List<ParticipantProfile> profiles,
    List<PilotImportSelection> selections,
    MutationMetadata metadata,
  )?
  saveImport;
  final DateTime Function() _clock;

  Future<PilotImportOutcome> apply(
    Id ownerAccountId,
    List<PilotImportSelection> selections, {
    required MutationMetadata metadata,
    Map<Id, int>? reviewedRevisions,
  }) async {
    if (reviewedRevisions != null) {
      await _checkReviewed(ownerAccountId, selections, reviewedRevisions);
    }
    final now = _clock();
    final toSave = <ParticipantProfile>[];
    final working = <Id, ParticipantProfile>{};
    final addedIds = <Id>{};
    final updatedIds = <Id>{};
    final newIds = <Id>{};
    var unchanged = 0;
    var skipped = 0;

    for (final selection in selections) {
      switch (selection.choice) {
        case PilotImportChoice.skip:
          skipped++;
        case PilotImportChoice.add:
          final id = selection.newProfileId;
          if (!newIds.add(id)) {
            throw ArgumentError(
              'two selections add a profile with the same id $id',
            );
          }
          final stored = await profiles.findById(id);
          if (stored != null) {
            if (stored.ownerAccountId != ownerAccountId) {
              throw AlreadyStoredError(
                entityType: 'ParticipantProfile',
                entityId: id,
              );
            }
            unchanged++;
            continue;
          }
          final created = _create(
            id,
            ownerAccountId,
            selection.match.draft,
            now,
          );
          toSave.add(created);
          working[id] = created;
          addedIds.add(id);
        case PilotImportChoice.update:
          final id = _target(selection);
          final current = working[id] ?? await _require(ownerAccountId, id);
          final expected =
              selection.expectedRevision ??
              selection.match.candidateRevisions[id];
          if (expected != null && current.revision != expected) {
            throw StaleRevisionError(
              entityType: 'ParticipantProfile',
              entityId: id,
              expectedRevision: expected,
              storedRevision: current.revision,
            );
          }
          final merged = merge(current, selection.match.draft, now);
          if (merged == null) {
            unchanged++;
            continue;
          }
          final index = toSave.indexWhere((p) => p.id == id);
          if (index >= 0) {
            toSave[index] = merged;
          } else {
            toSave.add(merged);
          }
          working[id] = merged;
          if (!addedIds.contains(id)) {
            updatedIds.add(id);
          }
      }
    }

    final saved = saveImport != null
        ? await saveImport!(toSave, selections, metadata)
        : toSave.isEmpty
        ? const <ParticipantProfile>[]
        : await profiles.saveAll(toSave, metadata: metadata);
    return PilotImportOutcome(
      added: [
        for (final p in saved)
          if (addedIds.contains(p.id)) p,
      ],
      updated: [
        for (final p in saved)
          if (updatedIds.contains(p.id)) p,
      ],
      unchanged: unchanged,
      skipped: skipped,
    );
  }

  Future<void> _checkReviewed(
    Id ownerAccountId,
    List<PilotImportSelection> selections,
    Map<Id, int> reviewed,
  ) async {
    // A profile an earlier try of this same import stored is expected.
    final ours = {
      for (final s in selections)
        if (s.choice == PilotImportChoice.add) s.newProfileId,
    };
    final stored = {
      for (final p in await profiles.listForOwner(ownerAccountId))
        p.id: p.revision,
    };
    final changed = <Id>[
      for (final entry in stored.entries)
        if (reviewed[entry.key] != entry.value && !ours.contains(entry.key))
          entry.key,
      for (final id in reviewed.keys)
        if (!stored.containsKey(id)) id,
    ];
    if (changed.isNotEmpty) {
      throw PilotImportReviewChangedError(changed);
    }
  }

  /// [existing] with the non-blank values of [draft] applied, or null when it
  /// already holds them all. Names are never changed and a blank value never
  /// clears one. Values that are equal after normalising (case, spaces) are
  /// left as they are.
  static ParticipantProfile? merge(
    ParticipantProfile existing,
    PilotDraft draft,
    DateTime now,
  ) {
    var changed = false;

    String? pick(
      String? current,
      String? incoming, {
      bool Function(String a, String b)? same,
    }) {
      if (incoming == null || incoming.trim().isEmpty) {
        return current;
      }
      final equal =
          current != null &&
          (same ?? (String a, String b) => a == b)(incoming, current);
      if (equal) {
        return current;
      }
      changed = true;
      return incoming;
    }

    final email = pick(
      existing.email,
      draft.email?.trim().toLowerCase(),
      same: (a, b) =>
          PilotImportMatcher.normalizeEmail(a) ==
          PilotImportMatcher.normalizeEmail(b),
    );
    bool sameNumber(String a, String b) =>
        PilotImportMatcher.normalizeNumber(a) ==
        PilotImportMatcher.normalizeNumber(b);
    final fai = pick(existing.faiNumber, draft.faiNumber, same: sameNumber);
    final org = pick(
      existing.nationalOrgId,
      draft.nationalOrgId,
      same: sameNumber,
    );
    final club = pick(existing.club, draft.club);
    final city = pick(existing.city, draft.city);
    final state = pick(existing.state, draft.state);
    final country = pick(existing.country, draft.country);

    if (!changed) {
      return null;
    }
    return ParticipantProfile(
      id: existing.id,
      ownerAccountId: existing.ownerAccountId,
      firstName: existing.firstName,
      lastName: existing.lastName,
      club: club,
      faiNumber: fai,
      nationalOrgId: org,
      city: city,
      state: state,
      country: country,
      email: email,
      createdAt: existing.createdAt,
      updatedAt: now,
      revision: existing.revision,
    );
  }

  static ParticipantProfile _create(
    Id id,
    Id ownerAccountId,
    PilotDraft draft,
    DateTime now,
  ) => ParticipantProfile(
    id: id,
    ownerAccountId: ownerAccountId,
    firstName: draft.firstName,
    lastName: draft.lastName,
    club: draft.club,
    faiNumber: draft.faiNumber,
    nationalOrgId: draft.nationalOrgId,
    city: draft.city,
    state: draft.state,
    country: draft.country,
    email: draft.email?.trim().toLowerCase(),
    createdAt: now,
    updatedAt: now,
  );

  static Id _target(PilotImportSelection selection) {
    final explicit = selection.targetProfileId;
    if (explicit != null) {
      return explicit;
    }
    final candidates = selection.match.candidateIds;
    if (candidates.length == 1) {
      return candidates.single;
    }
    throw ArgumentError(
      'choose which profile to update for pilot '
      '${selection.match.draft.sourcePilotNo}',
    );
  }

  Future<ParticipantProfile> _require(Id ownerAccountId, Id id) async {
    final profile = await profiles.findById(id);
    if (profile == null || profile.ownerAccountId != ownerAccountId) {
      throw EntityNotFoundError(entityType: 'ParticipantProfile', entityId: id);
    }
    return profile;
  }
}
