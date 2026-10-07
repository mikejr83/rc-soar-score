import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/new_contest_wizard_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';

import '../support/new_contest_test_support.dart';

void main() {
  testWidgets('the home page opens the wizard from the empty state', (
    tester,
  ) async {
    await pumpWizard(tester, respond: emptyApi, initial: homePath);

    await tester.tap(find.byKey(const ValueKey('empty-create-contest')));
    await tester.pumpAndSettle();
    expect(find.byType(NewContestWizardPage), findsOneWidget);
    expect(find.byKey(const ValueKey('create-contest')), findsNothing);
  });

  testWidgets('leaving with nothing unsaved needs no dialog, and the draft '
      'resumes when the wizard is opened again', (tester) async {
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    expect(find.byKey(const ValueKey('draft-status')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('breadcrumb-contests')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(NewContestWizardPage), findsNothing);
    expect(find.text(NewContestWizardPage.leftMessage), findsOneWidget);

    wizard.router.go(newContestPath);
    await tester.pumpAndSettle();
    expect(find.text('Gator Cup F5J'), findsOneWidget);
  });

  testWidgets('leaving with errors shown asks first', (tester) async {
    await pumpWizard(tester, respond: emptyApi);
    await next(tester);

    await tester.tap(find.text('Participants').first);
    await tester.pumpAndSettle();
    expect(find.text('Leave new contest?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(NewContestWizardPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('breadcrumb-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.byType(NewContestWizardPage), findsNothing);
  });

  testWidgets('a failed draft save keeps the values and offers Retry', (
    tester,
  ) async {
    var fail = false;
    final store = ContestDraftStore(
      writer: (_) async {
        if (fail) {
          throw StateError('storage full');
        }
      },
    );
    await pumpWizard(tester, respond: emptyApi, store: store);

    fail = true;
    await tester.enterText(find.byKey(const ValueKey('contest-name')), 'Cup');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('banner-save-failed')), findsOneWidget);
    expect(find.text('Draft not saved'), findsNWidgets(2));
    expect(find.text('Cup'), findsOneWidget);

    fail = false;
    await tester.tap(find.byKey(const ValueKey('draft-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('banner-save-failed')), findsNothing);
    expect(find.text('Draft saved.'), findsOneWidget);
  });
}
