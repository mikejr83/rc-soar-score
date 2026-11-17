import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// Accepted sync changes are a trigger of the automatic officialization, but
/// the first upload of a contest is not: an imported contest keeps its
/// pending scores pending.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  var evaluations = 0;

  setUp(() async {
    evaluations = 0;
    harness = await AcceptorHarness.open(
      backend,
      recalculation: (server) => RecalculationService(
        ResultsService(server),
        officialize: (_) async {
          evaluations++;
          return AutomaticOfficialization.none;
        },
      ),
    );
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
  });

  tearDown(() => harness.close());

  test('the first upload of a contest never evaluates', () async {
    await harness.uploadAll(contestId);

    expect(evaluations, 0);
    expect(await harness.stored('Contest', contestId), isNotNull);
  });

  test('a later accepted change evaluates once', () async {
    await harness.uploadAll(contestId);
    final participation =
        (await harness.server.stores.of('ContestParticipation').all()).first
            as core.ContestParticipation;

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('ContestParticipation', {
          ...participation.toJson(),
          'participant_number': 99,
        }, base: participation.revision),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.accepted);
    expect(evaluations, 1);
  });
}
