import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_fact_source.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts_loader.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/configuration_fixtures.dart';
import '../../support/matrix_test_support.dart';
import '../../support/workspace_checklist_support.dart';
import '../../support/workspace_facts_support.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// The matrix fake server plus scores and publication, which each answer with
/// [scoresStatus] and [publication].
Future<WorkspaceFacts> _load({
  int scoresStatus = 200,
  int publicationStatus = 404,
  int landingTablesStatus = 200,
  Map<String, Object?> publication = const {},
  bool offline = false,
  List<String>? requests,
}) {
  final matrix = drawnMatrix();
  final server = MatrixServer(configuration: configRevision(3), matrix: matrix);
  final client = ApiClient(
    baseUrl: Uri.parse('http://localhost'),
    httpClient: MockClient((request) async {
      requests?.add(request.url.path);
      final path = request.url.path;
      if (path.endsWith('/scores')) {
        return scoresStatus == 200
            ? _json(scoresFor(matrix, {(1, 1): at(0)}).toJson())
            : _json({
                'error': {'code': 'boom', 'message': 'Broken.'},
              }, scoresStatus);
      }
      if (path.endsWith('/landing-tables')) {
        return landingTablesStatus == 200
            ? _json({
                'landing_tables': [
                  landingTableView(f5jLandingTableId, 'F5J default').toJson(),
                ],
              })
            : _json({
                'error': {'code': 'boom', 'message': 'Broken.'},
              }, landingTablesStatus);
      }
      if (path.endsWith('/publication')) {
        return _json(
          publicationStatus == 200
              ? publication
              : {
                  'error': {'code': 'x', 'message': 'No publication.'},
                },
          publicationStatus,
        );
      }
      return server.handle(request);
    }),
  );
  return WorkspaceFactsLoader.load(
    client,
    matrixContest(state: LifecycleState.running),
    isOffline: offline,
  );
}

void main() {
  test('loads the facts without fetching the contest again', () async {
    final requests = <String>[];
    final facts = await _load(requests: requests);
    expect(facts.hasMatrix, isTrue);
    expect(facts.latestScore?.roundOrdinal, 1);
    expect(facts.publication, PublicationFacts.notPublished);
    expect(facts.unavailable, isEmpty);
    expect(facts.landingTableName, 'F5J default');
    expect(facts.disciplineLabel, 'F5J');
    expect(facts.isOffline, isFalse);
    expect(
      requests.where((path) => path.endsWith('/contests/$matrixContestId')),
      isEmpty,
    );
  });

  test('reads a publication', () async {
    final facts = await _load(
      publicationStatus: 200,
      publication: const {
        'visibility': 'Unlisted',
        'published_at': '2026-10-18T12:00:00.000Z',
      },
      offline: true,
    );
    expect(facts.publication.visibility, PublicationVisibility.unlisted);
    expect(facts.isOffline, isTrue);
  });

  test('a failed scores read is listed and the rest still loads', () async {
    final facts = await _load(scoresStatus: 500);
    expect(facts.unavailable, {WorkspaceFactSource.scores});
    expect(facts.rounds, isEmpty);
    expect(facts.hasMatrix, isTrue);
  });

  test('a failed publication read is unknown, not unpublished', () async {
    final facts = await _load(publicationStatus: 500);
    expect(facts.unavailable, {WorkspaceFactSource.publication});
    expect(facts.publication, PublicationFacts.unknown);
  });

  test(
    'a failed landing-table read is listed and the rest still loads',
    () async {
      final facts = await _load(landingTablesStatus: 500);
      expect(facts.unavailable, {WorkspaceFactSource.landingTables});
      expect(facts.landingTableName, isNull);
      expect(facts.disciplineLabel, 'F5J');
      expect(facts.hasMatrix, isTrue);
    },
  );
}
