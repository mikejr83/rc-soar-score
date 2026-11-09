import 'package:soar_score_core/soar_score_core.dart' as core;
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
    harness = await AcceptorHarness.open(backend);
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
}
