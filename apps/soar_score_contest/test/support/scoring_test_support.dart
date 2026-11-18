import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/scoring_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/contest_scope.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_test_support.dart';

final Id _landingTableId = Id.parse('019c0000-0000-7000-8000-0000000000f1');
final Id _setBy = Id.parse('019c0000-0000-7000-8000-0000000000b1');

Id _sid(String kind, int n) =>
    Id.parse('019c0000-0000-7000-8000-$kind${n.toString().padLeft(8, '0')}');

/// The assignment id of [pilot] (1 to 4) in [round] of the drawn matrix.
Id scoringAssignmentId(int round, int pilot) =>
    _sid('0004', round * 100 + pilot);

/// A fake server for the scoring page: the matrix server's reads, the score
/// slots, a landing table and the score entry.
///
/// [entryStatus] other than 200 answers every entry with that status and
/// [entryCode]. [offlineOnEntry] makes entries fail like a lost connection.
class ScoringServer {
  /// Answers the landing-table list empty, as a contest without a table.
  final bool noLandingTable;

  ScoringServer({
    Contest? contest,
    CurrentMatrix? matrix,
    Map<String, Object?> discipline = const {},
    Map<String, Object?> core = const {},
    this.noLandingTable = false,
  }) : matrixServer = MatrixServer(
         contest: contest ?? matrixContest(state: LifecycleState.running),
         configuration: _configuration(discipline, core),
         matrix: matrix ?? drawnMatrix(),
       ),
       _score = {};

  static ContestConfigurationRevision _configuration(
    Map<String, Object?> discipline,
    Map<String, Object?> core,
  ) {
    final base = matrixConfiguration();
    return ContestConfigurationRevision(
      id: base.id,
      contestId: base.contestId,
      revisionNumber: base.revisionNumber,
      disciplineProfileId: base.disciplineProfileId,
      config: ContestConfig(core: core, discipline: discipline),
      landingTableId: _landingTableId,
      createdBy: base.createdBy,
      createdAt: base.createdAt,
    );
  }

  final MatrixServer matrixServer;
  final Map<Id, OfficialScore> _score;

  /// When set, every read answers with this status instead of the data.
  int? readFailure;

  int entryStatus = 200;

  /// Answers a bulk request with this status instead of the entries, like
  /// a server without the bulk route (404).
  int bulkStatus = 200;

  /// The recalculation warning a bulk answer carries.
  String? bulkWarning;
  String entryCode = 'rejected';
  bool offlineOnEntry = false;

  /// Answers the entry for [assignmentId] with [status] and [code] instead
  /// of the defaults, for a row-specific failure while the rest succeeds.
  final Map<Id, (int, String)> entryFailures = {};

  /// The bodies of the entries received, in order (a bulk request adds one
  /// per entry).
  final List<Map<String, dynamic>> entries = [];

  /// How many score-entry requests arrived: a bulk request counts once.
  int entryRequests = 0;

  /// When set, a bulk request waits for this before it is answered.
  Completer<void>? holdBulk;

  /// Stores one entry like the server does and answers it: the status and
  /// the body of the single-entry route, or, for a [bulk] entry, the
  /// per-entry outcome (`result` or `error`).
  (int, Map<String, Object?>) _enter(
    Id assignmentId,
    Map<String, dynamic> body, {
    bool bulk = false,
  }) {
    entries.add(body);
    final failure = entryFailures[assignmentId];
    final status = failure?.$1 ?? entryStatus;
    final code = failure?.$2 ?? entryCode;
    if (status != 200) {
      final message = 'The entry was $code.';
      return (
        status,
        bulk
            ? {
                'error': {'status': status, 'code': code, 'message': message},
              }
            : {
                'error': {'code': code, 'message': message},
              },
      );
    }
    final revision = (_score[assignmentId]?.scoreRevision ?? 0) + 1;
    final components = Map<String, Object?>.from(
      body['components'] as Map<String, dynamic>,
    );
    final official = _official(assignmentId, components, revision);
    _score[assignmentId] = official;
    _record(
      assignmentId,
      components,
      revision,
      body['reason'] as String? ?? 'Entered by the director',
    );
    // The first score moves a Ready contest to Running, as the server does.
    if (matrixServer.contest.lifecycleState == LifecycleState.ready) {
      matrixServer.contest = matrixServer.contest.copyWithState(
        lifecycleState: LifecycleState.running,
        updatedAt: DateTime.utc(2026, 10, 17, 15),
      );
    }
    final result = ScoreEntryResult(
      officialScore: official,
      placeholder: _placeholder(assignmentId),
      contest: matrixServer.contest,
      calculated: const CalculatedFlight(
        outcome: FlightOutcome.scored,
        rawScore: 0,
      ),
    ).toJson();
    return (200, bulk ? {'result': result} : result);
  }

