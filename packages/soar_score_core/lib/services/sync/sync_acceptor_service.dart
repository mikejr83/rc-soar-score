import 'dart:convert';

import '../../enums/conflict_resolution_choice.dart';
import '../../enums/mutation_outcome.dart';
import '../../errors/forbidden_error.dart';
import '../../errors/sync_refusal.dart';
import '../../models/id.dart';
import '../../models/sync/installation.dart';
import '../../models/sync/mutation_record.dart';
import '../../models/sync/sync_cursor.dart';
import '../../models/sync/system_seed.dart';
import '../../repositories/repository.dart';
import '../../repositories/sync_acceptor_store.dart';
import '../../repositories/sync_scope_key.dart';
import '../../sync/sync_protocol.dart';
import 'accepted_change.dart';
import 'conflict_resolver.dart';
import 'exchange_context.dart';
import 'keyed_lock.dart';
import 'mutation_payloads.dart';
import 'mutation_processor.dart';
import '../recalculation/recalculation_service.dart';
import 'mutation_result.dart';
import 'sync_entity_catalog.dart';
import 'sync_exchange.dart';
import 'sync_scope_ids.dart';
import 'sync_versions.dart';

/// The server side of the sync protocol: takes an installation's unsent
/// mutations, decides each, and answers with what changed since its cursor.
///
/// Specified in `plan/architecture-requirements/sync-protocol.md`. The
/// service is domain logic; the routes only translate to and from the wire.
class SyncAcceptorService {
  SyncAcceptorService(
    this._repository, {
    required this.versions,
    DateTime Function()? clock,
    Id Function()? newId,
    this.pageSize = SyncProtocol.defaultPageSize,
    this.recalculation,
  }) : _clock = clock ?? (() => DateTime.now().toUtc()),
       _newId = newId ?? Id.create;

  /// The protocol and schema ranges accepted.
  final SyncVersions versions;

  /// The most changes one response carries; a longer pull is paged.
  final int pageSize;

  /// Rebuilds a contest's results after an exchange accepted changes to it.
  /// Results are derived data that never sync, so without this the service
  /// holds a synced contest's scores and no standings, and publishing refuses
  /// it as stale. Null (the default) recalculates nothing.
  final RecalculationService? recalculation;

  final Repository _repository;
  final DateTime Function() _clock;
  final Id Function() _newId;

  // Built on first use, so building the service does not touch the store.
  late final SyncAcceptorStore _store = _repository.syncAcceptorStore;
  late final MutationProcessor _processor = MutationProcessor(_store);
  late final ConflictResolver _resolver = ConflictResolver(
    _store,
    _clock,
    _newId,
  );
  final KeyedLock _locks = KeyedLock();

  /// The service's clock, for `GET /sync/info`.
  DateTime get serverTime => _clock();

  /// The highest sequence of [scope]'s log, for a client that only wants to
  /// know whether anything changed (`GET /sync/revision`). Reads nothing else.
  ///
  /// Throws a [ForbiddenError] for a scope the account does not own.
  Future<int> revision({required Id accountId, required SyncScopeKey scope}) {
    if (scope is SystemScopeKey) {
      throw ArgumentError.value(
        'system',
        'scope',
        'system data has its own stream',
      );
    }
    return _store.transaction((tx) async {
      await _requireScopeAccess(tx, scope, accountId);
      return tx.highestSequence(scope);
    });
  }

  /// Handles one `POST /sync/exchange`.
  ///
  /// Version negotiation comes first and refuses a client outside the range
  /// before any mutation is looked at. The mutations are then decided one by
  /// one, each in its own transaction, and the changes after the cursor are
  /// read last, so the response includes what the request just accepted.
  ///
  /// Throws a [SyncRefusal] for a version outside the range, a revoked
  /// installation or an expired page token, and a [ForbiddenError] for an
  /// installation or scope the account does not own.
  Future<SyncExchangeOutput> exchange({
    required Id accountId,
    required SyncExchangeInput input,
  }) async {
    versions.require(
      protocolVersion: input.protocolVersion,
      schemaVersion: input.schemaVersion,
    );
    final scope = input.scope;
    if (scope is SystemScopeKey) {
      throw ArgumentError.value(
        'system',
        'scope',
        'system data has its own stream, not an exchange',
      );
    }
    final position = input.pageToken == null
        ? null
        : _readToken(input.pageToken!, input);
    if (position != null && input.mutations.isNotEmpty) {
      throw ArgumentError.value(
        input.mutations.length,
        'mutations',
        'a continuation request carries none',
      );
    }

    await _store.transaction((tx) async {
      await _requireInstallation(tx, accountId, input.installationId);
      await _requireScopeAccess(tx, scope, accountId);
    });

    return _locks.run(scope, () async {
      final ctx = ExchangeContext(
        scope: scope,
        accountId: accountId,
        installationId: input.installationId,
        clock: _clock,
        newId: _newId,
      );
      final results = <MutationResult>[];
      if (position == null) {
        results.addAll(await _decideAll(ctx, input));
        await _recalculateAfter(scope, results);
      }
      final after = position ?? input.lastAcknowledgedSequence;
      return _store.transaction((tx) => _pull(tx, ctx, input, results, after));
    });
  }

