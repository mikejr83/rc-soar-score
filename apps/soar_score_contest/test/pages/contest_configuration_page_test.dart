import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest_configuration_page.dart';
import 'package:soar_score_core/soar_score_core.dart';

const _id = '019c0000-0000-7000-8000-000000000017';
final _created = DateTime.utc(2026, 9);

Contest _contest({
  LifecycleState state = LifecycleState.configuring,
  AdminLock lock = AdminLock.unlocked,
}) => Contest(
  id: Id.parse(_id),
  name: 'Front Range ALES Open',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  lifecycleState: state,
  adminLock: lock,
  createdAt: _created,
  updatedAt: _created,
);

ContestConfigurationRevision _revision(
  int number, [
  Map<String, Object?> core = const {},
]) => ContestConfigurationRevision(
  id: Id.parse('019c0000-0000-7000-8000-0000000000a$number'),
  contestId: Id.parse(_id),
  revisionNumber: number,
  disciplineProfileId: Id.parse('019c0000-0000-7000-8000-0000000000d1'),
  config: ContestConfig(core: core, discipline: const {}),
  createdBy: Id.parse('019c0000-0000-7000-8000-0000000000b1'),
  createdAt: _created,
);

ContestParticipation _participation(int n, {RoleType type = RoleType.pilot}) =>
    ContestParticipation(
      id: Id.parse('019c0000-0000-7000-8000-00000000010$n'),
      contestId: Id.parse(_id),
      participantProfileId: Id.parse('019c0000-0000-7000-8000-00000000020$n'),
      roleId: Id.parse('019c0000-0000-7000-8000-0000000000c1'),
      roleName: 'Pilot',
      roleType: type,
      scoringUuid: ScoringUuid.parse('0000000$n-0000-4000-8000-000000000000'),
    );

CurrentMatrix _drawnMatrix() => CurrentMatrix(
  revision: MatrixRevision(
    id: Id.parse('019c0000-0000-7000-8000-0000000000e1'),
    contestId: Id.parse(_id),
    revisionNumber: 1,
    firstRound: 1,
    lastRound: 1,
    drawMode: DrawMode.standardManOnMan,
    randomSeed: 1,
    algorithmVersion: '1',
    drawConfig: const {},
    seedingSnapshot: const {},
    createdBy: Id.parse('019c0000-0000-7000-8000-0000000000b1'),
    createdAt: _created,
  ),
);

class _Server {
  _Server({
    Contest? contest,
    this.revision,
    this.participations = const [],
    CurrentMatrix? matrix,
  }) : contest = contest ?? _contest(),
       matrix = matrix ?? CurrentMatrix();

  final Contest contest;
  final ContestConfigurationRevision? revision;
  final List<ContestParticipation> participations;
  final CurrentMatrix matrix;
  Map<String, dynamic>? saved;

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'POST' && path.endsWith('/configuration')) {
      saved = jsonDecode(request.body) as Map<String, dynamic>;
      return _json(
        SavedConfiguration(
          revision: _revision(2, {
            ...?revision?.config.core,
            ...(saved!['config'] as Map)['core'] as Map<String, Object?>,
          }),
          contest: contest,
        ).toJson(),
      );
    }
    if (path.endsWith('/configuration')) {
      return revision == null
          ? _json({
              'error': {'code': 'not_found', 'message': 'none'},
            }, 404)
          : _json(revision!.toJson());
    }
    if (path.endsWith('/participations')) {
      return _json({
        'participations': [for (final p in participations) p.toJson()],
      });
    }
    if (path.endsWith('/matrix')) {
      return _json(matrix.toJson());
    }
    return _json(contest.toJson());
  }
}

