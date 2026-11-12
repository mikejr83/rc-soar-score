import '../../enums/sync_reason_code.dart';
import '../../models/id.dart';
import '../../repositories/sync_acceptor_store.dart';
import 'exchange_context.dart';
import 'mutation_payloads.dart';
import 'sync_entity_catalog.dart';
import 'sync_scope_ids.dart';

/// Why a write is refused before it is looked at in detail.
typedef ScopeRefusal = (SyncReasonCode reason, String message);

/// The ownership and reference rules every write to a synced entity obeys,
/// whether it arrives as a mutation or as the director's conflict decision.
///
/// A write may only name an entity of the exchange's own scope, and every
/// stored row it refers to must belong to that scope too, so no path reads,
/// reports or changes another scope's data.
abstract final class SyncScopeGuard {
  /// The contest-scoped rows each entity type refers to: JSON key to the type
  /// of the row it names. A key that is absent or null is not checked.
  static const _references = <String, Map<String, String>>{
    'ScorePlaceholder': {
      'assignment_id': 'MatrixAssignment',
      'current_attempt_id': 'ScoreAttempt',
    },
    'ScoreAttempt': {
      'score_placeholder_id': 'ScorePlaceholder',
      'matrix_revision_id': 'MatrixRevision',
    },
    'OfficialScore': {
      'score_placeholder_id': 'ScorePlaceholder',
      'score_attempt_id': 'ScoreAttempt',
    },
    'ReviewRequest': {
      'score_placeholder_id': 'ScorePlaceholder',
      'resulting_attempt_id': 'ScoreAttempt',
    },
    'MatrixAssignment': {
      'matrix_revision_id': 'MatrixRevision',
      'source_assignment_id': 'MatrixAssignment',
    },
    'MatrixRevision': {'previous_revision_id': 'MatrixRevision'},
    'Round': {'matrix_revision_id': 'MatrixRevision'},
    'RoundGroup': {'round_id': 'Round'},
    'ReFlightParticipant': {
      're_flight_id': 'ReFlight',
      'assignment_id': 'MatrixAssignment',
    },
  };

  static String scopeId(ExchangeContext ctx) =>
      ctx.scope.contestIdOrNull?.value ?? ctx.scope.ownerAccountIdOrNull!.value;

  /// Why a write of [entityType] [entityId] touches an entity outside the
  /// scope or the account's reach, or null when it does not.
  ///
  /// [entity] is the state being written (null for a deletion) and [stored]
  /// the row now held under [entityId].
  static ScopeRefusal? ownershipProblem(
    ExchangeContext ctx,
    SyncEntityKind kind,
    Id entityId,
    Map<String, Object?>? entity,
    Map<String, Object?>? stored,
  ) {
    final scopeId = SyncScopeGuard.scopeId(ctx);
    ScopeRefusal foreign(Object? found) => (
      SyncReasonCode.unauthorized,
      'The ${kind.entityType} belongs to another scope: ${kind.scopeKey} is '
          '$found, the exchange scope is $scopeId.',
    );
    ScopeRefusal notOwner(Object? owner) => (
      SyncReasonCode.unauthorized,
      'Only the contest director owns the contest: owner_account_id is '
          '$owner, the signed-in account is ${ctx.accountId.value}.',
    );
    if (entity != null) {
      if (entity['id'] != entityId.value) {
        return (
          SyncReasonCode.invalidPayload,
          'The entity id does not match the mutation.',
        );
      }
      if (entity[kind.scopeKey] != scopeId) {
        return foreign(entity[kind.scopeKey]);
      }
      if (kind.entityType == 'Contest' &&
          entity['owner_account_id'] != ctx.accountId.value) {
        return notOwner(entity['owner_account_id']);
      }
    }
    if (stored != null) {
      if (stored[kind.scopeKey] != scopeId) {
        return foreign(stored[kind.scopeKey]);
      }
      if (kind.entityType == 'Contest' &&
          stored['owner_account_id'] != ctx.accountId.value) {
        return notOwner(stored['owner_account_id']);
      }
    }
    return null;
  }

  /// Why a row that [entityType] [entity] refers to (or [supersedes], the
  /// assignment a move replaces) belongs to another contest, or null.
  ///
  /// A referenced row that is not stored is not this check's concern: the
  /// ordinary missing-reference rules apply. One that is stored must belong
  /// to the exchange's contest, and this runs before its content is read.
  static Future<ScopeRefusal?> referenceProblem(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    String entityType,
    Map<String, Object?> entity, {
    String? supersedes,
  }) async {
    final contestId = ctx.scope.contestIdOrNull;
    if (contestId == null) return null;
    final refs = {
      ...?_references[entityType],
      if (supersedes != null && entityType == 'MatrixAssignment')
        '__supersedes': 'MatrixAssignment',
    };
    for (final ref in refs.entries) {
      final raw = ref.key == '__supersedes' ? supersedes : entity[ref.key];
      if (raw == null) continue;
      final Id id;
      try {
        id = Id.parse(raw as String);
      } on Object {
        return (
          SyncReasonCode.invalidPayload,
          '${ref.key == '__supersedes' ? 'supersedes' : ref.key} is not an id.',
        );
      }
      final row = await tx.findEntity(ref.value, id);
      if (row != null && row['contest_id'] != contestId.value) {
        return (
          SyncReasonCode.unauthorized,
          'The ${ref.value} it refers to belongs to another scope.',
        );
      }
    }
    return null;
  }

  /// [ownershipProblem] then [referenceProblem] for a save of [payload].
  static Future<ScopeRefusal?> writeProblem(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncEntityKind kind,
    Id entityId,
    MutationPayload payload,
    Map<String, Object?>? stored,
  ) async {
    final problem = ownershipProblem(
      ctx,
      kind,
      entityId,
      payload.isDelete ? null : payload.entity,
      stored,
    );
    if (problem != null || payload.isDelete) return problem;
    return referenceProblem(
      tx,
      ctx,
      kind.entityType,
      payload.entity,
      supersedes: payload.supersedes,
    );
  }
}
