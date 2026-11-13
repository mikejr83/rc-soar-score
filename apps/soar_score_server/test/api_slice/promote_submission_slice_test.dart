import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000030';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';

String _profileId(int n) => '019c0000-0000-7000-8000-00000000a1${_two(n)}';
String _participationId(int n) =>
    '019c0000-0000-7000-8000-00000000b2${_two(n)}';
String _two(int n) => n.toString().padLeft(2, '0');

const _goodScore = {
  'time_flown': 540,
  'launch_height': 45,
  'landing': 'points_50',
};

/// Runs [before] ahead of, and [after] once behind, chosen reads of a slot's
/// placeholder (1-based), to make another request commit mid-operation.
class _HookedPlaceholders extends ScorePlaceholderRepository {
  _HookedPlaceholders(super.db);

  final before = <int, Future<void> Function()>{};
  final after = <int, Future<void> Function()>{};
  var _calls = 0;

  @override
  Future<core.ScorePlaceholder?> findForAssignment(core.Id assignmentId) async {
    final call = ++_calls;
    await before.remove(call)?.call();
    final found = await super.findForAssignment(assignmentId);
    await after.remove(call)?.call();
    return found;
  }
}

class _HookedRepository extends Repository {
  _HookedRepository(super.database, this.placeholders);

  final _HookedPlaceholders placeholders;

  @override
  core.ScorePlaceholderRepository get scorePlaceholderRepository =>
      placeholders;
}

/// A director adopting a pilot's submission as official, over a real
/// database.
void main() {
  final postgresMissing = PostgresConfig.fromEnvironment() == null;
  for (final backend in SliceBackend.values) {
    group(
      backend.name,
      () => _tests(backend),
      skip: backend == SliceBackend.postgres && postgresMissing
          ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD)'
          : false,
    );
  }
}