Future<void> _pump(WidgetTester tester, _Server server) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: const MaterialApp(
        home: Scaffold(body: ContestConfigurationPage(contestId: _id)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _save = find.byKey(const ValueKey('save-configuration'));
final _draw = find.byKey(const ValueKey('draw-matrix'));

Future<void> _chooseLanes(WidgetTester tester) async {
  await tester.tap(find.text('None').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Random').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the groups with their revision and impact', (
    tester,
  ) async {
    await _pump(tester, _Server(revision: _revision(1)));

    for (final title in [
      'Identity',
      'Discipline and scoring rules',
      'Participant options',
      'Participants',
      'Draw options',
      'Scoring access',
      'Administration lock',
      'Public update policy',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Configuration revision 1'), findsNWidgets(4));
    expect(find.text('Invalidates the matrix'), findsOneWidget);
    expect(find.text('Recalculates scores'), findsOneWidget);
    expect(find.text('Not drawn'), findsOneWidget);
  });

  testWidgets('Save is off until an option changes, then saves the next '
      'revision', (tester) async {
    final server = _Server(revision: _revision(1));
    await _pump(tester, server);
    expect(tester.widget<FilledButton>(_save).onPressed, isNull);

    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(server.saved!['base_revision_number'], 1);
    expect((server.saved!['config'] as Map)['core']['classes_enabled'], true);
    expect(find.text('Configuration revision 2'), findsNWidgets(4));
    expect(tester.widget<FilledButton>(_save).onPressed, isNull);
  });

  testWidgets('saving never draws the matrix', (tester) async {
    final server = _Server(
      revision: _revision(1),
      participations: [_participation(1), _participation(2)],
    );
    await _pump(tester, server);
    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(find.text('Matrix revision'), findsNothing);
    expect(find.text('Not drawn'), findsOneWidget);
  });

  testWidgets('Draw matrix is enabled with two scoring pilots', (tester) async {
    await _pump(
      tester,
      _Server(
        revision: _revision(1),
        participations: [
          _participation(1),
          _participation(2),
          _participation(3, type: RoleType.nonFlier),
        ],
      ),
    );
    expect(tester.widget<OutlinedButton>(_draw).onPressed, isNotNull);
    expect(find.byKey(const ValueKey('draw-reason')), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Draw matrix says why it is off', (tester) async {
    await _pump(
      tester,
      _Server(revision: _revision(1), participations: [_participation(1)]),
    );
    expect(tester.widget<OutlinedButton>(_draw).onPressed, isNull);
    expect(
      find.text('Draw matrix: At least two scoring pilots are needed.'),
      findsOneWidget,
    );
  });

  testWidgets('a locked contest is read-only', (tester) async {
    await _pump(
      tester,
      _Server(
        contest: _contest(lock: AdminLock.locked),
        revision: _revision(1),
        participations: [_participation(1), _participation(2)],
      ),
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Classes'),
          )
          .onChanged,
      isNull,
    );
    expect(tester.widget<OutlinedButton>(_draw).onPressed, isNull);
    expect(find.text('Draw matrix: Administration is locked.'), findsOneWidget);
  });

  testWidgets('changing an option that invalidates a drawn matrix warns '
      'first', (tester) async {
    final server = _Server(
      revision: _revision(1),
      participations: [_participation(1), _participation(2)],
      matrix: _drawnMatrix(),
    );
    await _pump(tester, server);
    expect(find.text('Matrix revision'), findsOneWidget);

    await _chooseLanes(tester);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Save these changes?'), findsOneWidget);
    expect(server.saved, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(server.saved, isNull);

    await tester.tap(_save);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-save')));
    await tester.pumpAndSettle();
    expect((server.saved!['config'] as Map)['core']['lane_mode'], 'Random');
  });

  testWidgets('changing lanes with no matrix saves without a warning', (
    tester,
  ) async {
    final server = _Server(revision: _revision(1));
    await _pump(tester, server);
    await _chooseLanes(tester);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Save these changes?'), findsNothing);
    expect(server.saved, isNotNull);
  });

  testWidgets('a load failure offers Retry', (tester) async {
    var fail = true;
    final server = _Server(revision: _revision(1));
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ApiClientInherited(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient(
            (request) async =>
                fail ? http.Response('boom', 500) : server.handle(request),
          ),
        ),
        child: const MaterialApp(
          home: Scaffold(body: ContestConfigurationPage(contestId: _id)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('The configuration could not be loaded.'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Identity'), findsOneWidget);
  });
}
