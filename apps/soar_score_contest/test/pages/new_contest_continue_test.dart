import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';

import '../support/new_contest_test_support.dart';

void main() {
  testWidgets('with a draft underway the entry points say Continue '
      'configuration', (tester) async {
    final store = ContestDraftStore();
    await pumpWizard(
      tester,
      respond: emptyApi,
      store: store,
      initial: homePath,
    );

    // No draft yet: both entry points create.
    expect(find.text('Create contest'), findsOneWidget);
    expect(find.byTooltip('Create contest'), findsOneWidget);
    expect(find.text('Continue configuration'), findsNothing);

    // Opening the wizard without entering anything is not a draft.
    await store.update(const ContestDraft());
    await tester.pumpAndSettle();
    expect(find.text('Create contest'), findsOneWidget);

    await store.update(const ContestDraft(name: 'Gator Cup'));
    await tester.pumpAndSettle();
    expect(find.text('Continue configuration'), findsOneWidget);
    expect(find.byTooltip('Continue configuration'), findsOneWidget);
    expect(find.text('Create contest'), findsNothing);
    expect(find.byIcon(Icons.edit_note), findsNWidgets(2));

    // Both open the wizard, where the draft resumes.
    await tester.tap(find.byKey(const ValueKey('empty-create-contest')));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'Details & copy source');

    // Creating the contest (or discarding) brings the plain label back.
    store.discard();
    await tester.pumpAndSettle();
    expect(store.hasDraft, isFalse);
  });
}