  /// Handles `POST /sync/conflicts/{id}/resolve`.
  Future<MutationResult> resolveConflict({
    required Id accountId,
    required Id conflictId,
    required String clientMutationId,
    required ConflictResolutionChoice choice,
    Map<String, Object?>? payload,
  }) async {
    final conflict = await _resolver.find(conflictId, accountId: accountId);
    final scope = conflict.contestId != null
        ? ContestScopeKey(conflict.contestId!) as SyncScopeKey
        : DirectorScopeKey(conflict.ownerAccountId!);
    return _locks.run(
      scope,
      () => _resolver.resolve(
        accountId: accountId,
        conflictId: conflictId,
        clientMutationId: clientMutationId,
        choice: choice,
        payload: payload,
      ),
    );
  }

  /// Handles `GET /sync/system-data`.
  ///
  /// The app ships the system data it needs (`SystemSeed.sequence` is the
  /// version of that set), so the stream holds nothing above an
  /// installation's own seed yet: it answers an empty page at the later of
  /// [afterSequence] and the seed's sequence. A release that changes a
  /// shipped profile raises the seed's sequence and adds the changes here
  /// without a protocol change.
  ({List<AcceptedChange> changes, int systemDataSeq}) systemData({
    required int afterSequence,
  }) => (
    changes: const <AcceptedChange>[],
    systemDataSeq: afterSequence > SystemSeed.sequence
        ? afterSequence
        : SystemSeed.sequence,
  );

  /// Decides the mutations and returns the results in request order.
  ///
  /// The mutation that creates the contest is decided first wherever it sits
  /// in the batch, because the first upload of a contest becomes the
  /// installation's activation and everything else in the batch needs it.
  Future<List<MutationResult>> _decideAll(
    ExchangeContext ctx,
    SyncExchangeInput input,
  ) async {
    final scope = ctx.scope;
    final order = [for (var i = 0; i < input.mutations.length; i++) i];
    if (scope is ContestScopeKey) {
      final creation = order.indexWhere(
        (i) =>
            input.mutations[i].entityType == 'Contest' &&
            input.mutations[i].entityId == scope.contestId,
      );
      if (creation > 0) order.insert(0, order.removeAt(creation));
    }
    final decided = <int, MutationResult>{};
    for (final i in order) {
      decided[i] = await _processor.process(ctx, input.mutations[i]);
    }
    return [for (var i = 0; i < input.mutations.length; i++) decided[i]!];
  }

  /// Recalculates the results of the contest in [scope] when [results]
  /// accepted a change to it. The changes are already committed, so a failure
  /// is reported by [RecalculationService] in the log and leaves the results
  /// stale; it never fails the exchange.
  Future<void> _recalculateAfter(
    SyncScopeKey scope,
    List<MutationResult> results,
  ) async {
    final recalculation = this.recalculation;
    if (recalculation == null || scope is! ContestScopeKey) return;
    if (!results.any((r) => r.outcome == MutationOutcome.accepted)) return;
    await recalculation.recalculateAfterEntry(scope.contestId, cause: 'a sync');
  }

  Future<SyncExchangeOutput> _pull(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncExchangeInput input,
    List<MutationResult> results,
    int after,
  ) async {
    final records = await tx.acceptedAfter(
      ctx.scope,
      after,
      limit: pageSize + 1,
    );
    final more = records.length > pageSize;
    final page = more ? records.sublist(0, pageSize) : records;
    final changes = [for (final record in page) _change(record)];

    final conflicts = [...ctx.conflicts];
    for (final record in page) {
      if (record.entityType != SyncEntityCatalog.conflictRecordType) continue;
      final entity = MutationPayload.parse(record.payload).entity;
      final pointer = SyncConflictPointer(
        id: record.entityId,
        requiresAction:
            entity['requires_action'] == true &&
            entity['resolution'] == 'Pending',
      );
      // A conflict can change more than once in a page (a review replaced by
      // a later edit, then closed): the last record is the one that counts.
      final known = conflicts.indexWhere((c) => c.id == record.entityId);
      if (known >= 0) {
        conflicts[known] = pointer;
      } else {
        conflicts.add(pointer);
      }
    }

    await _noteProgress(tx, ctx, input, finished: !more);
    return SyncExchangeOutput(
      results: results,
      changes: changes,
      conflicts: conflicts,
      nextPageToken: more ? _token(ctx, input, page.last.sequence!) : null,
      serverSequence: await tx.highestSequence(ctx.scope),
    );
  }

