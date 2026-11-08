import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/native_contest_exchange.dart';
import 'package:soar_score_contest/platform/native_pilot_import_store.dart';
import 'package:soar_score_contest/server/profile_access.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/claimed_profile_harness.dart';

/// An operation that began before a claim, a sign-in or a mismatch must not
/// store anything after it: the hook runs between its last write and the
/// commit, where the real transition would land.
void main() {
  late Directory tempDir;
  late Directory otherDir;
  late ClaimedProfileHarness app;
  late ClaimedProfileHarness source;
  final accountA = core.Id.create();
  late Uint8List file;
  late core.Id fileContestId;

  Future<ClaimedProfileHarness> open(
    Directory dir, {
    required String? subject,
  }) => ClaimedProfileHarness.open(
    dir,
    subject: subject,
    claim: (request) async {
      if (app.auth.subject != 'auth0|a') throw alreadyClaimedError();
      return claimedBy(accountA, request);
    },
  );

  Future<int> rows(String where) async =>
      (await app.server.database
              .customSelect('SELECT COUNT(*) AS n FROM contests WHERE $where')
              .getSingle())
          .read<int>('n');

  Future<int> importedRows() => rows("id = '${fileContestId.value}'");

  Matcher refused() => throwsA(
    isA<ExchangeFailure>().having(
      (e) => e.message,
      'message',
      anyOf(
        const ProfileUnavailableError.changed().message,
        ProfileAccess.linking.message,
        ProfileAccess.unverified.message,
        ProfileAccess.mismatched.message,
      ),
    ),
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_delay_test');
    otherDir = Directory.systemTemp.createTempSync('soar_score_delay_src');
    // A contest on another installation, exported to a file.
    source = await ClaimedProfileHarness.open(
      otherDir,
      subject: null,
      claim: (_) async => throw unreachableError(),
    );
    final made = await source.createContest('Exported contest');
    fileContestId = made.id;
    file = (await NativeContestExchange(
      source.server,
    ).export(made.id, redact: false)).bytes;
    // The installation the file is imported into: signed out, never claimed.
    app = await open(tempDir, subject: null);
  });

  tearDown(() async {
    await source.close();
    await app.close();
    for (final dir in [tempDir, otherDir]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  group('a contest import', () {
    test('crossing a claim stores nothing and leaves no Local row', () async {
      final exchange = NativeContestExchange(app.server);
      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        app.server.beginClaim(accountA, 'auth0|a');
      };

      await expectLater(
        exchange.import(file, ExchangeImportMode.editable),
        refused(),
      );
      app.server.endClaim();

      expect(await importedRows(), 0);
      expect(
        await rows("owner_account_id = '${app.server.localAccountId.value}'"),
        0,
      );
    });

    test('crossing a different sign-in stores nothing', () async {
      // The installation belongs to A, who is signed in and verified.
      await app.auth.signInAs('auth0|a');
      await app.claimer.run();
      expect(app.acting.profileAccess, ProfileAccess.verified);
      final before = await rows('1 = 1');

      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        app.acting.signedIn('auth0|b');
      };
      await expectLater(
        NativeContestExchange(app.server)
            .import(file, ExchangeImportMode.editable),
        refused(),
      );

      expect(app.acting.profileAccess, ProfileAccess.unverified);
      expect(await rows('1 = 1'), before);
      expect(await importedRows(), 0);
    });

    test('crossing a refusal of the claim stores nothing', () async {
      await app.auth.signInAs('auth0|a');
      await app.claimer.run();
      final before = await rows('1 = 1');

      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        app.acting.signedIn('auth0|b');
        app.server.markProfileMismatch();
      };
      await expectLater(
        NativeContestExchange(app.server)
            .import(file, ExchangeImportMode.editable),
        refused(),
      );

      expect(await rows('1 = 1'), before);
      expect(await importedRows(), 0);
    });

    test('a notification that changes nothing does not stop it', () async {
      await app.auth.signInAs('auth0|a');
      await app.claimer.run();

      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        // The service became reachable again: the same user, seen again.
        app.acting.signedIn('auth0|a');
      };
      await NativeContestExchange(app.server)
          .import(file, ExchangeImportMode.editable);

      expect(await importedRows(), 1);
    });
  });

  group('a pilot import', () {
    core.PilotImportSelection newPilot() => core.PilotImportSelection(
      match: const core.PilotMatch(
        draft: core.PilotDraft(
          sourcePilotNo: 1,
          firstName: 'Alex',
          lastName: 'Ashdown',
        ),
        kind: core.PilotMatchKind.newPilot,
        candidateIds: [],
      ),
      choice: core.PilotImportChoice.add,
    );

    Future<int> profiles() async =>
        (await app.server.database
                .customSelect('SELECT COUNT(*) AS n FROM participant_profiles')
                .getSingle())
            .read<int>('n');

    test('crossing a claim stores nothing', () async {
      final before = await profiles();
      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        app.server.beginClaim(accountA, 'auth0|a');
      };

      await expectLater(
        NativePilotImportStore(app.server)
            .apply([newPilot()], reviewedRevisions: const {}),
        throwsA(isA<ProfileUnavailableError>()),
      );
      app.server.endClaim();

      expect(await profiles(), before);
    });

    test('without a transition it stores the pilot', () async {
      final before = await profiles();

      await NativePilotImportStore(app.server)
          .apply([newPilot()], reviewedRevisions: const {});

      expect(await profiles(), before + 1);
    });
  });

  group('an API write', () {
    test('crossing a sign-in answers 409 and stores nothing', () async {
      await app.auth.signInAs('auth0|a');
      await app.claimer.run();
      final before = await rows('1 = 1');

      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        app.acting.signedIn('auth0|b');
      };
      await expectLater(
        app.createContest('Written across a sign-in'),
        throwsA(
          isA<ApiHttpError>()
              .having((e) => e.statusCode, 'status', 409)
              .having(
                (e) => e.error?.code,
                'code',
                anyOf(profileChangedCode, profileUnverifiedCode),
              ),
        ),
      );

      expect(await rows('1 = 1'), before);
    });
  });

  group('a read', () {
    test('finished after a transition returns nothing', () async {
      await app.auth.signInAs('auth0|a');
      await app.claimer.run();
      await app.createContest('A contest');

      await expectLater(
        app.server.runProfileOperation(() async {
          final contests = await app.server.repository.contestRepository
              .getAll();
          expect(contests, isNotEmpty);
          app.acting.signedIn('auth0|b');
          return contests;
        }),
        throwsA(isA<ProfileUnavailableError>()),
      );
    });

    test(
      'an export that finishes after a transition returns nothing',
      () async {
        await app.auth.signInAs('auth0|a');
        await app.claimer.run();
        final made = await app.createContest('A contest');

        // The transition lands while the export runs: the export reads the
        // database through the repository, so move the profile from there.
        final exchange = NativeContestExchange(app.server);
        final export = exchange.export(made.id, redact: false);
        app.acting.signedIn('auth0|b');

        await expectLater(export, refused());
      },
    );
  });

  test('a claim that moves nothing does not disturb running work', () async {
    await app.auth.signInAs('auth0|a');
    await app.claimer.run();

    app.server.beforeCommitHook = () async {
      app.server.beforeCommitHook = null;
      // The same account claiming again, as on every reconnect.
      expect(app.server.beginClaim(accountA, 'auth0|a'), isFalse);
    };
    await NativeContestExchange(app.server)
        .import(file, ExchangeImportMode.editable);

    expect(await importedRows(), 1);
  });
}
