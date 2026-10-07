import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';
import 'package:soar_score_contest/widgets/new_contest/wizard_dot_stepper.dart';
import 'package:soar_score_contest/widgets/new_contest/wizard_step_list.dart';

import '../support/new_contest_test_support.dart';

Future<void> _pick(WidgetTester tester, String name) async {
  final card = find.byKey(ValueKey('discipline-$name'));
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('step 1 blocks Next with a summary and inline errors, and the '
      'summary links focus the field', (tester) async {
    await pumpWizard(tester, respond: emptyApi);

    expect(find.byType(WizardStepList), findsOneWidget);
    expect(stepTitle(tester), 'Details & copy source');
    expect(find.text('Next: Discipline'), findsOneWidget);
    // No errors before trying to continue.
    expect(find.byKey(const ValueKey('banner-validation')), findsNothing);

    await next(tester);
    expect(stepTitle(tester), 'Details & copy source');
    expect(
      find.text('4 fields need attention before you continue'),
      findsOneWidget,
    );
    expect(find.text('Contest name: Enter a contest name.'), findsOneWidget);
    // Inline, next to the field.
    expect(find.text('Enter a contest name.'), findsOneWidget);
    expect(find.text('Current · needs attention'), findsOneWidget);

    await tester.tap(find.text('Contest name: Enter a contest name.'));
    await tester.pump();
    final name = tester.widget<TextField>(
      find.byKey(const ValueKey('contest-name')),
    );
    expect(name.focusNode!.hasFocus, isTrue);
  });

  testWidgets('the end date follows the start date unless a later one is '
      'chosen', (tester) async {
    await pumpWizard(tester, respond: emptyApi);
    String endText() => tester
        .widget<TextField>(find.byKey(const ValueKey('contest-end')))
        .controller!
        .text;

    await tester.enterText(
      find.byKey(const ValueKey('contest-start')),
      'Nov 14, 2026',
    );
    await tester.pump();
    expect(endText(), 'Nov 14, 2026');

    await tester.enterText(
      find.byKey(const ValueKey('contest-end')),
      'Nov 16, 2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey('contest-start')),
      'Nov 15, 2026',
    );
    await tester.pump();
    expect(endText(), 'Nov 16, 2026');
  });

  testWidgets('every discipline card is as tall as the tallest', (
    tester,
  ) async {
    await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);
    expect(stepTitle(tester), 'Discipline');

    final heights = {
      for (final discipline in WizardDiscipline.values)
        discipline.name: tester
            .getSize(find.byKey(ValueKey('discipline-${discipline.name}')))
            .height,
    };
    expect(heights.values.toSet(), hasLength(1), reason: '$heights');
  });

  testWidgets('an end date before the start date is an error', (tester) async {
    await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await tester.enterText(
      find.byKey(const ValueKey('contest-end')),
      'Nov 13, 2026',
    );
    await next(tester);

    expect(
      find.text('End date can’t be before the start date (Nov 14, 2026).'),
      findsOneWidget,
    );
    expect(find.text('1 field needs attention before you continue'), findsOne);
  });

  testWidgets('steps 1 to 3 advance when valid; visited steps can be jumped '
      'to without losing values', (tester) async {
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);

    expect(stepTitle(tester), 'Discipline');
    expect(find.text('Complete'), findsOneWidget);

    // A discipline is required.
    await next(tester);
    expect(find.text('Choose a discipline.'), findsOneWidget);

    // The first pick needs no confirmation; unsupported ones can't be picked.
    await _pick(tester, 'F3K');
    expect(wizard.store.draft.discipline, isNull);
    await _pick(tester, 'F5J');
    expect(find.byType(AlertDialog), findsNothing);
    expect(wizard.store.draft.discipline, WizardDiscipline.f5j);

    await next(tester);
    expect(stepTitle(tester), 'Participant options');

    // Jump back to step 1: the values are still there.
    await tester.tap(find.byKey(const ValueKey('wizard-step-1')));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), 'Details & copy source');
    expect(find.text('Gator Cup F5J'), findsOneWidget);
    expect(wizard.store.draft.visitedThrough, 3);
  });

  testWidgets('changing the discipline asks first and can be kept', (
    tester,
  ) async {
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);
    await _pick(tester, 'F5J');

    await _pick(tester, 'F3J');
    expect(find.text('Change discipline to F3J?'), findsOneWidget);
    await tester.tap(find.text('Keep F5J'));
    await tester.pumpAndSettle();
    expect(wizard.store.draft.discipline, WizardDiscipline.f5j);

    await _pick(tester, 'F3J');
    await tester.tap(find.text('Change and clear'));
    await tester.pumpAndSettle();
    expect(wizard.store.draft.discipline, WizardDiscipline.f3j);
    expect(
      find.text('Discipline changed to F3J. Incompatible values were cleared.'),
      findsOneWidget,
    );
  });

  testWidgets('step 3: Teams needs a positive team count and adds columns', (
    tester,
  ) async {
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);
    await _pick(tester, 'ALES');
    await next(tester);

    expect(find.byKey(const ValueKey('team-pilot-count')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('option-teams')));
    await tester.pumpAndSettle();
    expect(wizard.store.draft.options, {ParticipantOption.teams});
    expect(find.byKey(const ValueKey('team-pilot-count')), findsOneWidget);
    expect(find.text('Team optional', findRichText: true), findsOneWidget);

    await next(tester);
    expect(stepTitle(tester), 'Participant options');
    expect(
      find.text('Pilots counted for team score: enter a whole number above 0.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const ValueKey('team-pilot-count')), '0');
    await tester.pump();
    expect(find.text('Enter a whole number above 0.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('team-pilot-count')), '3');
    await tester.pump();
    await next(tester);

    // Step 4 needs at least 2 scoring pilots.
    expect(stepTitle(tester), 'Participants');
    await next(tester);
    expect(stepTitle(tester), 'Participants');
    expect(find.text('Add at least 2 scoring pilots'), findsOneWidget);
  });

  testWidgets('narrow windows show the dot stepper and reflow the fields', (
    tester,
  ) async {
    await pumpWizard(tester, respond: emptyApi, size: const Size(800, 1180));

    expect(find.byType(WizardStepList), findsNothing);
    expect(find.byType(WizardDotStepper), findsOneWidget);
    expect(
      find.byTooltip('Step 1, Details & copy source, Current step'),
      findsOne,
    );
    final error = tester.takeException();
    if (error != null) {
      debugPrint((error as FlutterError).toStringDeep());
    }
    expect(error, isNull);
  });
}
