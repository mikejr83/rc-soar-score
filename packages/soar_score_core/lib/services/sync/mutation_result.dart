import 'package:equatable/equatable.dart';

import '../../enums/mutation_outcome.dart';

/// The service's decision for one mutation.
class MutationResult extends Equatable {
  const MutationResult({
    required this.clientMutationId,
    required this.outcome,
    this.revision,
    this.sequence,
    this.reasonCode,
    this.currentRevision,
    this.dependsOn,
  });

  final String clientMutationId;
  final MutationOutcome outcome;

  /// The revision an `Accepted` change produced; null when the entity has no
  /// revision or was deleted.
  final int? revision;
  final int? sequence;
  final String? reasonCode;

  /// The entity's revision at decision time, for a `Rejected` or `Conflict`.
  final int? currentRevision;

  /// The `client_mutation_id` of the failed mutation a `Skipped` one needed.
  final String? dependsOn;

  bool get failed =>
      outcome == MutationOutcome.rejected ||
      outcome == MutationOutcome.conflict ||
      outcome == MutationOutcome.skipped;

  @override
  List<Object?> get props => [
    clientMutationId,
    outcome,
    revision,
    sequence,
    reasonCode,
    currentRevision,
    dependsOn,
  ];
}