  /// The history of each slot, oldest first.
  final Map<Id, List<ScoreHistoryEntry>> _history = {};

  /// Makes every history read fail with this status when not 200.
  int historyStatus = 200;

  /// Pre-fills an official score for one slot.
  void seedScore(Id assignmentId, Map<String, Object?> components) {
    _score[assignmentId] = _official(assignmentId, components, 1);
    _record(assignmentId, components, 1, 'seeded');
  }

  /// Pre-fills the next revision of a slot, with its reason.
  void seedCorrection(
    Id assignmentId,
    Map<String, Object?> components,
    String reason,
  ) {
    final revision = (_score[assignmentId]?.scoreRevision ?? 0) + 1;
    _score[assignmentId] = _official(assignmentId, components, revision);
    _record(assignmentId, components, revision, reason);
  }

  /// When set, a promotion request waits for this before it is answered.
  Completer<void>? holdPromote;

  /// Slots whose official score the contest accepted automatically, and the
  /// revision the director confirmed for each (review closed).
  final Set<Id> _automatic = {};
  final Map<Id, int> _confirmed = {};

  /// Pre-fills an official score the contest accepted on its own: origin
  /// automatic, no official actor, review still open.
  void seedAutomaticScore(Id assignmentId, Map<String, Object?> components) {
    _automatic.add(assignmentId);
    _score[assignmentId] = _official(
      assignmentId,
      components,
      1,
      automatic: true,
    );
    (_history[assignmentId] ??= []).add(
      ScoreHistoryEntry(
        attemptId: _automaticAttempt,
        outcome: ScoreHistoryOutcome.current,
        scoreRevision: 1,
        components: components,
        reason: 'automatic_acceptance',
        actorId: null,
        authority: Authority.participant,
        selectionOrigin: SelectionOrigin.automatic,
        at: DateTime.utc(2026, 10, 17, 15),
      ),
    );
  }

  /// Another director confirms the automatic score of [assignmentId].
  void confirmAsDirector(Id assignmentId) {
    final score = _score[assignmentId]!;
    _confirm(assignmentId, score.scoreAttemptId.value, score.scoreRevision);
  }

  Id get _automaticAttempt => _sid('000a', 77);

  /// Per slot, a status and code the promotion routes answer instead of
  /// adopting the submission (for example 503 or 409 `locked`).
  final Map<Id, (int, String)> promoteFailures = {};

  /// Slots another operator makes official at the moment their promotion is
  /// processed: the request was built from a waiting submission, and the
  /// promotion is refused as changed because the slot is official by then.
  final Set<Id> officialDuringPromote = {};

  /// Slots whose promotion is queued for the service instead of adopted, as
  /// on a syncing installation; the slot then lists the pending intent.
  final Set<Id> queuePromotions = {};
  final Map<Id, Map<String, Object?>> _queued = {};

  /// The service decides the queued adoption of [assignmentId] as accepted:
  /// the submission becomes the official score and the intent is gone.
  void settleQueued(Id assignmentId) {
    final pending = _pendingAttempt(assignmentId)!;
    _queued.remove(assignmentId);
    queuePromotions.remove(assignmentId);
    seedScore(assignmentId, pending.rawComponents);
  }

