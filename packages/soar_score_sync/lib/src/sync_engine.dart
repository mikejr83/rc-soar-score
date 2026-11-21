import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'outbox_batches.dart';
import 'outbox_order.dart';
import 'resolve_conflict_outcome.dart';
import 'sync_engine_config.dart';
import 'sync_failure_kind.dart';
import 'sync_gateway.dart';
import 'sync_mappers.dart';
import 'sync_scope_label.dart';
import 'sync_scope_state.dart';
import 'sync_skip_reason.dart';
import 'sync_state.dart';

final _logger = Logger('SyncEngine');

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

  // Whether the service lists `promote_score`. Read with the versions, and
  // read again when the service refuses the operation as unknown.
  bool _promoteScore = false;
  DateTime? _capabilitiesReadAt;

  // Per scope, the `promote_score` intents held back because the service does
  // not list the capability. They stay pending and nothing is sent for them.
  final _waitingForPeer = <SyncScopeKey, int>{};
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
      _logger.info(
        'Sync skipped: scope=${syncScopeLabel(scope)} reason=accountless',
      );
      await _refresh(scope, skip: SyncSkipReason.accountless);
      return null;
    }
    final watch = Stopwatch()..start();
    // Before the service is prepared, so a failed version check or
    // registration still follows a start line. The cursor is on the pull's
    // exchange line, and the pending count on the push plan.
    _logger.info('Sync started: scope=${syncScopeLabel(scope)}');
    _emit(_state.copyWith(syncing: true));
    try {
      final SyncFailureKind? failure;
      try {
        failure = await _runScope(scope);
        await _refresh(scope, failure: failure);
      } on Object catch (error) {
        // Local finalization can throw too (for example a store that rejects
        // the cursor write after a sign-out). The caller still gets the
        // error; the trace gets its end.
        _logThrown(scope, error, watch);
        rethrow;
      }
      _logEnd(scope, failure, watch);
      if (!_outcomes.isClosed) _outcomes.add(failure);
      return failure;
    } finally {
      _emit(_state.copyWith(syncing: false));
    }
  }

  /// The exchanges of one sync and the recording of its time. Returns why it
  /// failed, or null.
  Future<SyncFailureKind?> _runScope(SyncScopeKey scope) async {
    final failure = await _guard(() async {
      await _prepare();
      final cursor = await _store.readCursor(scope);
      // Pull first, so the push is based on what the service already has.
      final pulled = await _pull(
        scope,
        await _exchange(scope, cursor, [], purpose: 'pull'),
      );
      final pending = inDependencyOrder(await _store.pendingMutations(scope));
      await _recheckPromotionSupport(pending);
      final sendable = _withoutHeldBack(scope, pending);
      if (sendable.isNotEmpty) {
        await _push(scope, sendable, pulled.cursor);
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
    return failure;
  }

  /// [pending] without the `promote_score` intents the service cannot take.
  ///
  /// An intent is never sent to a service that does not list the capability:
  /// it stays pending, nothing is written, and the scope reports how many wait
  /// for a newer service.
  List<MutationRecord> _withoutHeldBack(
    SyncScopeKey scope,
    List<MutationRecord> pending,
  ) {
    if (_promoteScore) {
      _waitingForPeer.remove(scope);
      return pending;
    }
    final held = pending.where(_isPromotion).length;
    if (held == 0) {
      _waitingForPeer.remove(scope);
    } else {
      _waitingForPeer[scope] = held;
    }
    return [
      for (final m in pending)
        if (!_isPromotion(m)) m,
    ];
  }

  /// Reads the capability list again when intents are held back for want of
  /// `promote_score` and the last read is older than the recheck interval, so
  /// a service that was updated while this engine ran gets them without a
  /// restart. Only scopes with held intents ask, and a failed read keeps the
  /// intents queued (the sync goes on without them).
  Future<void> _recheckPromotionSupport(List<MutationRecord> pending) async {
    if (_promoteScore || !pending.any(_isPromotion)) return;
    final readAt = _capabilitiesReadAt;
    final now = _config.now();
    if (readAt != null &&
        now.difference(readAt) < _config.capabilityRecheckInterval) {
      return;
    }
    try {
      final info = await _gateway.syncInfo();
      _capabilitiesReadAt = now;
      _promoteScore = info.supports(SyncCapabilities.promoteScore);
    } on ApiException {
      // Unreachable or refused: the intents stay queued, and the exchange
      // that follows reports the failure.
    }
  }

  static bool _isPromotion(MutationRecord m) =>
      m.entityType == promotionReceiptEntityType;

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
    _logger.info(
      'Push plan: scope=${syncScopeLabel(scope)} pending=${pending.length} '
      'batches=${split.batches.length} oversized=${split.oversized.length} '
      'firstUpload=$firstUpload',
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
    var batchNumber = 0;
    for (final batch in split.batches) {
      batchNumber++;
      final sendable = <MutationRecord>[];
      for (final m in batch) {
        if (blocked.contains(m.dependsOnMutationId)) {
          blocked.add(m.id);
          left++;
        } else {
          sendable.add(m);
        }
      }
      if (sendable.isEmpty) {
        _logger.info(
          'Push batch $batchNumber of ${split.batches.length} not sent: '
          'every mutation depends on a refused one',
        );
        continue;
      }
      final response = await _exchange(
        scope,
        sequence,
        sendable.map(mutationToDto).toList(),
        firstUpload: openFlag,
        purpose: 'push $batchNumber/${split.batches.length}',
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
      await _settlePromotions(scope, sendable, response.results, sequence);
    }
    if (heldCreation != null && heldAccepted != null && left == 0) {
      // Everything of the upload is decided: tell the service, which then
      // ends the contest's exemption from the lock rules, and only then
      // let go of the creation.
      final done = await _exchange(
        scope,
        sequence,
        const [],
        firstUpload: _finishUpload,
        purpose: 'finish first upload',
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
    final watch = Stopwatch()..start();
    _logger.info('Sync started: scope=system');
    final failure = await _guard(() async {
      await _prepare();
      var cursor = await _store.readCursor(scope);
      String? token;
      var page = 0;
      do {
        page++;
        final requestWatch = Stopwatch()..start();
        final response = await _gateway.systemData(
          afterSequence: cursor,
          pageToken: token,
        );
        _logger.info(
          'System data page $page: changes=${response.changes.length} '
          'more=${response.nextPageToken != null} '
          'duration=${requestWatch.elapsedMilliseconds} ms',
        );
        cursor = await _storeChanges(scope, response.changes, cursor);
        token = response.nextPageToken;
      } while (token != null);
    });
    _logEnd(scope, failure, watch);
    return failure;
  }

  /// Checks the versions and registers the installation, once each.
  Future<void> _prepare() async {
    if (!_versionsChecked) {
      final watch = Stopwatch()..start();
      final info = await _gateway.syncInfo();
      _logger.info(
        'Checked service versions: protocol=${info.protocolVersion} '
        'duration=${watch.elapsedMilliseconds} ms',
      );
      if (!info.accepts(
        protocol: _config.protocolVersion,
        schema: _config.schemaVersion,
      )) {
        throw const _UpdateRequired();
      }
      _promoteScore = info.supports(SyncCapabilities.promoteScore);
      _capabilitiesReadAt = _config.now();
      _versionsChecked = true;
    }
    if (!_registered) {
      final watch = Stopwatch()..start();
      await _gateway.registerInstallation(
        RegisterInstallationRequest(
          id: _config.installationId,
          label: _config.label,
          platform: _config.platform,
        ),
      );
      _registered = true;
      _logger.info(
        'Registered installation: duration=${watch.elapsedMilliseconds} ms',
      );
    }
  }

  Future<SyncExchangeResponse> _exchange(
    SyncScopeKey scope,
    int cursor,
    List<SyncMutationDto> mutations, {
    String? pageToken,
    String? firstUpload,
    required String purpose,
  }) async {
    final watch = Stopwatch()..start();
    try {
      final response = await _gateway.exchange(
        _request(
          scope,
          cursor,
          mutations,
          pageToken: pageToken,
          firstUpload: firstUpload,
        ),
      );
      final results = <MutationOutcome, int>{};
      for (final r in response.results) {
        results[r.outcome] = (results[r.outcome] ?? 0) + 1;
      }
      final elapsed = watch.elapsedMilliseconds;
      _logger.log(
        elapsed >= _config.slowExchange.inMilliseconds
            ? Level.WARNING
            : Level.INFO,
        'Exchange ($purpose): scope=${syncScopeLabel(scope)} cursor=$cursor '
        'sent=${mutations.length} '
        'results=${_formatCounts(results)} '
        'changes=${response.changes.length} '
        'more=${response.nextPageToken != null} '
        'serverSequence=${response.serverSequence} '
        'duration=$elapsed ms'
        '${elapsed >= _config.slowExchange.inMilliseconds ? ' (slow)' : ''}',
      );
      return response;
    } on Object catch (error) {
      _logger.warning(
        'Exchange ($purpose) failed: scope=${syncScopeLabel(scope)} '
        'sent=${mutations.length} error=${_describeError(error)} '
        'duration=${watch.elapsedMilliseconds} ms',
      );
      rethrow;
    }
  }

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
      page = await _exchange(
        scope,
        requestedFrom,
        [],
        pageToken: token,
        purpose: 'pull page',
      );
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
    final watch = Stopwatch()..start();
    try {
      await _applyOrdered(scope, ordered, () => changed = true);
    } finally {
      if (changed) _bumpRevision(scope);
    }
    final highest = ordered.last.sequence;
    final moved = highest > cursor;
    if (moved) {
      await _store.writeCursor(scope, highest, syncedAt: _config.now());
    }
    // After the write, so the cursor reported is the one saved.
    _logger.info(
      'Stored changes: scope=${syncScopeLabel(scope)} count=${ordered.length} '
      'changedLocalData=$changed cursor=$cursor->${moved ? highest : cursor} '
      'duration=${watch.elapsedMilliseconds} ms',
    );
    return moved ? highest : cursor;
  }

  void _bumpRevision(SyncScopeKey scope) =>
      _dataRevision[scope] = (_dataRevision[scope] ?? 0) + 1;

  Future<void> _applyOrdered(
    SyncScopeKey scope,
    List<SyncChangeDto> ordered,
    void Function() onChanged,
  ) async {
    var i = 0;
    while (i < ordered.length) {
      // The changes of one aggregate are applied together, in one local
      // transaction with the settling of the intent they answer.
      final aggregateId = ordered[i].aggregateId;
      var end = i + 1;
      if (aggregateId != null) {
        while (end < ordered.length &&
            ordered[end].aggregateId == aggregateId) {
          end++;
        }
      }
      final run = ordered.sublist(i, end);
      try {
        final changed = aggregateId == null
            ? await _applier.apply(changeFromDto(scope, run.single))
            : await _applier.applyAggregate([
                for (final change in run) changeFromDto(scope, change),
              ]);
        if (changed) onChanged();
      } on UnsupportedEntityTypeError {
        // The applier refuses an entity type it has no store for, or one that
        // is derived. Stop here without moving the cursor past it: nothing is
        // dropped, and the scope reports why it cannot go on.
        final first = run.first;
        throw _UnsupportedChange(first.sequence, first.entityType);
      }
      i = end;
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
      if (_isPromotion(mutation)) {
        // An accepted intent is settled by the receipt that comes back in the
        // pulled aggregate, in the same transaction as its adoption (see
        // _settlePromotions); a refusal is final, unless the service turns
        // out not to know the operation.
        if (result.outcome == MutationOutcome.accepted) continue;
        if (await _promotionUnknownToService(result)) {
          // The older service recorded its refusal under these ids. It was a
          // decision about an entity type it did not know, never about the
          // slot, so a service that learns the operation later must not
          // replay it as final: the intent is asked again under new ids.
          await _store.reissueIntent(
            mutation.id,
            clientMutationId: Id.create().value,
            operationId: Id.create(),
          );
          continue;
        }
      }
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
          _logger.warning(
            'Change not accepted: outcome=${result.outcome.name} '
            'reason=${result.reasonCode} entityType=${mutation.entityType}',
          );
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

  /// Whether a refusal of a `promote_score` intent comes from a service that
  /// does not know the operation. An older service answers `invalid_payload`
  /// because it knows no such entity type; a current one gives the same code
  /// for a slot it does not hold, which is final. The capability list tells
  /// them apart, so it is read again. A service that no longer lists it holds
  /// the intent back; the refusal is not recorded.
  Future<bool> _promotionUnknownToService(SyncMutationResult result) async {
    if (result.reasonCode != SyncReasonCode.invalidPayload.code) return false;
    final info = await _gateway.syncInfo();
    _capabilitiesReadAt = _config.now();
    _promoteScore = info.supports(SyncCapabilities.promoteScore);
    return !_promoteScore;
  }

  /// Settles accepted `promote_score` intents whose receipt did not arrive in
  /// the pulled aggregate although the pull has passed its sequence. The
  /// receipt normally does the settling, together with the adoption.
  Future<void> _settlePromotions(
    SyncScopeKey scope,
    List<MutationRecord> sent,
    List<SyncMutationResult> results,
    int cursor,
  ) async {
    final accepted = {
      for (final r in results)
        if (r.outcome == MutationOutcome.accepted && r.sequence != null)
          r.clientMutationId: r.sequence!,
    };
    final candidates = [
      for (final m in sent)
        if (_isPromotion(m) &&
            (accepted[m.clientMutationId] ?? cursor + 1) <= cursor)
          m,
    ];
    if (candidates.isEmpty) return;
    final stillPending = {
      for (final m in await _store.pendingMutations(scope)) m.id,
    };
    for (final m in candidates) {
      if (!stillPending.contains(m.id)) continue;
      await _store.recordOutcome(
        mutationId: m.id,
        outcome: MutationOutcome.accepted,
        sequence: accepted[m.clientMutationId],
        serverAcceptanceTime: _config.now(),
      );
    }
  }

  /// Runs [body] and turns what it throws into a [SyncFailureKind].
  Future<SyncFailureKind?> _guard(Future<void> Function() body) async {
    try {
      await body();
      return null;
    } on _UpdateRequired {
      return SyncFailureKind.updateRequired;
    } on _UnsupportedChange catch (error) {
      _logger.warning(
        'Unsupported change from the service: sequence=${error.sequence} '
        'entityType=${error.entityType}',
      );
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

  /// Logs the end of a sync that threw: the scope, the time and the error's
  /// type, never its message.
  void _logThrown(SyncScopeKey scope, Object error, Stopwatch watch) {
    _logger.warning(
      'Sync failed: scope=${syncScopeLabel(scope)} '
      'error=${_describeError(error)} '
      'duration=${watch.elapsedMilliseconds} ms',
    );
  }

  void _logEnd(SyncScopeKey scope, SyncFailureKind? failure, Stopwatch watch) {
    _logger.log(
      failure == null ? Level.INFO : Level.WARNING,
      failure == null
          ? 'Sync finished: scope=${syncScopeLabel(scope)} '
                'duration=${watch.elapsedMilliseconds} ms'
          : 'Sync failed: scope=${syncScopeLabel(scope)} failure=${failure.name} '
                'duration=${watch.elapsedMilliseconds} ms',
    );
  }

  static String _formatCounts(Map<MutationOutcome, int> counts) =>
      counts.isEmpty
      ? 'none'
      : counts.entries.map((e) => '${e.key.name}:${e.value}').join(',');

  /// What a failure is, without its message (which may carry request data).
  static String _describeError(Object error) => error is ApiHttpError
      ? '${error.runtimeType} status=${error.statusCode}'
      : '${error.runtimeType}';

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
      waitingForNewerService: _waitingForPeer[scope] ?? 0,
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
