import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_sync/soar_score_sync.dart';

import 'acting_account.dart';
import 'auth_epoch.dart';

/// A [SyncGateway] whose every request is bound to the sign-in of the account
/// whose data it carries.
///
/// For each request it finds who owns the scope, asks [ActingAccount] for the
/// sign-in that account is acting under, and only then, with no await left in
/// between, runs the request bound to that sign-in (see [AuthEpoch]). The
/// request carries that sign-in's token or is not sent: signing out, or in as
/// another account, at any point before the token is read refuses it. The
/// refusal looks like a lost connection to the engine, which leaves the
/// changes in place and tries the scope again later.
class AccountBoundSyncGateway implements SyncGateway {
  AccountBoundSyncGateway(
    this._inner, {
    required this.acting,
    required this.ownerOf,
  });

  final SyncGateway _inner;
  final ActingAccount acting;

  /// The account that owns the data of a scope, or `null` when none does
  /// (not known, or the Local account).
  final Future<core.Id?> Function(core.SyncScopeKey scope) ownerOf;

  Future<T> _bound<T>(String what, int? lease, Future<T> Function() send) {
    if (lease == null) throw SessionChangedError(what);
    return acting.epoch.runBound(lease, send);
  }

  Future<T> _forScope<T>(
    String what,
    core.SyncScopeKey scope,
    Future<T> Function() send,
  ) async {
    final owner = await ownerOf(scope);
    // No await between choosing the sign-in and starting the request.
    return _bound(what, owner == null ? null : acting.leaseFor(owner), send);
  }

  @override
  Future<SyncInfoDto> syncInfo() async =>
      _bound('sync info', acting.lease(), _inner.syncInfo);

  @override
  Future<core.Installation> registerInstallation(
    RegisterInstallationRequest request,
  ) async => _bound(
    'installation',
    acting.lease(),
    () => _inner.registerInstallation(request),
  );

  @override
  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request) {
    final scope = request.scope;
    final key = scope.contestId != null
        ? core.ContestScopeKey(scope.contestId!)
        : core.DirectorScopeKey(scope.ownerAccountId!);
    return _forScope('exchange', key, () => _inner.exchange(request));
  }

  @override
  Future<SystemDataResponse> systemData({
    required int afterSequence,
    String? pageToken,
  }) async => _bound(
    'system data',
    acting.lease(),
    () => _inner.systemData(afterSequence: afterSequence, pageToken: pageToken),
  );

  @override
  Future<SyncMutationResult> resolveConflict(
    core.Id conflictId,
    ResolveConflictRequest request, {
    required core.SyncScopeKey scope,
  }) => _forScope(
    'conflict decision',
    scope,
    () => _inner.resolveConflict(conflictId, request, scope: scope),
  );
}
