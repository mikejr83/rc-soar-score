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

/// The contest accepting participant submissions on its own ("Scores become
/// official"), over a real database through the participant route.
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

  Future<int> submit(int pilot, int round) async {
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
    expect(response.statusCode, 201, reason: await response.readAsString());
    return response.statusCode;
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

  Future<void> expectWaiting(int round, int pilot) async {
    expect(
      (await placeholderOf(round, pilot)).state,
      core.ScorePlaceholderState.submitted,
      reason: 'pilot $pilot, round $round',
    );
    expect(await officialOf(round, pilot), isNull);
  }

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

  group('at the end of the round', () {
    setUp(() => open('EndOfRound'));

    test('the submission that completes the round accepts all of it', () async {
      await submit(1, 1);
      await submit(2, 1);
      await expectWaiting(1, 1);
      await expectWaiting(1, 2);
      await submit(3, 1);
      for (final pilot in [1, 2, 3]) {
        await expectAutomatic(1, pilot, core.automaticRoundCompleteReason);
      }
      // The next round is untouched.
      expect(await officialOf(2, 1), isNull);
      // The results see the accepted scores.
      final listed = await api.expectOk('GET', '/contests/$_contestId/scores');
      final official = (listed['scores']! as List)
          .cast<Map<String, Object?>>()
          .where((s) => s['official_score'] != null);
      expect(official, hasLength(3));
    });

    test('running the evaluator again changes nothing', () async {
      for (final pilot in [1, 2, 3]) {
        await submit(pilot, 1);
      }
      final again = await scores.evaluateAutomaticOfficialization(
        core.Id.parse(_contestId),
      );
      expect(again.promoted, isEmpty);
      await expectAutomatic(1, 1, core.automaticRoundCompleteReason);
    });

    test('a director-entered score completes the round for the rest', () async {
      await submit(1, 1);
      await submit(2, 1);
      final slot = core.Id.parse(assignmentOf(1, 3)['id']! as String);
      await scores.enterOfficialScore(
        core.Id.parse(_contestId),
        slot,
        clientMutationId: 'director-3',
        baseScoreRevision: 0,
        components: _score,
        actorId: api.director,
        metadata: core.MutationMetadata(
          clientMutationId: 'director-3',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 17, 15),
          actorId: api.director,
        ),
      );
      final run = await scores.evaluateAutomaticOfficialization(
        core.Id.parse(_contestId),
      );
      expect(run.promoted, hasLength(2));
      await expectAutomatic(1, 1, core.automaticRoundCompleteReason);
      await expectAutomatic(1, 2, core.automaticRoundCompleteReason);
      // The director's own score is not replaced.
      expect(
        (await officialOf(1, 3))!.selectionOrigin,
        core.SelectionOrigin.manual,
      );
    });

    test('a pilot who retired without a score is not waited for', () async {
      final participation = (await repository.contestParticipationRepository
          .findById(core.Id.parse(_participationId(3))))!;
      await repository.contestParticipationRepository.save(
        participation.withRetiredAtRound(1),
        metadata: core.MutationMetadata(
          clientMutationId: 'retire-3',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 17, 15),
          actorId: api.director,
        ),
      );
      await submit(1, 1);
      await expectWaiting(1, 1);
      await submit(2, 1);
      await expectAutomatic(1, 1, core.automaticRoundCompleteReason);
      await expectAutomatic(1, 2, core.automaticRoundCompleteReason);
    });

    test('a slot with an open review is held, the rest accepted', () async {
      await submit(1, 1);
      await submit(2, 1);
      final held = await placeholderOf(1, 1);
      final meta = core.MutationMetadata(
        clientMutationId: 'review-1',
        authority: core.Authority.participant,
        clientTime: DateTime.utc(2026, 10, 17, 15),
        actorId: api.director,
      );
      await repository.reviewRequestRepository.save(
        core.ReviewRequest(
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
        ),
        metadata: meta,
      );
      final fresh = (await repository.scorePlaceholderRepository.findById(
        held.id,
      ))!;
      await repository.scorePlaceholderRepository.save(
        core.ScorePlaceholder(
          id: held.id,
          contestId: held.contestId,
          contestParticipationId: held.contestParticipationId,
          assignmentId: held.assignmentId,
          state: core.ScorePlaceholderState.inReview,
          scoreRevision: held.scoreRevision,
          currentAttemptId: held.currentAttemptId,
          revision: fresh.revision,
        ),
        metadata: core.MutationMetadata(
          clientMutationId: 'review-state-1',
          authority: core.Authority.participant,
          clientTime: DateTime.utc(2026, 10, 17, 15),
          actorId: api.director,
        ),
      );

      await submit(3, 1);
      await expectAutomatic(1, 2, core.automaticRoundCompleteReason);
      await expectAutomatic(1, 3, core.automaticRoundCompleteReason);
      final still = await placeholderOf(1, 1);
      expect(still.state, core.ScorePlaceholderState.inReview);
      expect(await officialOf(1, 1), isNull);
      // The review itself is untouched.
      final reviews = await repository.reviewRequestRepository
          .listForScorePlaceholder(held.id);
      expect(reviews.single.isOpen, isTrue);
      expect(reviews.single.state, core.ReviewRequestState.submitted);
    });

    test('a locked slot is left as it is', () async {
      await submit(1, 1);
      await submit(2, 1);
      final slot = await placeholderOf(1, 1);
      await repository.scorePlaceholderRepository.save(
        core.ScorePlaceholder(
          id: slot.id,
          contestId: slot.contestId,
          contestParticipationId: slot.contestParticipationId,
          assignmentId: slot.assignmentId,
          state: slot.state,
          scoreRevision: slot.scoreRevision,
          currentAttemptId: slot.currentAttemptId,
          lockedBy: api.director,
          lockedAt: DateTime.utc(2026, 10, 17, 15),
          revision: slot.revision,
        ),
        metadata: core.MutationMetadata(
          clientMutationId: 'lock-1',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 17, 15),
          actorId: api.director,
        ),
      );
      await submit(3, 1);
      await expectWaiting(1, 1);
      await expectAutomatic(1, 2, core.automaticRoundCompleteReason);
      await expectAutomatic(1, 3, core.automaticRoundCompleteReason);
    });
  });

  group('at the end of the group', () {
    setUp(() => open('EndOfGroup', groups: 2));

    test('a finished group is accepted while the other still flies', () async {
      final round = rounds[0]['id'];
      final inGroup = <int, List<int>>{};
      for (var pilot = 1; pilot <= 3; pilot++) {
        final group = assignmentOf(1, pilot)['group']! as int;
        inGroup.putIfAbsent(group, () => []).add(pilot);
      }
      expect(round, isNotNull);
      final small = inGroup.values.reduce(
        (a, b) => a.length <= b.length ? a : b,
      );
      final large = inGroup.values.reduce(
        (a, b) => a.length > b.length ? a : b,
      );
      expect(small.length, lessThan(large.length));

      await submit(large.first, 1);
      await expectWaiting(1, large.first);
      for (final pilot in small) {
        await submit(pilot, 1);
      }
      for (final pilot in small) {
        await expectAutomatic(1, pilot, core.automaticGroupCompleteReason);
      }
      await expectWaiting(1, large.first);
      for (final pilot in large.skip(1)) {
        await submit(pilot, 1);
      }
      for (final pilot in large) {
        await expectAutomatic(1, pilot, core.automaticGroupCompleteReason);
      }
    });
  });

  group('manually', () {
    for (final policy in <String?>['Manual', null]) {
      test(
        '${policy ?? 'no stored setting'} never accepts on its own',
        () async {
          await open(policy);
          for (final pilot in [1, 2, 3]) {
            await submit(pilot, 1);
          }
          for (final pilot in [1, 2, 3]) {
            await expectWaiting(1, pilot);
          }
          final run = await scores.evaluateAutomaticOfficialization(
            core.Id.parse(_contestId),
          );
          expect(run.promoted, isEmpty);
        },
      );
    }
  });
}
