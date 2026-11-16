import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ScorePlaceholder make({
  Id? by,
  DateTime? at,
  int scoreRevision = 0,
  int? closed,
}) => ScorePlaceholder(
  id: exampleId(1),
  contestId: exampleId(2),
  contestParticipationId: exampleId(3),
  assignmentId: exampleId(4),
  scoreRevision: scoreRevision,
  lockedBy: by,
  lockedAt: at,
  reviewClosedScoreRevision: closed,
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

    test('review closure applies only to the score it was made for', () {
      OfficialScore official(int revision, SelectionOrigin origin) =>
          OfficialScore(
            id: exampleId(10),
            contestId: exampleId(2),
            scorePlaceholderId: exampleId(1),
            scoreAttemptId: exampleId(11),
            scoreRevision: revision,
            components: const {'time_flown': 585},
            setAt: t0,
            setBy: origin == SelectionOrigin.automatic ? null : exampleId(5),
            reason: 'r',
            selectionOrigin: origin,
          );
      final auto = official(2, SelectionOrigin.automatic);
      // Official by automatic acceptance does not close review.
      expect(make(scoreRevision: 2).isReviewClosed(auto), isFalse);
      // An explicit decision for this score does.
      expect(make(scoreRevision: 2, closed: 2).isReviewClosed(auto), isTrue);
      // A closure for an earlier score does not.
      expect(make(scoreRevision: 3, closed: 2).hasReviewClosure, isFalse);
      // A manual or review-decision version is itself the decision.
      for (final origin in [
        SelectionOrigin.manual,
        SelectionOrigin.reviewDecision,
      ]) {
        expect(
          make(scoreRevision: 2).isReviewClosed(official(2, origin)),
          isTrue,
        );
      }
      // A newer pending attempt (revision moved on) is open again.
      expect(
        make(scoreRevision: 3)
            .isReviewClosed(official(2, SelectionOrigin.manual)),
        isFalse,
      );
      expect(make(scoreRevision: 1).isReviewClosed(null), isFalse);
      expect(() => make(scoreRevision: 1, closed: 0), throwsArgumentError);
      expect(
        ScorePlaceholder.fromJson(make(closed: 1, scoreRevision: 1).toJson())
            .reviewClosedScoreRevision,
        1,
      );
    });

    test('old records without the closure read as open', () {
      final json = make().toJson()..remove('review_closed_score_revision');
      expect(ScorePlaceholder.fromJson(json).reviewClosedScoreRevision, isNull);
    });

    test('score revision cannot be negative', () {
      expect(() => make(scoreRevision: -1), throwsArgumentError);
    });
  });
}
