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

/// Refuses the second automatic acceptance of a run, as a failure part way
/// through would.
class _FailsOnSecondPromotion extends OfficialScoreRepository {
  _FailsOnSecondPromotion(super.db);

  var _calls = 0;

  @override
  Future<core.PromotedScore> recordPromotion(
    core.PromotedScore promotion, {
    required core.MutationMetadata metadata,
  }) {
    if (++_calls == 2) throw StateError('second promotion refused');
    return super.recordPromotion(promotion, metadata: metadata);
  }
}

/// Refuses to store the recalculated results while [failing], as an
/// interruption between the acceptances and the results would.
class _FailsToStoreResults extends ResultsRepository {
  _FailsToStoreResults(super.db);

  var failing = true;

  @override
  Future<void> replaceResultsForContest(
    core.Id contestId,
    Iterable<core.FlightResult> flights,
    Iterable<core.ParticipationStanding> standings,
    Iterable<core.TeamStanding> teams,
  ) {
    if (failing) throw StateError('results not stored');
    return super.replaceResultsForContest(contestId, flights, standings, teams);
  }
}

class _NoResultsRepository extends Repository {
  _NoResultsRepository(super.database)
    : _results = _FailsToStoreResults(database);

  final _FailsToStoreResults _results;

  @override
  ResultsRepository get resultsRepository => _results;
}

class _FailingRepository extends Repository {
  _FailingRepository(super.database)
    : _official = _FailsOnSecondPromotion(database);

  final _FailsOnSecondPromotion _official;