  /// While true, reading the score list fails (a server error).
  bool failScoreReads = false;

  /// Promotion requests that arrived: a group request counts once.
  int promoteRequests = 0;

  /// Items of the group promotion requests, in order.
  final List<Map<String, dynamic>> promotedItems = [];

  /// The bodies of single-row promotion requests, as sent.
  final List<Map<String, dynamic>> promotedBodies = [];

  /// Stores the adoption of the waiting submission like the server does:
  /// the submission and score revision must be the ones now on the slot.
  (int, Map<String, Object?>) _promote(
    Id assignmentId,
    String sourceAttemptId,
    int expectedRevision,
  ) {
    promotedItems.add({
      'assignment_id': assignmentId.value,
      'source_attempt_id': sourceAttemptId,
      'expected_score_revision': expectedRevision,
    });
    if (officialDuringPromote.remove(assignmentId)) {
      seedScore(assignmentId, _pendingAttempt(assignmentId)!.rawComponents);
    }
    final failure = promoteFailures[assignmentId];
    if (failure != null) {
      return (
        failure.$1,
        {
          'error': {
            'status': failure.$1,
            'code': failure.$2,
            'message': 'The adoption was ${failure.$2}.',
          },
        },
      );
    }
    final pending = _pendingAttempt(assignmentId);
    final revision = _score[assignmentId]?.scoreRevision ?? 0;
    if (_automatic.contains(assignmentId)) {
      if (queuePromotions.contains(assignmentId)) {
        return (
          202,
          {
            'queued': _queued[assignmentId] ??= {
              'operation_id': Id.create().value,
              'contest_id': matrixServer.contest.id.value,
              'assignment_id': assignmentId.value,
              'source_attempt_id': sourceAttemptId,
              'expected_score_revision': expectedRevision,
              'queued_at': '2026-11-17T10:00:00Z',
            },
          },
        );
      }
      return _confirm(assignmentId, sourceAttemptId, expectedRevision);
    }
    if (queuePromotions.contains(assignmentId) && pending != null) {
      return (
        202,
        {
          'queued': _queued[assignmentId] ??= {
            'operation_id': Id.create().value,
            'contest_id': matrixServer.contest.id.value,
            'assignment_id': assignmentId.value,
            'source_attempt_id': sourceAttemptId,
            'expected_score_revision': expectedRevision,
            'queued_at': '2026-11-17T10:00:00Z',
          },
        },
      );
    }
    if (pending == null ||
        pending.id.value != sourceAttemptId ||
        revision != expectedRevision) {
      return (
        409,
        {
          'error': {
            'status': 409,
            'code': 'stale_revision',
            'message': 'The slot changed.',
          },
        },
      );
    }
    final components = Map<String, Object?>.from(pending.rawComponents);
    _score[assignmentId] = _official(assignmentId, components, revision + 1);
    _record(assignmentId, components, revision + 1, 'director_accepted');
    final result = ScoreEntryResult(
      officialScore: _score[assignmentId]!,
      placeholder: _placeholder(assignmentId),
      contest: matrixServer.contest,
      calculated: const CalculatedFlight(
        outcome: FlightOutcome.scored,
        rawScore: 0,
      ),
    ).toJson();
    return (200, {...result, 'replayed': false});
  }

