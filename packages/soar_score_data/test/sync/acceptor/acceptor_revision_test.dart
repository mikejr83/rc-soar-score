import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// `revision`: where a scope's log stands, without reading its changes.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
  });
  tearDown(() => harness.close());

  test('an untouched contest stands at zero', () async {
    expect(
      await harness.service.revision(accountId: harness.account, scope: scope),
      0,
    );
  });

  test('uploaded changes move it to the highest sequence', () async {
    await harness.uploadAll(contestId);

    final revision = await harness.service.revision(
      accountId: harness.account,
      scope: scope,
    );

    expect(revision, greaterThan(0));
    final pulled = await harness.exchange(scope);
    expect(revision, pulled.serverSequence);
  });

  test('another account is refused a contest it does not own', () async {
    await harness.uploadAll(contestId);

    await expectLater(
      harness.service.revision(accountId: core.Id.create(), scope: scope),
      throwsA(isA<core.ForbiddenError>()),
    );
  });

  test('system data has no revision', () {
    expect(
      () => harness.service.revision(
        accountId: harness.account,
        scope: const core.SystemScopeKey(),
      ),
      throwsArgumentError,
    );
  });
}
