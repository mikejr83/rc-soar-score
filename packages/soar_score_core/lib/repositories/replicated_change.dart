import 'package:equatable/equatable.dart';

import '../models/id.dart';
import 'sync_scope_key.dart';

/// An accepted change received from the service, to be applied locally.
class ReplicatedChange extends Equatable {
  const ReplicatedChange({
    required this.scope,
    required this.sequence,
    required this.entityType,
    required this.entityId,
    required this.revision,
    required this.payload,
    this.isDelete = false,
  });

  final SyncScopeKey scope;

  /// The service-assigned position in the scope's sequence.
  final int sequence;

  final String entityType;
  final Id entityId;

  /// The revision the service stored; kept as received.
  final int revision;

  /// The entity as the service stored it; ignored when [isDelete].
  final Map<String, Object?> payload;

  final bool isDelete;

  @override
  List<Object?> get props => [
    scope,
    sequence,
    entityType,
    entityId,
    revision,
    payload,
    isDelete,
  ];
}
