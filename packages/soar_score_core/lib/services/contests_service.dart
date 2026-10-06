import 'package:logging/logging.dart';

import '../enums/contest_action.dart';
import '../errors/entity_not_found_error.dart';
import '../models/contest/contest.dart';
import '../models/id.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import '../repositories/stale_revision_error.dart';
import 'contest_details.dart';
import 'contest_lifecycle.dart';
import 'new_contest.dart';

final Logger _logger = Logger('ContestsService');

/// The contest operations of the API: create, read, update and the director
/// actions.
///
/// Callers name who acts through the [MutationMetadata] they pass; the
/// repository records it with the change.
class ContestsService {
  ContestsService(this.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Repository repository;
  final DateTime Function() _clock;

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
    final changed = ContestLifecycle.apply(stored, action, _clock());
    return repository.contestRepository.save(changed, metadata: metadata);
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
