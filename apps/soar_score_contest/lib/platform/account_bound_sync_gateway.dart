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
    this.isInspectionOwner,
  });

  final SyncGateway _inner;
  final ActingAccount acting;

  /// The account that owns the data of a scope, or `null` when none does
  /// (not known, or the Local account).
  final Future<core.Id?> Function(core.SyncScopeKey scope) ownerOf;

  /// Whether an owner holds data imported for inspection, which is never
  /// sent. A second line of defence behind the engine's own check: a request
  /// about such a scope is refused here, or fails if that cannot be told.
  final Future<bool> Function(core.Id owner)? isInspectionOwner;

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
    if (owner != null && await isInspectionOwner?.call(owner) == true) {
      throw InspectionDataError(what);
    }
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

/// The gateway of a build with no sign-in binding: every request goes
/// through, except those about a scope whose owner holds data imported for
/// inspection, which are refused. If the owner cannot be told apart from an
/// inspection owner, the request is not sent either.
class InspectionGuardedSyncGateway implements SyncGateway {
  InspectionGuardedSyncGateway(
    this._inner, {
    required this.ownerOf,
    required this.isInspectionOwner,
  });

  final SyncGateway _inner;
  final Future<core.Id?> Function(core.SyncScopeKey scope) ownerOf;
  final Future<bool> Function(core.Id owner) isInspectionOwner;

  Future<void> _check(String what, core.SyncScopeKey scope) async {
    final owner = await ownerOf(scope);
    if (owner != null && await isInspectionOwner(owner)) {
      throw InspectionDataError(what);
    }
  }

  @override
  Future<SyncInfoDto> syncInfo() => _inner.syncInfo();

  @override
  Future<core.Installation> registerInstallation(
    RegisterInstallationRequest request,
  ) => _inner.registerInstallation(request);

  @override
  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request) async {
    final scope = request.scope;
    await _check(
      'exchange',
      scope.contestId != null
          ? core.ContestScopeKey(scope.contestId!)
          : core.DirectorScopeKey(scope.ownerAccountId!),
    );
    return _inner.exchange(request);
  }

  @override
  Future<SystemDataResponse> systemData({
    required int afterSequence,
    String? pageToken,
  }) => _inner.systemData(afterSequence: afterSequence, pageToken: pageToken);

  @override
  Future<SyncMutationResult> resolveConflict(
    core.Id conflictId,
    ResolveConflictRequest request, {
    required core.SyncScopeKey scope,
  }) async {
    await _check('conflict decision', scope);
    return _inner.resolveConflict(conflictId, request, scope: scope);
  }
}

/// A request about data imported for inspection was about to be sent.
class InspectionDataError implements Exception {
  const InspectionDataError(this.what);

  final String what;

  @override
  String toString() =>
      'InspectionDataError: $what is data imported for '
      'inspection and is never sent';
}
