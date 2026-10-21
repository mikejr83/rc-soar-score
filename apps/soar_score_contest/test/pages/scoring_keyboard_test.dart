import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

String _id(int round, int pilot) => scoringAssignmentId(round, pilot).value;

Finder _time(int pilot) => find.byKey(ValueKey('score-time-${_id(1, pilot)}'));
Finder _key(String name, int pilot) =>
    find.byKey(ValueKey('score-$name-${_id(1, pilot)}'));

/// Whether the focused widget is [finder] or inside it.
bool _focusIn(Finder finder) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  for (final element in finder.evaluate()) {
    if (focus == element) return true;
    var found = false;
    focus.visitAncestorElements((ancestor) {
      if (ancestor == element) found = true;
      return !found;
    });
    if (found) return true;
  }
  return false;
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

Future<void> _enter(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
}

void main() {
  testWidgets('Enter moves time, height, landing, penalty, then saves', (
    tester,
  ) async {
    final server = ScoringServer();
    await pumpScoringPage(tester, server, round: 1, group: 1);
    await tester.tap(_time(1));
    await tester.pumpAndSettle();
    await tester.enterText(_time(1), '630');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_focusIn(_key('height', 1)), isTrue);
    await tester.enterText(_key('height', 1), '180');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_focusIn(_key('landing', 1)), isTrue);
    // The toggles are off the Enter path: Enter leaves the landing for the
    // flight penalty.
    await _enter(tester);
    expect(_focusIn(_key('penalty', 1)), isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(server.entries, hasLength(1));
    // The next pilot's time is focused.
    expect(_focusIn(_time(2)), isTrue);
  });

  testWidgets('Tab visits the controls in the design order', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await tester.tap(_time(1));
    await tester.pumpAndSettle();
    await tester.enterText(_time(1), '630');
    await tester.enterText(_key('height', 1), '180');
    await tester.pump();
    await tester.tap(_time(1));
    await tester.pump();
    final steps = <(String, Finder)>[
      ('height', _key('height', 1)),
      ('landing', _key('landing', 1)),
      ('late landing', _key('late', 1)),
      ('motor restart', _key('restart', 1)),
      ('out of bounds', _key('oob', 1)),
      ('no altitude', _key('noalt', 1)),
      ('flight penalty', _key('penalty', 1)),
      ('cumulative penalty', find.byKey(const ValueKey('cumulative-penalty'))),
      ('save row', _key('save', 1)),
      ('revert', _key('revert', 1)),
    ];
    for (final (name, finder) in steps) {
      await _tab(tester);
      expect(_focusIn(finder), isTrue, reason: 'Tab should reach $name');
    }
    // The row menu comes after Revert; the next row follows it.
    await _tab(tester);
    expect(
      _focusIn(find.byTooltip('More for Ann Lee')),
      isTrue,
      reason: 'Tab should reach the row menu',
    );
    await _tab(tester);
    expect(_focusIn(_time(2)), isTrue, reason: 'Tab should reach the next row');
  });

  testWidgets('the keyboard order can be shown over the controls', (
    tester,
  ) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await tester.tap(_time(1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focus-badge-1↵')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('group-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('show-focus-order')));
    await tester.pumpAndSettle();
    for (final badge in [
      '1↵',
      '2↵',
      '3↵',
      '4',
      '5',
      '6',
      '7',
      '8↵',
      '9',
      '10 → next pilot 1',
    ]) {
      expect(
        find.byKey(ValueKey('focus-badge-$badge')),
        findsWidgets,
        reason: 'badge $badge',
      );
    }
  });
}
