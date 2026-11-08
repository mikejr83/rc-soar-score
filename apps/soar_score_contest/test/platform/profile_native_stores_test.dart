import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/platform/native_competition_import_store.dart';
import 'package:soar_score_contest/platform/native_contest_exchange.dart';
import 'package:soar_score_contest/server/profile_access.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/claimed_profile_harness.dart';

/// A plan that fails the test if anything reads it: a refused operation must
/// stop before it looks at what it was given.
class _UntouchedPlan implements core.RestorePlan {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('read ${invocation.memberName}');
}

/// The stores that reach the embedded database without the HTTP API refuse
/// every operation while the profile is not open to the signed-in user.
void main() {
  late Directory tempDir;
  late ClaimedProfileHarness app;
  final accountA = core.Id.create();
  final someContest = core.Id.create();

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_stores_test');
    app = await ClaimedProfileHarness.open(
      tempDir,
      subject: 'auth0|a',
      claim: (request) async => claimedBy(accountA, request),
    );
    await app.claimer.run();
    await app.createContest('A contest');
  });

  tearDown(() async {
    await app.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<int> rowCount(String table) async =>
      (await app.server.database
              .customSelect('SELECT COUNT(*) AS n FROM $table')
              .getSingle())
          .read<int>('n');

  /// Runs every store operation and expects each to refuse with [access].
  Future<void> expectEverythingRefused(ProfileAccess access) async {
    final exchange = NativeContestExchange(app.server);
    final pilots = NativeCompetitionImportStore(app.server);
    final contests = await rowCount('contests');
    final profiles = await rowCount('participant_profiles');

    Matcher failure() => throwsA(
      isA<ExchangeFailure>().having(
        (e) => e.message,
        'message',
        access.message,
      ),
    );
    Matcher refused() => throwsA(
      isA<ProfileUnavailableError>().having((e) => e.access, 'access', access),
    );

    await expectLater(exchange.export(someContest, redact: false), failure());
    await expectLater(exchange.preview(Uint8List(0)), failure());
    await expectLater(
      exchange.import(Uint8List(0), ExchangeImportMode.editable),
      failure(),
    );
    await expectLater(
      exchange.import(Uint8List(0), ExchangeImportMode.inspection),
      failure(),
    );
    await expectLater(exchange.inspectionContests(), refused());

    await expectLater(() => pilots.existing(), refused());
    await expectLater(
      () => pilots.apply(const [], reviewedRevisions: const {}),
      refused(),
    );
    await expectLater(
      () => pilots.stampProfiles(
        operationId: core.Id.create(),
        fingerprint: 'sha256:x',
        entries: const [],
      ),
      refused(),
    );
    await expectLater(
      () => pilots.restoreTarget(const core.RestoreIdentity(compNo: 1)),
      refused(),
    );
    await expectLater(
      () => pilots.importRestore(
        plan: _UntouchedPlan(),
        profileIds: const {},
        operationId: core.Id.create(),
        fingerprint: 'sha256:x',
        completed: false,
        confirmedReplace: false,
      ),
      refused(),
    );
    await expectLater(() => pilots.noteFor(someContest), refused());

    expect(await rowCount('contests'), contests);
    expect(await rowCount('participant_profiles'), profiles);
  }

  test('a restored B session offline: every operation refuses', () async {
    app.claim = (_) async => throw unreachableError();
    await app.restart(subject: 'auth0|b');
    await app.claimer.run();
    expect(app.acting.profileAccess, ProfileAccess.unverified);

    await expectEverythingRefused(ProfileAccess.unverified);
  });

  test('B refused by the service: every operation refuses', () async {
    app.claim = (_) async => throw alreadyClaimedError();
    await app.restart(subject: 'auth0|b');
    await app.claimer.run();
    expect(app.acting.profileAccess, ProfileAccess.mismatched);

    await expectEverythingRefused(ProfileAccess.mismatched);
  });

  test('the owning account is served', () async {
    await app.restart(subject: 'auth0|a');

    expect(app.acting.profileAccess, ProfileAccess.verified);
    expect(
      await NativeContestExchange(app.server).inspectionContests(),
      isEmpty,
    );
  });
}
