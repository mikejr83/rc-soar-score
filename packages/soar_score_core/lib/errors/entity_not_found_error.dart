import '../models/id.dart';

/// A request named an entity that is not stored.
class EntityNotFoundError extends Error {
  EntityNotFoundError({required this.entityType, required this.entityId});

  final String entityType;
  final Id entityId;

  @override
  String toString() =>
      'EntityNotFoundError: no $entityType with id ${entityId.value}';
}
