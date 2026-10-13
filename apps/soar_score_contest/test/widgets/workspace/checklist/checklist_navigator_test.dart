import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/workspace/checklist/checklist_item.dart';
import 'package:soar_score_contest/services/workspace/workspace_control_target.dart';
import 'package:soar_score_contest/widgets/workspace/checklist/checklist_navigator.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_focus_controller.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_focus_link.dart';

import '../../../support/matrix_test_support.dart';

Future<GoRouter> _open(
  WidgetTester tester,
  ChecklistTarget target, {
  WorkspaceFocusLink? link,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ChecklistNavigator.open(
                context,
                target,
                contestId: matrixContestId,
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      ),
      for (final entry in {
        contestConfigurationPath(matrixContestId): 'Configuration stub',
        contestMatrixPath(matrixContestId): 'Matrix stub',
        contestParticipantsPath(matrixContestId): 'Participants stub',
        contestWorkspacePath(matrixContestId): 'Workspace stub',
      }.entries)
        GoRoute(path: entry.key, builder: (context, _) => Text(entry.value)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    WorkspaceFocusLinkScope(
      link: link ?? WorkspaceFocusLink(),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.tap(find.text('Go'));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('opens a page', () {
    final pages = {
      ChecklistTarget.configuration: 'Configuration stub',
      ChecklistTarget.matrix: 'Matrix stub',
      ChecklistTarget.participants: 'Participants stub',
    };
    pages.forEach((target, text) {
      testWidgets('${target.name} goes to its route', (tester) async {
        await _open(tester, target);
        expect(find.text(text), findsOneWidget);
      });
    });
  });

  group('a control card', () {
    final controls = {
      ChecklistTarget.publicationControl: 'publication',
      ChecklistTarget.scoringControl: 'scoring',
    };
    controls.forEach((target, fragment) {
      testWidgets('$fragment opens the workspace on it when the workspace is '
          'not showing', (tester) async {
        final router = await _open(tester, target);
        expect(find.text('Workspace stub'), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.fragment, fragment);
      });
    });

    testWidgets('is focused in place when the workspace is showing', (
      tester,
    ) async {
      final controller = WorkspaceFocusController();
      addTearDown(controller.dispose);
      final link = WorkspaceFocusLink()..attach(controller);
      // The control is mounted so the controller can reach it.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KeyedSubtree(
                key: controller.anchorFor(
                  WorkspaceControlTarget.publication.control,
                ),
                child: Focus(
                  focusNode: controller.nodeFor(
                    WorkspaceControlTarget.publication.control,
                  ),
                  child: const SizedBox(height: 40, width: 40),
                ),
              ),
            ),
          ),
        ),
      );
      final focused = link.focus(
        WorkspaceControlTarget.publication,
        animate: false,
      );
      expect(focused, isTrue);
      expect(
        controller.highlighted,
        WorkspaceControlTarget.publication.control,
      );
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
