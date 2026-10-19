import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_action.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_target.dart';
import 'package:soar_score_contest/widgets/workspace/next_step/next_step_navigator.dart';

import '../../../support/matrix_test_support.dart';

Future<void> _open(WidgetTester tester, NextStepAction action) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => NextStepNavigator.open(
                context,
                action,
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
        participantsPath: 'Participants stub',
        contestScoringPath(matrixContestId): 'Scoring stub',
        contestReportsPath(matrixContestId): 'Reports stub',
      }.entries)
        GoRoute(path: entry.key, builder: (context, _) => Text(entry.value)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('Go'));
  await tester.pumpAndSettle();
}

NextStepAction _to(NextStepTarget target, {int? round, int? group}) =>
    NextStepAction(label: 'Go on', target: target, round: round, group: group);

void main() {
  group('opens a page', () {
    final pages = {
      NextStepTarget.configuration: 'Configuration stub',
      NextStepTarget.matrix: 'Matrix stub',
      NextStepTarget.participants: 'Participants stub',
      NextStepTarget.reports: 'Reports stub',
    };
    pages.forEach((target, text) {
      testWidgets('${target.name} goes to its route', (tester) async {
        await _open(tester, _to(target));
        expect(find.text(text), findsOneWidget);
      });
    });
  });

  group('opens scoring', () {
    testWidgets('at the round and group of the action', (tester) async {
      final seen = <Uri>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => NextStepNavigator.open(
                    context,
                    _to(NextStepTarget.scoring, round: 3, group: 2),
                    contestId: matrixContestId,
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: contestScoringPath(matrixContestId),
            builder: (context, state) {
              seen.add(state.uri);
              return const Text('Scoring stub');
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(seen.single.queryParameters, {'round': '3', 'group': '2'});
    });

    testWidgets('without a place goes to the page itself', (tester) async {
      await _open(tester, _to(NextStepTarget.scoring));
      expect(find.text('Scoring stub'), findsOneWidget);
    });
  });

  group('shows the not-available dialog', () {
    final dialogs = {
      NextStepTarget.publish: ('Publish', 'The publish flow is not built yet.'),
    };
    dialogs.forEach((target, text) {
      testWidgets('${target.name} says what is missing', (tester) async {
        await _open(tester, _to(target));
        expect(find.text('${text.$1} is not available yet'), findsOneWidget);
        expect(find.text(text.$2), findsOneWidget);
      });
    });
  });

  test('the in-place targets are not navigation', () {
    expect(NextStepNavigator.isInPlace(NextStepTarget.unlock), isTrue);
    expect(NextStepNavigator.isInPlace(NextStepTarget.openScoring), isTrue);
    expect(NextStepNavigator.isInPlace(NextStepTarget.completeDialog), isTrue);
    expect(
      NextStepNavigator.isInPlace(NextStepTarget.dismissSuggestion),
      isTrue,
    );
    expect(NextStepNavigator.isInPlace(NextStepTarget.matrix), isFalse);
  });
}
