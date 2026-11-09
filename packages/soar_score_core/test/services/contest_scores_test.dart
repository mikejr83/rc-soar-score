import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('ScoreSlot JSON', () {
    final slot = ScoreSlot(
      placeholder: ScorePlaceholder(
        id: Id.create(),
        contestId: Id.create(),
        contestParticipationId: Id.create(),
        assignmentId: Id.create(),
        state: ScorePlaceholderState.notEntered,
        scoreRevision: 0,
      ),
    );

    test('an older response without pending_attempt still parses', () {
      final json = slot.toJson()..remove('pending_attempt');

      expect(ScoreSlot.fromJson(json).pendingAttempt, isNull);
    });

    test('a null pending_attempt parses as none', () {
      expect(slot.toJson()['pending_attempt'], isNull);
      expect(ScoreSlot.fromJson(slot.toJson()), slot);
    });
  });
}
