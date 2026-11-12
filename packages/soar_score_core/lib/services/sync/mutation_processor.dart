import '../../enums/activation_kind.dart';
import '../../enums/audit_action.dart';
import '../../enums/authority.dart';
import '../../enums/tombstone_status.dart';
import '../../enums/mutation_outcome.dart';
import '../../errors/sync_constraint_error.dart';
import '../../errors/sync_payload_error.dart';
import '../../models/id.dart';
import '../../models/shared/sync_scope.dart';
import '../../models/sync/installation_activation.dart';
import '../../models/sync/mutation_record.dart';
import '../../models/sync/tombstone.dart';
import '../../enums/sync_reason_code.dart';
import '../../repositories/sync_acceptor_store.dart';
import '../../repositories/sync_scope_key.dart';
import 'exchange_context.dart';
import 'field_merge.dart';
import 'json_equality.dart';
import 'mutation_payloads.dart';
import 'mutation_replay.dart';
import 'mutation_result.dart';
import 'pilot_link_collisions.dart';
import 'sync_entity_catalog.dart';
import 'sync_log.dart';
import 'sync_mutation.dart';
import 'sync_scope_guard.dart';
import 'sync_scope_ids.dart';

/// Decides one mutation: applies it, rejects it, or turns it into a conflict.
///
/// Each mutation commits or fails alone, so a rejection never rolls back its
/// valid siblings. The decision is recorded, so a retry of the same
/// `client_mutation_id` returns it unchanged and applies nothing twice.
class MutationProcessor {
  MutationProcessor(this._store, {SyncLog? log})
    : _log = log ?? SyncLog(),
      _links = PilotLinkCollisions(log ?? SyncLog());

  final SyncAcceptorStore _store;
  final SyncLog _log;
  final PilotLinkCollisions _links;

  /// Authorities a director's installation may send. A participant's
  /// submissions and the service's own changes never arrive in an exchange.
  static const _senders = {Authority.director, Authority.helper};

  /// Entity types where the director's decision beats a participant's change
  /// made after the director's base revision.
  static const _directorPrecedence = {'ScorePlaceholder', 'OfficialScore'};

  static final _contestStatesOpenToMerge = {'Created', 'Configuring'};

  Future<MutationResult> process(ExchangeContext ctx, SyncMutation m) async {
    final dependency = ctx.decided[m.dependsOnMutationId];
    if (dependency != null && dependency.failed) {
      final result = MutationResult(
        clientMutationId: m.clientMutationId,
        outcome: MutationOutcome.skipped,
        reasonCode: SyncReasonCode.dependencyFailed.code,
        dependsOn: dependency.clientMutationId,
      );
      ctx.decided[m.id] = result;
      return result;
    }

    final pointers = ctx.conflicts.length;
    MutationResult result;
    try {
      result = await _store.transaction((tx) => _decide(tx, ctx, m));
    } on SyncPayloadError catch (e) {
      ctx.conflicts.length = pointers;
      result = await _store.transaction(
        (tx) => _log.reject(
          tx,
          ctx,
          m,
          SyncReasonCode.invalidPayload.code,
          e.message,
        ),
      );
    } on SyncConstraintError catch (e) {
      ctx.conflicts.length = pointers;
      result = await _store.transaction((tx) => _constraint(tx, ctx, m, e));
    }
    ctx.decided[m.id] = result;
    return result;
  }