  @override
  OfficialScoreRepository get officialScoreRepository => _official;
}

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
      expect((await submit(1, 1))['state'], 'submitted');
      expect((await submit(2, 1))['state'], 'submitted');
      await expectWaiting(1, 1);
      await expectWaiting(1, 2);
      // The pilot who completes the round is told the score is official.
      final last = await submit(3, 1);
      expect(last['state'], 'official');
      expect(last['revision'], 2);
      expect(last['entered_by'], 'P3 X');
      // A retry of any of the mutations sees the state the score has now.
      final retry = await submit(3, 1);
      expect(retry['state'], 'official');
      expect(retry['revision'], 2);
      final first = await submit(1, 1);
      expect(first['state'], 'official');
      expect(first['revision'], 2);
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

    test('a pilot who retires after submitting keeps the submission', () async {
      await submit(1, 1);
      Future<void> retire(int pilot) async {
        final participation = (await repository.contestParticipationRepository
            .findById(core.Id.parse(_participationId(pilot))))!;
        await repository.contestParticipationRepository.save(
          participation.withRetiredAtRound(1),
          metadata: core.MutationMetadata(
            clientMutationId: 'retire-$pilot',
            authority: core.Authority.director,
            clientTime: DateTime.utc(2026, 10, 17, 15),
            actorId: api.director,
          ),
        );
      }

      await retire(1);
      await retire(3);
      await submit(2, 1);
      await expectAutomatic(1, 1, core.automaticRoundCompleteReason);
      await expectAutomatic(1, 2, core.automaticRoundCompleteReason);
    });

    test('a failure part way keeps the submission and no acceptance', () async {
      await submit(1, 1);
      await submit(2, 1);
      final service = core.InvitationService(
        repository,
        core.InvitationCodec.fromText(_secret),
      );
      final access = await service.authorize(tokens[3]!, write: true);
      final failing = core.ScoresService(_FailingRepository(api.database));
      final stored = await failing.submitParticipantScore(
        access,
        1,
        clientMutationId: 'm-3-1',
        matrixRevision: matrixRevision,
        components: _score,
      );
      expect(stored.isOfficial, isFalse);
      expect(stored.revision, 1);
      // The first acceptance of the run was rolled back with the second.
      for (final pilot in [1, 2, 3]) {
        await expectWaiting(1, pilot);
      }
      // The next run, with working storage, accepts all three.
      final run = await scores.evaluateAutomaticOfficialization(
        core.Id.parse(_contestId),
      );
      expect(run.promoted, hasLength(3));
    });

    test('results that cannot be stored roll the acceptances back, and a '
        'repeat of the request finishes them', () async {
      await submit(1, 1);
      await submit(2, 1);
      final broken = _NoResultsRepository(api.database);
      final service = core.InvitationService(
        repository,
        core.InvitationCodec.fromText(_secret),
      );
      final access = await service.authorize(tokens[3]!, write: true);
      Future<core.ParticipantSubmission> third(core.Repository over) =>
          core.ScoresService(over).submitParticipantScore(
            access,
            1,
            clientMutationId: 'm-3-1',
            matrixRevision: matrixRevision,
            components: _score,
          );

      final first = await third(broken);
      expect(first.isOfficial, isFalse);
      expect(first.revision, 1);
      // No score is official and no standing was written: nothing is half
      // done, so the standings are not behind the official scores.
      for (final pilot in [1, 2, 3]) {
        await expectWaiting(1, pilot);
      }
      expect(
        await repository.flightResultRepository.listForContest(
          core.Id.parse(_contestId),
        ),
        isEmpty,
      );

      // The same request again, with working storage, finishes the job.
      broken._results.failing = false;
      final repeat = await third(broken);
      expect(repeat.replayed, isTrue);
      expect(repeat.isOfficial, isTrue);
      expect(repeat.revision, 2);
      for (final pilot in [1, 2, 3]) {
        await expectAutomatic(1, pilot, core.automaticRoundCompleteReason);
      }
      expect(
        await repository.flightResultRepository.listForContest(
          core.Id.parse(_contestId),
        ),
        hasLength(3),
      );
      final standings = await core.ResultsService(repository)
          .read(core.Id.parse(_contestId));
      expect(standings.isStale, isFalse);
      expect(standings.standings, hasLength(3));
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

  group('simultaneous submissions', () {
    setUp(() => open('EndOfGroup', groups: 3, pilots: 3));

    test('completing different groups together keeps every standing', () async {
      // Three groups of one pilot each: each submission completes its group.
      await Future.wait([submit(1, 1), submit(2, 1), submit(3, 1)]);
      for (final pilot in [1, 2, 3]) {
        await expectAutomatic(1, pilot, core.automaticGroupCompleteReason);
      }
      final flights = await repository.flightResultRepository.listForContest(
        core.Id.parse(_contestId),
      );
      expect(flights, hasLength(3));
      final standings = await core.ResultsService(repository)
          .read(core.Id.parse(_contestId));
      expect(standings.isStale, isFalse);
      expect(standings.standings, hasLength(3));
    });
  });

  group('other triggers', () {
    Future<void> expectBothAccepted(String reason) async {
      await expectAutomatic(1, 1, reason);
      await expectAutomatic(1, 2, reason);
    }

    test('a director bulk entry that completes the round accepts it', () async {
      await open('EndOfRound');
      await submit(1, 1);
      await submit(2, 1);
      final entered = await api.expectOk(
        'POST',
        '/contests/$_contestId/scores/bulk',
        body: {
          'entries': [
            {
              'assignment_id': assignmentOf(1, 3)['id'],
              'client_mutation_id': 'bulk-3',
              'base_score_revision': 0,
              'components': _score,
            },
          ],
        },
      );
      expect(entered['recalculation_warning'], isNull);
      await expectBothAccepted(core.automaticRoundCompleteReason);
      expect(
        (await officialOf(1, 3))!.selectionOrigin,
        core.SelectionOrigin.manual,
      );
    });

    test('a retirement that completes the round accepts it', () async {
      await open('EndOfRound');
      await submit(1, 1);
      await submit(2, 1);
      await expectWaiting(1, 1);
      final participation = (await repository.contestParticipationRepository
          .findById(core.Id.parse(_participationId(3))))!;
      await api.expectOk(
        'PUT',
        '/contests/$_contestId/participations/${_participationId(3)}',
        body: {'base_revision': participation.revision, 'retired_at_round': 1},
      );
      await expectBothAccepted(core.automaticRoundCompleteReason);
    });

    test(
      'moving the only unscored pilot out of a group completes it',
      () async {
        await open('EndOfGroup', groups: 2, pilots: 4);
        final roundOne = assignments
            .where((a) => a['scheduled_round_id'] == rounds[0]['id'])
            .toList();
        final inGroupOne = roundOne.where((a) => a['group'] == 1).toList();
        expect(inGroupOne, hasLength(2));
        int pilotOf(Map<String, Object?> a) => [1, 2, 3, 4].singleWhere(
          (n) => a['contest_participation_id'] == _participationId(n),
        );
        final scored = pilotOf(inGroupOne[0]);
        final mover = inGroupOne[1];
        await submit(scored, 1);
        await expectWaiting(1, scored);

        await api.expectOk(
          'POST',
          '/contests/$_contestId/matrix/assignments/${mover['id']}/moves',
          status: 201,
          body: {
            'id': '019c0000-0000-7000-8000-000000000613',
            'group': 2,
            'reason': 'Moved to the other group',
          },
        );

        await expectAutomatic(1, scored, core.automaticGroupCompleteReason);
      },
    );

    test('choosing the policy accepts the rounds already complete', () async {
      await open('Manual');
      for (final pilot in [1, 2, 3]) {
        await submit(pilot, 1);
      }
      // Nothing is official yet, only waiting.
      await expectWaiting(1, 1);
      await api.expectOk(
        'POST',
        '/contests/$_contestId/configuration',
        status: 201,
        body: {
          'base_revision_number': 1,
          'discipline_profile_id': core.SystemDisciplineProfiles.f5jId.value,
          'config': {
            'core': {'scores_become_official': 'EndOfRound'},
            'discipline': {'working_time': 600},
          },
        },
      );
      for (final pilot in [1, 2, 3]) {
        await expectAutomatic(1, pilot, core.automaticRoundCompleteReason);
      }
    });

    test('moving back to Manually undoes nothing', () async {
      await open('EndOfRound');
      for (final pilot in [1, 2, 3]) {
        await submit(pilot, 1);
      }
      await api.expectOk(
        'POST',
        '/contests/$_contestId/configuration',
        status: 201,
        body: {
          'base_revision_number': 1,
          'discipline_profile_id': core.SystemDisciplineProfiles.f5jId.value,
          'config': {
            'core': {'scores_become_official': 'Manual'},
            'discipline': {'working_time': 600},
          },
        },
      );
      await expectAutomatic(1, 1, core.automaticRoundCompleteReason);
    });

    test('recovery finds an evaluation a restart interrupted', () async {
      await open('EndOfRound');
      await submit(1, 1);
      await submit(2, 1);
      final broken = _NoResultsRepository(api.database);
      final access = await core.InvitationService(
        repository,
        core.InvitationCodec.fromText(_secret),
      ).authorize(tokens[3]!, write: true);
      // The last submission is stored, but its evaluation cannot finish.
      final stored = await core.ScoresService(broken).submitParticipantScore(
        access,
        1,
        clientMutationId: 'm-3-1',
        matrixRevision: matrixRevision,
        components: _score,
      );
      expect(stored.isOfficial, isFalse);
      for (final pilot in [1, 2, 3]) {
        await expectWaiting(1, pilot);
      }

      // The server starts again with working storage.
      expect(await scores.recoverAutomaticOfficialization(), 1);
      for (final pilot in [1, 2, 3]) {
        await expectAutomatic(1, pilot, core.automaticRoundCompleteReason);
      }
      // A second pass has nothing left to do.
      expect(await scores.recoverAutomaticOfficialization(), 0);
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
