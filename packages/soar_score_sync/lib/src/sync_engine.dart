import 'dart:async';
import 'dart:convert';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'outbox_batches.dart';
import 'outbox_order.dart';
import 'resolve_conflict_outcome.dart';
import 'sync_engine_config.dart';
import 'sync_failure_kind.dart';
import 'sync_gateway.dart';
import 'sync_mappers.dart';
import 'sync_scope_state.dart';
import 'sync_skip_reason.dart';
import 'sync_state.dart';

const _openUpload = 'open';
const _finishUpload = 'finish';

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
  final _outcomes = StreamController<SyncFailureKind?>.broadcast();
  final _remoteSequence = <SyncScopeKey, int>{};

  // Per scope, how many exchanges changed local data or the service's copy.
  final _dataRevision = <SyncScopeKey, int>{};

  SyncState _state;
  bool _registered = false;
  bool _versionsChecked = false;
  Future<void> _tail = Future.value();

  /// The current state.
  SyncState get state => _state;

  /// A state after every step that changes what the director sees.
  Stream<SyncState> get states => _controller.stream;

  /// How each sync that contacted the service ended: null when it completed,
  /// else why it failed. A scope that is not synced at all reports nothing, so
  /// an event says whether the service could be reached.
  Stream<SyncFailureKind?> get outcomes => _outcomes.stream;

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

  /// Reads [scope]'s state from the local store without contacting the
  /// service, for a screen that opens before any sync has run.
  ///
  /// A failure from an earlier attempt is kept. Runs behind a sync in
  /// progress.
  Future<void> refresh(SyncScopeKey scope) {
    final result = _tail.then((_) async {
      final syncable = await _config.isSyncable?.call(scope) ?? true;
      await _refresh(
        scope,
        failure: _state.scopes[scope]?.failure,
        skip: syncable ? null : SyncSkipReason.accountless,
      );
    });
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// The mutations the service rejected in [scope], oldest first, with the
  /// reason code and message it gave.
  Future<List<MutationRecord>> rejectedMutations(SyncScopeKey scope) =>
      _store.rejectedMutations(scope);

  /// The conflicts in [scope] that wait for the director's decision, with the
  /// payloads for the side-by-side view.
  Future<List<ConflictRecord>> openConflicts(SyncScopeKey scope) =>
      _store.conflictsNeedingAction(scope);

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
        scope: scope,
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
    await _outcomes.close();
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
          await _push(scope, pending, pulled.cursor);
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
      if (!_outcomes.isClosed) _outcomes.add(failure);
      return failure;
    } finally {
      _emit(_state.copyWith(syncing: false));
    }
  }

  /// Sends [pending] in as many exchanges as the service's limits need, each
  /// one's results stored before the next is sent.
  ///
  /// A mutation that depends on one that was not accepted is not sent; it
  /// stays pending. One too large to ever fit is marked rejected with
  /// `payload_too_large` and stays in the outbox with that reason.
  ///
  /// The first upload of a contest is the contest's creation plus its whole
  /// history, and it may need several exchanges. The creation's own outcome
  /// is therefore held back until every other mutation of the upload has been
  /// decided: an interrupted upload still has it pending, sends it again (the
  /// service answers a repeat with its first decision) and says
  /// `first_upload`, so the service keeps the contest's history exempt from
  /// its lock and completed rules.
  Future<void> _push(
    SyncScopeKey scope,
    List<MutationRecord> pending,
    int cursor,
  ) async {
    final creation = scope is ContestScopeKey
        ? pending.where(
            (m) =>
                m.entityType == 'Contest' &&
                m.entityId == scope.contestId &&
                m.baseRevision == null,
          )
        : const <MutationRecord>[];
    final heldCreation = creation.isEmpty ? null : creation.first;
    final firstUpload = heldCreation != null;
    // What the data requests carry, so sizes are measured on the real thing.
    final openFlag = firstUpload ? _openUpload : null;

    final envelope = utf8
        .encode(
          jsonEncode(
            _request(scope, cursor, const [], firstUpload: openFlag).toJson(),
          ),
        )
        .length;
    final split = splitOutbox(
      pending,
      envelopeBytes: envelope,
      soloBytes: (m) => utf8
          .encode(
            jsonEncode(
              _request(scope, cursor, [
                mutationToDto(m),
              ], firstUpload: openFlag).toJson(),
            ),
          )
          .length,
      maxBytes: _config.maxExchangeBytes,
      maxMutations: _config.maxExchangeMutations,
    );
    for (final tooLarge in split.oversized) {
      await _store.recordOutcome(
        mutationId: tooLarge.id,
        outcome: MutationOutcome.rejected,
        serverRejectionTime: _config.now(),
        reasonCode: SyncReasonCode.payloadTooLarge.code,
        errorMessage: 'The change is too large to send in one request.',
      );
    }

    // Mutations not accepted, by id: whatever depends on one waits.
    // A refused mutation leaves the pending list, so earlier passes' refusals
    // come from the store: a dependent of one must not be sent either.
    final blocked = <Id>{
      ...await _store.refusedMutationIds(scope),
      for (final m in split.oversized) m.id,
    };
    SyncMutationResult? heldAccepted;
    var sequence = cursor;
    var left = 0;
    for (final batch in split.batches) {
      final sendable = <MutationRecord>[];
      for (final m in batch) {
        if (blocked.contains(m.dependsOnMutationId)) {
          blocked.add(m.id);
          left++;
        } else {
          sendable.add(m);
        }
      }
      if (sendable.isEmpty) continue;
      final response = await _exchange(
        scope,
        sequence,
        sendable.map(mutationToDto).toList(),
        firstUpload: openFlag,
      );
      final accepted = <String>{
        for (final r in response.results)
          if (r.outcome == MutationOutcome.accepted) r.clientMutationId,
      };
      final refused = <String>{
        for (final r in response.results)
          if (r.outcome == MutationOutcome.rejected ||
              r.outcome == MutationOutcome.conflict)
            r.clientMutationId,
      };
      for (final m in sendable) {
        if (accepted.contains(m.clientMutationId)) continue;
        blocked.add(m.id);
        // Still pending afterwards: skipped or not answered.
        if (!refused.contains(m.clientMutationId)) left++;
      }
      final held = heldCreation != null && sendable.contains(heldCreation);
      if (held) {
        for (final r in response.results) {
          if (r.clientMutationId == heldCreation.clientMutationId &&
              r.outcome == MutationOutcome.accepted) {
            heldAccepted = r;
          }
        }
      }
      // Only an accepted creation is held back; a refusal is recorded now.
      final keep = held && heldAccepted != null;
      await _recordResults(
        keep
            ? [
                for (final m in sendable)
                  if (m != heldCreation) m,
              ]
            : sendable,
        response.results,
      );
      // The service now holds what was accepted, which screens that read
      // it (invitations, the publication) need to read again.
      if (accepted.isNotEmpty) _bumpRevision(scope);
      sequence = (await _pull(scope, response, from: sequence)).cursor;
    }
    if (heldCreation != null &&
        heldAccepted != null &&
        left == 0 &&
        blocked.isEmpty) {
      // Everything of the upload is accepted: tell the service, which then
      // ends the contest's exemption from the lock rules, and only then
      // let go of the creation. While any change is refused (or too large)
      // the upload stays open, so the history can still be completed.
      final done = await _exchange(
        scope,
        sequence,
        const [],
        firstUpload: _finishUpload,
      );
      await _pull(scope, done, from: sequence);
      await _store.recordOutcome(
        mutationId: heldCreation.id,
        outcome: MutationOutcome.accepted,
        sequence: heldAccepted.sequence,
        serverAcceptanceTime: _config.now(),
      );
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
    String? firstUpload,
  }) => _gateway.exchange(
    _request(
      scope,
      cursor,
      mutations,
      pageToken: pageToken,
      firstUpload: firstUpload,
    ),
  );

  SyncExchangeRequest _request(
    SyncScopeKey scope,
    int cursor,
    List<SyncMutationDto> mutations, {
    String? pageToken,
    String? firstUpload,
  }) => SyncExchangeRequest(
    protocolVersion: _config.protocolVersion,
    schemaVersion: _config.schemaVersion,
    installationId: _config.installationId,
    scope: scopeToDto(scope),
    lastAcknowledgedSequence: cursor,
    pageToken: pageToken,
    mutations: mutations,
    firstUpload: firstUpload,
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
    // Whatever was written before a failure is already in the store. A change
    // the store already held (a replay after a failed page) writes nothing.
    var changed = false;
    try {
      await _applyOrdered(scope, ordered, () => changed = true);
    } finally {
      if (changed) _bumpRevision(scope);
    }
    final highest = ordered.last.sequence;
    if (highest <= cursor) return cursor;
    await _store.writeCursor(scope, highest, syncedAt: _config.now());
    return highest;
  }

  void _bumpRevision(SyncScopeKey scope) =>
      _dataRevision[scope] = (_dataRevision[scope] ?? 0) + 1;

  Future<void> _applyOrdered(
    SyncScopeKey scope,
    List<SyncChangeDto> ordered,
    void Function() onChanged,
  ) async {
    for (final change in ordered) {
      try {
        if (await _applier.apply(changeFromDto(scope, change))) onChanged();
      } on UnsupportedEntityTypeError {
        // The applier refuses an entity type it has no store for, or one that
        // is derived. Stop here without moving the cursor past it: nothing is
        // dropped, and the scope reports why it cannot go on.
        throw _UnsupportedChange(change.sequence, change.entityType);
      }
    }
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
      rejectedMutations: status.rejectedMutations,
      lastSyncedAt: status.lastSyncedAt,
      remoteSequence: _remoteSequence[scope],
      dataRevision: _dataRevision[scope] ?? 0,
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
