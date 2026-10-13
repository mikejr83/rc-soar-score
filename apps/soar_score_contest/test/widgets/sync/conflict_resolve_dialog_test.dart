import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/sync/conflict_answer.dart';
import 'package:soar_score_contest/services/sync/open_conflict.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_contest/widgets/sync/conflict_resolve_dialog.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _conflict = OpenConflict(
  id: Id.parse('019c0000-0000-7000-8000-000000000030'),
  entityType: 'OfficialScore',
  entityId: Id.parse('019c0000-0000-7000-8000-000000000031'),
  createdAt: DateTime.utc(2026, 10, 13, 18),
  reasonCode: 'stale_base',
  acceptedPayload: {'time_flown': 540, 'landing': 'A'},
  competingPayload: {'time_flown': 545, 'landing': 'A'},
);

class _Asked {
  ConflictResolutionChoice? choice;
  Map<String, Object?>? payload;
  int calls = 0;
}

/// Opens the dialog from a button, so a pop has somewhere to go back to.
Future<void> _open(
  WidgetTester tester,
  _Asked asked,
  ConflictAnswer answer,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<ConflictAnswer>(
            context: context,
            builder: (_) => ConflictResolveDialog(
              conflict: _conflict,
              onResolve: (choice, payload) async {
                asked
                  ..calls += 1
                  ..choice = choice
                  ..payload = payload;
                return answer;
              },
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows both versions and marks the fields that differ', (
    tester,
  ) async {
    await _open(tester, _Asked(), const ConflictAnswer.resolved());

    expect(find.text('Accepted by the service'), findsOneWidget);
    expect(find.text('Competing change'), findsOneWidget);
    expect(find.text('540'), findsOneWidget);
    expect(find.text('545'), findsOneWidget);
    expect(find.text('Stale base.'), findsOneWidget);
    final rows = tester.widgetList<Table>(find.byType(Table)).single.children;
    // header, landing (same), time_flown (differs)
    expect(rows[1].decoration, isNull);
    expect(rows[2].decoration, isNotNull);
  });

  testWidgets('keeping the accepted value sends KeptAccepted and closes', (
    tester,
  ) async {
    final asked = _Asked();
    await _open(tester, asked, const ConflictAnswer.resolved());

    await tester.tap(find.byKey(const ValueKey('conflict-keep-accepted')));
    await tester.pumpAndSettle();

    expect(asked.choice, ConflictResolutionChoice.keptAccepted);
    expect(asked.payload, isNull);
    expect(find.byKey(const ValueKey('conflict-dialog')), findsNothing);
  });

  testWidgets('using the competing change sends TookCompeting and closes', (
    tester,
  ) async {
    final asked = _Asked();
    await _open(tester, asked, const ConflictAnswer.resolved());

    await tester.tap(find.byKey(const ValueKey('conflict-take-competing')));
    await tester.pumpAndSettle();

    expect(asked.choice, ConflictResolutionChoice.tookCompeting);
    expect(find.byKey(const ValueKey('conflict-dialog')), findsNothing);
  });

  testWidgets('an edited value is sent as Merged with the payload', (
    tester,
  ) async {
    final asked = _Asked();
    await _open(tester, asked, const ConflictAnswer.resolved());

    await tester.tap(find.byKey(const ValueKey('conflict-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('conflict-edit-field')),
      '{"time_flown": 542, "landing": "B"}',
    );
    await tester.tap(find.byKey(const ValueKey('conflict-edit-save')));
    await tester.pumpAndSettle();

    expect(asked.choice, ConflictResolutionChoice.merged);
    expect(asked.payload, {'time_flown': 542, 'landing': 'B'});
    expect(find.byKey(const ValueKey('conflict-dialog')), findsNothing);
  });

  testWidgets('edited text that is not a JSON object is not sent', (
    tester,
  ) async {
    final asked = _Asked();
    await _open(tester, asked, const ConflictAnswer.resolved());

    await tester.tap(find.byKey(const ValueKey('conflict-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('conflict-edit-field')),
      '[1, 2]',
    );
    await tester.tap(find.byKey(const ValueKey('conflict-edit-save')));
    await tester.pumpAndSettle();

    expect(asked.calls, 0);
    expect(
      find.text('The edited value must be a JSON object.'),
      findsOneWidget,
    );
  });

  testWidgets('an answer that is not accepted leaves it open with the reason', (
    tester,
  ) async {
    final asked = _Asked();
    await _open(
      tester,
      asked,
      const ConflictAnswer.notAccepted(
        'The service did not accept the decision: locked.',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('conflict-keep-accepted')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conflict-dialog')), findsOneWidget);
    expect(
      find.text('The service did not accept the decision: locked.'),
      findsOneWidget,
    );
    // The director can try again.
    await tester.tap(find.byKey(const ValueKey('conflict-take-competing')));
    await tester.pumpAndSettle();
    expect(asked.calls, 2);
  });

  testWidgets('a failed send shows why, for example offline', (tester) async {
    await _open(
      tester,
      _Asked(),
      const ConflictAnswer.failed(SyncProblem.offline),
    );

    await tester.tap(find.byKey(const ValueKey('conflict-keep-accepted')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('conflict-dialog')), findsOneWidget);
    expect(
      find.textContaining(SyncProblem.offline.explanation),
      findsOneWidget,
    );
  });

  testWidgets('deciding later closes without sending anything', (tester) async {
    final asked = _Asked();
    await _open(tester, asked, const ConflictAnswer.resolved());

    await tester.tap(find.byKey(const ValueKey('conflict-close')));
    await tester.pumpAndSettle();

    expect(asked.calls, 0);
    expect(find.byKey(const ValueKey('conflict-dialog')), findsNothing);
  });
}
