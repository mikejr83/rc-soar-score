import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:flutter/semantics.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/workspace/shell_round_item.dart';
import 'package:soar_score_contest/services/workspace/workspace_control_target.dart';
import 'package:soar_score_contest/widgets/shell_status_panel.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';
import '../support/workspace_facts_support.dart';

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

final l10n = AppLocalizationsEn();

void main() {
  testWidgets('shows status, participant scoring and administration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ShellStatusPanel(contest: _contest(access: ScoringAccess.open)),
        ),
      ),
    );

    expect(find.text(l10n.shellStatusLifecycle), findsOneWidget);
    expect(find.text('Lifecycle'), findsNothing);
    expect(find.text(l10n.lifecycleRunning), findsOneWidget);
    expect(find.text(l10n.shellStatusScoring), findsOneWidget);
    expect(find.text(l10n.shellScoringOpen), findsOneWidget);
    expect(find.text(l10n.shellStatusAdministration), findsOneWidget);
    expect(find.text(l10n.shellAdminLocked), findsOneWidget);
  });

  testWidgets('each value is a button with its own accessible name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final opened = <WorkspaceControlTarget>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
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

    await tester.tap(find.text(l10n.shellStatusLifecycle));
    await tester.tap(find.text(l10n.shellStatusScoring));
    await tester.tap(find.text(l10n.shellStatusAdministration));
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ShellStatusPanel(contest: _contest(), onOpen: (_) {}),
        ),
      ),
    );
    final size = tester.getSize(
      find.ancestor(
        of: find.text(l10n.shellStatusLifecycle),
        matching: find.byType(InkWell),
      ),
    );
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });

  testWidgets('without a callback the values are not buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: ShellStatusPanel(contest: _contest())),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
  });

  group('round entry', () {
    Future<void> pump(
      WidgetTester tester, {
      ShellRoundItem? round,
      ValueChanged<ShellRoundItem>? onOpenRound,
    }) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShellStatusPanel(
            contest: _contest(),
            round: round,
            onOpenRound: onOpenRound,
          ),
        ),
      ),
    );

    testWidgets('is absent without a round', (tester) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('shell-round-status')), findsNothing);
      expect(find.text('Round'), findsNothing);
    });

    testWidgets('names the round and group and opens scoring', (tester) async {
      final opened = <ShellRoundItem>[];
      final item = _inProgress();
      await pump(tester, round: item, onOpenRound: opened.add);
      expect(find.text('Round'), findsOneWidget);
      expect(find.text('2 of 2, group A'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('shell-round-status')));
      expect(opened, [item]);
    });
  });
}

ShellRoundItem _inProgress() {
  final matrix = drawnMatrix();
  final facts = WorkspaceFacts.derive(
    data: workspaceData(matrix: matrix),
    scores: scoresFor(matrix, {(1, 1): at(0), (2, 1): at(1)}),
  );
  return ShellRoundItem.of(facts)!;
}
