import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/inspection_owner_guard.dart';
import 'package:soar_score_contest/platform/native_sync.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// An inspection check that waits until the test lets it answer.
class _GatedGuard extends InspectionOwnerGuard {
  _GatedGuard(super.database);

  bool gated = false;
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> isInspection(core.Id? owner) async {
    if (gated) {
      if (!entered.isCompleted) entered.complete();
      await release.future;
    }
    return super.isInspection(owner);
  }
}

void main() {
  late Directory dir;
  late EmbeddedServer server;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('native_sync_close_test');
    server = await startEmbeddedServer('${dir.path}/soar_score.db');
  });

  tearDown(() async {
    await server.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'closing waits for a local change that is still being looked at',
    () async {
      final guard = _GatedGuard(server.database);
      final sync = await NativeSync.start(
        database: server.database,
        localAccountId: server.localAccountId,
        remote: ApiClient(
          baseUrl: Uri.parse('http://hosted.invalid'),
          httpClient: MockClient((_) async => http.Response('{}', 503)),
        ),
        databasePath: '${dir.path}/soar_score.db',
        inspectionOwners: guard,
      );
      guard.gated = true;
      await ContestRepository(server.database).save(
        core.Contest(
          id: core.Id.create(),
          name: 'Spring Meet',
          startDateTime: DateTime.utc(2026, 4, 15, 10),
          endDateTime: DateTime.utc(2026, 4, 16, 20),
          timezone: 'America/Denver',
          createdAt: DateTime.utc(2026, 4),
          updatedAt: DateTime.utc(2026, 4),
          ownerAccountId: server.localAccountId,
        ),
        metadata: core.MutationMetadata(
          clientMutationId: 'close-test',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 4),
        ),
      );
      await guard.entered.future.timeout(const Duration(seconds: 5));

      var closed = false;
      final closing = sync.close().then((_) => closed = true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(closed, isFalse, reason: 'the change is still being looked at');

      guard.release.complete();
      await closing;
      expect(closed, isTrue);
    },
  );
}
