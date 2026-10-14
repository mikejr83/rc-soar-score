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
  });

  final SyncScopeKey scope;

  /// The authenticated director.
  final Id accountId;

  /// The installation that sent the mutations; null for a decision the
  /// director made through the resolve route.
  final Id? installationId;

  final DateTime Function() clock;
  final Id Function() newId;

  /// The results decided so far, by the id of the mutation that was sent, so
  /// a later mutation can see that the one it depends on failed.
  final Map<Id, MutationResult> decided = {};

  /// The conflicts the request created.
  final List<SyncConflictPointer> conflicts = [];
}
