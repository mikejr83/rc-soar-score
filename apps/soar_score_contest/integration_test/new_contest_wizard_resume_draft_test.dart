import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/stored_draft.dart';
import 'support/wizard_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a draft stored by an earlier run is offered when the wizard '
      'opens, and Continue brings back the values', (tester) async {
    await openMainPage(tester);
    final persistence = draftStoreOf(tester).persistence!;
    // Before the wizard opens, the rail does not know about the stored draft.
    expect(createContestEntryLabel(tester), 'Create contest');
    await storeDraftFromEarlierRun(
      persistence,
      const ContestDraft(
        name: 'E2E Stored Draft',
        venue: 'E2E Field',
        visitedThrough: 1,
      ),
    );

    await tapVisible(tester, find.byKey(const ValueKey('create-contest')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('resume-draft-dialog')),
    );
    expect(find.textContaining('last saved'), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('resume-draft-continue')),
    );
    await pumpUntilFound(tester, find.byKey(const ValueKey('contest-name')));
    expect(find.text('E2E Stored Draft'), findsOneWidget);
    expect(find.text('E2E Field'), findsOneWidget);
    expect(find.byKey(const ValueKey('resume-draft-dialog')), findsNothing);
  });
}
