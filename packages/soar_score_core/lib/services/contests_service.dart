import 'package:logging/logging.dart';

import '../enums/audit_action.dart';
import '../enums/audit_outcome.dart';
import '../enums/contest_action.dart';
import '../errors/entity_not_found_error.dart';
import '../models/contest/contest.dart';
import '../models/id.dart';
import '../models/sync/audit_event.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import '../repositories/stale_revision_error.dart';
import 'contest_details.dart';
import 'contest_lifecycle.dart';
import 'contest_transition_audit.dart';
import 'new_contest.dart';

final Logger _logger = Logger('ContestsService');

/// The contest operations of the API: create, read, update and the director
/// actions.
///
/// Callers name who acts through the [MutationMetadata] they pass; the
/// repository records it with the change.
class ContestsService {
  ContestsService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;

  Future<List<Contest>> getContests() async {
    _logger.info('Fetching contests from the repository');
    return repository.contestRepository.getAll();
  }

  /// The contest with [id].
  ///
  /// Throws an [EntityNotFoundError] when there is none.
  Future<Contest> getContest(Id id) async => _require(id);

  /// Creates a contest in `Created`, owned by [ownerAccountId].
  ///
  /// Idempotent on [NewContest.id]: repeating the same request returns the
  /// stored contest. A stored contest with the same id but different content
  /// or owner throws an [AlreadyStoredError]. Invalid details throw an
  /// [ArgumentError].
  Future<Contest> createContest(
    NewContest input, {
    required Id? ownerAccountId,
    required MutationMetadata metadata,
  }) async {
    final now = _clock();
    final contest = Contest(
      id: input.id,
      name: input.details.name,
      startDateTime: input.details.startDateTime,
      endDateTime: input.details.endDateTime,
      timezone: input.timezone,
      host: _blankToNull(input.details.host),
      city: _blankToNull(input.details.city),
      state: _blankToNull(input.details.state),
      country: _blankToNull(input.details.country),
      ownerAccountId: ownerAccountId,
      createdAt: now,
      updatedAt: now,
    );

    final stored = await repository.contestRepository.findById(input.id);
    if (stored != null) {
      if (_sameRequest(stored, contest)) return stored;
      throw AlreadyStoredError(entityType: 'Contest', entityId: input.id);
    }
    return repository.contestRepository.save(contest, metadata: metadata);
  }

  /// Replaces the identity, schedule and location of contest [id].
  ///
  /// [baseRevision] is the revision the caller read; a different stored
  /// revision throws a [StaleRevisionError].
  Future<Contest> updateContest(
    Id id,
    ContestDetails details, {
    required int baseRevision,
    required MutationMetadata metadata,
  }) async {
    final stored = await _require(id);
    final updated = Contest(
      id: stored.id,
      name: details.name,
      startDateTime: details.startDateTime,
      endDateTime: details.endDateTime,
      timezone: stored.timezone,
      host: _blankToNull(details.host),
      city: _blankToNull(details.city),
      state: _blankToNull(details.state),
      country: _blankToNull(details.country),
      ownerAccountId: stored.ownerAccountId,
      lifecycleState: stored.lifecycleState,
      scoringAccess: stored.scoringAccess,
      adminLock: stored.adminLock,
      resultsHiddenThroughRound: stored.resultsHiddenThroughRound,
      resultsHiddenAt: stored.resultsHiddenAt,
      localArchive: stored.localArchive,
      createdAt: stored.createdAt,
      updatedAt: _clock(),
      revision: baseRevision,
    );
    return repository.contestRepository.save(updated, metadata: metadata);
  }

  /// Applies the director [action] to contest [id].
  ///
  /// Each success leaves one `StateTransition` audit event, stored with the
  /// contest change; a refused action leaves none. See
  /// [ContestTransitionAudit] for how the action and the old and new values
  /// are recorded.
  ///
  /// Throws a [StaleRevisionError] when [baseRevision] is not the stored
  /// revision, and a `ContestStateError` when the contest's state does not
  /// allow the action.
  Future<Contest> applyAction(
    Id id,
    ContestAction action, {
    required int baseRevision,
    required MutationMetadata metadata,
  }) async {
    final stored = await _require(id);
    if (stored.revision != baseRevision) {
      throw StaleRevisionError(
        entityType: stored.entityType,
        entityId: id,
        expectedRevision: baseRevision,
        storedRevision: stored.revision,
      );
    }
    final now = _clock();
    final changed = ContestLifecycle.apply(stored, action, now);
    final audit = AuditEvent(
      id: _newId(),
      entityType: stored.entityType,
      entityId: id,
      contestId: id,
      action: AuditAction.stateTransition,
      actorId: metadata.actorId,
      authority: metadata.authority,
      installationId: metadata.sourceInstallationId,
      device: metadata.sourceDevice,
      baseRevision: stored.revision,
      resultingRevision: stored.revision + 1,
      serverTimestamp: now,
      clientTimestamp: metadata.clientTime,
      reason: ContestTransitionAudit.reason(action, stored, changed),
      outcome: AuditOutcome.success,
    );
    return repository.contestRepository.save(
      changed,
      metadata: metadata,
      audit: audit,
    );
  }

  /// The audit events of contest [id], newest first.
  ///
  /// [action] keeps only events of that kind and [limit] the newest that
  /// many. Throws an [EntityNotFoundError] when there is no such contest and
  /// an [ArgumentError] for a [limit] below 1.
  Future<List<AuditEvent>> auditEvents(
    Id id, {
    AuditAction? action,
    int? limit,
  }) async {
    if (limit != null && limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be at least 1');
    }
    await _require(id);
    return repository.auditEventRepository.listForContest(
      id,
      action: action,
      limit: limit,
    );
  }

  Future<Contest> _require(Id id) async {
    final contest = await repository.contestRepository.findById(id);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: id);
    }
    return contest;
  }

  /// Whether [stored] is what a request for [requested] would have created.
  static bool _sameRequest(Contest stored, Contest requested) =>
      stored.name == requested.name &&
      stored.startDateTime == requested.startDateTime &&
      stored.endDateTime == requested.endDateTime &&
      stored.timezone == requested.timezone &&
      stored.host == requested.host &&
      stored.city == requested.city &&
      stored.state == requested.state &&
      stored.country == requested.country &&
      stored.ownerAccountId == requested.ownerAccountId;

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
