import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// A system role is shared by every account, so its usage must name only the
/// asking account's contests, against the real repositories.
void _tests(Backend backend) {
  group('RolesService.usage', () {
    late Installation inst;
    late Repository repository;
    late RolesService service;
    final alice = core.Id.create();
    final bob = core.Id.create();
    late core.Id aliceContest;

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      service = RolesService(repository);
      aliceContest = await drawnContest(
        repository,
        alice,
        mutationPrefix: 'alice',
        name: 'Alice Open',
      );
      await drawnContest(
        repository,
        bob,
        mutationPrefix: 'bob',
        name: 'Bob Classic',
      );
    });

    tearDown(() => inst.close());

    test('a shared system role lists only the asking account\'s contests '
        'and counts', () async {
      final forAlice = await service.usage(alice, core.SystemRoles.pilotId);
      final forBob = await service.usage(bob, core.SystemRoles.pilotId);

      expect([for (final u in forAlice) u.contestName], ['Alice Open']);
      expect(forAlice.single.contestId, aliceContest);
      expect(forAlice.single.participantCount, 4);
      expect([for (final u in forBob) u.contestName], ['Bob Classic']);
      expect(forBob.single.participantCount, 4);
    });

    test('an account with no contest using the role sees none', () async {
      expect(
        await service.usage(core.Id.create(), core.SystemRoles.pilotId),
        isEmpty,
      );
    });
  });
}
