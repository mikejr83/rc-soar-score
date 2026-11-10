import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/score_changes.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/pilot_overview.dart';
import 'package:soar_score_self_score/pages/pilot_overview_page.dart';

/// Counts loads and can drop the team.
class _CountingRepository extends SampleSelfScoreRepository {
  _CountingRepository({this.team = true});

  final bool team;
  int loads = 0;
  bool linkFails = false;

  @override
  Future<String> invitationLink() async {
    if (linkFails) throw const SelfScoreLoadException('offline');
    return 'https://score.example/invitations/abc';
  }

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
  setUp(() => scoreChanges.value = 0);

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

  testWidgets('the bottom actions are buttons, results first', (tester) async {
    await _pump(tester, _CountingRepository());
    final results = find.widgetWithText(FilledButton, 'Results');
    final retire = find.widgetWithText(OutlinedButton, 'Retire pilot');
    expect(results, findsOneWidget);
    expect(retire, findsOneWidget);
    expect(
      find.descendant(of: results, matching: find.byType(Icon)),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(results).dy < tester.getTopLeft(retire).dy,
      isTrue,
    );
    expect(find.text('Copy invitation link'), findsNothing);
  });

  testWidgets('Copy invitation link is a title bar action', (tester) async {
    await _pump(tester, _CountingRepository());
    expect(find.byTooltip('Copy invitation link'), findsOneWidget);
  });

  testWidgets('the invitation link button copies the pilot\'s link', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, _CountingRepository());

    await tester.tap(find.byTooltip('Copy invitation link'));
    await tester.pumpAndSettle();

    expect(copied, 'https://score.example/invitations/abc');
    expect(find.text('Invitation link copied'), findsOneWidget);
  });

  testWidgets('a failed fetch says so and copies nothing', (tester) async {
    final repository = _CountingRepository()..linkFails = true;
    await _pump(tester, repository);

    await tester.tap(find.byTooltip('Copy invitation link'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Couldn't copy the invitation link"),
      findsOneWidget,
    );
    expect(find.text('Invitation link copied'), findsNothing);
  });
}
