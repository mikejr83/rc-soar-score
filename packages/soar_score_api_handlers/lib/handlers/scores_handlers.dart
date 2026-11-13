import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/handlers/write_metadata.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('Scores');

/// The score routes (all inside `/api/v1`):
///
/// - `GET /contests/{id}/scores` is every score slot of the current matrix
///   with its current official score, and how far each round is scored;
/// - `POST /contests/{id}/assignments/{assignmentId}/scores` enters the
///   official score of one pilot in one group (201). Entering a score for a
///   slot that already has one is a correction and adds the next score
///   revision; the earlier ones are kept. `cumulative_penalty` in
///   `components` is tri-state: absent (or `null`) means never applied, a
///   positive integer is an applied penalty and its value is the points
///   deducted, and `0` is a penalty that was applied and later removed; a
///   `0` is stored as stored, not dropped. The results are recalculated
///   afterwards in a separate transaction; the entry retries that once and,
///   if it still fails, keeps the score, leaves the results stale and warns
///   the director on the entry response (ticket 297). On a server that
///   publishes, the contest's public update mode then decides whether the
///   entry also reaches the public projection; a failed publish is logged
///   and audited, never an error;
/// - `POST /contests/{id}/assignments/{assignmentId}/scores/official`
///   accepts the stored participant submission named in the body
///   (`source_attempt_id`, `expected_score_revision`) as the official score
///   (201, or 200 with `replayed: true` for an exact repeat). No components
///   are taken from the request. A source or revision that is no longer
///   current, or a newer official score, is 409; locks are 409 as in an
///   entry. Open reviews of the slot are superseded. The recalculation and
///   public update then follow as for an entry;
/// - `POST /contests/{id}/rounds/{roundId}/groups/{group}/scores/official`
///   accepts the stored submissions named in the body (1 to
///   [PromoteGroupRequest.maxItems] items of `assignment_id`,
///   `source_attempt_id`, `expected_score_revision`) for one group (200). A
///   repeated slot or one outside the group is a 400. Each item is checked
///   like a single promotion and answered on its own (adopted, replayed, or
///   the refusal it would have got alone); live slots the request did not
///   name are never promoted and are listed as `not_requested`. The results
///   are recalculated ONCE and the public projection updated at most ONCE;
/// - `POST /contests/{id}/scores/bulk` enters the scores of 1 to
///   [EnterScoresRequest.maxEntries] slots of ONE round in one request (200;
///   more or none is a 400; an entry for another round, a second entry for a
///   slot or a repeated `client_mutation_id` is refused alone with 400). Each
///   entry is checked like a single one and answered on its own (stored, or
///   the refusal it would have got alone); the stored entries go in ONE
///   transaction, then the results are recalculated ONCE (own transaction,
///   one retry, a warning on the response when it still fails) and the public
///   projection is updated at most ONCE. A repeat is safe and finishes an
///   interrupted request: each entry keeps its `client_mutation_id`, so it
///   replays, and the contest start, recalculation and publish run again
///   whenever any entry is saved, replayed or new;
/// - `GET /contests/{id}/assignments/{assignmentId}/scores/history` is every
///   submission to a slot, oldest first: the official revisions with their
///   reasons, and the attempts that never became official.
///
/// The handlers only translate between HTTP and [ScoresService].
///
/// [recalculation] defaults to a [RecalculationService] over [repository]; it
/// is exposed so tests can force a recalculation failure (ticket 297).
void addScoreRoutes(
  Router router,
  Repository repository, {
  bool publishingEnabled = false,
  RecalculationService? recalculation,
}) {
  final service = ScoresService(repository);
  final results = ResultsService(repository);
  final recalculationService = recalculation ?? RecalculationService(results);
  final publicUpdates = PublicUpdateService(repository);

  router.get('/contests/<id>/scores', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final scores = await service.list(contestId);
    return jsonResponse(scores.toJson());
  });

  router.get('/contests/<id>/assignments/<assignmentId>/scores/history', (
    Request request,
    String id,
    String assignmentId,
  ) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    _logger.fine(
      'Fetching score history for assignment $assignmentId in contest $id',
    );
    final history = await service.history(contestId, Id.parse(assignmentId));
    return jsonResponse(history.toJson());
  });

  router.post('/contests/<id>/scores/bulk', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, EnterScoresRequest.fromJson);
    if (body.entries.isEmpty ||
        body.entries.length > EnterScoresRequest.maxEntries) {
      throw ArgumentError(
        'a bulk entry takes 1 to ${EnterScoresRequest.maxEntries} entries',
      );
    }

    _logger.fine(
      'Entering ${body.entries.length} official scores in contest $id',
    );

    final outcomes = await service.enterOfficialScores(
      contestId,
      [
        for (final entry in body.entries)
          BulkScoreEntry(
            assignmentId: entry.assignmentId,
            clientMutationId: entry.clientMutationId,
            baseScoreRevision: entry.baseScoreRevision,
            components: entry.components,
            reason: entry.reason,
          ),
      ],
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );

    String? warning;
    // A replayed entry counts too: the request that stored it may have
    // stopped before the recalculation or the publish, so a repeat finishes
    // them (the publish key makes an unchanged repeat publish once).
    final savedAt = [
      for (final (i, outcome) in outcomes.indexed)
        if (outcome.isSaved) i,
    ];
    if (savedAt.isNotEmpty) {
      warning = await recalculationService.recalculateAfterEntry(contestId);
      if (warning != null) {
        _logger.info(
          'Recalculation warning after ${savedAt.length} scores in contest '
          '$id: $warning',
        );
      }
      if (publishingEnabled) {
        // One publish for the request. A bulk request is for one round, so
        // the round-completion mode looks at the round of any stored entry.
        // The key is the last saved entry's mutation id: a request repeated
        // with new entries after it changes the key, a plain repeat of the
        // same entries does not.
        try {
          await publicUpdates.afterScoreEntry(
            contestId,
            assignmentId: body.entries[savedAt.last].assignmentId,
            entryMutationId: body.entries[savedAt.last].clientMutationId,
          );
        } on Object catch (error, stackTrace) {
          _logger.warning(
            'Public update after a bulk score entry failed; the last '
            'projection stays public',
            error,
            stackTrace,
          );
        }
      }
    }
    return jsonResponse(
      EnterScoresResult(
        results: outcomes,
        recalculationWarning: warning,
      ).toJson(),
    );
  });

  router.post('/contests/<id>/assignments/<assignmentId>/scores/official', (
    Request request,
    String id,
    String assignmentId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, PromoteScoreRequest.fromJson);
    final metadata = writeMetadata(principal);

    _logger.fine('Marking assignment $assignmentId official in contest $id');

    final promoted = await service.promoteSubmission(
      contestId,
      Id.parse(assignmentId),
      sourceAttemptId: Id.parse(body.sourceAttemptId),
      expectedScoreRevision: body.expectedScoreRevision,
      actorId: principal.accountId,
      metadata: metadata,
    );
    var entry = promoted.entry;
    // A replay still finishes the recalculation and publish a request that
    // stopped after the adoption may have missed.
    final warning = await recalculationService.recalculateAfterEntry(contestId);
    if (warning != null) {
      _logger.info(
        'Recalculation warning after marking assignment $assignmentId '
        'official in contest $id: $warning',
      );
      entry = ScoreEntryResult(
        officialScore: entry.officialScore,
        placeholder: entry.placeholder,
        contest: entry.contest,
        calculated: entry.calculated,
        recalculationWarning: warning,
      );
    }
    if (publishingEnabled) {
      try {
        await publicUpdates.afterScoreEntry(
          contestId,
          assignmentId: Id.parse(assignmentId),
          entryMutationId: entry.officialScore.id.value,
        );
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Public update after marking a score official failed; the last '
          'projection stays public',
          error,
          stackTrace,
        );
      }
    }
    return jsonResponse(
      ScorePromotionResult(entry: entry, replayed: promoted.replayed).toJson(),
      statusCode: promoted.replayed ? 200 : 201,
    );
  });

  router.post(
    '/contests/<id>/rounds/<roundId>/groups/<group>/scores/official',
    (Request request, String id, String roundId, String group) async {
      final principal = requirePrincipal(request);
      final contestId = Id.parse(id);
      await requireContestDirector(request, repository, contestId);
      final groupNumber = int.tryParse(group);
      if (groupNumber == null || groupNumber < 1) {
        throw ArgumentError('the group must be a positive whole number');
      }
      final body = await readJsonBody(request, PromoteGroupRequest.fromJson);
      if (body.items.isEmpty ||
          body.items.length > PromoteGroupRequest.maxItems) {
        throw ArgumentError(
          'a group promotion takes 1 to ${PromoteGroupRequest.maxItems} items',
        );
      }

      _logger.fine(
        'Marking ${body.items.length} slots of group $group of round $roundId '
        'official in contest $id',
      );

      var result = await service.promoteGroup(
        contestId,
        Id.parse(roundId),
        groupNumber,
        [for (final item in body.items) _promotionItem(item)],
        actorId: principal.accountId,
        metadata: writeMetadata(principal),
      );
      final adopted = [
        for (final outcome in result.outcomes)
          if (outcome.isAdopted) outcome,
      ];
      if (adopted.isNotEmpty) {
        // Once for the request; a replay counts, so a repeat finishes work an
        // interrupted request left.
        result = result.withWarning(
          await recalculationService.recalculateAfterEntry(contestId),
        );
        if (publishingEnabled) {
          try {
            await publicUpdates.afterScoreEntry(
              contestId,
              assignmentId: adopted.last.assignmentId,
              entryMutationId: _batchKey(adopted),
            );
          } on Object catch (error, stackTrace) {
            _logger.warning(
              'Public update after marking a group official failed; the last '
              'projection stays public',
              error,
              stackTrace,
            );
          }
        }
      }
      return jsonResponse(result.toJson());
    },
  );

  router.post('/contests/<id>/assignments/<assignmentId>/scores', (
    Request request,
    String id,
    String assignmentId,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final body = await readJsonBody(request, EnterScoreRequest.fromJson);

    _logger.fine(
      'Entering official score for assignment $assignmentId in contest $id',
    );

    var result = await service.enterOfficialScore(
      contestId,
      Id.parse(assignmentId),
      clientMutationId: body.clientMutationId,
      baseScoreRevision: body.baseScoreRevision,
      components: body.components,
      reason: body.reason,
      actorId: principal.accountId,
      metadata: writeMetadata(principal),
    );
    final warning = await recalculationService.recalculateAfterEntry(contestId);
    if (warning != null) {
      _logger.info(
        'Recalculation warning for assignment $assignmentId in contest $id: $warning',
      );
      result = ScoreEntryResult(
        officialScore: result.officialScore,
        placeholder: result.placeholder,
        contest: result.contest,
        calculated: result.calculated,
        recalculationWarning: warning,
      );
    } else {
      _logger.finer(
        'No recalculation warning for assignment $assignmentId in contest $id',
      );
    }
    if (publishingEnabled) {
      _logger.fine(
        'Publishing enabled, attempting public update for assignment $assignmentId in contest $id',
      );
      try {
        await publicUpdates.afterScoreEntry(
          contestId,
          assignmentId: Id.parse(assignmentId),
          entryMutationId: body.clientMutationId,
        );
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Public update after a score entry failed; the last projection '
          'stays public',
          error,
          stackTrace,
        );
      }
    }
    return jsonResponse(result.toJson(), statusCode: 201);
  });
}

