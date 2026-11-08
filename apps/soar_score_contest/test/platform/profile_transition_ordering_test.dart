import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/platform/native_contest_exchange.dart';
import 'package:soar_score_contest/server/profile_access.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/claimed_profile_harness.dart';

/// The rest of the transition matrix for a contest import held at its commit:
/// transitions that must not stop it, the two orderings of an import and a
/// claim, a claim that really runs against it, and a database that shuts
/// down under it.
void main() {
  late Directory tempDir;
  late Directory otherDir;
  late ClaimedProfileHarness app;
  late ClaimedProfileHarness source;
  final accountA = core.Id.create();
  late Uint8List file;
  late core.Id fileContestId;

  Future<int> rows(String where) async =>
      (await app.server.database
              .customSelect('SELECT COUNT(*) AS n FROM contests WHERE $where')
              .getSingle())
          .read<int>('n');

  Future<int> importedRows() => rows("id = '${fileContestId.value}'");

  Future<int> localOwnedRows() =>
      rows("owner_account_id = '${app.server.localAccountId.value}'");

  Matcher refused() => throwsA(
    isA<ExchangeFailure>().having(
      (e) => e.message,
      'message',
      anyOf(
        const ProfileUnavailableError.changed().message,
        ProfileAccess.linking.message,
        ProfileAccess.unverified.message,
      ),
    ),
  );

  Future<void> importFile() =>
      NativeContestExchange(app.server)
          .import(file, ExchangeImportMode.editable);

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_order_test');
    otherDir = Directory.systemTemp.createTempSync('soar_score_order_src');
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
    app = await ClaimedProfileHarness.open(
      tempDir,
      subject: null,
      claim: (request) async {
        if (app.auth.subject != 'auth0|a') throw alreadyClaimedError();
        return claimedBy(accountA, request);
      },
    );
  });

  tearDown(() async {
    await source.close();
    await app.close();
    for (final dir in [tempDir, otherDir]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  group('transitions that change nothing', () {
    test('signing out does not stop an import', () async {
      await app.auth.signInAs('auth0|a');
      await app.claimer.run();
      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        await app.auth.signOut();
      };

      await importFile();

      expect(await importedRows(), 1);
      expect(app.acting.profileAccess, ProfileAccess.verified);
    });

    test('the owner signing in again does not stop an import', () async {
      await app.auth.signInAs('auth0|a');
      await app.claimer.run();
      await app.auth.signOut();
      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        app.acting.signedIn('auth0|a');
      };

      await importFile();

      expect(await importedRows(), 1);
    });
  });

  group('an import and a claim', () {
    test('committed before the claim, the claim re-points it', () async {
      await importFile();
      expect(await importedRows(), 1);
      expect(await localOwnedRows(), greaterThan(0));

      await app.auth.signInAs('auth0|a');
      await app.claimer.run();

      expect(await importedRows(), 1);
      expect(await localOwnedRows(), 0);
      expect(
        await rows(
          "id = '${fileContestId.value}' AND owner_account_id = "
          "'${accountA.value}'",
        ),
        1,
      );
    });

    test('held at its commit while a real claim runs, it stores nothing '
        'and the claim still completes', () async {
      Future<void>? claim;
      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        // The sign-in starts the claim, which brackets the re-pointing before
        // it waits for the import's transaction.
        claim = app.auth.signInAs('auth0|a');
        await pumpEventQueue();
      };

      await expectLater(importFile(), refused());
      await claim;
      await app.claimer.run();

      expect(await importedRows(), 0);
      expect(await localOwnedRows(), 0);
      expect(app.acting.id, accountA);
      expect(app.acting.profileAccess, ProfileAccess.verified);
    });
  });

  group('the database shutting down', () {
    test('ends an import held at its commit without hanging', () async {
      app.server.beforeCommitHook = () async {
        app.server.beforeCommitHook = null;
        unawaited(app.server.close(drainTimeout: Duration.zero));
        await pumpEventQueue();
      };

      // Either outcome is clean: it commits before the close, or it fails.
      // What matters is that it ends, with no uncaught error.
      await importFile()
          .then<void>((_) {}, onError: (Object _) {})
          .timeout(const Duration(seconds: 20));
    });
  });
}
