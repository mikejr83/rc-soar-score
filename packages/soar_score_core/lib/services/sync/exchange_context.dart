import '../../models/id.dart';
import '../../repositories/sync_scope_key.dart';
import 'mutation_result.dart';
import 'sync_exchange.dart';

/// What the acceptor knows about the request it is working through.
class ExchangeContext {
  ExchangeContext({
    required this.scope,
    required this.accountId,
    required this.clock,
    required this.newId,
    this.installationId,
    this.firstUpload,
  });

  final SyncScopeKey scope;

  /// The authenticated director.
  final Id accountId;

  /// The installation that sent the mutations; null for a decision the
  /// director made through the resolve route.
  final Id? installationId;

  /// The request says it continues the first upload of the contest, sent in
  /// several exchanges (see `SyncExchangeInput.firstUpload`).
  final FirstUploadPhase? firstUpload;

  final DateTime Function() clock;
  final Id Function() newId;

  /// The results decided so far, by the id of the mutation that was sent, so
  /// a later mutation can see that the one it depends on failed.
  final Map<Id, MutationResult> decided = {};

  /// The contest this request created: its first upload. The other mutations
  /// of the same request are the contest's history, so the lock and completed
  /// rules do not apply to them even when the contest arrives Locked or
  /// Completed. Null when the request created no contest.
  Id? createdContestId;

  /// An accepted `Contest` write of this request changed what the public site
  /// shows: the contest details, the results visibility, or becoming
  /// Completed. Decided inside the write's own transaction, from the row it
  /// replaced and the row it stored, so nothing else touching the contest
  /// can set it. Scoring access, the administration lock and the other
  /// lifecycle steps leave it false.
  bool publicContestChange = false;

  /// The conflicts the request created.
  final List<SyncConflictPointer> conflicts = [];
}
