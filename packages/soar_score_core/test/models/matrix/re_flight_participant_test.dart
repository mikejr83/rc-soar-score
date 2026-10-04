import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ReFlightParticipant make({
  ReFlightParticipantRole role = ReFlightParticipantRole.awarded,
  ExcludedReason? excluded,
  ReFlightResponse response = ReFlightResponse.notRequired,
  Id? assignment,
  int? position,
}) => ReFlightParticipant(
  id: exampleId(1),
  contestId: exampleId(2),
  reFlightId: exampleId(3),
  contestParticipationId: exampleId(4),
  role: role,
  excludedReason: excluded,
  response: response,
  assignmentId: assignment,
  drawPosition: position,
);

void main() {
  group('ReFlightParticipant', () {
    test('round trips with defaults', () {
      final p = make(assignment: exampleId(5));
      expect(p.response, ReFlightResponse.notRequired);
      expect(p.notificationState, NotificationState.notRequired);
      expect(p.revision, 0);
      final json = p.toJson();
      expect(json['role'], 'Awarded');
      expect(json['response'], 'NotRequired');
      expect(json['notification_state'], 'NotRequired');
      expect(ReFlightParticipant.fromJson(json), p);
      expect(p.syncScope, SyncScope.contest);
    });

    test('role and reason values use their documented text', () {
      final p = make(
        role: ReFlightParticipantRole.excluded,
        excluded: ExcludedReason.sameTeam,
      );
      expect(p.toJson()['role'], 'Excluded');
      expect(p.toJson()['excluded_reason'], 'SameTeam');
      expect(
        make(role: ReFlightParticipantRole.groupMember).toJson()['role'],
        'GroupMember',
      );
    });

    test('a reason is set exactly when excluded', () {
      expect(
        () => make(role: ReFlightParticipantRole.excluded),
        throwsArgumentError,
      );
      expect(
        () => make(excluded: ExcludedReason.declined),
        throwsArgumentError,
      );
    });

    test('a group member has no response to give', () {
      expect(
        () => make(
          role: ReFlightParticipantRole.groupMember,
          response: ReFlightResponse.pending,
        ),
        throwsArgumentError,
      );
      expect(
        make(
          role: ReFlightParticipantRole.drawn,
          response: ReFlightResponse.accepted,
          position: 1,
        ).response,
        ReFlightResponse.accepted,
      );
    });

    test('candidates and excluded pilots have no assignment', () {
      expect(
        () => make(
          role: ReFlightParticipantRole.candidate,
          assignment: exampleId(5),
        ),
        throwsArgumentError,
      );
      expect(
        () => make(
          role: ReFlightParticipantRole.excluded,
          excluded: ExcludedReason.retired,
          assignment: exampleId(5),
        ),
        throwsArgumentError,
      );
    });

    test('draw position starts at 1', () {
      expect(() => make(position: 0), throwsArgumentError);
    });
  });
}
