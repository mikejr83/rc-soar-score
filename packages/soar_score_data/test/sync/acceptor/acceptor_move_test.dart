import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// A pilot moved offline: the move reaches the server and the other
/// installations with the assignment it replaces.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late core.MatrixAssignment source;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
    source =
        (await harness.server.stores.of('MatrixAssignment').all()).first
            as core.MatrixAssignment;
  });
  tearDown(() => harness.close());

  Map<String, Object?> moveOf(core.MatrixAssignment from) => {
    ...from.toJson(),
    'id': core.Id.create().value,
    'assignment_type': 'Moved',
    'source_assignment_id': from.id.value,
    'reason': 'Moved to the later round',
    'created_at': '2026-10-14T16:00:00Z',
  };

  test(
    'marks the old assignment and sends both to the other installation',
    () async {
      final moved = moveOf(source);

      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save('MatrixAssignment', moved, supersedes: source.id.value),
        ],
      );

      expect(out.results.single.outcome, core.MutationOutcome.accepted);
      final old = await harness.stored('MatrixAssignment', source.id);
      expect(old!['superseded_by_assignment_id'], moved['id']);
      final pulled = await harness.exchange(
        scope,
        installation: harness.installationA,
        after: out.results.single.sequence! - 1,
      );
      expect(pulled.changes.single.payload['supersedes'], source.id.value);

      final receiver = await harness.openReceiver();
      final people = await harness.exchange(
        core.DirectorScopeKey(harness.account),
      );
      await harness.applyChanges(
        receiver,
        core.DirectorScopeKey(harness.account),
        people.changes,
      );
      final all = await harness.exchange(scope);
      await harness.applyChanges(receiver, scope, all.changes);
      final received = await receiver.stores
          .of('MatrixAssignment')
          .findJson(source.id);
      expect(received!['superseded_by_assignment_id'], moved['id']);
      await receiver.close();
    },
  );

  test('a second move of the same assignment is a conflict', () async {
    await harness.exchange(
      scope,
      mutations: [
        harness.save(
          'MatrixAssignment',
          moveOf(source),
          supersedes: source.id.value,
        ),
      ],
    );

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save(
          'MatrixAssignment',
          moveOf(source),
          supersedes: source.id.value,
        ),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.conflict);
    expect(out.results.single.reasonCode, 'unique_violation');
    expect(out.conflicts.single.requiresAction, isTrue);
  });
}
