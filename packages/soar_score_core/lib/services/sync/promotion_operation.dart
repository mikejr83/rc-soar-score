import '../../enums/authority.dart';
import '../../enums/mutation_outcome.dart';
import '../../enums/sync_reason_code.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../errors/scoring_validation_error.dart';
import '../../models/id.dart';
import '../../models/shared/versioned_payload.dart';
import '../../models/sync/mutation_record.dart';
import '../../repositories/mutation_metadata.dart';
import '../../repositories/recorded_score.dart';
import '../../repositories/stale_revision_error.dart';
import '../../repositories/sync_acceptor_store.dart';
import '../../repositories/sync_scope_key.dart';
import '../../sync/sync_protocol.dart';
import '../scores_service.dart';
import 'exchange_context.dart';
import 'json_equality.dart';
import 'mutation_result.dart';
import 'sync_log.dart';
import 'sync_mutation.dart';

/// The `promote_score` operation of the sync protocol: an installation asks
/// the service to adopt a stored participant submission as the official score.
///
/// Specified in `plan/architecture-requirements/sync-protocol.md` (Promote
/// score operation). The intent is decided by [ScoresService.promoteSubmission]
/// inside the contest's score gate, so it is guarded exactly like the hosted
/// route: exactly the stated source at the stated score revision, or nothing.
/// It never goes through the generic director-wins merge.
class PromotionOperation {
  PromotionOperation(this._store, this._scores, this._log);

  final SyncAcceptorStore _store;
  final ScoresService _scores;
  final SyncLog _log;

  /// The payload version of the intent.
  static const operationVersion = 1;

  /// Decides [m] and answers it.
  ///
  /// A decided intent is answered from its record: a refusal stays a refusal,
  /// and an adoption is answered `Accepted` with `replayed` only while the
  /// slot still shows it (else `stale_source` with the current state in the
  /// pulled changes). The same `client_mutation_id` with another payload is
  /// refused as `operation_mismatch` without touching the record.
  Future<MutationResult> decide(ExchangeContext ctx, SyncMutation m) async {
    final scope = ctx.scope;
    if (scope is! ContestScopeKey) {
      return _reject(
        ctx,
        m,
        SyncReasonCode.invalidPayload,
        'A score promotion belongs to a contest.',
      );
    }
    final prior = await _store.transaction(
      (tx) => tx.findMutation(scope, m.clientMutationId),
    );
    final decided = prior != null && prior.outcome != MutationOutcome.pending;
    if (decided && !_sameIntent(prior.payload, m.payload)) {
      return MutationResult(
        clientMutationId: m.clientMutationId,
        outcome: MutationOutcome.rejected,
        reasonCode: SyncReasonCode.operationMismatch.code,
      );
    }
    if (decided && prior.outcome != MutationOutcome.accepted) {
      return MutationResult(
        clientMutationId: m.clientMutationId,
        outcome: prior.outcome,
        reasonCode: prior.reasonCode,
        replayed: true,
      );
    }

    final _Intent intent;
    try {
      intent = _Intent.parse(m);
    } on _Unsupported catch (e) {
      return _reject(ctx, m, SyncReasonCode.unsupportedOperation, e.message);
    } on FormatException catch (e) {
      return _reject(ctx, m, SyncReasonCode.invalidPayload, e.message);
    }
    if (m.authority != Authority.director) {
      return _reject(
        ctx,
        m,
        SyncReasonCode.unauthorized,
        'Only a director promotes a score.',
      );
    }
    if (!decided && !await _administers(ctx, scope)) {
      return _reject(
        ctx,
        m,
        SyncReasonCode.inactiveInstallation,
        'This installation does not administer the contest. Reactivate it as '
        'the primary installation first.',
      );
    }

    final metadata = MutationMetadata(
      clientMutationId: '${m.clientMutationId}/official',
      authority: Authority.director,
      clientTime: m.clientTime,
      actorId: ctx.accountId,
      sourceInstallationId: ctx.installationId,
    ).inAggregate(ctx.newId());
    try {
      final result = await _scores.promoteSubmission(
        scope.contestId,
        intent.assignmentId,
        sourceAttemptId: intent.sourceAttemptId,
        expectedScoreRevision: intent.expectedScoreRevision,
        actorId: ctx.accountId,
        metadata: metadata,
        intent: decided
            ? null
            : PromotionIntent(
                operationId: m.entityId,
                clientMutationId: m.clientMutationId,
                data: intent.data,
              ),
      );
      if (decided) {
        // Still the adoption this receipt decided: nothing is written.
        return MutationResult(
          clientMutationId: m.clientMutationId,
          outcome: MutationOutcome.accepted,
          revision: result.entry.officialScore.scoreRevision,
          sequence: prior.sequence,
          replayed: true,
        );
      }
      if (result.replayed) {
        // The slot already shows this adoption (another route made it), so
        // no receipt came with it: record one of its own.
        return await _receipt(ctx, m, scope, intent, result);
      }
      final receipt = await _store.transaction(
        (tx) => tx.findMutation(scope, m.clientMutationId),
      );
      return MutationResult(
        clientMutationId: m.clientMutationId,
        outcome: MutationOutcome.accepted,
        revision: result.entry.officialScore.scoreRevision,
        sequence: receipt?.sequence,
      );
    } on StaleRevisionError {
      return decided
          ? MutationResult(
              clientMutationId: m.clientMutationId,
              outcome: MutationOutcome.rejected,
              reasonCode: SyncReasonCode.staleSource.code,
            )
          : await _reject(
              ctx,
              m,
              SyncReasonCode.staleSource,
              'The submission is no longer the slot\'s current score source.',
            );
    } on ContestStateError catch (e) {
      return decided
          ? MutationResult(
              clientMutationId: m.clientMutationId,
              outcome: MutationOutcome.rejected,
              reasonCode: SyncReasonCode.locked.code,
            )
          : await _reject(ctx, m, SyncReasonCode.locked, e.message);
    } on EntityNotFoundError catch (e) {
      return await _reject(ctx, m, SyncReasonCode.invalidPayload, '$e');
    } on ScoringValidationError catch (e) {
      return await _reject(ctx, m, SyncReasonCode.invalidPayload, '$e');
    }
  }

