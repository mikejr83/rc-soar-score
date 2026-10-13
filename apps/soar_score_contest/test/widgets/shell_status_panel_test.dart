import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/semantics.dart';
import 'package:soar_score_contest/services/workspace/workspace_control_target.dart';
import 'package:soar_score_contest/widgets/shell_status_panel.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest({ScoringAccess access = ScoringAccess.closed}) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000017'),
  name: 'Front Range ALES Open',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  host: 'Front Range Soaring',
  lifecycleState: LifecycleState.running,
  scoringAccess: access,
  adminLock: AdminLock.locked,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

void main() {
  testWidgets('shows status, participant scoring and administration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShellStatusPanel(contest: _contest(access: ScoringAccess.open)),
        ),
      ),
    );

    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Lifecycle'), findsNothing);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Participant scoring'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
  });

  testWidgets('each value is a button with its own accessible name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final opened = <WorkspaceControlTarget>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShellStatusPanel(
            contest: _contest(access: ScoringAccess.open),
            onOpen: opened.add,
          ),
        ),
      ),
    );

    for (final name in [
      'Status: Running. Go to the status control',
      'Participant scoring: Open. Go to the participant scoring control',
      'Administration: Locked. Go to the administration control',
    ]) {
      final node = tester.getSemantics(find.bySemanticsLabel(name));
      expect(node.label, name);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    }

    await tester.tap(find.text('Status'));
    await tester.tap(find.text('Participant scoring'));
    await tester.tap(find.text('Administration'));
    // The panel's three values; publication is a target but has no value
    // in the panel.
    expect(opened, [
      WorkspaceControlTarget.lifecycle,
      WorkspaceControlTarget.scoring,
      WorkspaceControlTarget.administration,
    ]);
    handle.dispose();
  });

  testWidgets('a value is at least 48 dp to hit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShellStatusPanel(contest: _contest(), onOpen: (_) {}),
        ),
      ),
    );
    final size = tester.getSize(
      find.ancestor(of: find.text('Status'), matching: find.byType(InkWell)),
    );
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });

  testWidgets('without a callback the values are not buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ShellStatusPanel(contest: _contest())),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
  });
}
