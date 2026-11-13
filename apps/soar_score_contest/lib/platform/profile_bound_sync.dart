import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_sync/soar_score_sync.dart';

import '../server/profile_access.dart';
import 'acting_account.dart';
import 'auth_epoch.dart';
import 'sync_pin.dart';

/// Ties the local writes of a sync (changes applied from a response, the
/// cursor, the outcomes of sent mutations) to the profile and the sign-in the
/// exchange was made under.
///
/// The gateway records a [SyncPin] when a request starts. Each write then runs
/// as an operation pinned to it, so the database refuses the statement or the
/// commit once the profile has changed (a claim, a mismatch, another account)
/// or the sign-in has ended (signing out, signing in again). A refused write
/// ends the sync as a lost connection, which leaves everything in place for
/// the scope to be tried again later: applying a change twice is a no-op, and
/// the cursor only moves after its changes are stored.
class SyncProfileBinding {
  SyncProfileBinding(this._acting);

  final ActingAccount _acting;

  /// The pin of the exchange in progress. Only the gateway calls that the
  /// engine queues one after another (exchanges and system data, which are
  /// followed by local writes) set it; see [ProfileBoundSyncGateway].
  SyncPin? _pin;

  /// Pins the exchange about to be sent for the data of [owner]. [generation]
  /// is read by the caller before any await, so a change while the owner is
  /// looked up counts.
  void pin({required int generation, required core.Id? owner}) {
    _pin = SyncPin(
      generation: generation,
      owner: owner,
      lease: owner == null ? _acting.lease() : _acting.leaseFor(owner),
    );
  }

  int get generation => _acting.profileGeneration;

  /// Runs [write] pinned to the exchange in progress.
  Future<T> write<T>(Future<T> Function() write) async {
    final pin = _pin;
    if (pin == null) return write();
    try {
      return await _acting.runPinned(pin, write);
    } on ProfileUnavailableError {
      throw SessionChangedError('a sync write');
    }
  }
}

/// A [SyncGateway] that pins each exchange for [SyncProfileBinding].
class ProfileBoundSyncGateway implements SyncGateway {
  ProfileBoundSyncGateway(this._inner, this._binding, this._ownerOf);

  final SyncGateway _inner;
  final SyncProfileBinding _binding;
  final Future<core.Id?> Function(core.SyncScopeKey scope) _ownerOf;

  Future<void> _pinScope(core.SyncScopeKey scope) async {
    final generation = _binding.generation;
    _binding.pin(generation: generation, owner: await _ownerOf(scope));
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
    await _pinScope(
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
  }) async {
    _binding.pin(generation: _binding.generation, owner: null);
    return _inner.systemData(
      afterSequence: afterSequence,
      pageToken: pageToken,
    );
  }

  /// Not pinned: the decision writes nothing locally, and the engine does not
  /// queue it behind the syncs, so pinning here would replace the pin of a
  /// sync in progress. The sync that stores its answer pins its own exchange.
  @override
  Future<SyncMutationResult> resolveConflict(
    core.Id conflictId,
    ResolveConflictRequest request, {
    required core.SyncScopeKey scope,
  }) => _inner.resolveConflict(conflictId, request, scope: scope);
}

/// A [ReplicatedChangeApplier] whose every change is written pinned.
class ProfileBoundChangeApplier implements core.ReplicatedChangeApplier {
  ProfileBoundChangeApplier(this._inner, this._binding);

  final core.ReplicatedChangeApplier _inner;
  final SyncProfileBinding _binding;

  @override
  Future<bool> apply(core.ReplicatedChange change) =>
      _binding.write(() => _inner.apply(change));
}

/// A [core.SyncStore] whose writes are pinned; reads are not.
class ProfileBoundSyncStore implements core.SyncStore {
  ProfileBoundSyncStore(this._inner, this._binding);

  final core.SyncStore _inner;
  final SyncProfileBinding _binding;

  @override
  Future<List<core.MutationRecord>> pendingMutations(core.SyncScopeKey scope) =>
      _inner.pendingMutations(scope);

  @override
  Future<List<core.MutationRecord>> rejectedMutations(
    core.SyncScopeKey scope,
  ) => _inner.rejectedMutations(scope);

  @override
  Future<Set<core.Id>> refusedMutationIds(core.SyncScopeKey scope) =>
      _inner.refusedMutationIds(scope);

  @override
  Future<void> recordOutcome({
    required core.Id mutationId,
    required core.MutationOutcome outcome,
    int? sequence,
    DateTime? serverAcceptanceTime,
    DateTime? serverRejectionTime,
    String? reasonCode,
    String? errorMessage,
  }) => _binding.write(
    () => _inner.recordOutcome(
      mutationId: mutationId,
      outcome: outcome,
      sequence: sequence,
      serverAcceptanceTime: serverAcceptanceTime,
      serverRejectionTime: serverRejectionTime,
      reasonCode: reasonCode,
      errorMessage: errorMessage,
    ),
  );

  @override
  Future<int> readCursor(core.SyncScopeKey scope) => _inner.readCursor(scope);

  @override
  Future<void> writeCursor(
    core.SyncScopeKey scope,
    int lastSyncedSequence, {
    DateTime? syncedAt,
  }) => _binding.write(
    () => _inner.writeCursor(scope, lastSyncedSequence, syncedAt: syncedAt),
  );

  @override
  Future<List<core.ConflictRecord>> conflictsNeedingAction(
    core.SyncScopeKey scope,
  ) => _inner.conflictsNeedingAction(scope);

  @override
  Future<core.SyncStatus> status(core.SyncScopeKey scope) =>
      _inner.status(scope);
}
