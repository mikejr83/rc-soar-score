import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_control_slot.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_live_region.dart';
import 'package:soar_score_contest/services/workspace/workspace_control.dart';
import 'package:soar_score_contest/services/workspace/workspace_section.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_section_slot.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('a section slot is a labelled region with a placeholder', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const WorkspaceSectionSlot(section: WorkspaceSection.nextStep)),
    );
    expect(find.text('Next step goes here'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workspace-section-next-step')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Next step'), findsWidgets);
    handle.dispose();
  });

  testWidgets('a control slot highlights without colour alone', (tester) async {
    await tester.pumpWidget(
      _app(
        const WorkspaceControlSlot(
          control: WorkspaceControl.lifecycle,
          highlighted: true,
        ),
      ),
    );
    final card = tester.widget<Card>(
      find.byKey(const ValueKey('workspace-control-lifecycle')),
    );
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.side.width, 2);
  });

  testWidgets('the live region exposes its message politely', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const WorkspaceLiveRegion(message: 'Open scoring')),
    );
    expect(
      tester.getSemantics(find.byType(WorkspaceLiveRegion)),
      matchesSemantics(label: 'Open scoring', isLiveRegion: true),
    );
    handle.dispose();
  });
}
