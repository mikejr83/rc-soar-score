import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/score_changes.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/pilot_overview.dart';
import 'package:soar_score_self_score/pages/pilot_overview_page.dart';

/// Counts loads and can drop the team.
class _CountingRepository extends SampleSelfScoreRepository {
  _CountingRepository({this.team = true});

  final bool team;
  int loads = 0;

  @override
  Future<PilotOverview> pilotOverview(String contestId, String pilotId) async {
    loads++;
    final base = await super.pilotOverview(contestId, pilotId);
    return PilotOverview(
      contestName: base.contestName,
      teamName: team ? base.teamName : null,
      pilotName: base.pilotName,
      pilotNumber: base.pilotNumber,
      rounds: base.rounds,
    );
  }
}

Future<void> _pump(WidgetTester tester, _CountingRepository repository) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SelfScoreScope(
      repository: repository,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: PilotOverviewPage(contestId: SampleData.contestId, pilotId: '12'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a pilot on a team can go back to the team', (tester) async {
    await _pump(tester, _CountingRepository());
    expect(find.byTooltip('Back to pilots'), findsOneWidget);
  });

  testWidgets('a pilot without a team has no way back to a team', (
    tester,
  ) async {
    await _pump(tester, _CountingRepository(team: false));
    expect(find.byTooltip('Back to pilots'), findsNothing);
  });

  testWidgets('an accepted score reloads the overview', (tester) async {
    final repository = _CountingRepository();
    await _pump(tester, repository);
    expect(repository.loads, 1);

    scoreChanges.value++;
    await tester.pumpAndSettle();

    expect(repository.loads, 2);
  });
}
