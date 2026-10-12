import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/workspace/workspace_control_target.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_focus_controller.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_frame.dart';

import '../../support/matrix_test_support.dart';
import '../../support/next_step_widget_support.dart';

WorkspaceServer _server() => WorkspaceServer(
  configuration: matrixConfiguration(),
  matrix: drawnMatrix(),
);

String? _focusLabel() => FocusManager.instance.primaryFocus?.debugLabel;

double _scrolled(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(WorkspaceFrame),
        matching: find.byType(Scrollable),
      ),
    )
    .position
    .pixels;

bool _highlighted(WidgetTester tester, String id) {
  final card = tester.widget<Card>(
    find.byKey(ValueKey('workspace-control-$id')),
  );
  return (card.shape! as RoundedRectangleBorder).side.width == 2;
}

const _labels = {
  WorkspaceControlTarget.lifecycle: 'Status',
  WorkspaceControlTarget.scoring: 'Participant scoring',
  WorkspaceControlTarget.administration: 'Administration',
};

void main() {
  group('on the workspace', () {
    for (final target in WorkspaceControlTarget.values) {
      testWidgets('${target.fragment} scrolls, focuses and highlights, then '
          'the highlight fades', (tester) async {
        await pumpShellWorkspace(tester, _server());
        expect(_highlighted(tester, target.fragment), isFalse);

        await tester.tap(find.text(_labels[target]!));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(_focusLabel(), 'workspace-${target.fragment}');
        expect(_highlighted(tester, target.fragment), isTrue);
        if (target == WorkspaceControlTarget.administration) {
          expect(_scrolled(tester), greaterThan(0));
        }

        await tester.pump(workspaceHighlightDuration);
        expect(_highlighted(tester, target.fragment), isFalse);
        expect(_focusLabel(), 'workspace-${target.fragment}');
      });
    }

    testWidgets('a second link moves the highlight and cancels the first', (
      tester,
    ) async {
      await pumpShellWorkspace(tester, _server());
      await tester.tap(find.text('Administration'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Participant scoring'));
      await tester.pump();

      expect(_highlighted(tester, 'administration'), isFalse);
      expect(_highlighted(tester, 'scoring'), isTrue);
      // The first timer would end here; the second has 1.5 s left.
      await tester.pump(const Duration(milliseconds: 1600));
      expect(_highlighted(tester, 'scoring'), isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(_highlighted(tester, 'scoring'), isFalse);
    });

    testWidgets('the panel changes nothing on the server', (tester) async {
      final server = _server();
      await pumpShellWorkspace(tester, server);
      for (final label in _labels.values) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        await tester.pump(workspaceHighlightDuration);
      }
      expect(server.actions, isEmpty);
    });
  });

  group('reduced motion', () {
    testWidgets('jumps to the control and keeps the highlight', (tester) async {
      await pumpShellWorkspace(tester, _server(), disableAnimations: true);
      await tester.tap(find.text('Administration'));
      await tester.pump();
      final jumped = _scrolled(tester);
      expect(jumped, greaterThan(0));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(_scrolled(tester), jumped);
      expect(_highlighted(tester, 'administration'), isTrue);
    });

    testWidgets('otherwise the scroll animates', (tester) async {
      await pumpShellWorkspace(tester, _server());
      await tester.tap(find.text('Administration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final early = _scrolled(tester);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(early, lessThan(_scrolled(tester)));
    });
  });

  group('from another page', () {
    testWidgets('opens the workspace on the control and focuses it', (
      tester,
    ) async {
      final router = await pumpShellWorkspace(
        tester,
        _server(),
        location: contestConfigurationPath(matrixContestId),
      );
      expect(find.text('Configuration stub'), findsOneWidget);

      await tester.tap(find.text('Administration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        router.state.uri.toString(),
        contestWorkspacePathFor(
          matrixContestId,
          WorkspaceControlTarget.administration,
        ),
      );
      expect(find.text('Configuration stub'), findsNothing);
      expect(_focusLabel(), 'workspace-administration');
      expect(_highlighted(tester, 'administration'), isTrue);
    });
  });

  group('opening a link with a fragment', () {
    testWidgets('focuses the control once loaded', (tester) async {
      await pumpShellWorkspace(
        tester,
        _server(),
        location: contestWorkspacePathFor(
          matrixContestId,
          WorkspaceControlTarget.administration,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(_focusLabel(), 'workspace-administration');
      expect(_highlighted(tester, 'administration'), isTrue);
    });

    testWidgets('an unknown fragment does nothing', (tester) async {
      await pumpShellWorkspace(
        tester,
        _server(),
        location: '${contestWorkspacePath(matrixContestId)}#nonsense',
      );
      expect(_focusLabel(), isNot(startsWith('workspace-')));
      for (final id in ['lifecycle', 'scoring', 'administration']) {
        expect(_highlighted(tester, id), isFalse);
      }
    });
  });

  group('the fragment', () {
    test('maps to a target, and unknown or empty ones are ignored', () {
      expect(
        WorkspaceControlTarget.fromFragment('scoring'),
        WorkspaceControlTarget.scoring,
      );
      expect(WorkspaceControlTarget.fromFragment('results'), isNull);
      expect(WorkspaceControlTarget.fromFragment(''), isNull);
      expect(WorkspaceControlTarget.fromFragment(null), isNull);
    });

    test('is added to the workspace path', () {
      expect(
        contestWorkspacePathFor('c1', WorkspaceControlTarget.lifecycle),
        '${contestWorkspacePath('c1')}#lifecycle',
      );
    });
  });
}
