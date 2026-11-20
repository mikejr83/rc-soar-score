import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localization_delegates.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/widgets/sync/sync_details_card.dart';

Future<void> _pump(WidgetTester tester, SyncScopeSummary summary) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SyncDetailsCard(
            summary: summary,
            syncing: false,
            onSyncNow: null,
          ),
        ),
      ),
    );

void main() {
  testWidgets('a local-only contest says it is local only', (tester) async {
    await _pump(tester, const SyncScopeSummary(localOnly: true));

    expect(find.byKey(const ValueKey('sync-local-only')), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-problem')), findsNothing);
  });

  testWidgets('a local-only contest shows why the account is not linked', (
    tester,
  ) async {
    await _pump(
      tester,
      const SyncScopeSummary(
        localOnly: true,
        problem: SyncProblem.accountClaimBlocked,
      ),
    );

    expect(find.byKey(const ValueKey('sync-local-only')), findsOneWidget);
    expect(find.text('Account not linked'), findsOneWidget);
    expect(
      find.text(SyncProblem.accountClaimBlocked.explanation),
      findsOneWidget,
    );
  });

  testWidgets('a synced contest still shows its own problem', (tester) async {
    await _pump(tester, const SyncScopeSummary(problem: SyncProblem.offline));

    expect(find.text('Offline'), findsOneWidget);
    expect(find.byKey(const ValueKey('sync-local-only')), findsNothing);
  });

  testWidgets('changes held for an older service are counted', (tester) async {
    await _pump(
      tester,
      const SyncScopeSummary(pendingChanges: 1, waitingForNewerService: 1),
    );
    expect(find.text('Waiting for a newer service'), findsOneWidget);
  });

  testWidgets('no held changes, no such row', (tester) async {
    await _pump(tester, const SyncScopeSummary(pendingChanges: 1));
    expect(find.text('Waiting for a newer service'), findsNothing);
  });
}
