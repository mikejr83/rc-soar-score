import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/models/contests_view.dart';
import 'package:soar_score_self_score/models/link_candidate.dart';
import 'package:soar_score_self_score/pages/contests_page.dart';
import 'package:soar_score_self_score/widgets/link_candidates_section.dart';

/// Offers one candidate and records the answers; [answer] can fail them.
class _Repository extends SampleSelfScoreRepository {
  _Repository({this.candidates = _one, this.answer});

  static const _one = [
    LinkCandidate(
      id: 'c1',
      pilotName: 'Penny Pilot',
      contests: [
        LinkCandidateContest(
          name: 'Spring Open',
          dates: '10 Oct 2026 to 11 Oct 2026',
        ),
      ],
    ),
  ];

  final List<LinkCandidate> candidates;
  final Future<void> Function()? answer;
  final confirmed = <String>[];
  final declined = <String>[];
  int contestLoads = 0;
  int candidateLoads = 0;

  @override
  Future<List<LinkCandidate>> linkCandidates() async {
    candidateLoads++;
    return candidates;
  }

  @override
  Future<void> confirmLinkCandidate(String candidateId) async {
    await answer?.call();
    confirmed.add(candidateId);
  }

  @override
  Future<void> declineLinkCandidate(String candidateId) async {
    await answer?.call();
    declined.add(candidateId);
  }

  @override
  Future<ContestsView> contests() async {
    contestLoads++;
    return const ContestsView(contests: []);
  }
}

Widget _app(SelfScoreRepository repository, Widget home) => SelfScoreScope(
  repository: repository,
  child: MaterialApp(
    localizationsDelegates: appLocalizationDelegates,
    home: home,
  ),
);

Future<void> _tall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a candidate is shown with its contests and both answers', (
    tester,
  ) async {
    await _tall(tester);
    await tester.pumpWidget(
      _app(_Repository(), const Scaffold(body: LinkCandidatesSection())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Is this you?'), findsOneWidget);
    expect(
      find.text('The email on your account matches the pilot Penny Pilot.'),
      findsOneWidget,
    );
    expect(
      find.text('Spring Open, 10 Oct 2026 to 11 Oct 2026'),
      findsOneWidget,
    );
    expect(find.text("Yes, that's me"), findsOneWidget);
    expect(find.text('Not me'), findsOneWidget);
  });

  testWidgets('no candidates shows nothing', (tester) async {
    await _tall(tester);
    await tester.pumpWidget(
      _app(
        _Repository(candidates: const []),
        const Scaffold(body: LinkCandidatesSection()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Is this you?'), findsNothing);
  });

  testWidgets('Yes sends the confirmation, drops the card, tells the page', (
    tester,
  ) async {
    await _tall(tester);
    final repository = _Repository();
    var linked = 0;
    await tester.pumpWidget(
      _app(
        repository,
        Scaffold(body: LinkCandidatesSection(onLinked: () => linked++)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Yes, that's me"));
    await tester.pumpAndSettle();

    expect(repository.confirmed, ['c1']);
    expect(repository.declined, isEmpty);
    expect(linked, 1);
    expect(find.text('Is this you?'), findsNothing);
  });

  testWidgets('Not me sends the decline and drops the card', (tester) async {
    await _tall(tester);
    final repository = _Repository();
    var linked = 0;
    await tester.pumpWidget(
      _app(
        repository,
        Scaffold(body: LinkCandidatesSection(onLinked: () => linked++)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not me'));
    await tester.pumpAndSettle();

    expect(repository.declined, ['c1']);
    expect(repository.confirmed, isEmpty);
    expect(linked, 0);
    expect(find.text('Is this you?'), findsNothing);
  });

  testWidgets('buttons are off while an answer is in flight', (tester) async {
    await _tall(tester);
    final release = Completer<void>();
    final repository = _Repository(answer: () => release.future);
    await tester.pumpWidget(
      _app(repository, const Scaffold(body: LinkCandidatesSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Yes, that's me"));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, "Yes, that's me"),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Not me'))
          .onPressed,
      isNull,
    );
    release.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a failed answer keeps the card so it can be sent again', (
    tester,
  ) async {
    await _tall(tester);
    var fail = true;
    final repository = _Repository(
      answer: () async {
        if (fail) throw const SelfScoreOfflineException('offline');
      },
    );
    await tester.pumpWidget(
      _app(repository, const Scaffold(body: LinkCandidatesSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Yes, that's me"));
    await tester.pumpAndSettle();
    expect(find.text('Could not save your answer. Try again.'), findsOneWidget);
    expect(find.text('Is this you?'), findsOneWidget);

    fail = false;
    await tester.tap(find.text("Yes, that's me"));
    await tester.pumpAndSettle();
    expect(repository.confirmed, ['c1']);
    expect(find.text('Is this you?'), findsNothing);
  });

  testWidgets('a pilot held by another account says so, then goes', (
    tester,
  ) async {
    await _tall(tester);
    final repository = _Repository(
      answer: () async => throw const LinkCandidateGoneException(
        LinkCandidateGoneReason.alreadyLinked,
      ),
    );
    var linked = 0;
    await tester.pumpWidget(
      _app(
        repository,
        Scaffold(body: LinkCandidatesSection(onLinked: () => linked++)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Yes, that's me"));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('This pilot is already linked to another account.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Is this you?'), findsNothing);
    expect(linked, 0);
  });

  testWidgets('a match that is gone says so', (tester) async {
    await _tall(tester);
    final repository = _Repository(
      answer: () async => throw const LinkCandidateGoneException(
        LinkCandidateGoneReason.notAvailable,
      ),
    );
    await tester.pumpWidget(
      _app(repository, const Scaffold(body: LinkCandidatesSection())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not me'));
    await tester.pump();
    await tester.pump();
    expect(find.text('This match is no longer available.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Is this you?'), findsNothing);
  });

  testWidgets('a failed load offers Try again and does not break the page', (
    tester,
  ) async {
    await _tall(tester);
    final repository = _FlakyCandidates();
    await tester.pumpWidget(
      _app(repository, const Scaffold(body: LinkCandidatesSection())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not check for matching pilots.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Is this you?'), findsOneWidget);
    expect(find.text('Could not check for matching pilots.'), findsNothing);
  });

  testWidgets('the contests page loads its list again after a link', (
    tester,
  ) async {
    await _tall(tester);
    final repository = _Repository();
    await tester.pumpWidget(_app(repository, const ContestsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Is this you?'), findsOneWidget);
    expect(repository.contestLoads, 1);

    await tester.tap(find.text("Yes, that's me"));
    await tester.pumpAndSettle();
    expect(repository.contestLoads, 2);
    expect(find.text('Is this you?'), findsNothing);
  });

  testWidgets('declining does not reload the contests list', (tester) async {
    await _tall(tester);
    final repository = _Repository();
    await tester.pumpWidget(_app(repository, const ContestsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not me'));
    await tester.pumpAndSettle();
    expect(repository.contestLoads, 1);
  });
}

class _FlakyCandidates extends _Repository {
  @override
  Future<List<LinkCandidate>> linkCandidates() async {
    if (candidateLoads++ == 0) throw const SelfScoreOfflineException('down');
    return candidates;
  }
}
