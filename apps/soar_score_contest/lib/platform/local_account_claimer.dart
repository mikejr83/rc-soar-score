import 'dart:async';

import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../auth/auth_session.dart';
import '../services/sync/sync_problem.dart';

final _logger = Logger('LocalAccountClaimer');

/// Claims the installation's Local account into the signed-in account.
///
/// When a director is signed in, it asks the service to record that the Local
/// account now belongs to them, then re-points the Local data and the changes
/// waiting to be sent to their account, so that data starts to sync. Both
/// steps can be repeated without effect, so it runs at start-up, at sign-in
/// and whenever the service becomes reachable again, and never twice at once.
///
/// A failure leaves the data as it was and is reported through
/// [onProblem]; the next run tries again.
class LocalAccountClaimer {
  LocalAccountClaimer({
    required this._auth,
    required this._local,
    required this._claim,
    required this._onClaimed,
    required this._onProblem,
  });

  final AuthSession _auth;
  final core.LocalAccountRepository _local;
  final Future<LocalAccountClaimDto> Function(ClaimLocalAccountRequest) _claim;
  final Future<void> Function(core.Id accountId) _onClaimed;
  final void Function(SyncProblem? problem) _onProblem;

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
      _onProblem(null);
    }
  }

  /// Claims once, unless a claim is already running (then that one is awaited).
  Future<void> run() =>
      _running ??= _claimOnce().whenComplete(() => _running = null);

  Future<void> _claimOnce() async {
    if (!_auth.isSignedIn) return;
    final local = await _local.find();
    if (local == null) return;
    final core.Id accountId;
    try {
      final claim = await _claim(
        ClaimLocalAccountRequest(localAccountId: local),
      );
      accountId = claim.accountId;
    } on ApiNetworkError {
      _logger.fine('Claim postponed: the service is not reachable');
      return;
    } on ApiHttpError catch (error) {
      _logger.warning('The service refused the claim: ${error.statusCode}');
      _onProblem(_problemFor(error.statusCode));
      return;
    } on ApiException catch (error) {
      _logger.warning('The claim failed: $error');
      _onProblem(SyncProblem.accountClaimFailed);
      return;
    }
    // The director may have signed out while the service answered; the data
    // then stays as it is until the next sign-in repeats the claim.
    if (!_auth.isSignedIn) return;
    try {
      await _local.reassignTo(accountId);
    } on Object catch (error, stack) {
      _logger.warning('Re-pointing the Local data failed', error, stack);
      _onProblem(SyncProblem.accountClaimBlocked);
      return;
    }
    _onProblem(null);
    try {
      await _onClaimed(accountId);
    } on Object catch (error, stack) {
      _logger.warning('Starting the sync after the claim failed', error, stack);
    }
  }

  static SyncProblem _problemFor(int status) => switch (status) {
    401 || 403 => SyncProblem.signInExpired,
    >= 500 => SyncProblem.serverError,
    _ => SyncProblem.accountClaimFailed,
  };
}
