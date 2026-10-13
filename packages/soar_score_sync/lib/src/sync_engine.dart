import 'dart:async';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'outbox_order.dart';
import 'resolve_conflict_outcome.dart';
import 'sync_engine_config.dart';
import 'sync_failure_kind.dart';
import 'sync_gateway.dart';
import 'sync_mappers.dart';
import 'sync_scope_state.dart';
import 'sync_skip_reason.dart';
import 'sync_state.dart';

/// Keeps the local store in step with the service, one scope at a time.
///
/// A sync pulls first and only then pushes the outbox. Changes are stored
/// through the [ReplicatedChangeApplier], which never creates pending
/// mutations, and the cursor moves only after the changes it covers are
/// stored, so repeating a sync after a timeout is safe.
///
/// A failed sync never throws and never touches local data. It is reported
/// on [states] as a [SyncFailureKind].
class SyncEngine {
  SyncEngine({
    required this._store,
    required this._applier,
    required this._gateway,
    required this._config,
  }) : _state = SyncState(installationId: _config.installationId);

  final SyncStore _store;
  final ReplicatedChangeApplier _applier;
  final SyncGateway _gateway;
  final SyncEngineConfig _config;
  final _controller = StreamController<SyncState>.broadcast();
  final _remoteSequence = <SyncScopeKey, int>{};

  SyncState _state;
  bool _registered = false;
  bool _versionsChecked = false;
  Future<void> _tail = Future.value();

  /// The current state.
  SyncState get state => _state;

  /// A state after every step that changes what the director sees.
  Stream<SyncState> get states => _controller.stream;

