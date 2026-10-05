import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late core.RoleRepository repo;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    repo = Repository(inst.db).roleRepository;
  });
  tearDown(() => inst.close());

  Future<void> storeOwned(core.Id owner, String name) => inst.stores
      .of('Role')
      .upsertJson(
        core.Role(
          id: core.Id.create(),
          ownerAccountId: owner,
          displayName: name,
          type: core.RoleType.nonFlier,
        ).toJson(),
      );

  group('RoleRepository', () {
    test('installs every system role and reads them back unchanged', () async {
      for (final role in core.SystemRoles.all) {
        expect(await repo.installSystemRole(role), isTrue);
      }

      expect(await repo.listVisibleTo(), [
        core.SystemRoles.helper,
        core.SystemRoles.pilot,
        core.SystemRoles.teamManager,
      ]);
    });

    test('installing twice stores each role once', () async {
      await repo.installSystemRole(core.SystemRoles.pilot);

      expect(await repo.installSystemRole(core.SystemRoles.pilot), isFalse);
      expect(await repo.listVisibleTo(), [core.SystemRoles.pilot]);
    });

    test('leaves a stored role with the same id untouched', () async {
      await repo.installSystemRole(core.SystemRoles.helper);
      final changed = core.Role(
        id: core.SystemRoles.helperId,
        displayName: 'Renamed',
        type: core.RoleType.nonFlier,
        revision: 9,
      );

      expect(await repo.installSystemRole(changed), isFalse);
      expect(await repo.listVisibleTo(), [core.SystemRoles.helper]);
    });

    test('refuses a role with an owner and stores nothing', () async {
      final owned = core.Role(
        id: core.Id.create(),
        ownerAccountId: core.Id.create(),
        displayName: 'Mine',
        type: core.RoleType.nonFlier,
      );

      expect(() => repo.installSystemRole(owned), throwsArgumentError);
      expect(await repo.listVisibleTo(), isEmpty);
    });

    test('listVisibleTo shows system roles and the director\'s own', () async {
      final mine = core.Id.create();
      for (final role in core.SystemRoles.all) {
        await repo.installSystemRole(role);
      }
      await storeOwned(mine, 'Timekeeper');
      await storeOwned(core.Id.create(), 'Scorer');

      final names = (await repo.listVisibleTo(ownerAccountId: mine))
          .map((r) => r.displayName);
      final anonymous = (await repo.listVisibleTo()).map((r) => r.displayName);

      expect(names, ['Helper', 'Pilot', 'Team Manager', 'Timekeeper']);
      expect(anonymous, ['Helper', 'Pilot', 'Team Manager']);
    });
  });
}
