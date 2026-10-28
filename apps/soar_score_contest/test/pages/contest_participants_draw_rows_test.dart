import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participants_page_support.dart';

Finder _check(int n) => find.descendant(
  of: find.byKey(ValueKey('row-${personParticipationId(n).value}')),
  matching: find.byType(Checkbox),
);

Finder _remove() => find.byKey(const ValueKey('remove-participants'));

Finder _save() => find.byKey(const ValueKey('save-participants'));

Future<void> _pickRole(WidgetTester tester, int person, String role) async {
  await tester.tap(
    find.byKey(ValueKey('role-${personParticipationId(person).value}')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(role).last);
  await tester.pumpAndSettle();
}

ParticipantsServer _drawn({bool withScores = false}) => ParticipantsServer(
  state: LifecycleState.running,
  drawn: true,
  withScores: withScores,
);

/// A pilot with places in the draw but no scores can leave the contest or stop
/// flying; the draw then needs redoing.
void main() {
  group('removing a drawn pilot with no scores', () {
    testWidgets('the confirmation says their places in the draw go too', (
      tester,
    ) async {
      await pumpParticipantsPage(tester, _drawn());
      await tester.tap(_check(2));
      await tester.pumpAndSettle();

      await tester.tap(_remove());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Bo Ray is in the draw. Their places in it are removed too, and '
          'the draw will need redoing.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('afterwards a notice says the draw needs redoing and links to '
        'the Matrix redraw', (tester) async {
      final server = _drawn();
      await pumpParticipantsPage(tester, server);
      await tester.tap(_check(2));
      await tester.pumpAndSettle();
      await tester.tap(_remove());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('confirm-remove')));
      await tester.pumpAndSettle();

      expect(server.removals, [personParticipationId(2)]);
      expect(find.text('Bo Ray'), findsNothing);
      expect(find.text('The draw needs redoing'), findsOneWidget);
      expect(find.textContaining('Bo Ray was in the draw'), findsOneWidget);
      // The page read the matrix again, so no one is called unplaced.
      expect(find.textContaining('placed yet'), findsNothing);

      await tester.tap(find.text('Redo the draw'));
      await tester.pumpAndSettle();
      expect(find.text('Matrix stub'), findsOneWidget);
    });

    testWidgets('the notice can be dismissed', (tester) async {
      await pumpParticipantsPage(tester, _drawn());
      await tester.tap(_check(2));
      await tester.pumpAndSettle();
      await tester.tap(_remove());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-remove')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('banner-redo-draw')),
          matching: find.text('Dismiss'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('The draw needs redoing'), findsNothing);
    });

    testWidgets('a non-flier has no places in the draw to lose', (
      tester,
    ) async {
      await pumpParticipantsPage(tester, _drawn());
      await tester.tap(_check(5));
      await tester.pumpAndSettle();
      await tester.tap(_remove());
      await tester.pumpAndSettle();
      expect(find.textContaining('is in the draw'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('confirm-remove')));
      await tester.pumpAndSettle();

      expect(find.text('The draw needs redoing'), findsNothing);
    });

    testWidgets('before the draw nothing mentions it', (tester) async {
      await pumpParticipantsPage(tester, ParticipantsServer());
      await tester.tap(_check(2));
      await tester.pumpAndSettle();
      await tester.tap(_remove());
      await tester.pumpAndSettle();
      expect(find.textContaining('in the draw'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('confirm-remove')));
      await tester.pumpAndSettle();

      expect(find.text('The draw needs redoing'), findsNothing);
    });

    testWidgets('a pilot with a score cannot be removed, and says why', (
      tester,
    ) async {
      await pumpParticipantsPage(tester, _drawn(withScores: true));
      await tester.tap(_check(1));
      await tester.pumpAndSettle();

      expect(tester.widget<OutlinedButton>(_remove()).onPressed, isNull);
      expect(find.byKey(const ValueKey('remove-reason')), findsOneWidget);
    });
  });

  group('making a drawn pilot with no scores non-flying', () {
    testWidgets('the confirmation says their places in the draw are removed', (
      tester,
    ) async {
      await pumpParticipantsPage(tester, _drawn());

      await _pickRole(tester, 2, 'Helper');

      expect(
        find.textContaining(
          'Their places in the draw are removed when you save, and the draw '
          'will need redoing.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a pilot with no class is still asked', (tester) async {
      await pumpParticipantsPage(tester, _drawn());

      await _pickRole(tester, 4, 'Helper');

      expect(find.text('Change Di Park to Helper?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('class'),
        ),
        findsNothing,
      );
    });

    testWidgets('saving shows the notice; cancelling changes nothing', (
      tester,
    ) async {
      final server = _drawn();
      await pumpParticipantsPage(tester, server);
      await _pickRole(tester, 2, 'Helper');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('No changes to save.'), findsOneWidget);
      expect(server.updates, isEmpty);

      await _pickRole(tester, 2, 'Helper');
      await tester.tap(find.byKey(const ValueKey('confirm-role-change')));
      await tester.pumpAndSettle();
      await tester.tap(_save());
      await tester.pumpAndSettle();

      expect(server.updates.single.body['role_id'], SystemRoles.helperId.value);
      expect(find.text('The draw needs redoing'), findsOneWidget);
      expect(find.textContaining('Bo Ray was in the draw'), findsOneWidget);
    });

    testWidgets('a pilot with a score still cannot', (tester) async {
      await pumpParticipantsPage(tester, _drawn(withScores: true));

      await tester.tap(
        find.byKey(ValueKey('role-${personParticipationId(1).value}')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Helper (not available: has flights)'), findsOneWidget);
    });

    testWidgets('the bulk role change asks about the pilots in the draw', (
      tester,
    ) async {
      final server = _drawn();
      await pumpParticipantsPage(tester, server);
      await tester.tap(_check(2));
      await tester.tap(_check(3));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('bulk-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, 'Helper'));
      await tester.pumpAndSettle();

      expect(find.text('Change Bo Ray and Cy Fox to Helper?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-role-change')));
      await tester.pumpAndSettle();
      await tester.tap(_save());
      await tester.pumpAndSettle();

      expect(server.updates, hasLength(2));
      expect(
        find.textContaining('Bo Ray and Cy Fox were in the draw'),
        findsOneWidget,
      );
    });
  });
}
