import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ContestParticipation make({
  RoleType type = RoleType.pilot,
  String? classification,
  int? retiredAtRound,
  int? number,
}) => ContestParticipation(
  id: exampleId(1),
  contestId: exampleId(2),
  participantProfileId: exampleId(3),
  classification: classification,
  roleId: exampleId(4),
  roleName: type == RoleType.pilot ? 'Pilot' : 'Helper',
  roleType: type,
  participantNumber: number,
  scoringUuid: ScoringUuid.parse('3f6a1c52-8b7e-4d2a-9c41-0e5d7a9b8f13'),
  retiredAtRound: retiredAtRound,
);

void main() {
  group('ContestParticipation', () {
    test('round trips and is contest data', () {
      final p = make(classification: 'Expert', number: 1);
      final json = p.toJson();
      expect(json['role_type'], 'Pilot');
      expect(json['scoring_uuid'], '3f6a1c52-8b7e-4d2a-9c41-0e5d7a9b8f13');
      expect(ContestParticipation.fromJson(json), p);
      expect(p.syncScope, SyncScope.contest);
      expect(p.revision, 0);
    });

    test('is a pilot by default and reports retirement', () {
      expect(make().isPilot, isTrue);
      expect(make().isRetired, isFalse);
      expect(make(retiredAtRound: 3).isRetired, isTrue);
    });

    test('only pilots have a classification', () {
      expect(
        () => make(type: RoleType.nonFlier, classification: 'Expert'),
        throwsArgumentError,
      );
    });

    test('only pilots retire, from round 1 or later', () {
      expect(
        () => make(type: RoleType.nonFlier, retiredAtRound: 2),
        throwsArgumentError,
      );
      expect(() => make(retiredAtRound: 0), throwsArgumentError);
    });

    test('rejects a negative participant number', () {
      expect(() => make(number: -1), throwsArgumentError);
    });

    test('rejects a scoring uuid that is not a UUIDv4', () {
      expect(
        () => ScoringUuid.parse('019c0000-0000-7000-8000-000000000001'),
        throwsArgumentError,
      );
    });
  });
}
