import '../models/id.dart';

/// An append-only entity was written again.
///
/// Thrown by the unit of work, which never overwrites a score attempt,
/// official score, matrix revision or matrix assignment.
class AlreadyStoredError extends Error {
  AlreadyStoredError({required this.entityType, required this.entityId});

  final String entityType;
  final Id entityId;

  @override
  String toString() =>
      'AlreadyStoredError: $entityType ${entityId.value} is stored and '
      'cannot be changed';
}