void _tests(SliceBackend backend) {
  late SliceClient api;
  late core.Repository repository;
  late core.InvitationService service;
  late Handler handler;
  late String token;
  late int matrixRevision;
  late List<Map<String, Object?>> rounds;
  late List<Map<String, Object?>> assignments;

  Future<void> contestAction(String action) async => api.expectOk(
    'POST',
    '/contests/$_contestId/actions',
    body: {
      'action': action,
      'base_revision': (await api.expectOk(
        'GET',
        '/contests/$_contestId',
      ))['revision'],
    },
  );

  setUp(() async {
    api = await SliceClient.open(backend);
    repository = Repository(api.database);
    service = core.InvitationService(
      repository,
      core.InvitationCodec.fromText(_secret),
    );
    handler = createServerHandler(
      api.database,
      authMiddleware: fixedPrincipal(Principal(accountId: api.director)),
      invitationSecret: _secret,
    );
    await api.expectOk(
      'POST',
      '/contests',
      status: 201,
      body: {
        'id': _contestId,
        'name': 'Spring Open',
        'start_date_time': '2026-10-17T14:00:00.000Z',
        'end_date_time': '2026-10-18T22:00:00.000Z',
        'timezone': 'America/Denver',
      },
    );
    await api.expectOk(
      'POST',
      '/contests/$_contestId/configuration',
      status: 201,
      body: {
        'base_revision_number': 0,
        'discipline_profile_id': core.SystemDisciplineProfiles.f5jId.value,
        'config': {
          'core': <String, Object?>{},
          'discipline': {'working_time': 600},
        },
      },
    );
    for (var n = 1; n <= 3; n++) {
      await api.expectOk(
        'POST',
        '/participants',
        status: 201,
        body: {'id': _profileId(n), 'first_name': 'P$n', 'last_name': 'X'},
      );
      await api.expectOk(
        'POST',
        '/contests/$_contestId/participations',
        status: 201,
        body: {
          'id': _participationId(n),
          'participant_profile_id': _profileId(n),
          'role_id': core.SystemRoles.pilotId.value,
        },
      );
    }
    final matrix = await api.expectOk(
      'POST',
      '/contests/$_contestId/matrix/draws',
      status: 201,
      body: {
        'id': '019c0000-0000-7000-8000-000000000502',
        'rounds': 3,
        'groups_per_round': 1,
        'random_seed': 7,
      },
    );
    rounds = (matrix['rounds']! as List).cast<Map<String, Object?>>();
    assignments = (matrix['assignments']! as List).cast<Map<String, Object?>>();
    matrixRevision =
        (await repository.matrixRevisionRepository.latestForContest(
          core.Id.parse(_contestId),
        ))!.revisionNumber;
    await contestAction('openScoring');
    final issued = await service.issue(
      contestId: core.Id.parse(_contestId),
      participationId: core.Id.parse(_participationId(1)),
      issuedBy: api.director,
      clientMutationId: 'issue-1',
    );
    token = (await service.resolve(issued.credential)).sessionToken;
  });
  tearDown(() => api.close());

  Future<(int, Map<String, Object?>)> submit(
    int round, {
    String mutation = 'm-1',
    Map<String, Object?> components = _goodScore,
    int? revision,
  }) async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/self-scoring/rounds/$round/scores'),
        body: jsonEncode({
          'client_mutation_id': mutation,
          'matrix_revision': revision ?? matrixRevision,
          'components': components,
        }),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    final text = await response.readAsString();
    return (response.statusCode, jsonDecode(text) as Map<String, Object?>);
  }

  Future<core.ScorePlaceholder> placeholderOf(int round, int pilot) async {
    final slot = assignments.singleWhere(
      (a) =>
          a['scheduled_round_id'] == rounds[round - 1]['id'] &&
          a['contest_participation_id'] == _participationId(pilot),
    );
    return (await repository.scorePlaceholderRepository.findForAssignment(
      core.Id.parse(slot['id']! as String),
    ))!;
  }

  late core.ScoresService scores;
  late core.Id slotId;
  late core.Id attemptId;

  core.MutationMetadata meta(String id) => core.MutationMetadata(
    clientMutationId: id,
    authority: core.Authority.director,
    clientTime: DateTime.utc(2026, 10, 17, 16),
    actorId: api.director,
  );

  Future<void> submitFirst() async {
    scores = core.ScoresService(repository);
    final (status, body) = await submit(1);
    expect(status, 201, reason: '$body');
    final placeholder = await placeholderOf(1, 1);
    slotId = placeholder.assignmentId;
    attemptId = placeholder.currentAttemptId!;
  }

  Future<core.ScorePromotionResult> promote({
    String id = 'p-1',
    int? expected,
    core.Id? source,
  }) => scores.promoteSubmission(
    core.Id.parse(_contestId),
    slotId,
    sourceAttemptId: source ?? attemptId,
    expectedScoreRevision: expected ?? 1,
    actorId: api.director,
    metadata: meta(id),
  );

  test('a submission becomes official and keeps its source', () async {
    await submitFirst();
    final result = await promote();

    expect(result.replayed, isFalse);
    final official = result.entry.officialScore;
    expect(official.scoreAttemptId, attemptId);
    expect(official.scoreRevision, 2);
    expect(official.components, _goodScore);
    expect(official.setBy, api.director);
    expect(official.reason, core.directorAcceptedSubmissionReason);
    final placeholder = await placeholderOf(1, 1);
    expect(placeholder.state, core.ScorePlaceholderState.official);
    expect(placeholder.scoreRevision, 2);
    expect(placeholder.currentAttemptId, attemptId);
    // The pilot's attempt stays the only attempt; nothing was re-entered.
    expect(
      await repository.scoreAttemptRepository.listForPlaceholder(
        placeholder.id,
      ),
      hasLength(1),
    );
    expect(
      (await repository.officialScoreRepository.listForPlaceholder(
        placeholder.id,
      )),
      hasLength(1),
    );
  });

  test('a retry of the same adoption is a replay and stores nothing', () async {
    await submitFirst();
    final first = await promote();
    final again = await promote(id: 'p-2');

    expect(again.replayed, isTrue);
    expect(again.entry.officialScore.id, first.entry.officialScore.id);
    final placeholder = await placeholderOf(1, 1);
    expect(placeholder.scoreRevision, 2);
    expect(
      await repository.officialScoreRepository.listForPlaceholder(
        placeholder.id,
      ),
      hasLength(1),
    );
  });

  test('a wrong revision or source is stale', () async {
    await submitFirst();
    await expectLater(
      promote(expected: 0),
      throwsA(isA<core.StaleRevisionError>()),
    );
    await expectLater(
      promote(source: core.Id.create()),
      throwsA(isA<core.StaleRevisionError>()),
    );
    expect(
      (await placeholderOf(1, 1)).state,
      core.ScorePlaceholderState.submitted,
    );
  });

  test('a later director correction is never overwritten by a retry', () async {
    await submitFirst();
    await promote();
    await api.expectOk(
      'POST',
      '/contests/$_contestId/assignments/${slotId.value}/scores',
      status: 201,
      body: {
        'client_mutation_id': 'director-fix',
        'base_score_revision': 2,
        'components': {..._goodScore, 'time_flown': 500},
        'reason': 'Checked the logger',
      },
    );

    await expectLater(
      promote(id: 'p-3'),
      throwsA(isA<core.StaleRevisionError>()),
    );
    final current = await repository.officialScoreRepository
        .currentForPlaceholder((await placeholderOf(1, 1)).id);
    expect(current!.components['time_flown'], 500);
  });

  test('a locked round, group or score refuses the adoption', () async {
    await submitFirst();
    final slot = await repository.matrixAssignmentRepository.findById(slotId);
    final round = await repository.roundRepository.findById(
      slot!.scheduledRoundId,
    );
    await repository.roundRepository.save(
      core.Round(
        id: round!.id,
        contestId: round.contestId,
        matrixRevisionId: round.matrixRevisionId,
        ordinal: round.ordinal,
        groupCount: round.groupCount,
        status: core.RoundStatus.locked,
        revision: round.revision,
      ),
      metadata: meta('lock-round'),
    );
    await expectLater(
      promote(),
      throwsA(
        isA<core.ContestStateError>().having(
          (e) => e.code,
          'code',
          'round_locked',
        ),
      ),
    );
    expect(
      (await placeholderOf(1, 1)).state,
      core.ScorePlaceholderState.submitted,
    );
  });

  test('an open review is superseded without applying its proposal', () async {
    await submitFirst();
    final placeholder = await placeholderOf(1, 1);
    final review = await repository.reviewRequestRepository.save(
      core.ReviewRequest(
        id: core.Id.create(),
        contestId: core.Id.parse(_contestId),
        scorePlaceholderId: placeholder.id,
        proposedComponents: {..._goodScore, 'time_flown': 560},
        requesterId: api.director,
        baseScoreRevision: 1,
        requestedAt: DateTime.utc(2026, 10, 17, 15),
      ),
      metadata: meta('review-1'),
    );

    final result = await promote();

    expect(result.entry.officialScore.components, _goodScore);
    final stored = (await repository.reviewRequestRepository.findById(
      review.id,
    ))!;
    expect(stored.state, core.ReviewRequestState.superseded);
    expect(stored.decisionActorId, api.director);
    expect(stored.decisionMessage, core.supersededByOfficialSelectionReason);
    expect(stored.resultingAttemptId, isNull);
    expect(stored.proposedComponents['time_flown'], 560);
    expect(
      await repository.reviewRequestRepository.findOpenForScorePlaceholder(
        placeholder.id,
      ),
      isNull,
    );
  });

  test(
    'overlapping identical requests agree: one adopts, one replays',
    () async {
      await submitFirst();
      final results = await Future.wait([
        promote(id: 'race-1'),
        promote(id: 'race-2'),
        promote(id: 'race-3'),
      ]);

      expect(results.where((r) => !r.replayed), hasLength(1));
      expect(results.where((r) => r.replayed), hasLength(2));
      expect({for (final r in results) r.entry.officialScore.id}, hasLength(1));
      final placeholder = await placeholderOf(1, 1);
      expect(
        await repository.officialScoreRepository.listForPlaceholder(
          placeholder.id,
        ),
        hasLength(1),
      );
    },
  );

  group('another request commits mid-operation', () {
    late _HookedPlaceholders hooks;
    late core.ScoresService racing;

    setUp(() async {
      await submitFirst();
      hooks = _HookedPlaceholders(api.database);
      racing = core.ScoresService(_HookedRepository(api.database, hooks));
    });

    Future<core.ScorePromotionResult> retry() => racing.promoteSubmission(
      core.Id.parse(_contestId),
      slotId,
      sourceAttemptId: attemptId,
      expectedScoreRevision: 1,
      actorId: api.director,
      metadata: meta('retry'),
    );

    test('after the placeholder read, a retry still replays', () async {
      hooks.after[1] = () async {
        await promote(id: 'winner');
      };

      final result = await retry();

      expect(result.replayed, isTrue);
      expect(
        result.entry.placeholder.state,
        core.ScorePlaceholderState.official,
      );
      expect(result.entry.placeholder.scoreRevision, 2);
    });

    test('before the slot gate, a retry replays instead of 409', () async {
      hooks.before[2] = () async {
        await promote(id: 'winner');
      };

      final result = await retry();

      expect(result.replayed, isTrue);
      expect(
        result.entry.placeholder.state,
        core.ScorePlaceholderState.official,
      );
    });

    test('a competing director entry makes the promotion stale', () async {
      hooks.after[2] = () async {
        await scores.enterOfficialScore(
          core.Id.parse(_contestId),
          slotId,
          clientMutationId: 'director-wins',
          baseScoreRevision: 1,
          components: {..._goodScore, 'time_flown': 500},
          reason: 'Checked the logger',
          actorId: api.director,
          metadata: meta('director-wins'),
        );
      };

      await expectLater(retry(), throwsA(isA<core.StaleRevisionError>()));
      final current = await repository.officialScoreRepository
          .currentForPlaceholder((await placeholderOf(1, 1)).id);
      expect(current!.components['time_flown'], 500);
      expect(current.scoreAttemptId, isNot(attemptId));
    });
  });

  group('a whole group over HTTP', () {
    Future<core.ScorePlaceholder> submitAs(int pilot) async {
      final issued = await service.issue(
        contestId: core.Id.parse(_contestId),
        participationId: core.Id.parse(_participationId(pilot)),
        issuedBy: api.director,
        clientMutationId: 'issue-p$pilot',
      );
      final pilotToken = (await service.resolve(issued.credential))
          .sessionToken;
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/v1/self-scoring/rounds/1/scores'),
          body: jsonEncode({
            'client_mutation_id': 'm-p$pilot',
            'matrix_revision': matrixRevision,
            'components': _goodScore,
          }),
          headers: {'authorization': 'Bearer $pilotToken'},
        ),
      );
      expect(response.statusCode, 201, reason: await response.readAsString());
      return placeholderOf(1, pilot);
    }

    Map<String, Object?> item(core.ScorePlaceholder p, {int? revision}) => {
      'assignment_id': p.assignmentId.value,
      'source_attempt_id': p.currentAttemptId!.value,
      'expected_score_revision': revision ?? p.scoreRevision,
    };

    Future<SliceResponse> promoteGroup(List<Map<String, Object?>> items) {
      return api.send(
        'POST',
        '/contests/$_contestId/rounds/${rounds[0]['id']}/groups/1/scores/official',
        body: {'items': items},
      );
    }

    test('adopts the named rows and leaves the others alone', () async {
      final one = await submitAs(1);
      final two = await submitAs(2);
      final three = await submitAs(3);

      final response = await promoteGroup([item(one), item(two)]);

      expect(response.status, 200, reason: '${response.body}');
      final outcomes = (response.body['outcomes']! as List).cast<Map>();
      expect(outcomes, hasLength(2));
      expect(outcomes.every((o) => o['result'] != null), isTrue);
      expect((response.body['not_requested']! as List), [
        three.assignmentId.value,
      ]);
      expect(
        (await placeholderOf(1, 1)).state,
        core.ScorePlaceholderState.official,
      );
      expect(
        (await placeholderOf(1, 2)).state,
        core.ScorePlaceholderState.official,
      );
      expect(
        (await placeholderOf(1, 3)).state,
        core.ScorePlaceholderState.submitted,
      );
    });

    test(
      'a stale row is refused alone and a repeat replays the rest',
      () async {
        final one = await submitAs(1);
        final two = await submitAs(2);

        final response = await promoteGroup([
          item(one),
          item(two, revision: 0),
        ]);

        final outcomes = (response.body['outcomes']! as List).cast<Map>();
        expect(outcomes[0]['result'], isNotNull);
        expect((outcomes[1]['error']! as Map)['status'], 409);
        expect((outcomes[1]['error']! as Map)['code'], 'stale_revision');
        expect(
          (await placeholderOf(1, 2)).state,
          core.ScorePlaceholderState.submitted,
        );

        final again = await promoteGroup([item(one), item(two)]);
        final repeated = (again.body['outcomes']! as List).cast<Map>();
        expect((repeated[0]['result']! as Map)['replayed'], true);
        expect((repeated[1]['result']! as Map)['replayed'], false);
      },
    );

    test('a malformed source id is refused alone', () async {
      final one = await submitAs(1);
      final two = await submitAs(2);

      final response = await promoteGroup([
        item(one),
        {...item(two), 'source_attempt_id': 'not-a-uuid'},
      ]);

      expect(response.status, 200, reason: '${response.body}');
      final outcomes = (response.body['outcomes']! as List).cast<Map>();
      expect(outcomes[0]['result'], isNotNull);
      expect((outcomes[1]['error']! as Map)['status'], 400);
      expect((outcomes[1]['error']! as Map)['code'], 'invalid_request');
      expect(
        (await placeholderOf(1, 1)).state,
        core.ScorePlaceholderState.official,
      );
      expect(
        (await placeholderOf(1, 2)).state,
        core.ScorePlaceholderState.submitted,
      );
    });

    test(
      'a repeated, foreign or missing slot is 400 and stores nothing',
      () async {
        final one = await submitAs(1);
        expect((await promoteGroup([item(one), item(one)])).status, 400);
        expect((await promoteGroup([])).status, 400);
        final foreign = {
          ...item(one),
          'assignment_id': assignments.firstWhere(
            (a) => a['scheduled_round_id'] == rounds[1]['id'],
          )['id'],
        };
        expect((await promoteGroup([foreign])).status, 400);
        expect(
          (await placeholderOf(1, 1)).state,
          core.ScorePlaceholderState.submitted,
        );
      },
    );
  });

  group('over HTTP', () {
    Future<Map<String, Object?>> post(
      Map<String, Object?> body, {
      int status = 201,
    }) => api.expectOk(
      'POST',
      '/contests/$_contestId/assignments/${slotId.value}/scores/official',
      status: status,
      body: body,
    );

    test('marks the submission official, then answers a repeat 200', () async {
      await submitFirst();
      final body = {
        'source_attempt_id': attemptId.value,
        'expected_score_revision': 1,
      };

      final first = await post(body);
      expect(first['replayed'], false);
      expect(
        (first['official_score']! as Map)['score_attempt_id'],
        attemptId.value,
      );
      expect((first['placeholder']! as Map)['state'], 'Official');

      final again = await post(body, status: 200);
      expect(again['replayed'], true);
      expect(
        (again['official_score']! as Map)['id'],
        (first['official_score']! as Map)['id'],
      );
    });

    test(
      'a fractional or non-numeric revision is 400 and stores nothing',
      () async {
        await submitFirst();
        for (final revision in <Object>[1.9, '1', true]) {
          final response = await api.send(
            'POST',
            '/contests/$_contestId/assignments/${slotId.value}/scores/official',
            body: {
              'source_attempt_id': attemptId.value,
              'expected_score_revision': revision,
            },
          );
          expect(response.status, 400, reason: '$revision');
        }
        expect(
          (await placeholderOf(1, 1)).state,
          core.ScorePlaceholderState.submitted,
        );
      },
    );

    test('a stale revision is 409 and stores nothing', () async {
      await submitFirst();
      final response = await api.send(
        'POST',
        '/contests/$_contestId/assignments/${slotId.value}/scores/official',
        body: {
          'source_attempt_id': attemptId.value,
          'expected_score_revision': 0,
        },
      );
      expect(response.status, 409);
      expect(
        (await placeholderOf(1, 1)).state,
        core.ScorePlaceholderState.submitted,
      );
    });
  });
}
