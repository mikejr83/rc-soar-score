import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// A not-found names the id it looked for, and an id can contain digits that
/// are also a database error code. The error must stay a not-found.
void _tests(Backend backend) {
  late AcceptorHarness harness;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    await harness.drawContestOnClient();
  });
  tearDown(() => harness.close());

  // Both SQLSTATEs the store maps, inside a valid UUIDv7.
  for (final code in ['23505', '23503']) {
    test('an unknown contest whose id contains $code stays a not-found', () {
      final unknown = core.Id.parse('01900000-0000-7000-8000-0000${code}000');
      expect(unknown.value, contains(code));
      return expectLater(
        harness.installations.activate(
          accountId: harness.account,
          contestId: unknown,
          installationId: harness.installationA,
          kind: core.ActivationKind.replacement,
        ),
        throwsA(isA<core.EntityNotFoundError>()),
      );
    });
  }
}