  /// Whether [recorded] (the stored record's payload, which an accepted
  /// receipt extends with the adopted score) asks for what [sent] asks for.
  static bool _sameIntent(
    Map<String, Object?> recorded,
    Map<String, Object?> sent,
  ) {
    if (jsonEquals(recorded, sent)) return true;
    try {
      final a = _Intent.fromPayload(recorded);
      final b = _Intent.fromPayload(sent);
      return jsonEquals(a.data, b.data);
    } on Object {
      return false;
    }
  }

  Future<bool> _administers(ExchangeContext ctx, ContestScopeKey scope) =>
      _store.transaction((tx) async {
        final activations = await tx.listActivations(scope.contestId);
        return activations.any(
          (a) => a.isOpen && a.installationId == ctx.installationId,
        );
      });

  /// Stores the receipt of an adoption that was already in place.
  Future<MutationResult> _receipt(
    ExchangeContext ctx,
    SyncMutation m,
    ContestScopeKey scope,
    _Intent intent,
    ScorePromotionResult result,
  ) => _store.transaction((tx) async {
    final sequence = await tx.highestSequence(scope) + 1;
    final now = ctx.clock();
    await tx.recordMutation(
      MutationRecord(
        id: ctx.newId(),
        contestId: scope.contestId,
        sequence: sequence,
        entityType: promotionReceiptEntityType,
        entityId: m.entityId,
        clientMutationId: m.clientMutationId,
        actorId: ctx.accountId,
        authority: m.authority,
        sourceInstallationId: ctx.installationId,
        clientTime: m.clientTime,
        serverAcceptanceTime: now,
        payload: VersionedPayload(
          version: 1,
          data: {
            ...intent.data,
            'official_score_id': result.entry.officialScore.id.value,
            'score_revision': result.entry.officialScore.scoreRevision,
          },
        ).toJson(),
        outcome: MutationOutcome.accepted,
      ),
    );
    return MutationResult(
      clientMutationId: m.clientMutationId,
      outcome: MutationOutcome.accepted,
      revision: result.entry.officialScore.scoreRevision,
      sequence: sequence,
      replayed: true,
    );
  });

  Future<MutationResult> _reject(
    ExchangeContext ctx,
    SyncMutation m,
    SyncReasonCode reason,
    String message,
  ) => _store.transaction((tx) async {
    final prior = await tx.findMutation(ctx.scope, m.clientMutationId);
    if (prior != null && prior.outcome != MutationOutcome.pending) {
      // Never overwrite a decision (an accepted receipt stays accepted).
      return MutationResult(
        clientMutationId: m.clientMutationId,
        outcome: MutationOutcome.rejected,
        reasonCode: reason.code,
      );
    }
    return _log.reject(tx, ctx, m, reason.code, message);
  });
}

class _Unsupported implements Exception {
  const _Unsupported(this.message);
  final String message;
}

/// The parsed data of a `promote_score` payload.
class _Intent {
  const _Intent(
    this.assignmentId,
    this.sourceAttemptId,
    this.expectedScoreRevision,
    this.data,
  );

  final Id assignmentId;
  final Id sourceAttemptId;
  final int expectedScoreRevision;
  final Map<String, Object?> data;

  factory _Intent.parse(SyncMutation m) => _Intent.fromPayload(m.payload);

  factory _Intent.fromPayload(Map<String, Object?> json) {
    final VersionedPayload payload;
    try {
      payload = VersionedPayload.fromJson(json);
    } on ArgumentError catch (e) {
      throw FormatException('${e.message}');
    }
    final data = payload.data;
    if (payload.version != 1 ||
        data['operation'] != SyncCapabilities.promoteScore) {
      throw _Unsupported(
        'Operation ${data['operation']} (payload version ${payload.version}) '
        'is not known.',
      );
    }
    if (data['operation_version'] != PromotionOperation.operationVersion) {
      throw _Unsupported(
        'promote_score version ${data['operation_version']} is not known.',
      );
    }
    Id id(String key) {
      final value = data[key];
      if (value is! String) throw FormatException('$key must be an id');
      try {
        return Id.parse(value);
      } on Object {
        throw FormatException('$key must be an id');
      }
    }

    final revision = data['expected_score_revision'];
    if (revision is! int || revision < 0) {
      throw const FormatException(
        'expected_score_revision must be a whole number',
      );
    }
    return _Intent(id('assignment_id'), id('source_attempt_id'), revision, {
      'operation': SyncCapabilities.promoteScore,
      'operation_version': PromotionOperation.operationVersion,
      'assignment_id': data['assignment_id'],
      'source_attempt_id': data['source_attempt_id'],
      'expected_score_revision': revision,
    });
  }
}
