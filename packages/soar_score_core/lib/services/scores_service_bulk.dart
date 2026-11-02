part of 'scores_service.dart';

/// Bulk entry of official scores (`POST /contests/{id}/scores/bulk`), on top
/// of the checks and the store of a single entry.
extension BulkScoresService on ScoresService {
  /// Enters many scores at once, for the slots of one contest.
  ///
  /// Every entry is checked first, exactly as a single entry is (stale
  /// revision, locks, retired pilot, invalid components, a missing reason for
  /// a correction); an entry that fails is refused alone and the others go
  /// on. The accepted entries are stored together in ONE transaction. When
  /// that transaction is refused because a revision moved underneath it,
  /// nothing of it is kept and the entries are stored one by one instead, so
  /// only the entries that really conflict are refused, and an entry that
  /// fails otherwise is reported as failed (500) while the rest are kept.
  /// Any other failure of the single transaction is thrown with nothing
  /// stored. Repeating a request is safe because each entry keeps its
  /// [BulkScoreEntry.clientMutationId]; the contest start, the
  /// recalculation and the publish that follow run for a replay as well, so a
  /// request that stopped after storing its scores is finished by a repeat.
  ///
  /// Returns one outcome per entry, in order. The recalculation and the
  /// publish that follow are the caller's, and run once for the request.
  Future<List<BulkScoreOutcome>> enterOfficialScores(
    Id contestId,
    List<BulkScoreEntry> entries, {
    required Id actorId,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final context = await _configuration(contest);

    final outcomes = List<BulkScoreOutcome?>.filled(entries.length, null);
    final prepared = <int, _Prepared>{};
    final replays = <int, ScoreEntryResult>{};
    final seenSlots = <Id>{};
    final seenMutations = <String>{};
    int? round;
    for (final (i, entry) in entries.indexed) {
      if (!seenSlots.add(entry.assignmentId)) {
        outcomes[i] = const BulkScoreOutcome.refused(
          statusCode: 400,
          code: 'invalid_request',
          message: 'the request has two entries for the same slot',
        );
        continue;
      }
      if (!seenMutations.add(entry.clientMutationId)) {
        outcomes[i] = const BulkScoreOutcome.refused(
          statusCode: 400,
          code: 'invalid_request',
          message: 'the request uses one client mutation id twice',
        );
        continue;
      }
      try {
        final one = await _prepare(
          contest,
          context,
          entry.assignmentId,
          clientMutationId: entry.clientMutationId,
          baseScoreRevision: entry.baseScoreRevision,
          components: entry.components,
          reason: entry.reason,
          actorId: actorId,
          metadata: metadata.forPart(entry.clientMutationId),
          // The contest is started once, after the entries are stored, so
          // no entry can be refused because of a contest conflict.
          moveContest: false,
        );
        if (one.replay != null) {
          replays[i] = one.replay!;
        } else if (round != null && round != one.round) {
          outcomes[i] = const BulkScoreOutcome.refused(
            statusCode: 400,
            code: 'invalid_request',
            message: 'a bulk entry is for the slots of one round',
          );
        } else {
          round = one.round;
          prepared[i] = one;
        }
      } on Object catch (error) {
        final refused = _refusal(error);
        if (refused == null) rethrow;
        outcomes[i] = refused;
      }
    }

    var fellBack = false;
    final stored = <int, RecordedScore>{};
    if (prepared.isNotEmpty) {
      final order = prepared.keys.toList();
      List<RecordedScore>? recorded;
      try {
        recorded = await repository.officialScoreRepository.recordEntries([
          for (final i in order) prepared[i]!.entry!,
        ], metadata: metadata);
      } on StaleRevisionError {
        recorded = null;
      } on AlreadyStoredError {
        recorded = null;
      }
      if (recorded != null) {
        for (final (k, i) in order.indexed) {
          stored[i] = recorded[k];
        }
      } else {
        fellBack = true;
        // A revision moved while the entries were being stored. Nothing was
        // kept, so store them one by one; only the real conflicts are
        // refused.
        for (final i in order) {
          try {
            stored[i] = await repository.officialScoreRepository.recordEntry(
              prepared[i]!.entry!,
              metadata: metadata.forPart(entries[i].clientMutationId),
            );
          } on Object catch (error, stackTrace) {
            // The entries before this one are already stored, so report
            // this one as failed and go on instead of throwing.
            final refused = _refusal(error);
            if (refused == null) {
              _logger.warning(
                'Bulk fallback: storing entry $i failed',
                error,
                stackTrace,
              );
            }
            outcomes[i] =
                refused ??
                const BulkScoreOutcome.refused(
                  statusCode: 500,
                  code: 'internal_error',
                  message: 'The entry could not be stored.',
                );
          }
        }
      }
    }

    if (stored.isNotEmpty || replays.isNotEmpty) {
      // A replay also starts the contest: an earlier request may have
      // stopped after storing its scores.
      final started = await _startContest(contest, metadata);
      for (final MapEntry(key: i, value: replay) in replays.entries) {
        outcomes[i] = BulkScoreOutcome.saved(
          ScoreEntryResult(
            officialScore: replay.officialScore,
            placeholder: replay.placeholder,
            contest: started,
            calculated: replay.calculated,
          ),
        );
      }
      for (final MapEntry(key: i, value: one) in stored.entries) {
        outcomes[i] = BulkScoreOutcome.saved(
          ScoreEntryResult(
            officialScore: one.officialScore,
            placeholder: one.placeholder,
            contest: started,
            calculated: prepared[i]!.calculated!,
          ),
        );
      }
    }
    final result = [for (final outcome in outcomes) outcome!];
    _logger.info(
      'Bulk score entry in contest ${contestId.value}: ${entries.length} '
      'entries, ${stored.length} stored, ${replays.length} replayed, '
      '${result.where((o) => !o.isSaved).length} refused'
      '${fellBack ? ', stored one by one after a conflict' : ''}',
    );
    return result;
  }

  /// Moves a `Ready` contest to `Running` after its first stored scores, and
  /// returns the contest as it is. A conflicting contest change is read
  /// again once; a contest that has moved on by itself is left alone.
  Future<Contest> _startContest(
    Contest contest,
    MutationMetadata metadata,
  ) async {
    var current = contest;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (current.lifecycleState != LifecycleState.ready) return current;
      try {
        return await repository.contestRepository.save(
          current.copyWithState(
            lifecycleState: LifecycleState.running,
            updatedAt: _clock(),
          ),
          metadata: metadata.forPart('contest-${current.id.value}'),
        );
      } on StaleRevisionError {
        current = await _requireContest(current.id);
      } on Object catch (error, stackTrace) {
        // The scores are stored; a repeat of the request starts the contest.
        _logger.warning(
          'Starting the contest after a bulk entry failed',
          error,
          stackTrace,
        );
        return current;
      }
    }
    return current;
  }

  /// The outcome that stands for [error] on one entry, or null when the
  /// error is not about the entry (it is the request's, and is thrown).
  BulkScoreOutcome? _refusal(Object error) => switch (error) {
    EntityNotFoundError() => BulkScoreOutcome.refused(
      statusCode: 404,
      code: 'not_found',
      message: '$error',
    ),
    ContestStateError(:final code, :final message) => BulkScoreOutcome.refused(
      statusCode: 409,
      code: code,
      message: message,
    ),
    StaleRevisionError() => BulkScoreOutcome.refused(
      statusCode: 409,
      code: 'stale_revision',
      message: '$error',
    ),
    AlreadyStoredError() => BulkScoreOutcome.refused(
      statusCode: 409,
      code: 'already_stored',
      message: '$error',
    ),
    ScoringValidationError() => BulkScoreOutcome.refused(
      statusCode: 400,
      code: 'invalid_request',
      message: '$error',
    ),
    ArgumentError(:final message) => BulkScoreOutcome.refused(
      statusCode: 400,
      code: 'invalid_request',
      message: '${message ?? error}',
    ),
    _ => null,
  };
}
