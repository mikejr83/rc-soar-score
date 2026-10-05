import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show
        DisciplineType,
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
}
