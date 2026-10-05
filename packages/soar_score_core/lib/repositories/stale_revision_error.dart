import '../models/id.dart';

/// A write was based on a revision that is no longer the stored one.
///
/// Thrown by the unit of work so a caller never overwrites a change it has not
/// seen.
class StaleRevisionError extends Error {
  StaleRevisionError({
    required this.entityType,
    required this.entityId,
    required this.expectedRevision,
    required this.storedRevision,
  });

  final String entityType;
  final Id entityId;

  /// The revision the caller's copy carries.
  final int expectedRevision;

  /// The revision in the store.
  final int storedRevision;

  @override
  String toString() =>
      'StaleRevisionError: $entityType ${entityId.value} is at revision '
      '$storedRevision, the write was based on $expectedRevision';
}
