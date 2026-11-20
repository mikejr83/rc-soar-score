import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/new_contest/copy_mode.dart';
import 'package:soar_score_contest/services/participants/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';

import '../support/new_contest_test_support.dart';
import '../support/participant_test_support.dart';

final _source = sourceContest();

/// Answers for one source contest with an F5J configuration, two pilots and
/// a helper. [failSource] makes loading the source fail.
Future<http.Response> Function(http.Request) _api({bool failSource = false}) =>
    (request) async {
      final path = request.url.path;
      if (path.endsWith('/contests')) {
        return json({
          'contests': [_source.toJson()],
        });
      }
      if (path.endsWith('/configuration')) {
        return failSource
            ? errorResponse(503, 'unavailable', 'Try again later.')
            : json(sourceConfiguration(_source).toJson());
      }
      if (path.endsWith('/participations')) {
        return json({
          'participations': [
            participation(_source, 21, classification: 'Open').toJson(),
            participation(_source, 22, classification: 'Sportsman').toJson(),
            participation(_source, 23, pilot: false).toJson(),
          ],
        });
      }
      return json({
        'participants': [
          profile('Mike', 'Gardner', n: 21).toJson(),
          profile('Sarah', 'Albright', n: 22).toJson(),
          profile('Ana', 'Ruiz', n: 23).toJson(),
        ],
      });
    };

Future<void> _choose(WidgetTester tester, CopyMode mode) async {
  await tester.ensureVisible(find.byKey(ValueKey('copy-mode-${mode.name}')));
  await tester.tap(find.byKey(ValueKey('copy-mode-${mode.name}')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('copying all pilots loads the configuration and pilots only, '
      'and summarizes the copy', (tester) async {
    final l10n = AppLocalizationsEn();
    final wizard = await pumpWizard(tester, respond: _api());

    await _choose(tester, CopyMode.allPilots);
    final tile = find.byKey(ValueKey('copy-source-${_source.id.value}'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('copy-source-chosen')), findsOneWidget);
    expect(find.byKey(const ValueKey('copy-summary')), findsOneWidget);
    expect(find.text(l10n.wizardCopyAllPilots(2)), findsOneWidget);
    final draft = wizard.store.draft;
    expect(draft.discipline, WizardDiscipline.f5j);
    expect(draft.options, {ParticipantOption.teams, ParticipantOption.classes});
    expect(draft.teamPilotCount, '3');
    // The helper is not copied; pilots keep their class.
    expect(draft.participants.map((p) => p.name), [
      'Mike Gardner',
      'Sarah Albright',
    ]);
    expect(draft.participants.first.classification, 'Open');
  });

  testWidgets('selected pilots can be narrowed with Choose pilots', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final wizard = await pumpWizard(tester, respond: _api());
    await _choose(tester, CopyMode.selectedPilots);
    final tile = find.byKey(ValueKey('copy-source-${_source.id.value}'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text(l10n.wizardPilotsSelected(2, 2)), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('copy-source-choose-pilots')),
    );
    await tester.tap(find.byKey(const ValueKey('copy-source-choose-pilots')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sarah Albright'));
    await tester.tap(find.text(l10n.wizardUseThesePilots));
    await tester.pumpAndSettle();

    expect(find.text(l10n.wizardPilotsSelected(1, 2)), findsOneWidget);
    expect(wizard.store.draft.participants.map((p) => p.name), [
      'Mike Gardner',
    ]);
  });

  testWidgets('a source that fails to load can be retried or removed', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final wizard = await pumpWizard(tester, respond: _api(failSource: true));
    await _choose(tester, CopyMode.configuration);
    final tile = find.byKey(ValueKey('copy-source-${_source.id.value}'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('copy-source-failed')), findsOneWidget);
    expect(find.text(l10n.wizardSourceFailed('Labor Day F5J Open')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('copy-source-remove')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('copy-source-failed')), findsNothing);
    expect(wizard.store.draft.source, isNull);
    expect(
      find.text(l10n.wizardSourceRemoved),
      findsOneWidget,
    );
    // The picker is back, so the user can choose again or continue.
    expect(tile, findsOneWidget);
  });

  testWidgets('switching back to Don’t copy drops the source', (tester) async {
    final wizard = await pumpWizard(tester, respond: _api());
    await _choose(tester, CopyMode.allPilots);
    final tile = find.byKey(ValueKey('copy-source-${_source.id.value}'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    await _choose(tester, CopyMode.none);
    expect(wizard.store.draft.source, isNull);
    expect(wizard.store.draft.participants, isEmpty);
    expect(find.byKey(const ValueKey('copy-summary')), findsNothing);
  });

  testWidgets('public contests say they need a connection or are not '
      'searchable yet', (tester) async {
    await pumpWizard(tester, respond: _api());
    await _choose(tester, CopyMode.configuration);
    final tab = find.byKey(const ValueKey('copy-source-tab-public'));
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('copy-source-public-unavailable')),
      findsOneWidget,
    );
  });
}