  /// Syncs [scope]: pull, then push, then pull whatever the push returned.
  ///
  /// Syncs run one after another; asking again while one runs queues behind
  /// it. Returns why the sync failed, or null when it completed (or the scope
  /// is not synced at all, see [SyncScopeState.skipReason]).
  Future<SyncFailureKind?> syncScope(SyncScopeKey scope) {
    final result = _tail.then((_) => _syncScope(scope));
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Pulls the system data stream (profiles, system roles, landing tables).
  Future<SyncFailureKind?> syncSystemData() {
    final result = _tail.then((_) => _syncSystemData());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Sends the director's decision for [conflictId]. When the service
  /// accepts it, syncs [scope] so the answer is stored.
  ///
  /// Check [ResolveConflictOutcome.accepted]: the service can answer a
  /// successful request with a rejection or a conflict, and then the conflict
  /// is still open.
  Future<ResolveConflictOutcome> resolveConflict(
    SyncScopeKey scope,
    Id conflictId, {
    required String clientMutationId,
    required ConflictResolutionChoice choice,
    Map<String, Object?>? payload,
  }) async {
    SyncMutationResult? result;
    final failure = await _guard(() async {
      result = await _gateway.resolveConflict(
        conflictId,
        ResolveConflictRequest(
          clientMutationId: clientMutationId,
          choice: choice,
          payload: payload,
        ),
      );
    });
    if (failure != null || result?.outcome != MutationOutcome.accepted) {
      await _refresh(scope, failure: failure);
      return ResolveConflictOutcome(failure: failure, result: result);
    }
    final syncFailure = await syncScope(scope);
    return ResolveConflictOutcome(failure: syncFailure, result: result);
  }

  Future<void> dispose() async {
    await _tail;
    await _controller.close();
  }

  Future<SyncFailureKind?> _syncScope(SyncScopeKey scope) async {
    final syncable = await _config.isSyncable?.call(scope) ?? true;
    if (!syncable) {
      await _refresh(scope, skip: SyncSkipReason.accountless);
      return null;
    }
    _emit(_state.copyWith(syncing: true));
    try {
      final failure = await _guard(() async {
        await _prepare();
        final cursor = await _store.readCursor(scope);
        // Pull first, so the push is based on what the service already has.
        final pulled = await _pull(scope, await _exchange(scope, cursor, []));
        final pending = inDependencyOrder(await _store.pendingMutations(scope));
        if (pending.isNotEmpty) {
          final response = await _exchange(
            scope,
            pulled.cursor,
            pending.map(mutationToDto).toList(),
          );
          await _recordResults(pending, response.results);
          await _pull(scope, response, from: pulled.cursor);
        }
      });
      if (failure == null) {
        // Record the sync even when it brought no changes.
        await _store.writeCursor(
          scope,
          await _store.readCursor(scope),
          syncedAt: _config.now(),
        );
      }
      await _refresh(scope, failure: failure);
      return failure;
    } finally {
      _emit(_state.copyWith(syncing: false));
    }
  }

  Future<SyncFailureKind?> _syncSystemData() async {
    const scope = SystemScopeKey();
    final failure = await _guard(() async {
      await _prepare();
      var cursor = await _store.readCursor(scope);
      String? token;
      do {
        final page = await _gateway.systemData(
          afterSequence: cursor,
          pageToken: token,
        );
        cursor = await _storeChanges(scope, page.changes, cursor);
        token = page.nextPageToken;
      } while (token != null);
    });
    return failure;
  }

  /// Checks the versions and registers the installation, once each.
  Future<void> _prepare() async {
    if (!_versionsChecked) {
      final info = await _gateway.syncInfo();
      if (!info.accepts(
        protocol: _config.protocolVersion,
        schema: _config.schemaVersion,
      )) {
        throw const _UpdateRequired();
      }
      _versionsChecked = true;
    }
    if (!_registered) {
      await _gateway.registerInstallation(
        RegisterInstallationRequest(
          id: _config.installationId,
          label: _config.label,
          platform: _config.platform,
        ),
      );
      _registered = true;
    }
  }

  Future<SyncExchangeResponse> _exchange(
    SyncScopeKey scope,
    int cursor,
    List<SyncMutationDto> mutations, {
    String? pageToken,
  }) => _gateway.exchange(
    SyncExchangeRequest(
      protocolVersion: _config.protocolVersion,
      schemaVersion: _config.schemaVersion,
      installationId: _config.installationId,
      scope: scopeToDto(scope),
      lastAcknowledgedSequence: cursor,
      pageToken: pageToken,
      mutations: mutations,
    ),
  );

  /// Stores [first]'s changes and every following page, moving the cursor
  /// after each page is stored. [from] is the cursor the first response was
  /// requested from; continuation pages repeat it with the page token.
  Future<({int cursor})> _pull(
    SyncScopeKey scope,
    SyncExchangeResponse first, {
    int? from,
  }) async {
    final requestedFrom = from ?? await _store.readCursor(scope);
    var cursor = await _store.readCursor(scope);
    var page = first;
    while (true) {
      cursor = await _storeChanges(scope, page.changes, cursor);
      _remoteSequence[scope] = page.serverSequence;
      final token = page.nextPageToken;
      if (token == null) break;
      page = await _exchange(scope, requestedFrom, [], pageToken: token);
    }
    return (cursor: cursor);
  }

  /// Applies [changes] in sequence order, then moves the cursor to the
  /// highest sequence stored. Returns the new cursor.
  Future<int> _storeChanges(
    SyncScopeKey scope,
    List<SyncChangeDto> changes,
    int cursor,
  ) async {
    if (changes.isEmpty) return cursor;
    final ordered = [...changes]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    for (final change in ordered) {
      try {
        await _applier.apply(changeFromDto(scope, change));
      } on UnsupportedEntityTypeError {
        // The applier refuses an entity type it has no store for, or one that
        // is derived. Stop here without moving the cursor past it: nothing is
        // dropped, and the scope reports why it cannot go on.
        throw _UnsupportedChange(change.sequence, change.entityType);
      }
    }
    final highest = ordered.last.sequence;
    if (highest <= cursor) return cursor;
    await _store.writeCursor(scope, highest, syncedAt: _config.now());
    return highest;
  }

  Future<void> _recordResults(
    List<MutationRecord> sent,
    List<SyncMutationResult> results,
  ) async {
    final byClientId = {for (final m in sent) m.clientMutationId: m};
    for (final result in results) {
      final mutation = byClientId[result.clientMutationId];
      if (mutation == null) continue;
      switch (result.outcome) {
        case MutationOutcome.accepted:
          await _store.recordOutcome(
            mutationId: mutation.id,
            outcome: MutationOutcome.accepted,
            sequence: result.sequence,
            serverAcceptanceTime: _config.now(),
          );
        case MutationOutcome.rejected:
        case MutationOutcome.conflict:
          await _store.recordOutcome(
            mutationId: mutation.id,
            outcome: result.outcome,
            serverRejectionTime: _config.now(),
            reasonCode: result.reasonCode,
          );
        case MutationOutcome.skipped:
        case MutationOutcome.pending:
          // A skipped mutation waited on one that failed. It stays pending
          // and is sent again on the next sync.
          break;
      }
    }
  }

  /// Runs [body] and turns what it throws into a [SyncFailureKind].
  Future<SyncFailureKind?> _guard(Future<void> Function() body) async {
    try {
      await body();
      return null;
    } on _UpdateRequired {
      return SyncFailureKind.updateRequired;
    } on _UnsupportedChange {
      return SyncFailureKind.unsupportedChange;
    } on SyncRefusedError catch (error) {
      if (error.requiresUpdate) return SyncFailureKind.updateRequired;
      if (error.reason == SyncReasonCode.inactiveInstallation) {
        return SyncFailureKind.inactiveInstallation;
      }
      return SyncFailureKind.serverError;
    } on ApiNetworkError {
      return SyncFailureKind.offline;
    } on ApiHttpError catch (error) {
      return error.statusCode == 401
          ? SyncFailureKind.tokenExpired
          : SyncFailureKind.serverError;
    } on ApiException {
      return SyncFailureKind.serverError;
    }
  }

  Future<void> _refresh(
    SyncScopeKey scope, {
    SyncFailureKind? failure,
    SyncSkipReason? skip,
  }) async {
    final status = await _store.status(scope);
    final next = Map<SyncScopeKey, SyncScopeState>.of(_state.scopes);
    next[scope] = SyncScopeState(
      pendingMutations: status.pendingMutations,
      conflictsNeedingAction: status.conflictsNeedingAction,
      lastSyncedSequence: status.lastSyncedSequence,
      lastSyncedAt: status.lastSyncedAt,
      remoteSequence: _remoteSequence[scope],
      failure: failure,
      skipReason: skip,
    );
    _emit(_state.copyWith(scopes: next));
  }

  void _emit(SyncState next) {
    _state = next;
    if (!_controller.isClosed) _controller.add(next);
  }
}

/// The service's version range excludes this installation.
class _UpdateRequired implements Exception {
  const _UpdateRequired();
}

/// The applier cannot store a change the service sent.
class _UnsupportedChange implements Exception {
  const _UnsupportedChange(this.sequence, this.entityType);

  final int sequence;
  final String entityType;
}