  Future<MutationResult> _decide(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation m,
  ) async {
    final prior = await tx.findMutation(ctx.scope, m.clientMutationId);
    if (prior != null && prior.outcome != MutationOutcome.pending) {
      return replayDecision(tx, prior);
    }

    Future<MutationResult> reject(SyncReasonCode reason, String message) =>
        _log.reject(tx, ctx, m, reason.code, message);

    final kind = SyncEntityCatalog.of(m.entityType);
    if (kind == null) {
      return reject(
        SyncReasonCode.invalidPayload,
        '${m.entityType} is not accepted as a mutation: derived values are '
        'recomputed and system data only comes down.',
      );
    }
    if (kind.scope != _scopeKind(ctx.scope)) {
      return reject(
        SyncReasonCode.invalidPayload,
        '${m.entityType} does not belong to this scope.',
      );
    }
    if (!_senders.contains(m.authority)) {
      return reject(
        SyncReasonCode.unauthorized,
        'Mutations of authority ${m.authority.name} cannot be accepted here '
        '(accepted: ${_senders.map((a) => a.name).join(', ')}).',
      );
    }
    final MutationPayload payload;
    try {
      payload = MutationPayload.parse(m.payload);
    } on FormatException catch (e) {
      return reject(SyncReasonCode.invalidPayload, e.message);
    }
    final stored = await tx.findEntity(m.entityType, m.entityId);

    final problem = await SyncScopeGuard.writeProblem(
      tx,
      ctx,
      kind,
      m.entityId,
      payload,
      stored,
    );
    if (problem != null) return reject(problem.$1, problem.$2);

    var bootstrap = false;
    final scope = ctx.scope;
    if (scope is ContestScopeKey) {
      final activations = await tx.listActivations(scope.contestId);
      final holds = activations.any(
        (a) => a.isOpen && a.installationId == ctx.installationId,
      );
      if (!holds) {
        final firstUpload =
            activations.isEmpty &&
            m.entityType == 'Contest' &&
            !payload.isDelete &&
            stored == null;
        if (!firstUpload) {
          return reject(
            SyncReasonCode.inactiveInstallation,
            'This installation does not administer the contest. Reactivate '
            'it as the primary installation first.',
          );
        }
        bootstrap = true;
        ctx.createdContestId = scope.contestId;
      }
    }

    if (await tx.findTombstone(m.entityType, m.entityId) != null) {
      if (payload.isDelete && PilotLinkCollisions.handles(ctx, m.entityType)) {
        // The link already went with its participant: the same wish twice.
        return _log.accept(tx, ctx, m, MutationPayload.delete);
      }
      return reject(
        SyncReasonCode.entityDeleted,
        'The ${m.entityType} was deleted.',
      );
    }

    Map<String, Object?>? contest;
    if (scope is ContestScopeKey) {
      contest = m.entityType == 'Contest'
          ? stored
          : await tx.findEntity('Contest', scope.contestId);
      if (m.entityType != 'Contest' &&
          contest != null &&
          ctx.createdContestId != scope.contestId &&
          (contest['admin_lock'] == 'Locked' ||
              contest['lifecycle_state'] == 'Completed')) {
        return reject(
          SyncReasonCode.locked,
          contest['admin_lock'] == 'Locked'
              ? 'The contest is locked. Unlock it to change this.'
              : 'The contest is completed and no longer accepts changes.',
        );
      }
    }

    if (!payload.isDelete &&
        (m.entityType == 'ScoreAttempt' || m.entityType == 'OfficialScore')) {
      final refused = await _scoreReferenceProblem(tx, m, payload.entity);
      if (refused != null) return reject(refused.$1, refused.$2);
    }

    final links = PilotLinkCollisions.handles(ctx, m.entityType);
    if (links) {
      final writer = await _links.writerProblem(tx, ctx, m);
      if (writer != null) return reject(writer.$1, writer.$2);
    }
    if (links && !payload.isDelete) {
      final problem = await _links.targetProblem(tx, ctx, payload.entity);
      if (problem != null) return reject(problem.$1, problem.$2);
    }

    final step = _Step(tx, ctx, m, kind, payload, stored, contest);
    final result = payload.isDelete
        ? await _delete(step)
        : kind.shape == SyncEntityShape.revisioned
        ? await _saveRevisioned(step)
        : await _saveImmutable(step);

    if (result.outcome == MutationOutcome.accepted) {
      if (links) {
        // A change to the stored link ends the reviews that compared it.
        await _links.storedLinkChanged(tx, ctx, m.entityId);
      } else if (payload.isDelete && m.entityType == 'ParticipantProfile') {
        await _links.participantDeleted(tx, ctx, m, m.entityId);
      }
    }

    if (bootstrap && result.outcome == MutationOutcome.accepted) {
      await _openInitialActivation(tx, ctx, scope as ContestScopeKey);
    }
    return result;
  }

