import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_entry.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_facts.dart';
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
  String publicationErrorCode = 'x',
  int landingTablesStatus = 200,
  Map<String, Object?> publication = const {},
  bool offline = false,
  List<String>? requests,
  Contest? contest,
  int auditStatus = 200,
  String? failingAuditAction,
  List<Map<String, Object?>> auditEvents = const [],
  String? actingAccountId,
}) {
  final matrix = drawnMatrix();
  final server = MatrixServer(configuration: configRevision(3), matrix: matrix);
  final client = ApiClient(
    baseUrl: Uri.parse('http://localhost'),
    httpClient: MockClient((request) async {
      requests?.add(request.url.toString());
      final path = request.url.path;
      if (path.endsWith('/audit-events')) {
        final failing =
            auditStatus != 200 ||
            request.url.queryParameters['action'] == failingAuditAction;
        return !failing
            ? _json({
                'audit_events': [
                  for (final event in auditEvents)
                    if (request.url.queryParameters['action'] == null ||
                        request.url.queryParameters['action'] ==
                            event['action'])
                      event,
                ],
              })
            : _json({
                'error': {'code': 'boom', 'message': 'Broken.'},
              }, auditStatus == 200 ? 500 : auditStatus);
      }
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
                  'error': {
                    'code': publicationErrorCode,
                    'message': 'No publication.',
                  },
                },
          publicationStatus,
        );
      }
      return server.handle(request);
    }),
  );
  return WorkspaceFactsLoader.load(
    client,
    contest ?? matrixContest(state: LifecycleState.running),
    isOffline: offline,
    actingAccountId: actingAccountId,
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

  test(
    'a 401 publication read asks for a sign-in, not a failed read',
    () async {
      final facts = await _load(publicationStatus: 401);
      expect(facts.publication, PublicationFacts.signInRequired);
      expect(facts.publication.needsSignIn, isTrue);
    },
  );

  test('a failed publication read is unknown, not unpublished', () async {
    final facts = await _load(publicationStatus: 500);
    expect(facts.unavailable, {WorkspaceFactSource.publication});
    expect(facts.publication, PublicationFacts.unknown);
  });

  test(
    'a 409 publishing_not_available is unsupported, not a failed read',
    () async {
      final facts = await _load(
        publicationStatus: 409,
        publicationErrorCode: 'publishing_not_available',
      );
      expect(facts.publication, PublicationFacts.unsupported);
      expect(facts.unavailable, isEmpty);
      expect(facts.nextStepFactsUnavailable, isFalse);
    },
  );

  test('another 409 on the publication read is still a failed read', () async {
    final facts = await _load(
      publicationStatus: 409,
      publicationErrorCode: 'stale_results',
    );
    expect(facts.publication, PublicationFacts.unknown);
    expect(facts.unavailable, {WorkspaceFactSource.publication});
    expect(facts.nextStepFactsUnavailable, isTrue);
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

  group('audit trail', () {
    final director = '019c0000-0000-7000-8000-0000000000b1';
    Map<String, Object?> event(String transition, String at) => {
      'id': Id.create().value,
      'entity_type': 'Contest',
      'entity_id': matrixContestId,
      'action': 'StateTransition',
      'transition': transition,
      'actor_id': director,
      'authority': 'Director',
      'server_timestamp': at,
      'outcome': 'Success',
    };

    test('a locked contest gets the lock time and "you"', () async {
      final facts = await _load(
        contest: matrixContest(
          state: LifecycleState.running,
          lock: AdminLock.locked,
        ),
        auditEvents: [event('lock', '2026-10-18T15:00:00.000Z')],
        actingAccountId: director,
      );

      expect(facts.lockedAt, DateTime.utc(2026, 10, 18, 15));
      expect(facts.lockedBy, 'you');
      expect(facts.unavailable, isEmpty);
    });

    test(
      'a failed audit read leaves the facts null and the rest loads',
      () async {
        final facts = await _load(
          contest: matrixContest(
            state: LifecycleState.running,
            lock: AdminLock.locked,
          ),
          auditStatus: 500,
          actingAccountId: director,
        );

        expect(facts.lockedAt, isNull);
        expect(facts.lockedBy, isNull);
        expect(facts.unavailable, isEmpty);
        expect(facts.hasMatrix, isTrue);
      },
    );

    test(
      'an open, running contest reads the trail by action for transitions and '
      'activity',
      () async {
        final requests = <String>[];
        await _load(requests: requests);

        final uris = requests.map(Uri.parse).toList();
        final auditReads = uris
            .where((u) => u.path.endsWith('/audit-events'))
            .toList();
        expect(auditReads, hasLength(5));
        expect(
          {for (final u in auditReads) u.queryParameters['action']},
          {
            'StateTransition',
            'ConfigurationSaved',
            'MatrixDrawn',
            'ScoreAttempt',
            'PublicationAttempt',
          },
        );
      },
    );

    test('the newest events become activity lines', () async {
      final facts = await _load(
        auditEvents: [
          event('lock', '2026-10-18T15:00:00.000Z'),
          event('openScoring', '2026-10-18T09:00:00.000Z'),
        ],
        actingAccountId: director,
      );

      expect(facts.activity.failed, isFalse);
      expect(facts.activity.entries.map((e) => e.kind), [
        ActivityKind.lock,
        ActivityKind.openScoring,
      ]);
      expect(facts.activity.entries.every((e) => e.byYou), isTrue);
    });

    for (final action in [
      'ConfigurationSaved',
      'MatrixDrawn',
      'ScoreAttempt',
    ]) {
      test('a failed $action read fails the activity but keeps the transition '
          'facts', () async {
        final facts = await _load(
          contest: matrixContest(
            state: LifecycleState.running,
            lock: AdminLock.locked,
          ),
          auditEvents: [event('lock', '2026-10-18T15:00:00.000Z')],
          failingAuditAction: action,
          actingAccountId: director,
        );

        expect(facts.lockedAt, DateTime.utc(2026, 10, 18, 15));
        expect(facts.activity, ActivityFacts.unavailable);
        expect(facts.unavailable, isEmpty);
      });
    }

    test('a failed publication read keeps the transition facts and fails the '
        'activity', () async {
      final facts = await _load(
        contest: matrixContest(
          state: LifecycleState.running,
          lock: AdminLock.locked,
        ),
        auditEvents: [event('lock', '2026-10-18T15:00:00.000Z')],
        failingAuditAction: 'PublicationAttempt',
        actingAccountId: director,
      );

      expect(facts.lockedAt, DateTime.utc(2026, 10, 18, 15));
      expect(facts.lockedBy, 'you');
      expect(facts.activity, ActivityFacts.unavailable);
      expect(facts.unavailable, isEmpty);
    });

    test('a failed audit read marks only the activity as failed', () async {
      final facts = await _load(auditStatus: 500);

      expect(facts.activity, ActivityFacts.unavailable);
      expect(facts.unavailable, isEmpty);
      expect(facts.hasMatrix, isTrue);
    });
  });
}
