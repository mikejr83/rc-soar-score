import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('SystemRoles', () {
    test('ships Pilot, Helper and Team Manager', () {
      expect(SystemRoles.all.map((r) => r.displayName), [
        'Pilot',
        'Helper',
        'Team Manager',
      ]);
    });

    test('every role is a system role', () {
      for (final role in SystemRoles.all) {
        expect(role.isSystem, isTrue, reason: role.displayName);
        expect(role.syncScope, SyncScope.system);
      }
    });

    test('exactly one role is the Pilot', () {
      final pilots = SystemRoles.all.where((r) => r.type == RoleType.pilot);

      expect(pilots.map((r) => r.id), [SystemRoles.pilotId]);
      expect(
        SystemRoles.all.where((r) => r.type == RoleType.nonFlier),
        hasLength(2),
      );
    });

    test('ids and names are unique and match the documented ids', () {
      expect(SystemRoles.all.map((r) => r.id.value), [
        '019c0000-0000-7000-8000-000000000030',
        '019c0000-0000-7000-8000-000000000032',
        '019c0000-0000-7000-8000-000000000033',
      ]);
      expect(
        SystemRoles.all.map((r) => r.displayName.toLowerCase()).toSet(),
        hasLength(SystemRoles.all.length),
      );
    });
  });
}
