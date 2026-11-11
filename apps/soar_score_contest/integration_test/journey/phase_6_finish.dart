import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/widgets/reports/standings/standings_table_view.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/open_demo_contest.dart';
import '../support/pump_until_gone.dart';
import 'export_step.dart';
import 'journey.dart';

Finder _key(String key) => find.byKey(ValueKey(key));
const _apiBase = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');

/// Phase 6: complete the contest and check the results a director publishes.
Future<void> runFinishPhase(Journey journey, JourneyContext data) async {
  final tester = journey.tester;

  Future<void> inContest(Future<void> Function() body) async {
    await goToMainPage(tester);
    await openContest(tester, data.contestName);
    await body();
  }

  await journey.step(
    'Complete: nothing is left open, so the contest completes and closes',
    () => inContest(() async {
      await pumpUntilFound(tester, _key('status-summary'));
      await tapVisible(tester, _key('control-complete'));
      await pumpUntilFound(tester, _key('complete-dialog'));
      // Every flight is scored or retired, and every round was flown.
      expect(_key('complete-dialog-missing'), findsNothing);
      expect(_key('complete-dialog-unflown'), findsNothing);
      await tester.tap(_key('complete-dialog-confirm'));
      await pumpUntilGone(tester, _key('complete-dialog'));
      await pumpUntilFound(tester, find.text('Completed'));

      String status(String id) =>
          tester.widget<Text>(_key('status-$id-value')).data!;
      expect(status('lifecycle'), 'Completed');
      expect(status('scoring'), 'Closed');
      // The next-step card dates the completion from the audit trail.
      await pumpUntilFound(
        tester,
        find.textContaining('The contest was completed'),
      );
      expect(
        tester.widget<FilledButton>(_key('control-complete')).onPressed,
        isNull,
      );
      expect(_key('control-lifecycle-reason'), findsOneWidget);
    }),
  );

  await journey.step(
    'Publication: the card and page say this server does not publish, with no delisting or history',
    () => inContest(() async {
      await pumpUntilFound(tester, _key('status-summary'));
      // Publishing goes to the server the app syncs with (the remote client),
      // not to the embedded server. The native journey has no publishing
      // server, so the card explains why the action is unavailable.
      await pumpUntilFound(tester, _key('workspace-control-publication'));
      await pumpUntilFound(tester, _key('control-publication-reason'));
      expect(_key('publication-publish'), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(_key('publication-publish')).onPressed,
        isNull,
      );

      await tapVisible(tester, _key('publication-open-page'));
      await pumpUntilFound(tester, _key('publication-page-state'));
      expect(
        find.descendant(
          of: _key('publication-page-card'),
          matching: _key('publication-page-state'),
        ),
        findsOneWidget,
      );
      expect(_key('publication-page-no-copy'), findsOneWidget);
      expect(_key('publication-page-reason'), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(_key('publication-publish')).onPressed,
        isNull,
      );
      // Nothing was published, so there is nothing to delist and no history.
      expect(_key('publication-request-delisting'), findsNothing);
      expect(_key('publication-withdraw-delisting'), findsNothing);
      expect(_key('publication-page-history'), findsNothing);
    }),
    nativeOnly: true,
  );

  await journey.step('Publication: publish and make the real copy public', () async {
    await inContest(() async {
      await pumpUntilFound(tester, _key('workspace-control-publication'));
      final location = GoRouter.of(
        tester.element(_key('workspace-control-publication')),
      ).routeInformationProvider.value.uri.path;
      final match = RegExp(r'/contests/([^/]+)').firstMatch(location);
      expect(match, isNotNull, reason: 'Expected a contest route: $location');
      final contestId = match!.group(1)!;
      // This fresh contest has never been published, so its copies start at 1.
      final before = await http.get(
        Uri.parse('$_apiBase/api/v1/contests/$contestId/publication'),
      );
      expect(before.statusCode, 404);
      await pumpUntilFound(tester, _key('publication-publish'));
      await tapVisible(tester, _key('publication-publish'));
      await pumpUntilFound(tester, _key('publish-dialog'));
      await tester.tap(_key('publish-dialog-confirm'));
      await pumpUntilFound(tester, _key('publication-visibility'));

      final director = await http.get(
        Uri.parse('$_apiBase/api/v1/contests/$contestId/publication'),
      );
      expect(director.statusCode, 200);
      final publication = jsonDecode(director.body) as Map<String, dynamic>;
      final id = publication['publication_id'] as String;
      final unlisted = await http.get(
        Uri.parse('$_apiBase/public/publications/$id'),
      );
      expect(unlisted.statusCode, 200);
      final copy = jsonDecode(unlisted.body) as Map<String, dynamic>;
      expect(copy['visibility'], 'Unlisted');
      expect(copy['projection_revision'], 1);
      expect(
        (copy['contest'] as Map<String, dynamic>)['name'],
        data.contestName,
      );
      expect(copy['participants'], isNotEmpty);
      expect(copy['scores'], isNotEmpty);

      await tapVisible(tester, _key('publication-visibility'));
      await pumpUntilFound(tester, _key('public-dialog'));
      await tester.tap(_key('public-dialog-confirm'));
      await pumpUntilFound(tester, _key('publication-request-delisting'));
      final published = await http.get(
        Uri.parse('$_apiBase/public/publications/$id'),
      );
      expect(published.statusCode, 200);
      expect(
        (jsonDecode(published.body) as Map<String, dynamic>)['visibility'],
        'Public',
      );
      await tapVisible(tester, _key('publication-open-page'));
      await pumpUntilFound(tester, _key('publication-page-copy'));
      await pumpUntilFound(tester, _key('publication-page-history'));
      expect(find.text('Published, Public'), findsWidgets);
      await pumpUntilGone(tester, find.text('Results published.'));
      await tapVisible(tester, _key('publication-publish'));
      await pumpUntilFound(tester, _key('publish-dialog'));
      await tester.tap(_key('publish-dialog-confirm'));
      await pumpUntilFound(tester, find.text('Results published.'));
      final updated = await http.get(
        Uri.parse('$_apiBase/public/publications/$id'),
      );
      expect(updated.statusCode, 200);
      expect(
        (jsonDecode(updated.body)
            as Map<String, dynamic>)['projection_revision'],
        2,
      );
      final history = await http.get(
        Uri.parse(
          '$_apiBase/api/v1/contests/$contestId/publication/projections',
        ),
      );
      expect(history.statusCode, 200);
      final revisions =
          (jsonDecode(history.body) as Map<String, dynamic>)['projections']
              as List<dynamic>;
      expect(revisions.map((entry) => entry['projection_revision']), [2, 1]);
    });
  }, webOnly: true);

  await journey.step(
    'Overall Standings: every pilot ranked, no Provisional, options apply',
    () => inContest(() async {
      await tapRail(tester, 'Reports');
      await pumpUntilFound(tester, find.text('Reports are built from'));
      await tapVisible(tester, _key('report-open-standings'));
      await pumpUntilFound(tester, find.text('Rank'));

      // The heading, the columns and a column for each round.
      expect(find.textContaining('Overall Results - '), findsWidgets);
      expect(find.text('Total'), findsWidgets);
      for (var round = 1; round <= data.rounds; round++) {
        expect(find.text('R$round'), findsWidgets);
      }
      expect(find.text('Raw'), findsNothing);

      // Every score is final: no Provisional switch, but Flight details.
      expect(
        find.widgetWithText(CheckboxListTile, 'Flight details'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CheckboxListTile, 'Provisional'),
        findsNothing,
      );

      // The ranking follows the flights the journey entered: the pilot who
      // flew longest and lowest wins (possibly tied with another group's
      // winner), the pilot who flew least and retired last, and nobody
      // ranks above a pilot with a higher total.
      final rows = tester
          .widgetList<StandingsTableView>(find.byType(StandingsTableView))
          .first
          .table
          .rows;
      final names = rows.map((r) => r.pilot.givenSurname).toList();
      expect(names, unorderedEquals(data.pilotNames));
      final best = rows.firstWhere(
        (r) => r.pilot.givenSurname == data.pilotNames.first,
      );
      final worst = rows.firstWhere(
        (r) => r.pilot.givenSurname == data.pilotNames.last,
      );
      expect(best.place, 1);
      expect(worst.place, data.pilotNames.length);
      expect(rows.where((r) => r.place == worst.place), hasLength(1));
      for (var i = 1; i < rows.length; i++) {
        expect(rows[i].place, greaterThanOrEqualTo(rows[i - 1].place));
        expect(rows[i].total, lessThanOrEqualTo(rows[i - 1].total));
      }
      // The retired pilot has no score in the round they left.
      expect(worst.cells[data.rounds]?.score ?? 0, 0);

      // An option adds its column at once.
      await tapVisible(
        tester,
        find.widgetWithText(CheckboxListTile, 'Raw score'),
      );
      await pumpUntilFound(tester, find.text('Raw'));

      // Flight details come in the same one-call report read as the
      // standings (`report-data`): the entered flight times show as m:ss.
      await tapVisible(
        tester,
        find.widgetWithText(CheckboxListTile, 'Flight details'),
      );
      await pumpUntilFound(tester, find.textContaining(RegExp(r'\d+:\d{2}')));

      await tapVisible(tester, _key('viewer-back'));
      await pumpUntilFound(tester, find.text('Reports are built from'));
    }),
  );

  await journey.step(
    'Export: the contest is saved to a file (native)',
    () => exportContestToFile(tester, data),
    nativeOnly: true,
  );
}
