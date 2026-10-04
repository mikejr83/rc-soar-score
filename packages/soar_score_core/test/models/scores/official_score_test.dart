import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

OfficialScore make({
  int revision = 1,
  String reason = 'Accepted director entry',
  Map<String, Object?> components = const {'time_flown': 585},
}) => OfficialScore(
  id: exampleId(1),
  contestId: exampleId(2),
  scorePlaceholderId: exampleId(3),
  scoreAttemptId: exampleId(4),
  scoreRevision: revision,
  components: components,
  setAt: t0,
  setBy: exampleId(5),
  reason: reason,
);

void main() {
  group('OfficialScore', () {
    test('round trips and is contest data without a row revision', () {
      final s = make();
      expect(s.toJson().containsKey('revision'), isFalse);
      expect(OfficialScore.fromJson(s.toJson()), s);
      expect(s.syncScope, SyncScope.contest);
    });

    test('the first official version is revision 1 or later', () {
      expect(() => make(revision: 0), throwsArgumentError);
    });

    test('needs a reason', () {
      expect(() => make(reason: ' '), throwsArgumentError);
    });

    test('a zero cumulative penalty means one was applied and removed', () {
      final s = make(components: const {'cumulative_penalty': 0});
      expect(s.components['cumulative_penalty'], 0);
      expect(
        () => make(components: const {'cumulative_penalty': -5}),
        throwsArgumentError,
      );
    });

    test('copies the components', () {
      final c = <String, Object?>{'time_flown': 1};
      final s = make(components: c);
      c['time_flown'] = 2;
      expect(s.components['time_flown'], 1);
    });
  });
}
