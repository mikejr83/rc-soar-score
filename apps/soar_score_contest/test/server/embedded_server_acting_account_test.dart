import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' show Contest, Id;

void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late ApiClient client;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_acting_test');
    server = await startEmbeddedServer(
      '${tempDir.path}${Platform.pathSeparator}soar_score.db',
    );
    client = ApiClient(baseUrl: server.baseUrl);
  });

  tearDown(() async {
    client.close();
    await server.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<Contest> createContest(String name) => client.createContest(
    CreateContestRequest(
      id: Id.create(),
      name: name,
      startDateTime: DateTime.utc(2026, 10, 17, 14),
      endDateTime: DateTime.utc(2026, 10, 18, 22),
      timezone: 'America/Denver',
    ),
  );

  test('acts as the Local account until the claim', () async {
    expect(server.actingAccountId, server.localAccountId);
    final contest = await createContest('Before');
    expect(contest.ownerAccountId, server.localAccountId);
  });

  test('sign-in, create, sign-out, create', () async {
    final account = Id.create();

    server.actAs(account);
    final signedIn = await createContest('While signed in');
    final role = await client.createRole(
      CreateRoleRequest(id: Id.create(), displayName: 'Timer'),
    );
    expect(signedIn.ownerAccountId, account);
    expect(role.ownerAccountId, account);

    server.actAsLocal();
    final signedOut = await createContest('After sign-out');
    expect(signedOut.ownerAccountId, server.localAccountId);
    expect(server.actingAccountId, server.localAccountId);

    server.actAs(account);
    expect((await createContest('Again')).ownerAccountId, account);
  });
}
