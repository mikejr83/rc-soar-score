import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/local_account_claimer.dart';
import 'package:soar_score_contest/platform/native_pilot_import_store.dart';
import 'package:soar_score_contest/platform/native_sync.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../support/fake_auth_session.dart';

/// Two installations of one director and a hosted service, through the real
/// engines: the installation that writes the first pilot link manages the
/// remembered links; the other learns it does not, its queued link writes are
/// refused when it reconnects, and an import there leaves the saved links
/// alone.
void main() {
  late SoarScoreDatabase hostedDatabase;
  late Repository hosted;
  late shelf.Handler api;
  late Directory dir;
  late EmbeddedServer a;
  late EmbeddedServer b;
  late NativeSync syncA;
  late NativeSync syncB;
  late ApiClient remoteA;
  late ApiClient remoteB;
  final director = core.Id.create();
  late core.DirectorScopeKey scope;
  var dropPush = false;
  var edits = 0;
  const pilot = 12;

  ApiClient client() => ApiClient(
    baseUrl: Uri.parse('http://hosted.invalid'),
    tokenProvider: () async => director.value,
    httpClient: MockClient((request) async {
      final response = await api(
        shelf.Request(
          request.method,
          request.url,
          headers: request.headers,
          body: request.bodyBytes,
        ),
      );
      final body = await response.read().expand((chunk) => chunk).toList();
      if (dropPush && request.body.contains('"mutations":[{')) {
        // The service decided, but the answer never arrived.
        dropPush = false;
        throw http.ClientException('connection lost', request.url);
      }
      return http.Response.bytes(
        body,
        response.statusCode,
        headers: response.headers,
      );
    }),
  );

  /// The account an installation acts as: its Local account until it signs
  /// in, then the director.
  core.Id ownerOf(EmbeddedServer installation) => installation.actingAccountId;

  core.MutationMetadata meta(EmbeddedServer installation, String name) =>
      core.MutationMetadata(
        clientMutationId: '$name-${edits++}',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 4, 1).add(Duration(minutes: edits)),
        actorId: ownerOf(installation),
      );

  Future<core.ParticipantProfile> addProfile(
    EmbeddedServer installation,
    String name,
  ) async {
    final now = DateTime.utc(2026, 4);
    return ParticipantProfileRepository(installation.database).save(
      core.ParticipantProfile(
        id: core.Id.create(),
        ownerAccountId: ownerOf(installation),
        firstName: name,
        lastName: 'Pilot',
        createdAt: now,
        updatedAt: now,
      ),
      metadata: meta(installation, 'profile-$name'),
    );
  }

  Future<core.PilotImportLink> addLink(
    EmbeddedServer installation,
    core.ParticipantProfile profile, {
    Map<String, Object?> values = const {},
  }) {
    final now = DateTime.utc(2026, 4);
    return PilotImportLinkRepository(installation.database).save(
      core.PilotImportLink(
        id: core.Id.create(),
        ownerAccountId: ownerOf(installation),
        sourcePilotNo: pilot,
        participantProfileId: profile.id,
        sourceValues: values,
        createdAt: now,
        updatedAt: now,
      ),
      metadata: meta(installation, 'link'),
    );
  }

  Future<void> signIn(
    EmbeddedServer installation,
    NativeSync sync,
    ApiClient remote,
  ) async {
    final auth = FakeAuthSession(signedIn: true);
    await LocalAccountClaimer(
      auth: auth,
      epoch: AuthEpoch(auth),
      local: LocalAccountRepository(installation.database),
      claim: remote.claimLocalAccount,
      onClaimed: (id, _) => sync.accountClaimed(id),
      onSignedOut: () {},
      onProblem: (_) {},
    ).run();
    installation.actAs(director);
    expect(await sync.engine.syncScope(scope), isNull);
  }

  Future<List<core.PilotImportLink>> linksOn(EmbeddedServer installation) =>
      PilotImportLinkRepository(installation.database).listForOwner(director);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    dropPush = false;
    edits = 0;
    scope = core.DirectorScopeKey(director);
    hostedDatabase = SoarScoreDatabase(
      NativeDatabase.memory(),
      profile: DatabaseProfile.server,
    );
    hosted = Repository(hostedDatabase);
    await hosted.accountRepository.save(
      core.Account(
        id: director,
        firstName: 'Dana',
        lastName: 'Director',
        kind: core.AccountKind.registered,
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
      ),
    );
    api = buildApiHandler(
      name: 'hosted',
      displayName: 'Hosted',
      version: '0.0.0',
      schemaRevision: hostedDatabase.schemaVersion,
      repository: hosted,
      authMiddleware: fixedPrincipal(Principal(accountId: director)),
    );
    dir = Directory.systemTemp.createTempSync('pilot_link_collision_sync');
    a = await startEmbeddedServer('${dir.path}/a/soar_score.db');
    b = await startEmbeddedServer('${dir.path}/b/soar_score.db');
    remoteA = client();
    remoteB = client();
    syncA = await NativeSync.start(
      database: a.database,
      localAccountId: a.localAccountId,
      remote: remoteA,
      databasePath: '${dir.path}/a/soar_score.db',
    );
    syncB = await NativeSync.start(
      database: b.database,
      localAccountId: b.localAccountId,
      remote: remoteB,
      databasePath: '${dir.path}/b/soar_score.db',
    );
  });

  tearDown(() async {
    await syncA.close();
    await syncB.close();
    await a.close();
    await b.close();
    remoteA.close();
    remoteB.close();
    await hostedDatabase.close();
    dir.deleteSync(recursive: true);
  });

  /// A writes a link and syncs; B holds a link of its own that it wrote while
  /// offline, and signs in afterwards.
  Future<core.ParticipantProfile> managerAndLateWriter() async {
    final first = await addProfile(a, 'First');
    await addLink(a, first);
    final second = await addProfile(b, 'Second');
    await addLink(b, second);
    await signIn(a, syncA, remoteA);
    await signIn(b, syncB, remoteB);
    return first;
  }

  test('the installation that wrote the links manages them', () async {
    await managerAndLateWriter();

    expect(await NativePilotImportStore(a).linksManagedElsewhere(), isFalse);
    expect(await NativePilotImportStore(b).linksManagedElsewhere(), isTrue);
  });

  test('queued link writes of the other installation are refused', () async {
    final first = await managerAndLateWriter();

    final service = await hosted.pilotImportLinkRepository.listForOwner(
      director,
    );
    expect(service.single.participantProfileId, first.id);
    final rejected = await syncB.engine.rejectedMutations(scope);
    expect(
      rejected.where((m) => m.reasonCode == 'not_link_manager'),
      isNotEmpty,
    );
    // Reconnecting again does not get the refused write through.
    expect(await syncB.engine.syncScope(scope), isNull);
    expect(
      (await hosted.pilotImportLinkRepository.listForOwner(director)).single.id,
      service.single.id,
    );
  });

  test('an import without remembered links leaves the links alone', () async {
    final first = await managerAndLateWriter();
    final before = await hosted.pilotImportLinkRepository.listForOwner(
      director,
    );
    final store = NativePilotImportStore(b);
    final profiles = await store.existing();
    expect(profiles, isNotEmpty);

    const draft = core.PilotDraft(
      sourcePilotNo: 40,
      firstName: 'New',
      lastName: 'Pilot',
    );
    final match = core.PilotMatch(
      draft: draft,
      kind: core.PilotMatchKind.newPilot,
      candidateIds: const [],
    );
    final outcome = await store.apply(
      [
        core.PilotImportSelection(
          match: match,
          choice: core.PilotImportChoice.add,
        ),
      ],
      reviewedRevisions: {for (final p in profiles) p.id: p.revision},
      rememberLinks: false,
    );

    expect(outcome.added, hasLength(1));
    expect(await syncB.engine.syncScope(scope), isNull);
    final after = await hosted.pilotImportLinkRepository.listForOwner(director);
    expect(after.map((l) => l.id), before.map((l) => l.id));
    expect(after.single.participantProfileId, first.id);
    expect((await linksOn(b)).where((l) => l.sourcePilotNo == 40), isEmpty);
  });

  test('the manager corrects a match and a later import reuses it', () async {
    final x = await addProfile(a, 'Xavier');
    final y = await addProfile(a, 'Yolanda');
    final store = NativePilotImportStore(a);
    const draft = core.PilotDraft(
      sourcePilotNo: 40,
      firstName: 'Pat',
      lastName: 'Pilot',
    );
    const matcher = core.PilotImportMatcher();

    Future<void> importTo(core.Id target) async {
      final profiles = await store.existing();
      final links = await store.existingLinks();
      final match = matcher.match([draft], profiles, links: links).single;
      await store.apply(
        [
          core.PilotImportSelection(
            match: match,
            choice: core.PilotImportChoice.update,
            targetProfileId: target,
          ),
        ],
        reviewedRevisions: {for (final p in profiles) p.id: p.revision},
      );
    }

    await importTo(x.id);
    await importTo(y.id);

    final links = await store.existingLinks();
    expect(links.single.participantProfileId, y.id);
    final later = matcher
        .match([draft], await store.existing(), links: links)
        .single;
    expect(later.remembered, isTrue);
    expect(later.candidateIds, [y.id]);
  });
}
