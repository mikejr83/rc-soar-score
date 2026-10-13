/// A replicated change names an entity type this installation cannot store.
///
/// Applying one stops the pull for that scope without moving its cursor.
/// It is an [ArgumentError] so existing callers that catch one still do.
class UnsupportedEntityTypeError extends ArgumentError {
  UnsupportedEntityTypeError(String entityType, String reason)
    : super.value(entityType, 'entityType', reason);

  /// The entity type that was refused.
  String get entityType => invalidValue! as String;
}
