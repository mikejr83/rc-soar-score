import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' show Contest, Id;
import 'package:soar_score_data/soar_score_data.dart'
    show LocalAccountRepository;

void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late ApiClient client;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_acting_test');
    server = await startEmbeddedServer(
      '${tempDir.path}${Platform.pathSeparator}soar_score.db',
    );
    client = ApiClient(
      baseUrl: server.baseUrl,
      tokenProvider: () async => server.secret,
    );
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
    // The data was claimed into the account, so sign-out keeps showing it.
    expect(signedOut.ownerAccountId, account);
    expect(server.actingAccountId, account);

    server.actAs(account);
    expect((await createContest('Again')).ownerAccountId, account);
  });

  test('a claimed installation acts as the account when it restarts', () async {
    final account = Id.create();
    await createContest('Offline work');
    await LocalAccountRepository(server.database).reassignTo(account);
    final dbPath = '${tempDir.path}${Platform.pathSeparator}soar_score.db';
    client.close();
    await server.close();

    server = await startEmbeddedServer(dbPath);
    client = ApiClient(
      baseUrl: server.baseUrl,
      tokenProvider: () async => server.secret,
    );

    expect(server.actingAccountId, account);
    expect((await client.contests()).map((c) => c.name), ['Offline work']);
  });
}
