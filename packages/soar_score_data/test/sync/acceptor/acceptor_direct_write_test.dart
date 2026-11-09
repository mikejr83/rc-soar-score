import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// A change the service makes itself (a hosted API write, such as a pilot's
/// submitted score) joins the scope's log as accepted, so an installation
/// pulls it with the next sync.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;

  setUp(() async {
    harness = await AcceptorHarness.open(backend, pageSize: 100000);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
  });

  tearDown(() => harness.close());

  test('a direct write on the service reaches a pull', () async {
    final before = (await harness.exchange(scope)).serverSequence;
    final repository = harness.serverRepository.contestRepository;
    final contest = (await repository.findById(contestId))!;
    await repository.save(
      contest.copyWithState(
        lifecycleState: core.LifecycleState.running,
        updatedAt: DateTime.utc(2026, 10, 20),
      ),
      metadata: core.MutationMetadata(
        clientMutationId: 'hosted-1',
        authority: core.Authority.participant,
        clientTime: DateTime.utc(2026, 10, 20),
      ),
    );

    final pulled = await harness.exchange(scope, after: before);

    expect(pulled.changes.map((c) => c.entityType), contains('Contest'));
    expect(pulled.serverSequence, before + 1);
  });

  core.MutationMetadata hosted(String id) => core.MutationMetadata(
    clientMutationId: id,
    authority: core.Authority.participant,
    clientTime: DateTime.utc(2026, 10, 20),
  );

  test('a hosted score attempt and its Submitted slot reach a native '
      'database with their revisions', () async {
    final receiver = await harness.openReceiver();
    final director = core.DirectorScopeKey(harness.account);
    await harness.applyChanges(
      receiver,
      director,
      (await harness.exchange(director)).changes,
    );
    final first = await harness.exchange(scope);
    await harness.applyChanges(receiver, scope, first.changes);

    final server = harness.serverRepository;
    final placeholder = (await server.scorePlaceholderRepository.listForContest(
      contestId,
    )).first;
    final assignment = (await server.matrixAssignmentRepository.findById(
      placeholder.assignmentId,
    ))!;
    final attempt = core.ScoreAttempt(
      id: core.Id.create(),
      contestId: contestId,
      scorePlaceholderId: placeholder.id,
      configRevisionId:
          (await server.contestConfigurationRevisionRepository.latestForContest(
            contestId,
          ))!.id,
      matrixRevisionId: assignment.matrixRevisionId,
      rawComponents: const {'time_flown': 600, 'launch_height': 100},
      actorId: core.Id.create(),
      authority: core.Authority.participant,
      clientMutationId: 'pilot-1',
      baseScoreRevision: 0,
      acceptedAt: DateTime.utc(2026, 10, 20, 15),
    );
    await server.scoreAttemptRepository.recordAttempt(
      attempt,
      core.ScorePlaceholder(
        id: placeholder.id,
        contestId: contestId,
        contestParticipationId: placeholder.contestParticipationId,
        assignmentId: placeholder.assignmentId,
        state: core.ScorePlaceholderState.submitted,
        scoreRevision: 1,
        revision: placeholder.revision,
      ),
      metadata: hosted('pilot-1'),
    );

    final pulled = await harness.exchange(scope, after: first.serverSequence);
    expect(pulled.changes.map((c) => c.entityType).toSet(), {
      'ScoreAttempt',
      'ScorePlaceholder',
    });
    await harness.applyChanges(receiver, scope, pulled.changes);

    final gotAttempt = await receiver.stores
        .of('ScoreAttempt')
        .find(attempt.id);
    expect(gotAttempt, equals(attempt));
    final stored = (await server.scorePlaceholderRepository.findById(
      placeholder.id,
    ))!;
    final gotPlaceholder = (await receiver.stores
        .of('ScorePlaceholder')
        .findJson(placeholder.id))!;
    expect(gotPlaceholder['state'], 'Submitted');
    expect(gotPlaceholder['score_revision'], 1);
    expect(gotPlaceholder['revision'], stored.revision);
    expect(stored.revision, placeholder.revision + 1);
    await receiver.close();
  });

  test(
    'concurrent hosted writes take distinct, contiguous sequences',
    () async {
      final before = (await harness.exchange(scope)).serverSequence;
      final repositories = [harness.serverRepository];
      SoarScoreDatabase? second;
      if (backend == Backend.postgres) {
        second = SoarScoreDatabase(
          postgresConfig!.named(harness.server.databaseName!).toPgDatabase(),
          profile: DatabaseProfile.server,
        );
        repositories.add(Repository(second));
      }
      await Future.wait([
        for (var i = 0; i < 12; i++)
          repositories[i % repositories.length].teamRepository.save(
            core.Team(
              id: core.Id.create(),
              contestId: contestId,
              name: 'Team $i',
            ),
            metadata: hosted('team-$i'),
          ),
      ]);
      await second?.close();

      final pulled = await harness.exchange(scope, after: before);
      expect(pulled.changes.map((c) => c.sequence), [
        for (var i = 1; i <= 12; i++) before + i,
      ]);
    },
  );
}
