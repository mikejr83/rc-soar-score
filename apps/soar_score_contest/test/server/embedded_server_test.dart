import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show
        AdminLock,
        ContestAction,
        ContestConfig,
        ScorePlaceholderState,
        DisciplineType,
        Id,
        LifecycleState,
        SystemDisciplineProfiles,
        SystemLandingTables,
        SystemRoles;
import 'package:soar_score_contest/server/embedded_server.dart';

void main() {
  late Directory tempDir;
  late String databasePath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('soar_score_embedded_test');
    databasePath = '${tempDir.path}${Platform.pathSeparator}soar_score.db';
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.delete(recursive: true);
    }
  });

  test('serves the health endpoint on an OS-assigned free port', () async {
    final server = await startEmbeddedServer(databasePath);
    final client = ApiClient(baseUrl: server.baseUrl);
    try {
      // The caller never chooses a port: `startEmbeddedServer` binds port 0
      // and the OS assigns one, which the server reports back.
      expect(server.port, inInclusiveRange(1, 65535));
      expect(server.baseUrl, Uri.parse('http://localhost:${server.port}'));

      final health = await client.health();
      expect(
        health,
        HealthDto(
          name: embeddedServerName,
          displayName: embeddedServerDisplayName,
          version: embeddedServerVersion,
          schemaRevision: null,
        ),
      );
      client.close();
    } finally {
      await server.close();
    }
  });

  test(
    'the client round-trips /health over loopback with no external network',
    () async {
      final server = await startEmbeddedServer(databasePath);
      final client = ApiClient(baseUrl: server.baseUrl);
      try {
        // The request travels the loopback interface to the in-process server;
        // nothing off-machine is involved. This is the offline guarantee the
        // Windows build must hold (ticket 018).
        final health = await client.health();
        expect(health.name, embeddedServerName);
        expect(health.schemaRevision, null);
        client.close();
      } finally {
        await server.close();
      }
    },
  );

  test(
    'closing the server shuts it down cleanly and releases the port',
    () async {
      final server = await startEmbeddedServer(databasePath);
      final client = ApiClient(baseUrl: server.baseUrl);
      final port = server.port;

      // Baseline: the server answers before it is closed.
      final health = await client.health();
      expect(health.name, embeddedServerName);
      client.close();

      await server.close();

      // No orphaned server: nothing answers connections on the closed port
      // anymore; the port is released and can be bound again.
      await expectLater(
        Socket.connect('localhost', port, timeout: const Duration(seconds: 2)),
        throwsA(isA<SocketException>()),
      );
      final rebind = await ServerSocket.bind('localhost', port);
      await rebind.close();
    },
  );

  test(
    'a contest created through the API is owned by the Local account',
    () async {
      final server = await startEmbeddedServer(databasePath);
      final client = ApiClient(baseUrl: server.baseUrl);
      try {
        final id = Id.create();
        final created = await client.createContest(
          CreateContestRequest(
            id: id,
            name: 'Spring Open',
            startDateTime: DateTime.utc(2026, 10, 17, 14),
            endDateTime: DateTime.utc(2026, 10, 18, 22),
            timezone: 'America/Denver',
          ),
        );

        expect(created.ownerAccountId, server.localAccountId);
        expect(created.lifecycleState, LifecycleState.created);
        expect(await client.contest(id), created);

        final locked = await client.applyContestAction(
          id,
          ContestActionRequest(
            action: ContestAction.lock,
            baseRevision: created.revision,
          ),
        );
        expect(locked.adminLock, AdminLock.locked);
        expect(locked.revision, created.revision + 1);
      } finally {
        client.close();
        await server.close();
      }
    },
  );

  test('a configuration saved through the API moves the contest on', () async {
    final server = await startEmbeddedServer(databasePath);
    final client = ApiClient(baseUrl: server.baseUrl);
    try {
      final id = Id.create();
      await client.createContest(
        CreateContestRequest(
          id: id,
          name: 'Spring Open',
          startDateTime: DateTime.utc(2026, 10, 17, 14),
          endDateTime: DateTime.utc(2026, 10, 18, 22),
          timezone: 'America/Denver',
        ),
      );

      final saved = await client.saveConfiguration(
        id,
        SaveConfigurationRequest(
          baseRevisionNumber: 0,
          disciplineProfileId: SystemDisciplineProfiles.f5jId,
          config: ContestConfig(core: {}, discipline: {'working_time': 600}),
        ),
      );

      expect(saved.revision.revisionNumber, 1);
      expect(saved.revision.createdBy, server.localAccountId);
      expect(saved.contest.lifecycleState, LifecycleState.configuring);
      expect(await client.configuration(id), saved.revision);
      expect(await client.configurationRevisions(id), [saved.revision]);
      expect(await client.contest(id), saved.contest);
    } finally {
      client.close();
      await server.close();
    }
  });

  test('a score entered through the API starts the contest', () async {
    final server = await startEmbeddedServer(databasePath);
    final client = ApiClient(baseUrl: server.baseUrl);
    try {
      final id = Id.create();
      await client.createContest(
        CreateContestRequest(
          id: id,
          name: 'Spring Open',
          startDateTime: DateTime.utc(2026, 10, 17, 14),
          endDateTime: DateTime.utc(2026, 10, 18, 22),
          timezone: 'America/Denver',
        ),
      );
      await client.saveConfiguration(
        id,
        SaveConfigurationRequest(
          baseRevisionNumber: 0,
          disciplineProfileId: SystemDisciplineProfiles.f5jId,
          config: ContestConfig(core: {}, discipline: {'working_time': 600}),
        ),
      );
      for (var i = 0; i < 4; i++) {
        final profile = Id.create();
        await client.createParticipant(
          CreateParticipantRequest(
            id: profile,
            firstName: 'Pilot$i',
            lastName: 'Test',
          ),
        );
        await client.addParticipation(
          id,
          AddParticipationRequest(
            id: Id.create(),
            participantProfileId: profile,
          ),
        );
      }
      final matrix = await client.drawMatrix(
        id,
        DrawMatrixRequest(
          id: Id.create(),
          rounds: 2,
          groupsPerRound: 1,
          randomSeed: 7,
        ),
      );

      final result = await client.enterScore(
        id,
        matrix.assignments.first.id,
        const EnterScoreRequest(
          clientMutationId: 'entry-1',
          baseScoreRevision: 0,
          components: {'time_flown': 540, 'launch_height': 200},
        ),
      );

      expect(result.officialScore.scoreRevision, 1);
      expect(result.officialScore.setBy, server.localAccountId);
      expect(result.placeholder.state, ScorePlaceholderState.official);
      expect(result.calculated.rawScore, 440);
      expect(result.contest.lifecycleState, LifecycleState.running);
      final scores = await client.scores(id);
      expect(scores.slots.where((s) => s.officialScore != null), hasLength(1));
      expect(scores.rounds.first.scored, 1);
      expect(scores.rounds.first.total, 4);
      // The entry recalculated the results; three flights are still open.
      final results = await client.results(id);
      expect(results.asOfRound, 1);
      expect(results.isStale, isFalse);
      expect(results.isPreliminary, isTrue);
      expect(results.standings, hasLength(4));
      expect((await client.recalculateResults(id)).standings, hasLength(4));
    } finally {
      client.close();
      await server.close();
    }
  });

  test('opens the SQLite database at the requested path', () async {
    final server = await startEmbeddedServer(databasePath);
    await server.repository.contestRepository.getAll();
    try {
      expect(File(databasePath).existsSync(), isTrue);
    } finally {
      await server.close();
    }
  });

  test(
    'lists the four discipline profiles straight after first start',
    () async {
      final server = await startEmbeddedServer(databasePath);
      try {
        final profiles = await server.repository.disciplineProfileRepository
            .listPublished();

        expect(profiles.map((p) => p.profile.type), [
          DisciplineType.ales,
          DisciplineType.f3j,
          DisciplineType.f5j,
          DisciplineType.thermalDuration,
        ]);
        expect(profiles, unorderedEquals(SystemDisciplineProfiles.all));
        expect(
          await server.repository.roleRepository.listVisibleTo(),
          unorderedEquals(SystemRoles.all),
        );
      } finally {
        await server.close();
      }
    },
  );

  test('a later launch keeps the same system data', () async {
    final first = await startEmbeddedServer(databasePath);
    await first.close();

    final second = await startEmbeddedServer(databasePath);
    try {
      expect(
        await second.repository.landingTableRepository.listVisibleTo(),
        unorderedEquals(SystemLandingTables.all),
      );
      expect(
        await second.repository.disciplineProfileRepository.listPublished(),
        hasLength(4),
      );
    } finally {
      await second.close();
    }
  });

  test('has no contests unless the demo seed is requested', () async {
    final server = await startEmbeddedServer(databasePath);
    final client = ApiClient(baseUrl: server.baseUrl);
    try {
      expect(await client.contests(), isEmpty);
    } finally {
      client.close();
      await server.close();
    }
  });

  test('the demo data is served once, across launches', () async {
    final first = await startEmbeddedServer(databasePath, seedDemo: true);
    final firstClient = ApiClient(baseUrl: first.baseUrl);
    final seeded = await firstClient.contests();
    firstClient.close();
    await first.close();

    final second = await startEmbeddedServer(databasePath, seedDemo: true);
    final secondClient = ApiClient(baseUrl: second.baseUrl);
    try {
      expect(seeded, hasLength(5));
      expect(await secondClient.contests(), seeded);
    } finally {
      secondClient.close();
      await second.close();
    }
  });

  test('the demo data includes a drawn matrix', () async {
    final server = await startEmbeddedServer(databasePath, seedDemo: true);
    final client = ApiClient(baseUrl: server.baseUrl);
    try {
      final ready = (await client.contests()).firstWhere(
        (contest) => contest.name == 'Front Range F5J Open',
      );
      expect(ready.lifecycleState, LifecycleState.ready);
      expect((await client.matrix(ready.id)).rounds, hasLength(8));
      expect(await client.participations(ready.id), hasLength(16));
    } finally {
      client.close();
      await server.close();
    }
  });

  test('creates the Local account once and keeps it across launches', () async {
    final first = await startEmbeddedServer(databasePath);
    final id = first.localAccountId;
    await first.close();

    final second = await startEmbeddedServer(databasePath);
    try {
      expect(second.localAccountId, id);
    } finally {
      await second.close();
    }
  });

  test('the demo data is owned by the Local account', () async {
    final server = await startEmbeddedServer(databasePath, seedDemo: true);
    try {
      final owners = (await server.repository.contestRepository.getAll()).map(
        (contest) => contest.ownerAccountId,
      );
      expect(owners, everyElement(server.localAccountId));
    } finally {
      await server.close();
    }
  });

  test('refuses to publish a contest', () async {
    final server = await startEmbeddedServer(databasePath);
    final client = ApiClient(baseUrl: server.baseUrl);
    try {
      await expectLater(
        client.publishContest(
          Id.create(),
          const PublishContestRequest(
            clientMutationId: 'm-1',
            sourceContestRevision: 1,
          ),
        ),
        throwsA(
          isA<ApiHttpError>()
              .having((e) => e.statusCode, 'status', 409)
              .having(
                (e) => e.body,
                'body',
                contains('publishing_not_available'),
              ),
        ),
      );
    } finally {
      client.close();
      await server.close();
    }
  });

  test('the import route is served and answers 503 when the helpers are not shipped', () async {
    final server = await startEmbeddedServer(databasePath);
    final client = ApiClient(baseUrl: server.baseUrl);
    try {
      // The embedded server always wires the import route; without the
      // gs_importer helpers next to the executable it answers 503
      // `import_unavailable` instead of 404 (the route exists).
      await expectLater(
        client.importGliderScore('C:\\GliderScoreData.mdb'),
        throwsA(
          isA<ApiHttpError>()
              .having((e) => e.statusCode, 'status', 503)
              .having((e) => e.body, 'body', contains('import_unavailable')),
        ),
      );
    } finally {
      client.close();
      await server.close();
    }
  });
}
