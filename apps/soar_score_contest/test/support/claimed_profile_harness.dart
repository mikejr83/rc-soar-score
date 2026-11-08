import 'dart:io';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/acting_account.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/local_account_claimer.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/server/profile_access.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import 'fake_auth_session.dart';

/// A [FakeAuthSession] whose identity the test sets.
class SubjectAuthSession extends FakeAuthSession {
  SubjectAuthSession({String? subject})
    : _subject = subject,
      super(signedIn: subject != null);

  String? _subject;

  @override
  String? get subject => isSignedIn ? _subject : null;

  /// Signs in as [subject] (the stored session of that user).
  Future<void> signInAs(String? subject) async {
    _subject = subject;
    await signIn();
  }
}

/// The embedded server, sign-in and claimer wired as `NativeBootstrap` wires
/// them, over a database file that can be closed and opened again.
///
/// [claim] stands for the service. A test makes it fail with
/// `ApiNetworkError` for "offline", or hold its answer on a `Completer`.
class ClaimedProfileHarness {
  ClaimedProfileHarness._(this.path, this.claim);

  final String path;
  Future<LocalAccountClaimDto> Function(ClaimLocalAccountRequest) claim;

  late EmbeddedServer server;
  late ApiClient client;
  late SubjectAuthSession auth;
  late ActingAccount acting;
  late LocalAccountClaimer claimer;
  final problems = <SyncProblem?>[];

  /// Runs after the Local data was re-pointed (and committed) but before the
  /// claimer carries on, so a test can sign out at that exact moment.
  Future<void> Function()? afterReassign;

  static Future<ClaimedProfileHarness> open(
    Directory directory, {
    required String? subject,
    required Future<LocalAccountClaimDto> Function(ClaimLocalAccountRequest)
    claim,
  }) async {
    final harness = ClaimedProfileHarness._(
      '${directory.path}${Platform.pathSeparator}soar_score.db',
      claim,
    );
    await harness._start(subject);
    return harness;
  }

  /// Closes the app and starts it again with [subject] restored (null for a
  /// signed-out start), as `NativeBootstrap.start` does.
  Future<void> restart({required String? subject}) async {
    await close();
    await _start(subject);
  }

  Future<void> _start(String? subject) async {
    server = await startEmbeddedServer(path);
    client = ApiClient(
      baseUrl: server.baseUrl,
      tokenProvider: () async => server.secret,
    );
    auth = SubjectAuthSession(subject: subject);
    final epoch = AuthEpoch(auth);
    acting = ActingAccount(server, epoch);
    claimer = LocalAccountClaimer(
      auth: auth,
      epoch: epoch,
      local: _HookedLocalAccount(
        LocalAccountRepository(server.database),
        () => afterReassign,
      ),
      claim: (request) => claim(request),
      onSignedIn: acting.signedIn,
      onClaimRecorded: acting.claimRecorded,
      onClaimPostponed: () {
        if (acting.profileAccess == ProfileAccess.unverified) {
          problems.add(SyncProblem.accountUnverified);
        }
      },
      onClaimed: (id, session) async {
        acting.actAs(id, epoch: session);
      },
      onSignedOut: acting.actAsLocal,
      onProblem: problems.add,
      onAccountMismatch: (session) =>
          acting.markProfileMismatch(epoch: session),
    )..start();
  }

  Future<core.Contest> createContest(String name) => client.createContest(
    CreateContestRequest(
      id: core.Id.create(),
      name: name,
      startDateTime: DateTime.utc(2026, 10, 17, 14),
      endDateTime: DateTime.utc(2026, 10, 18, 22),
      timezone: 'America/Denver',
    ),
  );

  Future<int> contestRows() async =>
      (await server.database
              .customSelect('SELECT COUNT(*) AS n FROM contests')
              .getSingle())
          .read<int>('n');

  Future<void> close() async {
    claimer.stop();
    client.close();
    await server.close();
  }
}

/// The service's answer to a claim by [account].
LocalAccountClaimDto claimedBy(
  core.Id account,
  ClaimLocalAccountRequest request,
) => LocalAccountClaimDto(
  accountId: account,
  localAccountId: request.localAccountId,
  claimedAt: DateTime.utc(2026, 11, 8),
);

/// The service refusing a claim: the Local account is another account's.
ApiHttpError alreadyClaimedError() => ApiHttpError(
  'claimed',
  statusCode: 409,
  body: '{"error":{"code":"already_claimed","message":"claimed"}}',
  requestUri: Uri.parse('http://hosted.invalid/api/v1/account/local-claims'),
);

/// The service being out of reach.
ApiNetworkError unreachableError() => ApiNetworkError(
  'offline',
  requestUri: Uri.parse('http://hosted.invalid/api/v1/account/local-claims'),
);

/// The data layer's Local account repository that lets a test act between the
/// re-pointing and what follows it.
class _HookedLocalAccount implements core.LocalAccountRepository {
  _HookedLocalAccount(this._inner, this._hook);

  final LocalAccountRepository _inner;
  final Future<void> Function()? Function() _hook;

  @override
  Future<void> reassignTo(core.Id accountId, {String? subject}) async {
    await _inner.reassignTo(accountId, subject: subject);
    await _hook()?.call();
  }

  @override
  Future<core.Id?> find() => _inner.find();

  @override
  Future<core.Id> ensure() => _inner.ensure();

  @override
  Future<core.Id?> linkedAccount() => _inner.linkedAccount();

  @override
  Future<String?> linkedSubject() => _inner.linkedSubject();

  @override
  Future<core.AccountPreferences> preferences() => _inner.preferences();

  @override
  Future<void> savePreferences(core.AccountPreferences preferences) =>
      _inner.savePreferences(preferences);
}
