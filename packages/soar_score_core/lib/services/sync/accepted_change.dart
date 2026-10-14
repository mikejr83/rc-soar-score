import 'package:equatable/equatable.dart';

import '../../models/id.dart';

/// One accepted change of a scope's stream.
class AcceptedChange extends Equatable {
  const AcceptedChange({
    required this.sequence,
    required this.entityType,
    required this.entityId,
    required this.revision,
    required this.payload,
  });

  final int sequence;
  final String entityType;
  final Id entityId;

  /// The stored revision; 0 for an entity that has none.
  final int revision;

  /// The entity as stored, or `{"deleted": true}` for a deletion.
  final Map<String, Object?> payload;

  @override
  List<Object?> get props => [
    sequence,
    entityType,
    entityId,
    revision,
    payload,
  ];
}
