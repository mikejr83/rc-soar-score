import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/preferences/director_time.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_contest/services/new_contest/draft_persistence.dart';

import '../support/fake_draft_persistence.dart';
import '../support/new_contest_test_support.dart';

void main() {
  final savedAt = DateTime(2026, 10, 18, 9, 5);
  const dialog = ValueKey('resume-draft-dialog');
  const keep = ValueKey('resume-draft-continue');
  const fresh = ValueKey('resume-draft-fresh');

  late FakeDraftPersistence persistence;
  late ContestDraftStore store;

  setUp(() {
    persistence = FakeDraftPersistence();
    store = ContestDraftStore(persistence: persistence);
  });

  void storeDraft(ContestDraft draft) =>
      persistence.stored['local'] = FoundStoredDraft(draft, savedAt);

  testWidgets('Continue brings back the stored values, and the time saved is '
      'shown', (tester) async {
    storeDraft(const ContestDraft(name: 'Gator Cup', visitedThrough: 1));
    await pumpWizard(tester, respond: emptyApi, store: store);

    expect(find.byKey(dialog), findsOneWidget);
    expect(find.textContaining(DirectorTime.format(savedAt)), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-name')), findsNothing);

    await tester.tap(find.byKey(keep));
    await tester.pumpAndSettle();

    expect(find.byKey(dialog), findsNothing);
    expect(find.text('Gator Cup'), findsOneWidget);
    expect(store.draft.name, 'Gator Cup');
  });

  testWidgets('Continue reopens on the step the director reached', (
    tester,
  ) async {
    storeDraft(const ContestDraft(name: 'Gator Cup', visitedThrough: 3));
    await pumpWizard(tester, respond: emptyApi, store: store);

    await tester.tap(find.byKey(keep));
    await tester.pumpAndSettle();

    expect(stepTitle(tester), isNot('Details & copy source'));
    expect(find.textContaining('STEP 3 OF'), findsOneWidget);
  });

  testWidgets('Start fresh shows a blank wizard and deletes the stored draft', (
    tester,
  ) async {
    storeDraft(const ContestDraft(name: 'Gator Cup'));
    await pumpWizard(tester, respond: emptyApi, store: store);

    await tester.tap(find.byKey(fresh));
    await tester.pumpAndSettle();

    expect(find.byKey(dialog), findsNothing);
    expect(store.draft.isBlank, isTrue);
    expect(find.text('Gator Cup'), findsNothing);
    expect(persistence.stored, isEmpty);
  });

  testWidgets('the prompt cannot be dismissed without choosing', (
    tester,
  ) async {
    storeDraft(const ContestDraft(name: 'Gator Cup'));
    await pumpWizard(tester, respond: emptyApi, store: store);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byKey(dialog), findsOneWidget);
    expect(persistence.stored, isNotEmpty);
  });

  testWidgets('a draft from another version can only be discarded', (
    tester,
  ) async {
    persistence.stored['local'] = UnreadableStoredDraft(savedAt);
    await pumpWizard(tester, respond: emptyApi, store: store);

    expect(find.byKey(dialog), findsOneWidget);
    expect(find.byKey(keep), findsNothing);

    await tester.tap(find.byKey(fresh));
    await tester.pumpAndSettle();

    expect(find.byKey(dialog), findsNothing);
    expect(persistence.stored, isEmpty);
    expect(find.byKey(const ValueKey('contest-name')), findsOneWidget);
  });

  testWidgets('nothing stored never shows the prompt', (tester) async {
    await pumpWizard(tester, respond: emptyApi, store: store);

    expect(find.byKey(dialog), findsNothing);
    expect(find.byKey(const ValueKey('contest-name')), findsOneWidget);
  });

  testWidgets('a draft already in memory resumes without asking', (
    tester,
  ) async {
    await store.restore();
    await store.update(const ContestDraft(name: 'Typed'));
    await pumpWizard(tester, respond: emptyApi, store: store);

    expect(find.byKey(dialog), findsNothing);
    expect(find.text('Typed'), findsOneWidget);
  });

  testWidgets('when Start fresh cannot delete the draft, Retry is offered', (
    tester,
  ) async {
    storeDraft(const ContestDraft(name: 'Gator Cup'));
    await pumpWizard(tester, respond: emptyApi, store: store);

    persistence.failing = true;
    await tester.tap(find.byKey(fresh));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('banner-save-failed')), findsOneWidget);
    expect(persistence.stored, isNotEmpty);

    persistence.failing = false;
    await tester.tap(find.byKey(const ValueKey('draft-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('banner-save-failed')), findsNothing);
    expect(persistence.stored, isEmpty);
  });

  testWidgets('leaving while the choice is open loses nothing', (tester) async {
    storeDraft(const ContestDraft(name: 'Gator Cup'));
    final wizard = await pumpWizard(tester, respond: emptyApi, store: store);
    expect(find.byKey(dialog), findsOneWidget);

    // The dialog outlives the page; the choice still counts.
    wizard.router.go(homePath);
    await tester.pumpAndSettle();
    expect(persistence.stored, isNotEmpty);
    await tester.tap(find.byKey(keep));
    await tester.pumpAndSettle();

    wizard.router.go(newContestPath);
    await tester.pumpAndSettle();
    expect(find.byKey(dialog), findsNothing);
    expect(find.text('Gator Cup'), findsOneWidget);
  });
}
