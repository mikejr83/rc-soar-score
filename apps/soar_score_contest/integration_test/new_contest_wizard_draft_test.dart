import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/new_contest_wizard_page.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/wizard_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('leaving the wizard with errors asks first, and the draft '
      'resumes through Continue configuration', (tester) async {
    await openMainPage(tester);
    expect(createContestEntryLabel(tester), 'Create contest');
    await openWizard(tester);

    // Only the name, then Next shows the errors of the other fields.
    await enterIn(
      tester,
      find.byKey(const ValueKey('contest-name')),
      'E2E Draft Contest',
    );
    await wizardPrimary(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('banner-validation')),
    );

    // Leaving asks; Keep editing stays.
    await tapVisible(tester, find.byKey(const ValueKey('breadcrumb-contests')));
    await pumpUntilFound(tester, find.text('Leave new contest?'));
    await tapVisible(tester, find.text('Keep editing'));
    expect(find.byType(NewContestWizardPage), findsOneWidget);
    expect(find.text('Leave new contest?'), findsNothing);

    // Leave goes to the contest list.
    await tapVisible(tester, find.byKey(const ValueKey('breadcrumb-contests')));
    await pumpUntilFound(tester, find.text('Leave new contest?'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Leave'));
    await pumpUntilFound(tester, find.byType(HomePage));

    // The entry now offers to continue, and the draft is as it was left.
    await tester.pump(const Duration(milliseconds: 300));
    expect(createContestEntryLabel(tester), 'Continue configuration');
    await openWizard(tester);
    expect(find.text('E2E Draft Contest'), findsOneWidget);
    expect(find.byKey(const ValueKey('draft-status')), findsOneWidget);
  });
}