  // Saving a revisioned entity ------------------------------------------

  Future<MutationResult> _saveRevisioned(_Step s) async {
    final entity = s.payload.entity;
    final stored = s.stored;
    final base = s.m.baseRevision;

    if (stored == null) {
      if (base != null) {
        return _log.reject(
          s.tx,
          s.ctx,
          s.m,
          SyncReasonCode.staleBase.code,
          'The ${s.m.entityType} is not stored, so revision $base is unknown.',
        );
      }
      final created = {...entity, 'revision': entity['revision'] ?? 1};
      return _store_(s, created);
    }

    final current = stored['revision'] as int;
    if (base == null) {
      if (jsonEquals(_comparable(stored), _comparable(entity))) {
        return _acceptStored(s, stored);
      }
      return _conflict(
        s,
        SyncReasonCode.staleBase,
        'The ${s.m.entityType} already exists with different content.',
        current,
      );
    }
    if (base == current) {
      return _store_(s, {...entity, 'revision': current + 1});
    }
    if (base > current) {
      return _log.reject(
        s.tx,
        s.ctx,
        s.m,
        SyncReasonCode.staleBase.code,
        'Revision $base is ahead of the stored revision $current.',
        currentRevision: current,
      );
    }

    // The change was made on an older revision than the one stored.
    final latest = await _latestAccepted(s, stored);
    if (_directorPrecedence.contains(s.m.entityType) &&
        s.m.authority == Authority.director &&
        latest != null &&
        _byParticipant(latest)) {
      final replaced = MutationPayload.parse(latest.payload).entity;
      final recordId = s.ctx.newId();
      final result = await _store_(s, {
        ...entity,
        'revision': current + 1,
      }, recordId: recordId);
      await _log.silentRecord(
        s.tx,
        s.ctx,
        s.m,
        acceptedMutationId: recordId,
        competingMutationId: latest.id,
        accepted: {...entity, 'revision': current + 1},
        competing: replaced,
        currentRevision: current,
      );
      return result;
    }

    final snapshot = await _snapshotAt(s, base);
    if (snapshot != null && _mayMerge(s)) {
      final merged = FieldMerge.merge(
        base: snapshot,
        current: stored,
        submitted: entity,
      );
      if (merged != null) {
        return _store_(s, {...merged, 'revision': current + 1});
      }
    }
    return _conflict(
      s,
      SyncReasonCode.staleBase,
      'The ${s.m.entityType} changed on revision $current after the revision '
      '$base this change was based on.',
      current,
      acceptedMutation: latest,
    );
  }

  bool _mayMerge(_Step s) {
    if (!SyncEntityCatalog.fixedAfterConfiguration.contains(s.m.entityType)) {
      return true;
    }
    final contest = s.contest;
    if (s.ctx.scope is! ContestScopeKey || contest == null) return true;
    return _contestStatesOpenToMerge.contains(contest['lifecycle_state']);
  }

  // Saving an entity that never changes ---------------------------------

