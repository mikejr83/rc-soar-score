import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
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
    final server = await startEmbeddedServer(databasePath: databasePath);
    final client = ApiClient(baseUrl: server.baseUrl);
    try {
      // The caller never chooses a port: `startEmbeddedServer` binds port 0
      // and the OS assigns one, which the server reports back.
      expect(server.port, inInclusiveRange(1, 65535));
      expect(server.baseUrl, Uri.parse('http://localhost:${server.port}'));

      final health = await client.health();
      expect(
        health,
        const HealthDto(
          name: embeddedServerName,
          displayName: embeddedServerDisplayName,
          version: embeddedServerVersion,
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
      final server = await startEmbeddedServer(databasePath: databasePath);
      final client = ApiClient(baseUrl: server.baseUrl);
      try {
        // The request travels the loopback interface to the in-process server;
        // nothing off-machine is involved. This is the offline guarantee the
        // Windows build must hold (ticket 018).
        final health = await client.health();
        expect(
          health,
          const HealthDto(
            name: embeddedServerName,
            displayName: embeddedServerDisplayName,
            version: embeddedServerVersion,
          ),
        );
        client.close();
      } finally {
        await server.close();
      }
    },
  );

  test(
    'closing the server shuts it down cleanly and releases the port',
    () async {
      final server = await startEmbeddedServer(databasePath: databasePath);
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
    final server = await startEmbeddedServer(databasePath: databasePath);
    try {
      expect(File(databasePath).existsSync(), isTrue);
    } finally {
      await server.close();
    }
  });
}
