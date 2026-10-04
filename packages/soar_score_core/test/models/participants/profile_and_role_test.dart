import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ParticipantProfile profile({String first = 'Ada', String last = 'Lovelace'}) =>
    ParticipantProfile(
      id: exampleId(1),
      ownerAccountId: exampleId(2),
      firstName: first,
      lastName: last,
      email: 'ada@example.com',
      createdAt: t0,
      updatedAt: t0,
    );

Role role({Id? owner, RoleType type = RoleType.nonFlier}) => Role(
  id: exampleId(3),
  ownerAccountId: owner,
  displayName: 'Timekeeper',
  type: type,
);

void main() {
  group('ParticipantProfile', () {
    test('round trips and defaults revision to 0', () {
      final p = profile();
      expect(p.revision, 0);
      expect(ParticipantProfile.fromJson(p.toJson()), p);
      expect(p.toJson()['club'], isNull);
    });

    test('is director data', () {
      expect(profile().syncScope, SyncScope.director);
      expect(profile().entityType, 'ParticipantProfile');
    });

    test('needs a first and last name', () {
      expect(() => profile(first: ' '), throwsArgumentError);
      expect(() => profile(last: ''), throwsArgumentError);
    });
  });

  group('Role', () {
    test('round trips with the documented type text', () {
      final r = role();
      expect(r.toJson()['type'], 'NonFlier');
      expect(Role.fromJson(r.toJson()), r);
      expect(role(type: RoleType.pilot).toJson()['type'], 'Pilot');
    });

    test('is system data without an owner, director data with one', () {
      expect(role().syncScope, SyncScope.system);
      expect(role(owner: exampleId(9)).syncScope, SyncScope.director);
    });

    test('a director can only add non-flier roles', () {
      expect(
        () => role(owner: exampleId(9), type: RoleType.pilot),
        throwsArgumentError,
      );
      expect(role(type: RoleType.pilot).isSystem, isTrue);
    });

    test('reports archiving', () {
      final r = Role(
        id: exampleId(3),
        displayName: 'Helper',
        type: RoleType.nonFlier,
        archivedAt: t0,
      );
      expect(r.isArchived, isTrue);
      expect(role().isArchived, isFalse);
    });
  });
}
