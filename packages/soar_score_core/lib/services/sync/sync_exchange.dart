import 'package:equatable/equatable.dart';

import '../../models/id.dart';
import '../../repositories/sync_scope_key.dart';
import 'accepted_change.dart';
import 'mutation_result.dart';
import 'sync_mutation.dart';

/// What a client sends to `POST /sync/exchange`.
class SyncExchangeInput {
  const SyncExchangeInput({
    required this.protocolVersion,
    required this.schemaVersion,
    required this.installationId,
    required this.scope,
    required this.lastAcknowledgedSequence,
    this.pageToken,
    this.mutations = const [],
    this.firstUpload = false,
  });

  final int protocolVersion;
  final int schemaVersion;
  final Id installationId;

  /// A contest or a director; never the system scope.
  final SyncScopeKey scope;
  final int lastAcknowledgedSequence;
  final String? pageToken;
  final List<SyncMutation> mutations;

  /// The installation says this request belongs to the upload of a contest it
  /// created, sent in several exchanges. The service honors it only while the
  /// installation still holds the contest's `Initial` activation.
  final bool firstUpload;
}

/// A conflict an exchange created or touched.
class SyncConflictPointer extends Equatable {
  const SyncConflictPointer({required this.id, required this.requiresAction});

  final Id id;
  final bool requiresAction;

  @override
  List<Object?> get props => [id, requiresAction];
}

/// What the service answers an exchange with.
class SyncExchangeOutput {
  const SyncExchangeOutput({
    required this.results,
    required this.changes,
    required this.conflicts,
    required this.serverSequence,
    this.nextPageToken,
  });

  /// One per submitted mutation, in request order.
  final List<MutationResult> results;
  final List<AcceptedChange> changes;
  final List<SyncConflictPointer> conflicts;
  final String? nextPageToken;
  final int serverSequence;
}