  Future<MutationResult> _saveImmutable(_Step s) async {
    final entity = s.payload.entity;
    final stored = s.stored;
    if (stored != null) {
      if (jsonEquals(_comparable(stored), _comparable(entity))) {
        return _acceptStored(s, stored);
      }
      return _log.reject(
        s.tx,
        s.ctx,
        s.m,
        SyncReasonCode.locked.code,
        'The ${s.m.entityType} is stored and never changes.',
      );
    }

    switch (s.m.entityType) {
      case 'ContestConfigurationRevision':
        final held = await s.tx.findEntitiesWhere(
          'ContestConfigurationRevision',
          'contest_id',
          (s.ctx.scope as ContestScopeKey).contestId,
        );
        final latest = _highest(held, 'revision_number');
        final number = entity['revision_number'];
        final newest = latest?['revision_number'] as int? ?? 0;
        if (number != newest + 1) {
          return _conflict(
            s,
            SyncReasonCode.configRevisionConflict,
            'The configuration changed after the revision this one followed.',
            latest == null ? null : newest,
            acceptedEntity: latest,
          );
        }
      case 'OfficialScore':
        final held = await s.tx.findEntitiesWhere(
          'OfficialScore',
          'score_placeholder_id',
          Id.parse(entity['score_placeholder_id']! as String),
        );
        final latest = _highest(held, 'score_revision');
        final number = entity['score_revision'] as int? ?? 0;
        final newest = latest?['score_revision'] as int? ?? 0;
        if (number <= newest) {
          return _officialScoreCollision(s, latest!, newest);
        }
      case 'MatrixAssignment':
        final supersedes = s.payload.supersedes;
        if (supersedes != null) {
          final sourceId = Id.parse(supersedes);
          final source = await s.tx.findEntity('MatrixAssignment', sourceId);
          if (source == null) {
            return _log.reject(
              s.tx,
              s.ctx,
              s.m,
              SyncReasonCode.invalidPayload.code,
              'The assignment to move is not stored.',
            );
          }
          if (source['superseded_by_assignment_id'] != null) {
            return _conflict(
              s,
              SyncReasonCode.uniqueViolation,
              'The assignment was already moved.',
              null,
              acceptedEntity: source,
            );
          }
          await s.tx.markSuperseded(
            sourceId,
            s.m.entityId,
            (s.ctx.scope as ContestScopeKey).contestId,
          );
        }
    }
    return _store_(s, entity);
  }

  /// A director's official score collides with one stored for the same
  /// score revision. If the stored one came from a participant or the
  /// service, the director's wins and the other is kept as a silent record.
  Future<MutationResult> _officialScoreCollision(
    _Step s,
    Map<String, Object?> latest,
    int newest,
  ) async {
    final scope = s.ctx.scope;
    final decided = await s.tx.acceptedMutationsFor(
      scope,
      'OfficialScore',
      Id.parse(latest['id']! as String),
    );
    final by = decided.isEmpty ? null : decided.last;
    if (s.m.authority == Authority.director &&
        by != null &&
        _byParticipant(by)) {
      final renumbered = {...s.payload.entity, 'score_revision': newest + 1};
      final recordId = s.ctx.newId();
      final result = await _store_(s, renumbered, recordId: recordId);
      await _log.silentRecord(
        s.tx,
        s.ctx,
        s.m,
        acceptedMutationId: recordId,
        competingMutationId: by.id,
        accepted: renumbered,
        competing: latest,
        currentRevision: newest,
      );
      return result;
    }
    return _conflict(
      s,
      SyncReasonCode.staleBase,
      'The score changed after the revision this decision followed.',
      newest,
      acceptedEntity: latest,
      acceptedMutation: by,
    );
  }

  // Deleting ------------------------------------------------------------

  Future<MutationResult> _delete(_Step s) async {
    final stored = s.stored;
    if (s.kind.shape == SyncEntityShape.appendOnly) {
      // The one append-only deletion: the matrix row of a pilot with no
      // scores who left the contest or stopped flying after the draw.
      if (s.m.entityType != 'MatrixAssignment') {
        return _log.reject(
          s.tx,
          s.ctx,
          s.m,
          SyncReasonCode.locked.code,
          'The ${s.m.entityType} is immutable and cannot be deleted.',
        );
      }
      final refusal = await _assignmentDeletionRefusal(s);
      if (refusal != null) {
        return _log.reject(
          s.tx,
          s.ctx,
          s.m,
          SyncReasonCode.locked.code,
          refusal,
        );
      }
    }
    if (stored != null && s.kind.shape == SyncEntityShape.revisioned) {
      final current = stored['revision'] as int;
      final base = s.m.baseRevision;
      if (base != null && base > current) {
        return _log.reject(
          s.tx,
          s.ctx,
          s.m,
          SyncReasonCode.staleBase.code,
          'Revision $base is ahead of the stored revision $current.',
          currentRevision: current,
        );
      }
      if (base != null && base < current) {
        return _conflict(
          s,
          SyncReasonCode.staleBase,
          'The ${s.m.entityType} changed after the revision this deletion '
          'was based on.',
          current,
          acceptedMutation: await _latestAccepted(s, stored),
        );
      }
    }
    if (stored != null) await s.tx.removeEntity(s.m.entityType, s.m.entityId);
    final now = s.ctx.clock();
    await s.tx.saveTombstone(
      Tombstone(
        id: s.ctx.newId(),
        contestId: s.ctx.scope.contestIdOrNull,
        ownerAccountId: s.ctx.scope.ownerAccountIdOrNull,
        entityType: s.m.entityType,
        entityId: s.m.entityId,
        status: TombstoneStatus.acknowledged,
        deletedAt: s.m.clientTime,
        acknowledgedAt: now,
        purgeAfter: now.add(Tombstone.retention),
      ),
    );
    return _log.accept(
      s.tx,
      s.ctx,
      s.m,
      MutationPayload.delete,
      audit: AuditAction.deletion,
    );
  }

