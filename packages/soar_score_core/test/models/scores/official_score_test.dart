import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

OfficialScore make({
  int revision = 1,
  String reason = 'Accepted director entry',
  Map<String, Object?> components = const {'time_flown': 585},
  SelectionOrigin origin = SelectionOrigin.manual,
  bool noActor = false,
}) => OfficialScore(
  id: exampleId(1),
  contestId: exampleId(2),
  scorePlaceholderId: exampleId(3),
  scoreAttemptId: exampleId(4),
  scoreRevision: revision,
  components: components,
  setAt: t0,
  setBy: noActor ? null : exampleId(5),
  reason: reason,
  selectionOrigin: origin,
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

    test('selection origin round trips and old records read as manual', () {
      for (final origin in SelectionOrigin.values) {
        final s = make(
          origin: origin,
          noActor: origin == SelectionOrigin.automatic,
        );
        expect(OfficialScore.fromJson(s.toJson()), s);
      }
      expect(make().toJson()['selection_origin'], 'Manual');
      final old = make().toJson()..remove('selection_origin');
      expect(
        OfficialScore.fromJson(old).selectionOrigin,
        SelectionOrigin.manual,
      );
    });

    test('an automatic selection has no actor and others must have one', () {
      final auto = make(origin: SelectionOrigin.automatic, noActor: true);
      expect(auto.setBy, isNull);
      expect(auto.toJson()['set_by'], isNull);
      expect(OfficialScore.fromJson(auto.toJson()).setBy, isNull);
      expect(
        () => make(origin: SelectionOrigin.automatic),
        throwsArgumentError,
      );
      expect(() => make(noActor: true), throwsArgumentError);
      expect(
        () => make(origin: SelectionOrigin.reviewDecision, noActor: true),
        throwsArgumentError,
      );
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
