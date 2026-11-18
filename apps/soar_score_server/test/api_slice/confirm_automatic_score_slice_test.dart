import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000031';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';

String _profileId(int n) => '019c0000-0000-7000-8000-00000000a2${_two(n)}';
String _participationId(int n) =>
    '019c0000-0000-7000-8000-00000000b3${_two(n)}';
String _two(int n) => n.toString().padLeft(2, '0');

const _score = {'time_flown': 540, 'launch_height': 45, 'landing': 'points_50'};

/// A director's confirmation of a score the contest accepted on its own,
/// through the mark-official route, over a real database.
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
  late core.ScoresService scores;
  late Handler handler;
  late int matrixRevision;
  late List<Map<String, Object?>> rounds;
  late List<Map<String, Object?>> assignments;
  final tokens = <int, String>{};

  Future<void> open(String? policy, {int groups = 1, int pilots = 3}) async {
    api = await SliceClient.open(backend);
    repository = Repository(api.database);
    scores = core.ScoresService(repository);
    final service = core.InvitationService(
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
          'core': <String, Object?>{'scores_become_official': ?policy},
          'discipline': {'working_time': 600},
        },
      },
    );
    for (var n = 1; n <= pilots; n++) {
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
        'id': '019c0000-0000-7000-8000-000000000512',
        'rounds': 2,
        'groups_per_round': groups,
        'random_seed': 7,
      },
    );
    rounds = (matrix['rounds']! as List).cast<Map<String, Object?>>();
    assignments = (matrix['assignments']! as List).cast<Map<String, Object?>>();
    matrixRevision =
        (await repository.matrixRevisionRepository.latestForContest(
          core.Id.parse(_contestId),
        ))!.revisionNumber;
    await api.expectOk(
      'POST',
      '/contests/$_contestId/actions',
      body: {
        'action': 'openScoring',
        'base_revision': (await api.expectOk(
          'GET',
          '/contests/$_contestId',
        ))['revision'],
      },
    );
    for (var n = 1; n <= pilots; n++) {
      final issued = await service.issue(
        contestId: core.Id.parse(_contestId),
        participationId: core.Id.parse(_participationId(n)),
        issuedBy: api.director,
        clientMutationId: 'issue-$n',
      );
      tokens[n] = (await service.resolve(issued.credential)).sessionToken;
    }
  }

  tearDown(() => api.close());

  Future<Map<String, Object?>> submit(int pilot, int round) async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/self-scoring/rounds/$round/scores'),
        body: jsonEncode({
          'client_mutation_id': 'm-$pilot-$round',
          'matrix_revision': matrixRevision,
          'components': _score,
        }),
        headers: {'authorization': 'Bearer ${tokens[pilot]}'},
      ),
    );
    final text = await response.readAsString();
    expect(response.statusCode, anyOf(200, 201), reason: text);
    return (jsonDecode(text) as Map<String, Object?>)['score']!
        as Map<String, Object?>;
  }

  Map<String, Object?> assignmentOf(int round, int pilot) =>
      assignments.singleWhere(
        (a) =>
            a['scheduled_round_id'] == rounds[round - 1]['id'] &&
            a['contest_participation_id'] == _participationId(pilot),
      );

  Future<core.ScorePlaceholder> placeholderOf(int round, int pilot) async =>
      (await repository.scorePlaceholderRepository.findForAssignment(
        core.Id.parse(assignmentOf(round, pilot)['id']! as String),
      ))!;

  Future<core.OfficialScore?> officialOf(int round, int pilot) async =>
      repository.officialScoreRepository.currentForPlaceholder(
        (await placeholderOf(round, pilot)).id,
      );

  Future<void> expectAutomatic(int round, int pilot, String reason) async {
    final placeholder = await placeholderOf(round, pilot);
    expect(placeholder.state, core.ScorePlaceholderState.official);
    expect(placeholder.scoreRevision, 2);
    final official = (await officialOf(round, pilot))!;
    expect(official.selectionOrigin, core.SelectionOrigin.automatic);
    expect(official.setBy, isNull);
    expect(official.reason, reason);
    expect(official.scoreRevision, 2);
    expect(official.components, _score);
    // It cites the pilot's own attempt, so authorship stays on record.
    final attempt = (await repository.scoreAttemptRepository.findById(
      official.scoreAttemptId,
    ))!;
    expect(attempt.authority, core.Authority.participant);
    expect(placeholder.isReviewClosed(official), isFalse);
  }

  group('confirming an automatic score', () {
    setUp(() => open('EndOfRound'));

    Future<SliceResponse> confirmRaw(int round, int pilot, int expected) async {
      final official = (await officialOf(round, pilot))!;
      return api.send(
        'POST',
        '/contests/$_contestId/assignments/${assignmentOf(round, pilot)['id']}/scores/official',
        body: {
          'source_attempt_id': official.scoreAttemptId.value,
          'expected_score_revision': expected,
        },
      );
    }

    Future<int> auditCount() async =>
        (await repository.auditEventRepository.listForContest(
          core.Id.parse(_contestId),
          action: core.AuditAction.scoreReview,
        )).length;

    Future<void> acceptRound() async {
      for (final pilot in [1, 2, 3]) {
        await submit(pilot, 1);
      }
      for (final pilot in [1, 2, 3]) {
        await expectAutomatic(1, pilot, core.automaticRoundCompleteReason);
      }
    }

    test('closes review and writes no second version', () async {
      await acceptRound();
      expect(
        (await placeholderOf(1, 1)).isReviewClosed(await officialOf(1, 1)),
        isFalse,
      );

      final response = await confirmRaw(1, 1, 1);

      expect(response.status, 201, reason: '${response.body}');
      expect(response.body['replayed'], isFalse);
      final placeholder = await placeholderOf(1, 1);
      final official = (await officialOf(1, 1))!;
      expect(placeholder.scoreRevision, 2);
      expect(placeholder.reviewClosedScoreRevision, 2);
      expect(placeholder.isReviewClosed(official), isTrue);
      expect(official.selectionOrigin, core.SelectionOrigin.automatic);
      expect(official.setBy, isNull);
      expect(
        await repository.officialScoreRepository.listForPlaceholder(
          placeholder.id,
        ),
        hasLength(1),
      );
      // The history still reads "accepted by the contest", and now closed.
      final entry = (await scores.history(
        core.Id.parse(_contestId),
        core.Id.parse(assignmentOf(1, 1)['id']! as String),
      )).entries.single;
      expect(entry.selectionOrigin, core.SelectionOrigin.automatic);
      expect(entry.actorId, isNull);
      expect(entry.reviewClosed, isTrue);
    });

    test('a repeat is a replay and changes nothing', () async {
      await acceptRound();
      await confirmRaw(1, 1, 1);
      final before = await placeholderOf(1, 1);

      final again = await confirmRaw(1, 1, 1);

      expect(again.status, 200, reason: '${again.body}');
      expect(again.body['replayed'], isTrue);
      expect((await placeholderOf(1, 1)).revision, before.revision);
    });

    for (final expected in [1, 2]) {
      test('a request naming revision $expected confirms once, then replays '
          'with nothing more written', () async {
        await acceptRound();
        final first = await confirmRaw(1, 2, expected);
        expect(first.status, 201, reason: '${first.body}');
        final slot = await placeholderOf(1, 2);
        final events = await auditCount();

        final again = await confirmRaw(1, 2, expected);

        expect(again.status, 200, reason: '${again.body}');
        expect(again.body['replayed'], isTrue);
        expect((await placeholderOf(1, 2)).revision, slot.revision);
        expect(slot.reviewClosedScoreRevision, 2);
        expect(
          await repository.officialScoreRepository.listForPlaceholder(slot.id),
          hasLength(1),
        );
        expect(await auditCount(), events);
      });
    }

    test(
      'a locked round refuses a fresh confirmation, writing nothing',
      () async {
        await acceptRound();
        final held = await placeholderOf(1, 1);
        final assignment = (await repository.matrixAssignmentRepository
            .findById(core.Id.parse(assignmentOf(1, 1)['id']! as String)))!;
        final round = (await repository.roundRepository.findById(
          assignment.scheduledRoundId,
        ))!;
        await repository.roundRepository.save(
          core.Round(
            id: round.id,
            contestId: round.contestId,
            matrixRevisionId: round.matrixRevisionId,
            ordinal: round.ordinal,
            groupCount: round.groupCount,
            status: core.RoundStatus.locked,
            revision: round.revision,
          ),
          metadata: core.MutationMetadata(
            clientMutationId: 'lock-round',
            authority: core.Authority.director,
            clientTime: DateTime.utc(2026, 10, 17, 16),
            actorId: api.director,
          ),
        );
        final events = await auditCount();

        final response = await confirmRaw(1, 1, 1);

        expect(response.status, 409, reason: '${response.body}');
        expect((response.body['error']! as Map)['code'], 'round_locked');
        expect((await placeholderOf(1, 1)).reviewClosedScoreRevision, isNull);
        expect((await placeholderOf(1, 1)).revision, held.revision);
        expect(await auditCount(), events);
      },
    );

    test('another revision is stale and stores nothing', () async {
      await acceptRound();
      final response = await confirmRaw(1, 1, 7);
      expect(response.status, 409, reason: '${response.body}');
      expect((await placeholderOf(1, 1)).reviewClosedScoreRevision, isNull);
    });

    test('a locked score is only replayed, nothing is written', () async {
      await acceptRound();
      final held = await placeholderOf(1, 1);
      await repository.scorePlaceholderRepository.save(
        core.ScorePlaceholder(
          id: held.id,
          contestId: held.contestId,
          contestParticipationId: held.contestParticipationId,
          assignmentId: held.assignmentId,
          state: held.state,
          scoreRevision: held.scoreRevision,
          currentAttemptId: held.currentAttemptId,
          lockedBy: api.director,
          lockedAt: DateTime.utc(2026, 10, 17, 16),
          revision: held.revision,
        ),
        metadata: core.MutationMetadata(
          clientMutationId: 'lock-1',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 17, 16),
          actorId: api.director,
        ),
      );
      final response = await confirmRaw(1, 1, 1);
      // Locking already closes review; the repeat reads state only.
      expect(response.status, 200, reason: '${response.body}');
      expect(response.body['replayed'], isTrue);
      expect((await placeholderOf(1, 1)).reviewClosedScoreRevision, isNull);
    });

    test('an open review is superseded and the confirmation audited', () async {
      await acceptRound();
      final held = await placeholderOf(1, 1);
      final review = core.ReviewRequest(
        id: core.Id.create(),
        contestId: held.contestId,
        scorePlaceholderId: held.id,
        proposedComponents: const {
          'time_flown': 500,
          'launch_height': 45,
          'landing': 'points_50',
        },
        requesterId: api.director,
        baseScoreRevision: held.scoreRevision,
        requestedAt: DateTime.utc(2026, 10, 17, 15),
      );
      await repository.reviewRequestRepository.save(
        review,
        metadata: core.MutationMetadata(
          clientMutationId: 'review-1',
          authority: core.Authority.participant,
          clientTime: DateTime.utc(2026, 10, 17, 15),
          actorId: api.director,
        ),
      );

      final response = await confirmRaw(1, 1, 1);

      expect(response.status, 201, reason: '${response.body}');
      final reviews = await repository.reviewRequestRepository
          .listForScorePlaceholder(held.id);
      expect(reviews.single.state, core.ReviewRequestState.superseded);
      final events = await repository.auditEventRepository.listForContest(
        core.Id.parse(_contestId),
        action: core.AuditAction.scoreReview,
      );
      final codes = [
        for (final e in events) (jsonDecode(e.reason!) as Map)['code'],
      ];
      expect(codes, contains(core.directorConfirmedAutomaticReason));
      expect(codes, contains(core.supersededByOfficialSelectionReason));
    });

    test('a later correction opens review again', () async {
      await acceptRound();
      await confirmRaw(1, 1, 1);
      final slot = core.Id.parse(assignmentOf(1, 1)['id']! as String);
      await scores.enterOfficialScore(
        core.Id.parse(_contestId),
        slot,
        clientMutationId: 'correct-1',
        baseScoreRevision: 2,
        components: const {
          'time_flown': 500,
          'launch_height': 45,
          'landing': 'points_50',
        },
        reason: 'stopwatch',
        actorId: api.director,
        metadata: core.MutationMetadata(
          clientMutationId: 'correct-1',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 17, 17),
          actorId: api.director,
        ),
      );
      final placeholder = await placeholderOf(1, 1);
      expect(placeholder.scoreRevision, 3);
      // A director's correction is itself the decision.
      expect(placeholder.isReviewClosed(await officialOf(1, 1)), isTrue);
    });
  });
}