  /// Why the deletion of a matrix assignment is refused, or null. Only a
  /// director removes one, and only after its score slot is gone: the slot's
  /// own deletion cannot happen while attempts, official scores or review
  /// requests refer to it, so a row that was ever scored stays.
  Future<String?> _assignmentDeletionRefusal(_Step s) async {
    if (s.m.authority != Authority.director) {
      return 'Only a director removes a matrix assignment.';
    }
    if (s.stored == null) return null;
    final slots = await s.tx.findEntitiesWhere(
      'ScorePlaceholder',
      'assignment_id',
      s.m.entityId,
    );
    if (slots.isNotEmpty) {
      return 'The assignment still has a score slot; remove the empty slot '
          'first.';
    }
    return null;
  }

  // Shared steps --------------------------------------------------------

  Future<MutationResult> _store_(
    _Step s,
    Map<String, Object?> entity, {
    Id? recordId,
  }) async {
    await s.tx.writeEntity(s.m.entityType, entity);
    final audit = switch (s.m.entityType) {
      'ScoreAttempt' => AuditAction.scoreAttempt,
      'OfficialScore' => AuditAction.scoreReview,
      _ => null,
    };
    return _log.accept(
      s.tx,
      s.ctx,
      s.m,
      MutationPayload.save(entity, supersedes: s.payload.supersedes),
      revision: entity['revision'] as int?,
      audit: audit,
      recordId: recordId,
    );
  }

  /// Accepts a mutation whose entity is already stored exactly as sent, so a
  /// client that lost its answer still gets a sequence for it.
  Future<MutationResult> _acceptStored(_Step s, Map<String, Object?> stored) =>
      _log.accept(
        s.tx,
        s.ctx,
        s.m,
        MutationPayload.save(stored, supersedes: s.payload.supersedes),
        revision: stored['revision'] as int?,
      );

  Future<MutationResult> _conflict(
    _Step s,
    SyncReasonCode reason,
    String message,
    int? currentRevision, {
    MutationRecord? acceptedMutation,
    Map<String, Object?>? acceptedEntity,
  }) => _log.conflict(
    s.tx,
    s.ctx,
    s.m,
    reasonCode: reason.code,
    message: message,
    competing: s.payload,
    acceptedMutationId: acceptedMutation?.id,
    accepted: acceptedEntity ?? s.stored,
    currentRevision: currentRevision,
  );

  Future<MutationRecord?> _latestAccepted(
    _Step s,
    Map<String, Object?> stored,
  ) async {
    final history = await s.tx.acceptedMutationsFor(
      s.ctx.scope,
      s.m.entityType,
      s.m.entityId,
    );
    return history.isEmpty ? null : history.last;
  }

  Future<Map<String, Object?>?> _snapshotAt(_Step s, int revision) async {
    final history = await s.tx.acceptedMutationsFor(
      s.ctx.scope,
      s.m.entityType,
      s.m.entityId,
    );
    for (final record in history.reversed) {
      final payload = MutationPayload.parse(record.payload);
      if (!payload.isDelete && payload.entity['revision'] == revision) {
        return payload.entity;
      }
    }
    return null;
  }