  /// Confirming an automatic score: the director's decision closes review,
  /// with no second official version; repeating it is a replay.
  (int, Map<String, Object?>) _confirm(
    Id assignmentId,
    String sourceAttemptId,
    int expectedRevision,
  ) {
    final score = _score[assignmentId]!;
    if (sourceAttemptId != score.scoreAttemptId.value ||
        expectedRevision != score.scoreRevision) {
      return (
        409,
        {
          'error': {
            'status': 409,
            'code': 'stale_revision',
            'message': 'The slot changed.',
          },
        },
      );
    }
    final replayed = _confirmed[assignmentId] == score.scoreRevision;
    _confirmed[assignmentId] = score.scoreRevision;
    confirmedAssignments.add(assignmentId);
    final entries = _history[assignmentId]!;
    _history[assignmentId] = [
      for (final e in entries)
        e.outcome == ScoreHistoryOutcome.current
            ? ScoreHistoryEntry(
                attemptId: e.attemptId,
                outcome: e.outcome,
                scoreRevision: e.scoreRevision,
                components: e.components,
                reason: e.reason,
                actorId: e.actorId,
                authority: e.authority,
                selectionOrigin: e.selectionOrigin,
                at: e.at,
                reviewClosed: true,
              )
            : e,
    ];
    final result = ScoreEntryResult(
      officialScore: score,
      placeholder: _placeholder(assignmentId),
      contest: matrixServer.contest,
      calculated: const CalculatedFlight(
        outcome: FlightOutcome.scored,
        rawScore: 0,
      ),
    ).toJson();
    return (replayed ? 200 : 201, {...result, 'replayed': replayed});
  }

  /// Slots the director confirmed, in order.
  final List<Id> confirmedAssignments = [];

  final Set<Id> _submitted = {};
  final Set<Id> _inReview = {};

  /// The newest waiting submission of the slot, as the service lists it.
  ScoreAttempt? _pendingAttempt(Id assignmentId) {
    // Kept even after an official score, so a test can prove the row's own
    // gate hides stale values (the service itself drops it).
    if (!_submitted.contains(assignmentId)) return null;
    final entry = (_history[assignmentId] ?? const []).lastWhere(
      (e) => e.outcome == ScoreHistoryOutcome.pending,
    );
    return ScoreAttempt(
      id: entry.attemptId,
      contestId: contestId,
      scorePlaceholderId: _placeholderId(assignmentId),
      configRevisionId: _sid('000d', 1),
      matrixRevisionId: _sid('000e', 1),
      rawComponents: entry.components,
      actorId: _setBy,
      authority: Authority.participant,
      clientMutationId: 'seeded-pending',
      baseScoreRevision: 0,
      acceptedAt: DateTime.utc(2026, 10, 17, 15),
    );
  }

  /// A participant's submission waiting for the director: the slot is
  /// Submitted, with no official score.
  void seedPendingSubmission(
    Id assignmentId,
    Map<String, Object?> components, {
    bool inReview = false,
  }) {
    _submitted.add(assignmentId);
    if (inReview) _inReview.add(assignmentId);
    (_history[assignmentId] ??= []).add(
      ScoreHistoryEntry(
        attemptId: _sid('000c', 100 + (_history[assignmentId]?.length ?? 0)),
        outcome: ScoreHistoryOutcome.pending,
        components: components,
        actorId: _setBy,
        authority: Authority.participant,
      ),
    );
  }

  /// Adds a participant's submission that never became official.
  void seedLostSubmission(Id assignmentId, Map<String, Object?> components) {
    (_history[assignmentId] ??= []).add(
      ScoreHistoryEntry(
        attemptId: _sid('000c', (_history[assignmentId]?.length ?? 0) + 50),
        outcome: ScoreHistoryOutcome.notAdopted,
        components: components,
        actorId: _setBy,
        authority: Authority.participant,
      ),
    );
  }

  void _record(
    Id assignmentId,
    Map<String, Object?> components,
    int revision,
    String reason,
  ) {
    final entries = _history[assignmentId] ??= [];
    final shown = [
      for (final e in entries)
        if (e.outcome == ScoreHistoryOutcome.current)
          ScoreHistoryEntry(
            attemptId: e.attemptId,
            outcome: ScoreHistoryOutcome.superseded,
            scoreRevision: e.scoreRevision,
            components: e.components,
            reason: e.reason,
            actorId: e.actorId,
            authority: e.authority,
            at: e.at,
          )
        else
          e,
    ];
    shown.add(
      ScoreHistoryEntry(
        attemptId: _sid(
          '000c',
          revision + assignmentId.value.hashCode.abs() % 9999,
        ),
        outcome: ScoreHistoryOutcome.current,
        scoreRevision: revision,
        components: components,
        reason: reason,
        actorId: _setBy,
        authority: Authority.director,
        at: DateTime.utc(2026, 10, 17, 14 + revision),
      ),
    );
    _history[assignmentId] = shown;
  }