/// One requested slot; a malformed id becomes a refusal of that slot alone.
PromotionItem _promotionItem(PromoteGroupItem item) {
  final Id assignmentId;
  try {
    assignmentId = Id.parse(item.assignmentId);
  } on Object {
    throw ArgumentError('an assignment id is not valid');
  }
  final Id sourceAttemptId;
  try {
    final raw = item.rawSourceAttemptId;
    if (raw is! String) throw const FormatException();
    sourceAttemptId = Id.parse(raw);
  } on Object {
    return PromotionItem.invalid(
      assignmentId: assignmentId,
      invalidMessage: 'the source attempt id is not valid',
    );
  }
  final int revision;
  try {
    revision = wholeNumber(item.rawExpectedScoreRevision);
  } on Object {
    return PromotionItem.invalid(
      assignmentId: assignmentId,
      invalidMessage: 'the expected score revision must be a whole number',
    );
  }
  return PromotionItem(
    assignmentId: assignmentId,
    sourceAttemptId: sourceAttemptId,
    expectedScoreRevision: revision,
  );
}

/// Publication key for a batch: derived from every adopted official score, so
/// a corrected retry publishes anew and an exact retry reuses the projection.
String _batchKey(List<PromotionOutcome> adopted) {
  final ids = [
    for (final outcome in adopted)
      outcome.promotion!.entry.officialScore.id.value,
  ]..sort();
  return 'group-${sha256.convert(utf8.encode(ids.join(','))).toString()}';
}
