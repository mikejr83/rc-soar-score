import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_contest/services/new_contest/draft_participant.dart';
import 'package:soar_score_contest/services/new_contest/draw_settings.dart';
import 'package:soar_score_contest/services/new_contest/participant_option.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/new_contest_test_support.dart';
import '../support/participants_step_support.dart';

/// [n] pilots; the first [teamSize] are on one team.
List<DraftParticipant> _pilots(int n, {int teamSize = 0}) => [
  for (var i = 0; i < n; i++)
    DraftParticipant(
      profileId: Id.parse(
        '019c0000-0000-7000-8000-0000000002${i.toString().padLeft(2, '0')}',
      ),
      name: 'Pilot $i',
      team: i < teamSize ? 'Flying Gators' : '',
    ),
];

Future<ContestDraftStore> _store({
  int pilots = 10,
  int teamSize = 3,
  Set<ParticipantOption> options = const {ParticipantOption.teams},
}) => storeAtStep4(
  options: options,
  participants: _pilots(pilots, teamSize: teamSize),
  visitedThrough: 6,
);

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pilots per group updates live, and too many groups blocks', (
    tester,
  ) async {
    final store = await _store();
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(stepTitle(tester), 'Draw options');
    expect(find.text('The matrix isn’t drawn here'), findsOneWidget);
    // 10 pilots start as 1 group of 10.
    expect(find.text('10 pilots'), findsOneWidget);

    await tester.enterText(_field('groups-per-round'), '3');
    await tester.pumpAndSettle();
    expect(find.text('3–4 pilots'), findsOneWidget);
    expect(store.draft.drawSettings.groups, '3');

    await tester.enterText(_field('groups-per-round'), '6');
    await tester.pumpAndSettle();
    expect(find.textContaining('Blocked:', findRichText: true), findsOneWidget);
    await next(tester);
    expect(stepTitle(tester), 'Draw options');
    expect(
      find.text(
        'Groups per round: Use 5 or fewer so every group has at least 2 '
        'scoring pilots.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('team protection raises the minimum groups and rules out a '
      'seeded draw', (tester) async {
    final store = await _store();
    await pumpWizard(tester, respond: stepApi, store: store);

    await _tap(tester, find.byKey(const ValueKey('team-protection')));
    expect(store.draft.drawSettings.teamProtection, isTrue);
    // The largest team has 3 pilots, so groups go up to 3.
    expect(store.draft.drawSettings.groups, '3');
    expect(find.text('Seeded Man on Man is now unavailable'), findsOneWidget);
    expect(
      find.textContaining('Unavailable while team protection is on.'),
      findsOneWidget,
    );

    await tester.enterText(_field('groups-per-round'), '2');
    await tester.pumpAndSettle();
    expect(
      find.text('Team protection needs at least 3 groups.'),
      findsOneWidget,
    );

    await _tap(tester, find.byKey(const ValueKey('draw-mode-seededManOnMan')));
    expect(store.draft.drawSettings.drawMode, DrawMode.standardManOnMan);
  });

  testWidgets('a seeded draw disables team protection and asks for seeded '
      'rounds', (tester) async {
    final store = await _store();
    await pumpWizard(tester, respond: stepApi, store: store);

    await _tap(tester, find.byKey(const ValueKey('draw-mode-seededManOnMan')));
    expect(store.draft.drawSettings.seeded, isTrue);
    expect(find.text('Unavailable with Seeded Man on Man'), findsOneWidget);
    final protection = tester.widget<Switch>(
      find.byKey(const ValueKey('team-protection')),
    );
    expect(protection.onChanged, isNull);

    await tester.enterText(_field('seeded-rounds'), '0');
    await tester.pumpAndSettle();
    expect(find.text('At least 1 seeded round'), findsOneWidget);
  });

  testWidgets('avoiding back-to-back flights warns about fairness, and about '
      'small contests', (tester) async {
    final store = await _store(teamSize: 0, options: const {});
    await pumpWizard(tester, respond: stepApi, store: store);
    expect(find.text('Teams are off'), findsOneWidget);

    await tester.enterText(_field('groups-per-round'), '2');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('back-to-back')));
    expect(find.text('Draw fairness decreases'), findsOneWidget);
    expect(
      find.text('This contest is too small for the constraint'),
      findsOneWidget,
    );

    // The warning doesn't block continuing.
    await next(tester);
    expect(stepTitle(tester), 'Summary & create');
  });

  testWidgets('narrow windows stack the calculation under the inputs', (
    tester,
  ) async {
    final store = await _store();
    await pumpWizard(
      tester,
      respond: stepApi,
      store: store,
      size: const Size(800, 1180),
    );
    expect(find.byKey(const ValueKey('group-calculation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('GroupPlan', () {
    test('suggests groups of about 10 within the limits', () {
      expect(GroupPlan.suggestedGroups(2, 1), 1);
      expect(GroupPlan.suggestedGroups(25, 1), 3);
      expect(GroupPlan.suggestedGroups(25, 4), 4);
      expect(GroupPlan.suggestedGroups(3, 1), 1);
    });
  });
}
