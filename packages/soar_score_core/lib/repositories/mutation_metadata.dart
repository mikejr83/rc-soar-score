import 'package:equatable/equatable.dart';

import '../enums/authority.dart';
import '../models/id.dart';

/// Who made a change and how, supplied by the caller of a unit of work.
///
/// The unit of work turns it, with the entity, into a `MutationRecord`. The
/// base revision is read from the entity being saved, not supplied here.
class MutationMetadata extends Equatable {
  const MutationMetadata({
    required this.clientMutationId,
    required this.authority,
    required this.clientTime,
    this.actorId,
    this.sourceInstallationId,
    this.sourceDevice,
    this.dependsOnMutationId,
  });

  /// Unique request identifier, used for idempotency.
  final String clientMutationId;

  final Authority authority;

  /// Time on the client, for audit only.
  final DateTime clientTime;

  /// The account that made the change; null for a change by the system.
  final Id? actorId;

  /// The installation making the change; null for a participant submission.
  final Id? sourceInstallationId;

  final String? sourceDevice;

  /// A mutation that must be accepted first.
  final Id? dependsOnMutationId;

  /// The metadata for one more mutation of the same request.
  ///
  /// A request that changes several entities writes one mutation each, and a
  /// mutation id is unique, so each further mutation takes the request id
  /// plus a [part] such as the id of its entity. The same request always
  /// derives the same ids, so a retry stays idempotent.
  MutationMetadata forPart(String part) => MutationMetadata(
    clientMutationId: '$clientMutationId/$part',
    authority: authority,
    clientTime: clientTime,
    actorId: actorId,
    sourceInstallationId: sourceInstallationId,
    sourceDevice: sourceDevice,
    dependsOnMutationId: dependsOnMutationId,
  );

  @override
  List<Object?> get props => [
    clientMutationId,
    authority,
    clientTime,
    actorId,
    sourceInstallationId,
    sourceDevice,
    dependsOnMutationId,
  ];
}
