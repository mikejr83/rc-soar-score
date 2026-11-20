import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

const _flight = {'time_flown': 540, 'launch_height': 120};
const _saved = {'time_flown': 600, 'launch_height': 80};

Finder _key(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(_key(key)).controller!.text;

bool _revertOn(WidgetTester tester, String id) =>
    tester.widget<TextButton>(_key('score-revert-$id')).onPressed != null;

Future<void> _open(WidgetTester tester, String id) async {
  await tester.tap(_key('score-row-$id'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.enterText(_key(key), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a pilot entry starts with Revert off and restores the pilot '
      'values after an edit, and Mark official saves those values', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final id = first.value;
    final server = ScoringServer()..seedPendingSubmission(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);
    await _open(tester, id);

    expect(_text(tester, 'score-time-$id'), '9:00');
    expect(_text(tester, 'score-height-$id'), '120');
    expect(_revertOn(tester, id), isFalse);
    expect(
      tester.widget<TextButton>(_key('score-mark-official-$id')).onPressed,
      isNotNull,
    );

    await _type(tester, 'score-height-$id', '99');
    expect(_revertOn(tester, id), isTrue);
    expect(
      tester.widget<TextButton>(_key('score-mark-official-$id')).onPressed,
      isNull,
    );

    await tester.tap(_key('score-revert-$id'));
    await tester.pumpAndSettle();

    expect(_text(tester, 'score-time-$id'), '9:00');
    expect(_text(tester, 'score-height-$id'), '120');
    expect(_revertOn(tester, id), isFalse);

    await tester.tap(_key('score-mark-official-$id'));
    await tester.pumpAndSettle();
    expect(server.promoteRequests, 1);
    expect(find.text('Mark official'), findsNothing);
  });

  testWidgets('a saved score is restored by revert, and a blank row clears', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final second = scoringAssignmentId(1, 2);
    final server = ScoringServer()..seedScore(first, _saved);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _open(tester, first.value);
    expect(_revertOn(tester, first.value), isFalse);
    await _type(tester, 'score-height-${first.value}', '99');
    expect(_revertOn(tester, first.value), isTrue);
    await tester.tap(_key('score-revert-${first.value}'));
    await tester.pumpAndSettle();
    expect(_text(tester, 'score-height-${first.value}'), '80');
    expect(_text(tester, 'score-time-${first.value}'), '10:00');
    expect(_revertOn(tester, first.value), isFalse);

    await _open(tester, second.value);
    expect(_revertOn(tester, second.value), isFalse);
    await _type(tester, 'score-height-${second.value}', '55');
    expect(_revertOn(tester, second.value), isTrue);
    await tester.tap(_key('score-revert-${second.value}'));
    await tester.pumpAndSettle();
    expect(_text(tester, 'score-height-${second.value}'), '');
    expect(_revertOn(tester, second.value), isFalse);
  });

  testWidgets('revert takes back a confirmed zero', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final id = first.value;
    final server = ScoringServer()
      ..seedPendingSubmission(first, const {'out_of_bounds': true});
    await pumpScoringPage(tester, server, round: 1, group: 1);
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await _open(tester, id);

    expect(_key('score-confirm-zero-$id'), findsOneWidget);
    expect(_revertOn(tester, id), isFalse);

    await tester.tap(_key('score-confirm-zero-$id'));
    await tester.pumpAndSettle();
    expect(_key('score-confirm-zero-$id'), findsNothing);
    expect(_revertOn(tester, id), isTrue);

    await tester.tap(_key('score-revert-$id'));
    await tester.pumpAndSettle();
    expect(_key('score-confirm-zero-$id'), findsOneWidget);
    expect(_revertOn(tester, id), isFalse);
  });
}