  OfficialScore _official(
    Id assignmentId,
    Map<String, Object?> components,
    int revision, {
    bool automatic = false,
  }) {
    // A later revision by the director replaces the automatic one.
    if (!automatic) _automatic.remove(assignmentId);
    return OfficialScore(
      id: _sid('0009', assignmentId.value.hashCode.abs() % 99999999),
      contestId: contestId,
      scorePlaceholderId: _placeholderId(assignmentId),
      scoreAttemptId: automatic ? _automaticAttempt : _sid('000a', 1),
      scoreRevision: revision,
      components: components,
      setAt: DateTime.utc(2026, 10, 17, 15),
      setBy: automatic ? null : _setBy,
      reason: automatic ? 'automatic_acceptance' : 'seeded',
      selectionOrigin: automatic
          ? SelectionOrigin.automatic
          : SelectionOrigin.manual,
    );
  }

  Id _placeholderId(Id assignmentId) =>
      _sid('0008', assignmentId.value.hashCode.abs() % 99999999);

  ScorePlaceholder _placeholder(Id assignmentId) {
    final matrix = matrixServer.matrix!;
    final assignment = matrix.assignments.firstWhere(
      (a) => a.id == assignmentId,
    );
    final score = _score[assignmentId];
    return ScorePlaceholder(
      id: _placeholderId(assignmentId),
      contestId: contestId,
      contestParticipationId: assignment.contestParticipationId,
      assignmentId: assignmentId,
      state: score != null
          ? ScorePlaceholderState.official
          : _inReview.contains(assignmentId)
          ? ScorePlaceholderState.inReview
          : _submitted.contains(assignmentId)
          ? ScorePlaceholderState.submitted
          : ScorePlaceholderState.notEntered,
      scoreRevision: score?.scoreRevision ?? 0,
      currentAttemptId: score?.scoreAttemptId,
      reviewClosedScoreRevision: _confirmed[assignmentId],
    );
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    final failure = readFailure;
    if (failure != null && request.method == 'GET') {
      return _json({
        'code': failure == 403 ? 'forbidden' : 'unavailable',
        'message': 'Not available.',
      }, failure);
    }
    if (request.method == 'GET' && path.endsWith('/landing-tables')) {
      if (noLandingTable) return _json({'landing_tables': []});
      return _json({
        'landing_tables': [
          {
            'table': LandingTable(
              id: _landingTableId,
              name: 'F5J standard',
              inputUnit: LandingInputUnit.meters,
              createdAt: DateTime.utc(2026),
            ).toJson(),
            'results': [
              for (final (i, (key, label, points)) in [
                ('within_1m', 'Within 1 m', 50),
                ('within_5m', 'Within 5 m', 30),
                ('within_10m', 'Within 10 m', 10),
              ].indexed)
                LandingResult(
                  id: _sid('000b', i + 1),
                  landingTableId: _landingTableId,
                  entryKey: key,
                  displayValue: label,
                  pointValue: points,
                  ordinalPosition: i,
                ).toJson(),
            ],
            'in_use': true,
          },
        ],
      });
    }
    if (request.method == 'GET' && path.endsWith('/scores/history')) {
      if (historyStatus != 200) {
        return _json({
          'error': {'code': 'rejected', 'message': 'No history for you.'},
        }, historyStatus);
      }
      final assignmentId = Id.parse(
        path.split('/')[path.split('/').length - 3],
      );
      return _json(
        ScoreHistory(
          assignmentId: assignmentId,
          entries: _history[assignmentId] ?? const [],
        ).toJson(),
      );
    }
    if (request.method == 'GET' && path.endsWith('/scores')) {
      if (failScoreReads) {
        return _json({
          'error': {'code': 'server_error', 'message': 'Failed.'},
        }, 500);
      }
      final matrix = matrixServer.matrix!;
      return _json({
        'scores': [
          for (final assignment in matrix.assignments)
            {
              'placeholder': _placeholder(assignment.id).toJson(),
              'official_score': _score[assignment.id]?.toJson(),
              'pending_attempt': _pendingAttempt(assignment.id)?.toJson(),
              'pending_promotion': _queued[assignment.id],
            },
        ],
        'rounds': const <Object>[],
      });
    }
    if (request.method == 'GET' && path.contains('/results/rounds/')) {
      return _json({
        'error': {'code': 'not_calculated', 'message': 'none'},
      }, 400);
    }
    if (request.method == 'POST' && path.endsWith('/scores/official')) {
      promoteRequests++;
      await holdPromote?.future;
      if (offlineOnEntry) {
        throw http.ClientException('offline', request.url);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (path.contains('/groups/')) {
        return _json({
          'outcomes': [
            for (final raw in body['items'] as List<dynamic>)
              () {
                final item = raw as Map<String, dynamic>;
                final id = Id.parse(item['assignment_id'] as String);
                final (status, answer) = _promote(
                  id,
                  item['source_attempt_id'] as String,
                  item['expected_score_revision'] as int,
                );
                return {
                  'assignment_id': id.value,
                  if (status == 200 || status == 201)
                    'result': answer
                  else if (status == 202)
                    'queued': answer['queued']
                  else
                    'error': (answer['error']! as Map<String, Object?>),
                };
              }(),
          ],
          'not_requested': <String>[],
          'recalculation_warning': null,
        });
      }
      promotedBodies.add(body);
      final segments = path.split('/');
      final (status, answer) = _promote(
        Id.parse(segments[segments.length - 3]),
        body['source_attempt_id'] as String,
        body['expected_score_revision'] as int,
      );
      if (status == 200 || status == 201 || status == 202) {
        return _json(answer, status);
      }
      final error = (answer['error']! as Map<String, Object?>);
      return _json({
        'error': {'code': error['code'], 'message': error['message']},
      }, status);
    }
    if (request.method == 'POST' && path.endsWith('/scores/bulk')) {
      entryRequests++;
      await holdBulk?.future;
      if (offlineOnEntry) {
        throw http.ClientException('offline', request.url);
      }
      if (bulkStatus != 200) {
        return _json({
          'error': {'code': 'not_found', 'message': 'No such route.'},
        }, bulkStatus);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _json({
        'results': [
          for (final raw in body['entries'] as List<dynamic>)
            _enter(
              Id.parse(
                (raw as Map<String, dynamic>)['assignment_id'] as String,
              ),
              raw,
              bulk: true,
            ).$2,
        ],
        'recalculation_warning': bulkWarning,
      });
    }
    if (request.method == 'POST' && path.endsWith('/scores')) {
      entryRequests++;
      if (offlineOnEntry) {
        throw http.ClientException('offline', request.url);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final segments = path.split('/');
      final assignmentId = Id.parse(segments[segments.length - 2]);
      final (status, answer) = _enter(assignmentId, body);
      return _json(answer, status);
    }
    return matrixServer.handle(request);
  }
}

/// Pumps [ContestScoringPage] against [server] in a window of [size].
Future<void> pumpScoringPage(
  WidgetTester tester,
  ScoringServer server, {
  Size size = const Size(1280, 1100),
  int? round,
  int? group,
  ContestScope? shell,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: contestScoringPath(
      matrixContestId,
      round: round,
      group: group,
    ),
    routes: [
      GoRoute(
        path: contestScoringPath(matrixContestId),
        builder: (context, state) {
          final page = Scaffold(
            body: ContestScoringPage(
              contestId: matrixContestId,
              round: int.tryParse(state.uri.queryParameters['round'] ?? ''),
              group: int.tryParse(state.uri.queryParameters['group'] ?? ''),
            ),
          );
          return shell == null
              ? page
              : ContestScope(
                  contest: shell.contest,
                  reload: shell.reload,
                  child: page,
                );
        },
      ),
      GoRoute(
        path: contestMatrixPath(matrixContestId),
        builder: (context, state) => const Text('Matrix stub'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
