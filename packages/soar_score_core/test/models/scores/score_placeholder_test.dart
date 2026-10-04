import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ScorePlaceholder make({Id? by, DateTime? at, int scoreRevision = 0}) =>
    ScorePlaceholder(
      id: exampleId(1),
      contestId: exampleId(2),
      contestParticipationId: exampleId(3),
      assignmentId: exampleId(4),
      scoreRevision: scoreRevision,
      lockedBy: by,
      lockedAt: at,
    );

void main() {
  group('ScorePlaceholder', () {
    test('round trips with defaults', () {
      final p = make();
      expect(p.state, ScorePlaceholderState.notEntered);
      expect(p.scoreRevision, 0);
      expect(p.revision, 0);
      expect(p.toJson()['state'], 'NotEntered');
      expect(ScorePlaceholder.fromJson(p.toJson()), p);
      expect(p.syncScope, SyncScope.contest);
      expect(p.entityType, 'ScorePlaceholder');
    });

    test('state values use their documented text', () {
      for (final text in ['NotEntered', 'Submitted', 'InReview', 'Official']) {
        final json = make().toJson()..['state'] = text;
        expect(ScorePlaceholder.fromJson(json).toJson()['state'], text);
      }
    });

    test('lock fields are set together', () {
      expect(() => make(by: exampleId(5)), throwsArgumentError);
      expect(() => make(at: t0), throwsArgumentError);
      expect(make(by: exampleId(5), at: t0).isLocked, isTrue);
      expect(make().isLocked, isFalse);
    });

    test('score revision cannot be negative', () {
      expect(() => make(scoreRevision: -1), throwsArgumentError);
    });
  });
}
