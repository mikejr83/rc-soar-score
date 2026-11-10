import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/group_results.dart';
import 'package:soar_score_self_score/models/results_view.dart';
import 'package:soar_score_self_score/pages/group_results_page.dart';
import 'package:soar_score_self_score/pages/results_page.dart';

class _Repository extends SampleSelfScoreRepository {
  int calls = 0;
  Completer<void>? pending;

  Future<void> _read() async {
    calls++;
    await pending?.future;
  }

  @override
  Future<GroupResults> groupResults(
    String contestId,
    String pilotId,
    int round,
  ) async {
    await _read();
    final data = await super.groupResults(contestId, pilotId, round);
    return GroupResults(
      contestName: 'Fetch $calls',
      round: data.round,
      group: data.group,
      latestRound: data.latestRound,
      rows: data.rows,
    );
  }

  @override
  Future<ResultsView> results(String contestId, {int? asOfRound}) async {
    await _read();
    final data = await super.results(contestId, asOfRound: asOfRound);
    return ResultsView(
      contestName: 'Fetch $calls',
      latestRound: data.latestRound,
      snapshot: data.snapshot,
      heldRound: data.heldRound,
    );
  }
}

void main() {
  for (final group in [true, false]) {
    testWidgets(
      '${group ? 'group' : 'overall'} refresh succeeds, fails and retries',
      (tester) async {
        final repository = _Repository();
        var now = DateTime(2026, 1, 1, 12);
        await tester.pumpWidget(
          SelfScoreScope(
            repository: repository,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: group
                  ? GroupResultsPage(
                      contestId: SampleData.contestId,
                      pilotId: '12',
                      roundId: '4',
                      now: () => now,
                    )
                  : ResultsPage(
                      contestId: SampleData.contestId,
                      asOfRound: 4,
                      now: () => now,
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(repository.calls, 1);
        expect(find.textContaining('Fetch 1'), findsOneWidget);
        final initialTime = tester
            .widget<Text>(find.textContaining('Last refreshed:'))
            .data;
        now = now.add(const Duration(seconds: 2));
        repository.pending = Completer<void>();
        await tester.tap(find.text('Refresh'));
        await tester.pump();
        expect(find.text('Refreshing…'), findsOneWidget);
        expect(find.textContaining('Fetch 1'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, 'Refreshing…'),
              )
              .onPressed,
          isNull,
        );
        expect(repository.calls, 2);
        now = now.add(const Duration(seconds: 1));
        repository.pending!.complete();
        await tester.pumpAndSettle();
        final successTime = tester
            .widget<Text>(find.textContaining('Last refreshed:'))
            .data;
        final successClock = successTime!.substring(
          successTime.indexOf(':') + 2,
        );
        expect(successTime, isNot(initialTime));
        expect(find.textContaining('Fetch 2'), findsOneWidget);
        expect(find.textContaining('Fetch 1'), findsNothing);
        repository.pending = Completer<void>();
        await tester.tap(find.text('Refresh'));
        await tester.pump();
        now = now.add(const Duration(seconds: 1));
        repository.pending!.completeError(Exception('offline'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Could not load this page'), findsOneWidget);
        expect(
          tester.widget<Text>(find.textContaining('last updated')).data,
          endsWith(successClock),
        );
        repository.pending = null;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Could not load this page'), findsNothing);
        expect(repository.calls, 4);
        await tester.pump(const Duration(minutes: 5));
        expect(repository.calls, 4); // No polling.
        repository.pending = Completer<void>();
        await tester.tap(find.text('Refresh'));
        await tester.pump();
        repository.pending!.completeError(const SessionEndedException());
        await tester.pumpAndSettle();
        expect(find.text('Back to start'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Refresh'))
              .onPressed,
          isNull,
        );
        expect(find.text('(you)'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
