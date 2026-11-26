import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/models/past_contests.dart';
import 'package:soar_score_self_score/public_site.dart';
import 'package:soar_score_self_score/widgets/past_contests_section.dart';

PastContest _contest(int n, {Uri? results, String? location}) => PastContest(
  participationId: 'p-$n',
  contestId: 'c-$n',
  name: 'Contest $n',
  startDate: DateTime.utc(2026, 4, n),
  endDate: DateTime.utc(2026, 4, n + 1),
  location: location,
  publicResultsUrl: results,
);

class _Repository extends SampleSelfScoreRepository {
  _Repository(this.pages);

  /// The pages in the order they are asked for; an [Exception] is thrown.
  final List<Object> pages;
  final offsets = <int>[];

  @override
  Future<PastContestsPage> pastContests({int offset = 0}) async {
    offsets.add(offset);
    final next = pages.removeAt(0);
    if (next is Exception) throw next;
    return next as PastContestsPage;
  }
}

Future<void> _pump(
  WidgetTester tester,
  SelfScoreRepository repository, {
  UrlOpener? opener,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SelfScoreScope(
      repository: repository,
      child: MaterialApp(
        localizationsDelegates: appLocalizationDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: opener == null
                ? const PastContestsSection()
                : PastContestsSection(opener: opener),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the contests with dates and place', (tester) async {
    await _pump(
      tester,
      _Repository([
        PastContestsPage(contests: [_contest(1, location: 'Boulder, CO')]),
      ]),
    );

    expect(find.text('Past contests'), findsOneWidget);
    expect(find.text('Contest 1'), findsOneWidget);
    expect(find.text('Boulder, CO'), findsOneWidget);
    expect(find.textContaining('Apr 1, 2026'), findsOneWidget);
    expect(find.text('Public results'), findsNothing);
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets('says so when there are none', (tester) async {
    await _pump(tester, _Repository([const PastContestsPage(contests: [])]));

    expect(
      find.text('No finished contests yet. They show up here after they end.'),
      findsOneWidget,
    );
  });

  testWidgets('shows more adds the next page after the first', (tester) async {
    final repository = _Repository([
      PastContestsPage(contests: [_contest(1), _contest(2)], nextOffset: 2),
      PastContestsPage(contests: [_contest(3)]),
    ]);
    await _pump(tester, repository);
    expect(find.text('Contest 3'), findsNothing);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(repository.offsets, [0, 2]);
    expect(
      [for (var n = 1; n <= 3; n++) find.text('Contest $n').evaluate().length],
      [1, 1, 1],
    );
    expect(find.text('Show more'), findsNothing, reason: 'last page');
  });

  testWidgets('a failed load says so and try again recovers', (tester) async {
    final repository = _Repository([
      const SelfScoreLoadException('down'),
      PastContestsPage(contests: [_contest(1)]),
    ]);
    await _pump(tester, repository);
    expect(find.text('Could not load your past contests.'), findsOneWidget);
    expect(find.text('Contest 1'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Contest 1'), findsOneWidget);
    expect(find.text('Could not load your past contests.'), findsNothing);
    expect(repository.offsets, [0, 0]);
  });

  testWidgets('a failed second page keeps the first and retries it', (
    tester,
  ) async {
    final repository = _Repository([
      PastContestsPage(contests: [_contest(1)], nextOffset: 1),
      const SelfScoreLoadException('down'),
      PastContestsPage(contests: [_contest(2)]),
    ]);
    await _pump(tester, repository);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('Contest 1'), findsOneWidget);
    expect(find.text('Could not load your past contests.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Contest 2'), findsOneWidget);
    expect(repository.offsets, [0, 1, 1]);
  });

  testWidgets('public results open through the opener', (tester) async {
    final opened = <Uri>[];
    await _pump(
      tester,
      _Repository([
        PastContestsPage(
          contests: [
            _contest(1, results: Uri.parse('https://rcsoarscore.com/r/1')),
          ],
        ),
      ]),
      opener: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    await tester.tap(find.text('Public results'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('https://rcsoarscore.com/r/1')]);
  });

  testWidgets('a page that arrives after the screen left is dropped', (
    tester,
  ) async {
    final gate = Completer<PastContestsPage>();
    final repository = _Slow(gate.future);
    await tester.pumpWidget(
      SelfScoreScope(
        repository: repository,
        child: MaterialApp(
          localizationsDelegates: appLocalizationDelegates,
          home: const Scaffold(body: PastContestsSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());

    gate.complete(PastContestsPage(contests: [_contest(1)]));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _Slow extends SampleSelfScoreRepository {
  _Slow(this.answer);

  final Future<PastContestsPage> answer;

  @override
  Future<PastContestsPage> pastContests({int offset = 0}) => answer;
}
