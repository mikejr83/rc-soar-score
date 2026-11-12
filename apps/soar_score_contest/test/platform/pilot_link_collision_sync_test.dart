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

/// Two installations of one director link the same GliderScore pilot while
/// offline, through the real engines and a hosted service: the director's
/// choices are kept for review, retries and interruptions keep them, and the
/// decision reaches both devices.
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

  Future<core.PilotImportLink> editLink(
    EmbeddedServer installation,
    core.PilotImportLink link, {
    core.ParticipantProfile? profile,
    Map<String, Object?>? values,
  }) => PilotImportLinkRepository(installation.database).save(
    core.PilotImportLink(
      id: link.id,
      ownerAccountId: link.ownerAccountId,
      sourcePilotNo: link.sourcePilotNo,
      participantProfileId: profile?.id ?? link.participantProfileId,
      sourceValues: values ?? link.sourceValues,
      createdAt: link.createdAt,
      updatedAt: DateTime.utc(2026, 4, 2),
      revision: link.revision,
    ),
    metadata: meta(installation, 'edit'),
  );

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

  Future<List<core.ConflictRecord>> reviewsOn(NativeSync sync) async => [
    for (final c in await sync.engine.openConflicts(scope))
      if (c.entityType == 'PilotImportLink') c,
  ];

  Future<core.PilotImportLink?> linkOnService() async {
    final links = await hosted.pilotImportLinkRepository.listForOwner(director);
    return links.isEmpty ? null : links.single;
  }

  /// A links the pilot to [first]; B, offline, links it to [second] and edits
  /// the link twice (the last edit names [third]). A signs in and syncs
  /// first, then B.
  Future<
    ({
      core.ParticipantProfile first,
      core.ParticipantProfile second,
      core.ParticipantProfile third,
    })
  >
  collide() async {
    final first = await addProfile(a, 'First');
    await addLink(a, first);
    final second = await addProfile(b, 'Second');
    final third = await addProfile(b, 'Third');
    final mine = await addLink(b, second);
    final edited = await editLink(b, mine, values: {'club': 'north'});
    await editLink(b, edited, profile: third);
    await signIn(a, syncA, remoteA);
    await signIn(b, syncB, remoteB);
    return (first: first, second: second, third: third);
  }

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

  group('different participants', () {
    test('keep the latest edit of the other device for review', () async {
      final p = await collide();

      final onB = await reviewsOn(syncB);
      expect(onB, hasLength(1));
      expect(onB.single.acceptedPayload!['source_pilot_no'], pilot);
      expect(
        onB.single.acceptedPayload!['participant_profile_id'],
        p.first.id.value,
      );
      expect(
        onB.single.competingPayload!['participant_profile_id'],
        p.third.id.value,
      );
      expect(onB.single.competingPayload!['source_values'], {'club': 'north'});
      // The service kept the first link and nothing else.
      expect((await linkOnService())!.participantProfileId, p.first.id);
      // B shows the service's link while the review waits.
      expect((await linksOn(b)).single.participantProfileId, p.first.id);
      // A learns of the review on its next sync.
      expect(await syncA.engine.syncScope(scope), isNull);
      final onA = await reviewsOn(syncA);
      expect(onA.map((c) => c.id), [onB.single.id]);
    });

    test('are held back from imports on both devices until decided', () async {
      await collide();
      await syncA.engine.syncScope(scope);

      expect(await NativePilotImportStore(b).pilotsUnderReview(), {pilot});
      expect(await NativePilotImportStore(a).pilotsUnderReview(), {pilot});
    });

    test('the director takes the other device link on both devices', () async {
      final p = await collide();
      final review = (await reviewsOn(syncB)).single;

      final result = await syncB.engine.resolveConflict(
        scope,
        review.id,
        clientMutationId: 'decide-1',
        choice: core.ConflictResolutionChoice.tookCompeting,
      );
      expect(result.accepted, isTrue);
      expect(await syncA.engine.syncScope(scope), isNull);

      for (final links in [
        await linksOn(a),
        await linksOn(b),
        await hosted.pilotImportLinkRepository.listForOwner(director),
      ]) {
        expect(links, hasLength(1));
        expect(links.single.participantProfileId, p.third.id);
        expect(links.single.sourceValues, {'club': 'north'});
      }
      expect(await reviewsOn(syncA), isEmpty);
      expect(await reviewsOn(syncB), isEmpty);
      expect(await NativePilotImportStore(a).pilotsUnderReview(), isEmpty);
      expect(await NativePilotImportStore(b).pilotsUnderReview(), isEmpty);
    });

    test('the director keeps the stored link on both devices', () async {
      final p = await collide();
      final review = (await reviewsOn(syncB)).single;

      final result = await syncB.engine.resolveConflict(
        scope,
        review.id,
        clientMutationId: 'decide-1',
        choice: core.ConflictResolutionChoice.keptAccepted,
      );
      expect(result.accepted, isTrue);
      expect(await syncA.engine.syncScope(scope), isNull);

      for (final links in [await linksOn(a), await linksOn(b)]) {
        expect(links.single.participantProfileId, p.first.id);
      }
      expect((await linkOnService())!.participantProfileId, p.first.id);
      expect(await reviewsOn(syncA), isEmpty);
      expect(await reviewsOn(syncB), isEmpty);
    });

    test(
      'keep every edit when an answer is lost and the sync repeats',
      () async {
        final first = await addProfile(a, 'First');
        await addLink(a, first);
        final second = await addProfile(b, 'Second');
        final third = await addProfile(b, 'Third');
        final mine = await addLink(b, second);
        await editLink(b, mine, profile: third);
        await signIn(a, syncA, remoteA);
        // B signs in: its claim syncs, and the answer to the push is lost.
        dropPush = true;
        final auth = FakeAuthSession(signedIn: true);
        await LocalAccountClaimer(
          auth: auth,
          epoch: AuthEpoch(auth),
          local: LocalAccountRepository(b.database),
          claim: remoteB.claimLocalAccount,
          onClaimed: (id, _) => syncB.accountClaimed(id),
          onSignedOut: () {},
          onProblem: (_) {},
        ).run();
        await syncB.engine.syncScope(scope);

        // The service decided; B does not know yet. The retry changes nothing.
        expect(await syncB.engine.syncScope(scope), isNull);
        expect(await syncB.engine.syncScope(scope), isNull);

        final reviews = await reviewsOn(syncB);
        expect(reviews, hasLength(1));
        expect(
          reviews.single.competingPayload!['participant_profile_id'],
          third.id.value,
        );
        expect(dropPush, isFalse);
        expect(syncB.engine.state.scopes[scope]?.pendingMutations, 0);
      },
    );

    test('a review shown before the link changed is refused', () async {
      final p = await collide();
      final shown = (await reviewsOn(syncB)).single;
      // Device A changes the stored link while the director looks at it.
      await syncA.engine.syncScope(scope);
      final mine = (await linksOn(a)).single;
      await editLink(a, mine, values: {'club': 'south'});
      expect(await syncA.engine.syncScope(scope), isNull);

      final stale = await syncB.engine.resolveConflict(
        scope,
        shown.id,
        clientMutationId: 'decide-old',
        choice: core.ConflictResolutionChoice.tookCompeting,
      );
      expect(stale.accepted, isFalse);
      expect((await linkOnService())!.participantProfileId, p.first.id);

      // The refreshed comparison needs a new decision.
      expect(await syncB.engine.syncScope(scope), isNull);
      final fresh = (await reviewsOn(syncB)).single;
      expect(fresh.id, isNot(shown.id));
      expect(fresh.acceptedPayload!['source_values'], {'club': 'south'});
      final decided = await syncB.engine.resolveConflict(
        scope,
        fresh.id,
        clientMutationId: 'decide-new',
        choice: core.ConflictResolutionChoice.tookCompeting,
      );
      expect(decided.accepted, isTrue);
      expect((await linkOnService())!.participantProfileId, p.third.id);
    });
  });

  group('one link both devices hold', () {
    /// Both devices hold the link; A relinks it and syncs; B edits twice
    /// offline (the last edit names the third participant) and syncs.
    Future<
      ({
        core.ParticipantProfile first,
        core.ParticipantProfile second,
        core.ParticipantProfile third,
      })
    >
    shared() async {
      final first = await addProfile(a, 'First');
      final second = await addProfile(a, 'Second');
      final third = await addProfile(a, 'Third');
      final link = await addLink(a, first);
      await signIn(a, syncA, remoteA);
      await signIn(b, syncB, remoteB);
      final held = (await linksOn(b)).single;
      expect(held.id, link.id);
      final relinked = await editLink(
        a,
        (await linksOn(a)).single,
        profile: second,
      );
      expect(await syncA.engine.syncScope(scope), isNull);
      final mine = await editLink(b, held, profile: third);
      await editLink(b, mine, values: {'club': 'north'});
      expect(relinked.revision, greaterThan(held.revision));
      expect(await syncB.engine.syncScope(scope), isNull);
      return (first: first, second: second, third: third);
    }

    for (final choice in core.ConflictResolutionChoice.values.where(
      (c) =>
          c == core.ConflictResolutionChoice.keptAccepted ||
          c == core.ConflictResolutionChoice.tookCompeting,
    )) {
      test('${choice.name} converges both devices and the service', () async {
        final p = await shared();
        final review = (await reviewsOn(syncB)).single;
        expect(await NativePilotImportStore(b).pilotsUnderReview(), {pilot});

        final result = await syncB.engine.resolveConflict(
          scope,
          review.id,
          clientMutationId: 'decide-1',
          choice: choice,
        );
        expect(result.accepted, isTrue);
        expect(await syncA.engine.syncScope(scope), isNull);
        expect(await syncB.engine.syncScope(scope), isNull);

        final expected = choice == core.ConflictResolutionChoice.keptAccepted
            ? p.second.id
            : p.third.id;
        final hostedLinks = await hosted.pilotImportLinkRepository.listForOwner(
          director,
        );
        for (final links in [await linksOn(a), await linksOn(b), hostedLinks]) {
          expect(links.single.participantProfileId, expected);
        }
        expect((await linksOn(a)).single.revision, hostedLinks.single.revision);
        expect((await linksOn(b)).single.revision, hostedLinks.single.revision);
        expect(await reviewsOn(syncA), isEmpty);
        expect(await reviewsOn(syncB), isEmpty);
        // The decision stays closed after another round of syncs, and both
        // devices import again.
        expect(await syncA.engine.syncScope(scope), isNull);
        expect(await syncB.engine.syncScope(scope), isNull);
        expect(await reviewsOn(syncB), isEmpty);
        expect(await NativePilotImportStore(a).pilotsUnderReview(), isEmpty);
        expect(await NativePilotImportStore(b).pilotsUnderReview(), isEmpty);
      });
    }
  });

  group('the same participant', () {
    test('needs no review and leaves the details to the next import', () async {
      const draft = core.PilotDraft(
        sourcePilotNo: pilot,
        firstName: 'Shared',
        lastName: 'Pilot',
      );
      final shared = await addProfile(a, 'Shared');
      await signIn(a, syncA, remoteA);
      await signIn(b, syncB, remoteB);
      // Both devices know the participant; each links the pilot to it offline
      // and saved what its own import saw.
      await addLink(
        a,
        shared,
        values: core.PilotImportMatcher.sourceValues(
          const core.PilotDraft(
            sourcePilotNo: pilot,
            firstName: 'Shared',
            lastName: 'Pilot',
            club: 'a',
          ),
        ),
      );
      await addLink(
        b,
        shared,
        values: core.PilotImportMatcher.sourceValues(
          const core.PilotDraft(
            sourcePilotNo: pilot,
            firstName: 'Shared',
            lastName: 'Pilot',
            club: 'b',
          ),
        ),
      );
      expect(await syncA.engine.syncScope(scope), isNull);
      expect(await syncB.engine.syncScope(scope), isNull);
      expect(await syncA.engine.syncScope(scope), isNull);

      expect(await reviewsOn(syncA), isEmpty);
      expect(await reviewsOn(syncB), isEmpty);
      expect(await NativePilotImportStore(b).pilotsUnderReview(), isEmpty);
      for (final links in [await linksOn(a), await linksOn(b)]) {
        expect(links.single.id, (await linkOnService())!.id);
      }
      // The next import compares the file with the saved details and asks.
      final onB = (await linksOn(b)).single;
      final shown = (await ParticipantProfileRepository(b.database)
          .findById(shared.id))!;
      final match = const core.PilotImportMatcher()
          .match(
            [
              const core.PilotDraft(
                sourcePilotNo: pilot,
                firstName: 'Shared',
                lastName: 'Pilot',
                club: 'b',
              ),
            ],
            [shown],
            links: [onB],
          )
          .single;
      expect(match.remembered, isTrue);
      expect(match.sourceChanged, isTrue);
      expect(match.sourceChanges.map((c) => c.field), ['club']);
      expect(match.defaultAction, core.PilotImportAction.ask);
      expect(draft.sourcePilotNo, pilot);
    });
  });

  group('a deleted participant', () {
    test('stays deleted when another device links it offline', () async {
      final shared = await addProfile(a, 'Shared');
      await signIn(a, syncA, remoteA);
      await signIn(b, syncB, remoteB);
      expect(
        await ParticipantProfileRepository(b.database).findById(shared.id),
        isNotNull,
      );
      // A deletes the participant; B, still offline, links the pilot to it.
      expect(
        await ParticipantProfileRepository(a.database)
            .delete(shared.id, metadata: meta(a, 'delete')),
        isTrue,
      );
      final orphan = await addLink(b, shared);

      expect(await syncA.engine.syncScope(scope), isNull);
      expect(await syncB.engine.syncScope(scope), isNull);

      expect(await linkOnService(), isNull);
      expect(await linksOn(a), isEmpty);
      expect(await linksOn(b), isEmpty);
      expect(
        await ParticipantProfileRepository(b.database).findById(shared.id),
        isNull,
      );
      final refused = await syncB.engine.rejectedMutations(scope);
      expect(refused.map((m) => m.entityId), contains(orphan.id));
      expect(await NativePilotImportStore(b).pilotsUnderReview(), isEmpty);
      expect(await reviewsOn(syncB), isEmpty);
    });

    test('takes a link another device made first', () async {
      final shared = await addProfile(a, 'Shared');
      await signIn(a, syncA, remoteA);
      await signIn(b, syncB, remoteB);
      await addLink(b, shared);
      expect(await syncB.engine.syncScope(scope), isNull);
      expect(await linkOnService(), isNotNull);

      await ParticipantProfileRepository(a.database)
          .delete(shared.id, metadata: meta(a, 'delete'));
      expect(await syncA.engine.syncScope(scope), isNull);
      expect(await syncB.engine.syncScope(scope), isNull);

      expect(await linkOnService(), isNull);
      expect(await linksOn(a), isEmpty);
      expect(await linksOn(b), isEmpty);
    });
  });
}
