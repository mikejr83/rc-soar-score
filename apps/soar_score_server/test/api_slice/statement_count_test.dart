@Timeout(Duration(minutes: 10))
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'slice_client.dart';
import 'statement_counter.dart';

const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';

/// How many statements the results and score reads run on contests the size
/// of the biggest real ones (#839).
///
/// Every statement is a network round trip to the hosted database, so the
/// statement count, not the response time, is what grows with a contest. The
/// budgets are deterministic counts; nothing here measures time. They are
/// ceilings with a little room, not exact values: lower one when a change
/// makes a read cheaper.
///
/// A contest is seeded through the services only for what has no bulk path
/// (the contest, its pilots and the draw); every score is written straight to
/// the tables in one transaction, so the large fixtures stay quick.
void main() {
  final postgresMissing = PostgresConfig.fromEnvironment() == null;
  for (final backend in SliceBackend.values) {
    group(
      backend.name,
      () {
        _size(backend, name: 'xtra-large', pilots: 100, rounds: 8, groups: 10);
        _size(backend, name: 'large', pilots: 50, rounds: 15, groups: 5);
      },
      skip: backend == SliceBackend.postgres && postgresMissing
          ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD)'
          : false,
    );
  }
}

void _size(
  SliceBackend backend, {
  required String name,
  required int pilots,
  required int rounds,
  required int groups,
}) {
  group('$name ($pilots pilots x $rounds rounds)', () {
    late SliceClient api;
    late core.Repository repository;
    late Handler participantHandler;
    late core.InvitationService invitations;
    late core.Id contestId;
    late core.Id firstPilot;
    final counter = StatementCounter();

    setUpAll(() async {
      api = await SliceClient.open(backend, interceptor: counter);
      repository = Repository(api.database);
      invitations = core.InvitationService(
        repository,
        core.InvitationCodec.fromText(_secret),
      );
      participantHandler = createServerHandler(
        api.database,
        authMiddleware: fixedPrincipal(Principal(accountId: api.director)),
        invitationSecret: _secret,
      );
      contestId = core.Id.create();
      firstPilot = await _seed(
        api,
        repository,
        contestId,
        pilots: pilots,
        rounds: rounds,
        groups: groups,
      );
    });

    tearDownAll(() => api.close());

    /// Runs [body] and returns the statements it took, printing the count so
    /// a budget can be set from a real run.
    Future<int> counted(String label, Future<void> Function() body) async {
      counter.reset();
      await body();
      final n = counter.count;
      // ignore: avoid_print
      print('[$name/${backend.name}] $label: $n statements');
      return n;
    }

    void within(int used, int budget, String label) => expect(
      used,
      lessThanOrEqualTo(budget),
      reason:
          '$label ran $used statements, over its budget of $budget:\n'
          '${counter.statements.take(40).join('\n')}',
    );

    Future<Map<String, Object?>> get(
      Handler handler,
      String path, {
      String? token,
    }) async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost$path'),
          headers: {if (token != null) 'authorization': 'Bearer $token'},
        ),
      );
      final text = await response.readAsString();
      expect(response.statusCode, 200, reason: '$path: $text');
      return jsonDecode(text) as Map<String, Object?>;
    }

    test('the score list', () async {
      final used = await counted(
        'GET scores',
        () => get(
          participantHandler,
          '/api/v1/contests/${contestId.value}/scores',
        ),
      );
      within(used, _budgetScores(rounds), 'GET scores');
    });

    test('the stored results and a single round', () async {
      final read = await counted(
        'GET results',
        () => get(
          participantHandler,
          '/api/v1/contests/${contestId.value}/results',
        ),
      );
      within(read, _budgetStored, 'GET results');
      final round = await counted(
        'GET results/rounds/1',
        () => get(
          participantHandler,
          '/api/v1/contests/${contestId.value}/results/rounds/1',
        ),
      );
      within(round, _budgetStored, 'GET results/rounds/1');
    });

    test('the pilot\'s group and overall results', () async {
      final issued = await invitations.issue(
        contestId: contestId,
        participationId: firstPilot,
        issuedBy: api.director,
        clientMutationId: 'issue-count',
      );
      final token = (await invitations.resolve(issued.credential)).sessionToken;
      late Map<String, Object?> groupBody;
      final group = await counted('self-scoring group results', () async {
        groupBody = await get(
          participantHandler,
          '/api/v1/self-scoring/rounds/1/group-results',
          token: token,
        );
      });
      expect(groupBody['rows'], hasLength(pilots ~/ groups));
      within(group, _budgetPilotResults(rounds), 'group results');
      late Map<String, Object?> overallBody;
      final overall = await counted('self-scoring overall results', () async {
        overallBody = await get(
          participantHandler,
          '/api/v1/self-scoring/results',
          token: token,
        );
      });
      expect(overallBody['standings'], hasLength(pilots));
      within(overall, _budgetPilotResults(rounds), 'overall results');
    });
  });
}

// Measured 2026-11-10 after batching (xtra-large 100x8 / large 50x15):
// scores 16 / 23, stored results 7-9, pilot group results 33 / 40, overall
// 30 / 37. Before batching the same reads ran 760-2,030 statements.
int _budgetScores(int rounds) => rounds + 12;
const _budgetStored = 12;
int _budgetPilotResults(int rounds) => rounds + 28;

