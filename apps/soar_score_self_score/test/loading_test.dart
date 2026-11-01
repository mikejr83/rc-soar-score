import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/models/contests_view.dart';
import 'package:soar_score_self_score/pages/contests_page.dart';
import 'package:soar_score_self_score/pages/team_page.dart';

/// Fails the first contests load, then succeeds, to exercise Retry.
class _FlakyRepository extends SampleSelfScoreRepository {
  _FlakyRepository();

  int calls = 0;

  @override
  Future<ContestsView> contests() async {
    calls++;
    if (calls == 1) throw Exception('network down');
    return super.contests();
  }
}

Widget _app(SelfScoreRepository repository, Widget home) => SelfScoreScope(
  repository: repository,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  ),
);

void main() {
  testWidgets('shows a loading indicator, then the data', (tester) async {
    await tester.pumpWidget(
      _app(const SampleSelfScoreRepository(), const ContestsPage()),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(SampleData.contestName), findsOneWidget);
  });

  testWidgets('a failed load shows Retry, and Retry loads again', (
    tester,
  ) async {
    final repository = _FlakyRepository();
    await tester.pumpWidget(_app(repository, const ContestsPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load this page'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsNothing);
    expect(find.text(SampleData.contestName), findsOneWidget);
    expect(repository.calls, 2);
  });

  testWidgets('an unknown contest shows the repository message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SampleSelfScoreRepository(),
        const TeamPage(contestId: 'nope'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This contest could not be found.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
