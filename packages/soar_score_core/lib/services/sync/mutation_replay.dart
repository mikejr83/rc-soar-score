import '../../enums/mutation_outcome.dart';
import '../../models/sync/mutation_record.dart';
import '../../repositories/sync_acceptor_store.dart';
import 'mutation_payloads.dart';
import 'mutation_result.dart';

/// The answer to a mutation that was already decided, rebuilt from its
/// record, so a retried request gets the original outcome and nothing is
/// applied again.
///
/// An accepted mutation answers with the revision and sequence it got. A
/// rejected or conflicting one answers with its reason and the entity's
/// revision as it stands now.
Future<MutationResult> replayDecision(
  SyncAcceptorTransaction tx,
  MutationRecord prior,
) async {
  if (prior.outcome == MutationOutcome.accepted) {
    final payload = MutationPayload.parse(prior.payload);
    return MutationResult(
      clientMutationId: prior.clientMutationId,
      outcome: MutationOutcome.accepted,
      revision: payload.isDelete ? null : payload.entity['revision'] as int?,
      sequence: prior.sequence,
    );
  }
  final stored = await tx.findEntity(prior.entityType, prior.entityId);
  return MutationResult(
    clientMutationId: prior.clientMutationId,
    outcome: prior.outcome,
    reasonCode: prior.reasonCode,
    currentRevision: stored?['revision'] as int?,
  );
}
