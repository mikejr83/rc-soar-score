import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/workspace_page.dart';
import 'package:soar_score_core/soar_score_core.dart';

const _id = '019c0000-0000-7000-8000-000000000017';

Contest _contest(LifecycleState state) => Contest(
  id: Id.parse(_id),
  name: 'Front Range ALES Open',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  host: 'Front Range Soaring',
  lifecycleState: state,
  scoringAccess: ScoringAccess.closed,
  adminLock: AdminLock.unlocked,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

Future<void> _pump(
  WidgetTester tester,
  LifecycleState state, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode(_contest(state).toJson()),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: ContestWorkspacePage(contestId: _id)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _section(String id) => find.byKey(ValueKey('workspace-section-$id'));

double _top(WidgetTester tester, String id) =>
    tester.getTopLeft(_section(id)).dy;

double _left(WidgetTester tester, String id) =>
    tester.getTopLeft(_section(id)).dx;

void main() {
  group('two columns at 1200 dp', () {
    for (final state in LifecycleState.values) {
      testWidgets('${state.name} places slots as the plan says', (
        tester,
      ) async {
        await _pump(tester, state, size: const Size(1200, 1600));

        final main =
            {
              LifecycleState.running: ['next-step', 'attention', 'progress'],
              LifecycleState.completed: ['next-step', 'progress'],
            }[state] ??
            ['next-step', 'checklist'];
        for (var i = 1; i < main.length; i++) {
          expect(_top(tester, main[i]), greaterThan(_top(tester, main[i - 1])));
          expect(_left(tester, main[i]), _left(tester, main[0]));
        }
        expect(
          _left(tester, 'controls'),
          greaterThan(_left(tester, 'next-step')),
        );
        expect(_left(tester, 'facts'), _left(tester, 'controls'));
        expect(_top(tester, 'facts'), greaterThan(_top(tester, 'controls')));
        expect(find.text('Front Range Soaring'), findsOneWidget);
      });
    }

    testWidgets('control cards follow the plan order while running', (
      tester,
    ) async {
      await _pump(tester, LifecycleState.running, size: const Size(1200, 1600));
      final ids = [
        'scoring',
        'results',
        'publication',
        'administration',
        'lifecycle',
        'archive',
      ];
      final tops = [
        for (final id in ids)
          tester.getTopLeft(find.byKey(ValueKey('workspace-control-$id'))).dy,
      ];
      expect(tops, [...tops]..sort());
    });
  });

  group('one column at 720 dp', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('running follows the single order at text scale $scale', (
        tester,
      ) async {
        await _pump(
          tester,
          LifecycleState.running,
          size: const Size(720, 900),
          textScale: scale,
        );
        final order = [
          'next-step',
          'attention',
          'progress',
          'controls',
          'facts',
          'activity',
        ];
        for (var i = 1; i < order.length; i++) {
          expect(
            _top(tester, order[i]),
            greaterThan(_top(tester, order[i - 1])),
            reason: order[i],
          );
          expect(_left(tester, order[i]), _left(tester, order[0]));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('created puts the checklist right after the next step', (
      tester,
    ) async {
      await _pump(tester, LifecycleState.created, size: const Size(720, 900));
      expect(_top(tester, 'checklist'), greaterThan(_top(tester, 'next-step')));
      expect(_top(tester, 'controls'), greaterThan(_top(tester, 'checklist')));
    });
  });

  testWidgets('no page-card list remains', (tester) async {
    await _pump(
      tester,
      LifecycleState.configuring,
      size: const Size(1200, 900),
    );
    expect(find.text('Administer'), findsNothing);
    expect(find.textContaining('Not available yet.'), findsNothing);
  });
}