/// Creates the contest, its [pilots] and the draw through the API, then
/// writes the scores straight to the tables. Returns the first pilot's
/// participation.
Future<core.Id> _seed(
  SliceClient api,
  core.Repository repository,
  core.Id contestId, {
  required int pilots,
  required int rounds,
  required int groups,
}) async {
  await api.expectOk(
    'POST',
    '/contests',
    status: 201,
    body: {
      'id': contestId.value,
      'name': 'Big Open',
      'start_date_time': '2026-10-17T14:00:00.000Z',
      'end_date_time': '2026-10-18T22:00:00.000Z',
      'timezone': 'America/Denver',
    },
  );
  await api.expectOk(
    'POST',
    '/contests/${contestId.value}/configuration',
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
  core.Id? first;
  for (var n = 0; n < pilots; n++) {
    final profile = core.Id.create();
    final participation = core.Id.create();
    first ??= participation;
    await api.expectOk(
      'POST',
      '/participants',
      status: 201,
      body: {
        'id': profile.value,
        'first_name': 'Pilot$n',
        'last_name': 'Rivera',
      },
    );
    await api.expectOk(
      'POST',
      '/contests/${contestId.value}/participations',
      status: 201,
      body: {
        'id': participation.value,
        'participant_profile_id': profile.value,
        'role_id': core.SystemRoles.pilotId.value,
      },
    );
  }
  await api.expectOk(
    'POST',
    '/contests/${contestId.value}/matrix/draws',
    status: 201,
    body: {
      'id': core.Id.create().value,
      'rounds': rounds,
      'groups_per_round': groups,
      'random_seed': 7,
    },
  );
  await _scoreFlights(api, repository, contestId);
  await core.ResultsService(repository).recalculate(contestId);
  return first!;
}

/// Gives every flight of all but the last round an official score, and the
/// last round a mix: official, a pilot's submitted attempt only, unscored.
Future<void> _scoreFlights(
  SliceClient api,
  core.Repository repository,
  core.Id contestId,
) async {
  final revision = (await repository.contestConfigurationRevisionRepository
      .latestForContest(contestId))!;
  final matrix = (await repository.matrixRevisionRepository.latestForContest(
    contestId,
  ))!;
  final rounds =
      (await repository.roundRepository.listForContest(contestId))
          .where((round) => round.isCurrent)
          .toList()
        ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
  final placeholders = {
    for (final p in await repository.scorePlaceholderRepository.listForContest(
      contestId,
    ))
      p.assignmentId: p,
  };
  final stores = EntityStores.forDatabase(api.database);
  final writes = <(String, Map<String, Object?>)>[];
  final at = DateTime.utc(2026, 10, 17, 15);
  var n = 0;
  for (final round in rounds) {
    final last = round.ordinal == rounds.length;
    for (final assignment
        in await repository.matrixAssignmentRepository.listLiveForRound(
          round.id,
        )) {
      final placeholder = placeholders[assignment.id]!;
      final kind = !last ? 0 : n % 3;
      n++;
      if (kind == 2) continue;
      final components = <String, Object?>{
        'time_flown': 300 + (n * 7) % 300,
        'launch_height': 80 + (n * 3) % 60,
        if (n % 4 != 0) 'landing': 'points_50',
      };
      final attempt = core.ScoreAttempt(
        id: core.Id.create(),
        contestId: contestId,
        scorePlaceholderId: placeholder.id,
        configRevisionId: revision.id,
        matrixRevisionId: matrix.id,
        rawComponents: components,
        actorId: api.director,
        authority: kind == 0
            ? core.Authority.director
            : core.Authority.participant,
        clientMutationId: 'seed-$n',
        baseScoreRevision: 0,
        acceptedAt: at,
      );
      writes.add(('ScoreAttempt', stores.of('ScoreAttempt').encode(attempt)));
      if (kind == 1) {
        writes.add((
          'ScorePlaceholder',
          stores
              .of('ScorePlaceholder')
              .encode(
                core.ScorePlaceholder(
                  id: placeholder.id,
                  contestId: contestId,
                  contestParticipationId: placeholder.contestParticipationId,
                  assignmentId: assignment.id,
                  state: core.ScorePlaceholderState.submitted,
                  revision: placeholder.revision + 1,
                ),
              ),
        ));
        continue;
      }
      final official = core.OfficialScore(
        id: core.Id.create(),
        contestId: contestId,
        scorePlaceholderId: placeholder.id,
        scoreAttemptId: attempt.id,
        scoreRevision: 1,
        components: components,
        setAt: at.add(Duration(seconds: n)),
        setBy: api.director,
        reason: 'Seeded',
      );
      writes.add((
        'OfficialScore',
        stores.of('OfficialScore').encode(official),
      ));
      writes.add((
        'ScorePlaceholder',
        stores
            .of('ScorePlaceholder')
            .encode(
              core.ScorePlaceholder(
                id: placeholder.id,
                contestId: contestId,
                contestParticipationId: placeholder.contestParticipationId,
                assignmentId: assignment.id,
                state: core.ScorePlaceholderState.official,
                scoreRevision: 1,
                revision: placeholder.revision + 1,
              ),
            ),
      ));
    }
  }
  await api.database.transaction(() async {
    for (final (type, json) in writes) {
      await stores.of(type).upsertJson(json);
    }
  });
}