  /// Records how far the installation says it has synchronized.
  Future<void> _noteProgress(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncExchangeInput input, {
    required bool finished,
  }) async {
    final now = _clock();
    final installation = await tx.findInstallation(input.installationId);
    if (installation != null) {
      await tx.saveInstallation(
        _copy(installation, seen: now, synced: finished ? now : null),
      );
    }
    final cursor = await tx.findCursor(input.installationId, ctx.scope);
    final held = cursor?.lastSyncedSequence ?? 0;
    if (cursor == null || input.lastAcknowledgedSequence > held) {
      await tx.saveCursor(
        SyncCursor(
          id: cursor?.id ?? _newId(),
          installationId: input.installationId,
          contestId: ctx.scope.contestIdOrNull,
          ownerAccountId: ctx.scope.ownerAccountIdOrNull,
          lastSyncedSequence: input.lastAcknowledgedSequence > held
              ? input.lastAcknowledgedSequence
              : held,
          lastSyncedAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  AcceptedChange _change(MutationRecord record) {
    final payload = MutationPayload.parse(record.payload);
    return AcceptedChange(
      sequence: record.sequence!,
      entityType: record.entityType,
      entityId: record.entityId,
      revision: payload.isDelete ? 0 : payload.entity['revision'] as int? ?? 0,
      payload: payload.isDelete
          ? const {'deleted': true}
          : {...payload.entity, 'supersedes': ?payload.supersedes},
    );
  }

  Future<Installation> _requireInstallation(
    SyncAcceptorTransaction tx,
    Id accountId,
    Id installationId,
  ) async {
    final installation = await tx.findInstallation(installationId);
    if (installation == null || installation.ownerAccountId != accountId) {
      throw ForbiddenError(
        'unknown_installation',
        'Register this installation before it synchronizes.',
      );
    }
    if (installation.revokedAt != null) {
      throw SyncRefusal(
        'inactive_installation',
        403,
        'This installation was revoked and cannot synchronize.',
      );
    }
    return installation;
  }

  Future<void> _requireScopeAccess(
    SyncAcceptorTransaction tx,
    SyncScopeKey scope,
    Id accountId,
  ) async {
    switch (scope) {
      case ContestScopeKey(:final contestId):
        final contest = await tx.findEntity('Contest', contestId);
        if (contest != null && contest['owner_account_id'] != accountId.value) {
          throw ForbiddenError(
            'not_director',
            'only the contest director synchronizes the contest',
          );
        }
      case DirectorScopeKey(:final ownerAccountId):
        if (ownerAccountId != accountId) {
          throw ForbiddenError(
            'not_owner',
            'a director synchronizes only their own data',
          );
        }
      case SystemScopeKey():
        break;
    }
  }

  Installation _copy(
    Installation i, {
    int? systemDataSeq,
    DateTime? seen,
    DateTime? synced,
  }) => Installation(
    id: i.id,
    ownerAccountId: i.ownerAccountId,
    label: i.label,
    platform: i.platform,
    createdAt: i.createdAt,
    lastSeenAt: seen ?? i.lastSeenAt,
    lastSyncAt: synced ?? i.lastSyncAt,
    systemDataSeq: systemDataSeq ?? i.systemDataSeq,
    revokedAt: i.revokedAt,
  );

  /// An opaque token for the next page: the scope, the installation and where
  /// to continue.
  String _token(ExchangeContext ctx, SyncExchangeInput input, int after) =>
      base64Url.encode(
        utf8.encode(
          jsonEncode({
            'scope': _scopeName(ctx.scope),
            'installation': input.installationId.value,
            'after': after,
          }),
        ),
      );

  int _readToken(String token, SyncExchangeInput input) {
    try {
      final data = jsonDecode(
        utf8.decode(base64Url.decode(token)),
      ) as Map<String, Object?>;
      if (data['scope'] == _scopeName(input.scope) &&
          data['installation'] == input.installationId.value &&
          data['after'] is int) {
        return data['after']! as int;
      }
    } on Object {
      // Falls through to the refusal below.
    }
    throw SyncRefusal(
      'page_token_expired',
      410,
      'The page token is no longer valid. Restart the pull from the stored '
          'cursor.',
    );
  }

  String _scopeName(SyncScopeKey scope) => switch (scope) {
    ContestScopeKey(:final contestId) => 'contest:${contestId.value}',
    DirectorScopeKey(:final ownerAccountId) => 'owner:${ownerAccountId.value}',
    SystemScopeKey() => 'system',
  };
}
