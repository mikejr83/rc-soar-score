import 'dart:async';

import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../auth/auth_session.dart';
import '../services/sync/sync_problem.dart';
import 'auth_epoch.dart';

final _logger = Logger('LocalAccountClaimer');

/// Claims the installation's Local account into the signed-in account.
///
/// When a director is signed in, it asks the service to record that the Local
/// account now belongs to them, then re-points the Local data and the changes
/// waiting to be sent to their account, so that data starts to sync. Both
/// steps can be repeated without effect, so it runs at start-up, at sign-in
/// and whenever the service becomes reachable again, and never twice at once.
///
/// A claim belongs to the sign-in it started under (see [AuthEpoch]): its
/// request carries that sign-in's token or is not sent. Once the service has
/// recorded it, the Local data is re-pointed to the account it names whatever
/// happened meanwhile, since the service would refuse a claim by anyone else.
/// Acting as the account ([onClaimed], which gets the sign-in's number) and
/// the problems shown wait for a sign-in that still is the one. A restart
/// between the two steps repeats the claim, which the service answers the same
/// way for the same account.
///
/// A failure leaves the data as it was and is reported through
/// [onProblem]; the next run tries again.
class LocalAccountClaimer {
  LocalAccountClaimer({
    required this._auth,
    required this._epoch,
    required this._local,
    required this._claim,
    required this._onClaimed,
    required this._onSignedOut,
    required this._onProblem,
    this._getPreferences,
    this._putPreferences,
  }) : assert(
         (_getPreferences == null) == (_putPreferences == null),
         'getPreferences and putPreferences are given together',
       );

  final AuthSession _auth;
  final AuthEpoch _epoch;
  final core.LocalAccountRepository _local;
  final Future<LocalAccountClaimDto> Function(ClaimLocalAccountRequest) _claim;
  final Future<void> Function(core.Id accountId, int session) _onClaimed;
  final void Function() _onSignedOut;
  final void Function(SyncProblem? problem) _onProblem;

  /// Reads and stores the signed-in account's preferences on the service.
  /// Both null (the default) skips carrying preferences over.
  final Future<core.AccountPreferences> Function()? _getPreferences;
  final Future<core.AccountPreferences> Function(core.AccountPreferences)?
  _putPreferences;

  Future<void>? _running;
  bool _stopped = false;

  /// Starts watching the sign-in; claims now when already signed in.
  void start() {
    _auth.addListener(_authChanged);
    _authChanged();
  }

  void stop() {
    _stopped = true;
    _auth.removeListener(_authChanged);
  }

  /// The service became reachable again: try again if signed in.
  void connectivityRestored() => _authChanged();

  void _authChanged() {
    if (_stopped) return;
    if (_auth.isSignedIn) {
      unawaited(run());
    } else {
      _onSignedOut();
      _onProblem(null);
    }
  }

  /// Claims once, unless a claim is already running (then that one is awaited).
  Future<void> run() =>
      _running ??= _claimLoop().whenComplete(() => _running = null);

  /// Claims for the current sign-in, and again if the sign-in changed while
  /// that ran (the director signed out and in as someone else).
  Future<void> _claimLoop() async {
    int session;
    do {
      session = _epoch.value;
      await _claimOnce(session);
    } while (session != _epoch.value && _auth.isSignedIn && !_stopped);
  }

  Future<void> _claimOnce(int session) async {
    if (!_epoch.isCurrent(session) || _stopped) return;
    final local = await _local.find();
    if (local == null || !_epoch.isCurrent(session) || _stopped) return;
    final core.Id accountId;
    try {
      final claim = await _epoch.runBound(
        session,
        () => _claim(ClaimLocalAccountRequest(localAccountId: local)),
      );
      accountId = claim.accountId;
    } on SessionChangedError {
      _logger.fine('Claim dropped: the sign-in changed before it was sent');
      return;
    } on ApiNetworkError {
      _logger.fine('Claim postponed: the service is not reachable');
      return;
    } on ApiHttpError catch (error) {
      _logger.warning('The service refused the claim: ${error.statusCode}');
      if (!_epoch.isCurrent(session) || _stopped) return;
      _onProblem(_problemFor(error.statusCode));
      return;
    } on ApiException catch (error) {
      _logger.warning('The claim failed: $error');
      if (!_epoch.isCurrent(session) || _stopped) return;
      _onProblem(SyncProblem.accountClaimFailed);
      return;
    }
    // The service has recorded the claim, so the Local data is that account's
    // whatever happened meanwhile: a later claim for another account would be
    // refused. Re-point it even if the director has signed out or in as
    // someone else; only acting as the account and syncing wait for a session
    // that still is theirs. Once stopped the database may be closing: the
    // next start repeats the claim.
    if (_stopped) return;
    try {
      await _local.reassignTo(accountId);
    } on Object catch (error, stack) {
      _logger.warning('Re-pointing the Local data failed', error, stack);
      if (!_epoch.isCurrent(session) || _stopped) return;
      _onProblem(SyncProblem.accountClaimBlocked);
      return;
    }
    if (!_epoch.isCurrent(session) || _stopped) return;
    _onProblem(null);
    await _carryOverPreferences(session);
    try {
      await _onClaimed(accountId, session);
    } on Object catch (error, stack) {
      _logger.warning('Starting the sync after the claim failed', error, stack);
    }
  }

  /// Merges the preferences chosen offline with the account's: a choice the
  /// account already has stands, one it lacks is taken from this installation.
  /// The merged result is kept locally too, so the installation shows the
  /// account's choices. A failure is only logged; the next run tries again.
  Future<void> _carryOverPreferences(int session) async {
    final get = _getPreferences;
    final put = _putPreferences;
    if (get == null || put == null) return;
    try {
      final stored = await _epoch.runBound(session, get);
      final local = await _local.preferences();
      final merged = stored.orElse(local);
      final result = merged == stored
          ? stored
          : await _epoch.runBound(session, () => put(merged));
      if (_stopped || result == local) return;
      await _local.savePreferences(result);
    } on SessionChangedError {
      _logger.fine('Preferences dropped: the sign-in changed');
    } on Object catch (error, stack) {
      _logger.warning('Carrying the preferences over failed', error, stack);
    }
  }

  static SyncProblem _problemFor(int status) => switch (status) {
    401 || 403 => SyncProblem.signInExpired,
    >= 500 => SyncProblem.serverError,
    _ => SyncProblem.accountClaimFailed,
  };
}