  Future<void> _openInitialActivation(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    ContestScopeKey scope,
  ) async {
    final now = ctx.clock();
    await tx.saveActivation(
      InstallationActivation(
        id: ctx.newId(),
        contestId: scope.contestId,
        installationId: ctx.installationId!,
        activatedBy: ctx.accountId,
        kind: ActivationKind.initial,
        activatedAt: now,
      ),
    );
  }

  Future<MutationResult> _constraint(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation m,
    SyncConstraintError error,
  ) async {
    if (error.kind == SyncConstraintKind.unique) {
      final stored = await tx.findEntity(m.entityType, m.entityId);
      return _log.conflict(
        tx,
        ctx,
        m,
        reasonCode: SyncReasonCode.uniqueViolation.code,
        message: 'The change collides with another one: ${error.message}',
        competing: MutationPayload.parse(m.payload),
        accepted: stored,
        currentRevision: stored?['revision'] as int?,
      );
    }
    return _log.reject(
      tx,
      ctx,
      m,
      SyncReasonCode.invalidPayload.code,
      'The change refers to something the service does not have: '
      '${error.message}',
    );
  }

  // Checks --------------------------------------------------------------

  Future<_Refusal?> _scoreReferenceProblem(
    SyncAcceptorTransaction tx,
    SyncMutation m,
    Map<String, Object?> entity,
  ) async {
    final placeholderId = entity['score_placeholder_id'];
    final placeholder = placeholderId is String
        ? await tx.findEntity('ScorePlaceholder', Id.parse(placeholderId))
        : null;
    if (placeholder == null) {
      return (
        SyncReasonCode.unknownFlightGroup,
        'The score refers to a flight group the service does not have yet.',
      );
    }
    if (placeholder['locked_by'] != null) {
      return (
        SyncReasonCode.locked,
        'The score is locked. Unlock it to change it.',
      );
    }
    if (m.entityType == 'OfficialScore') {
      final attemptId = entity['score_attempt_id'];
      if (attemptId is! String ||
          await tx.findEntity('ScoreAttempt', Id.parse(attemptId)) == null) {
        return (
          SyncReasonCode.invalidPayload,
          'The official score refers to a score attempt the service does not '
              'have: ${attemptId ?? 'none given'}.',
        );
      }
    }
    final matrixId = entity['matrix_revision_id'];
    if (m.entityType == 'ScoreAttempt' &&
        (matrixId is! String ||
            await tx.findEntity('MatrixRevision', Id.parse(matrixId)) ==
                null)) {
      return (
        SyncReasonCode.unknownMatrixRevision,
        'The score refers to a matrix revision the service does not have yet.',
      );
    }
    return null;
  }

  // Small helpers -------------------------------------------------------

  SyncScope _scopeKind(SyncScopeKey scope) => switch (scope) {
    ContestScopeKey() => SyncScope.contest,
    _ => SyncScope.director,
  };

  bool _byParticipant(MutationRecord record) =>
      record.authority == Authority.participant ||
      record.authority == Authority.system;

  Map<String, Object?>? _highest(
    List<Map<String, Object?>> rows,
    String field,
  ) {
    Map<String, Object?>? best;
    for (final row in rows) {
      if (best == null || (row[field]! as int) > (best[field]! as int)) {
        best = row;
      }
    }
    return best;
  }

  /// [entity] without what the service stores differently from what a client
  /// sends: a landing table travels with its entries, which are separate rows.
  Map<String, Object?> _comparable(Map<String, Object?> entity) => {
    for (final e in entity.entries)
      if (e.key != 'results') e.key: e.value,
  };
}

/// Why a mutation is refused before it is looked at in detail.
typedef _Refusal = ScopeRefusal;

/// The state of one mutation while it is decided.
class _Step {
  _Step(
    this.tx,
    this.ctx,
    this.m,
    this.kind,
    this.payload,
    this.stored,
    this.contest,
  );

  final SyncAcceptorTransaction tx;
  final ExchangeContext ctx;
  final SyncMutation m;
  final SyncEntityKind kind;
  final MutationPayload payload;
  final Map<String, Object?>? stored;
  final Map<String, Object?>? contest;
}
