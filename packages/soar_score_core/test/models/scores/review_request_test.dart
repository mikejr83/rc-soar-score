import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ReviewRequest make({
  ReviewRequestState state = ReviewRequestState.submitted,
  Map<String, Object?> proposed = const {'time_flown': 550},
  Id? actor,
  DateTime? time,
  Id? attempt,
  String? message,
}) => ReviewRequest(
  id: exampleId(1),
  contestId: exampleId(2),
  scorePlaceholderId: exampleId(3),
  proposedComponents: proposed,
  requesterId: exampleId(4),
  baseScoreRevision: 1,
  requestedAt: t0,
  state: state,
  decisionActorId: actor,
  decisionTime: time,
  decisionMessage: message,
  resultingAttemptId: attempt,
);

void main() {
  group('ReviewRequest', () {
    test('round trips with defaults', () {
      final r = make();
      expect(r.state, ReviewRequestState.submitted);
      expect(r.revision, 0);
      expect(r.isOpen, isTrue);
      expect(r.toJson()['state'], 'Submitted');
      expect(ReviewRequest.fromJson(r.toJson()), r);
      expect(r.syncScope, SyncScope.contest);
    });

    test('state values use their documented text', () {
      for (final text in [
        'Submitted',
        'UnderReview',
        'Approved',
        'Rejected',
        'Superseded',
      ]) {
        final json = make().toJson()
          ..['state'] = text
          ..['decision_actor_id'] = exampleId(5).toString()
          ..['decision_time'] = '2026-10-17T15:25:00Z'
          ..['resulting_attempt_id'] = text == 'Approved'
              ? exampleId(6).toString()
              : null;
        if (text == 'Submitted') {
          json
            ..['decision_actor_id'] = null
            ..['decision_time'] = null;
        }
        expect(ReviewRequest.fromJson(json).toJson()['state'], text);
      }
    });

    test('a submitted request has no decision yet', () {
      expect(() => make(actor: exampleId(5), time: t0), throwsArgumentError);
      expect(() => make(message: 'x'), throwsArgumentError);
    });

    test('rejected needs who and when, and no resulting attempt', () {
      final ok = make(
        state: ReviewRequestState.rejected,
        actor: exampleId(5),
        time: t0,
        message: 'The official timer stands',
      );
      expect(ok.isOpen, isFalse);
      expect(
        () => make(state: ReviewRequestState.rejected),
        throwsArgumentError,
      );
      expect(
        () => make(
          state: ReviewRequestState.rejected,
          actor: exampleId(5),
          time: t0,
          attempt: exampleId(6),
        ),
        throwsArgumentError,
      );
    });

    test('approved has a resulting attempt, nothing else does', () {
      final ok = make(
        state: ReviewRequestState.approved,
        actor: exampleId(5),
        time: t0,
        attempt: exampleId(6),
      );
      expect(ok.resultingAttemptId, exampleId(6));
      expect(
        () => make(
          state: ReviewRequestState.approved,
          actor: exampleId(5),
          time: t0,
        ),
        throwsArgumentError,
      );
    });

    test('decision actor and time are set together', () {
      expect(
        () => make(state: ReviewRequestState.underReview, actor: exampleId(5)),
        throwsArgumentError,
      );
    });

    test('a request cannot propose a cumulative penalty', () {
      expect(
        () => make(proposed: const {'cumulative_penalty': null}),
        throwsArgumentError,
      );
      expect(
        make(proposed: const {'flight_penalty': 10}).proposedComponents,
        isNotEmpty,
      );
    });
  });
}
