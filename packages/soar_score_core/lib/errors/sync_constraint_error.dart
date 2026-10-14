/// Which database rule a write broke.
enum SyncConstraintKind { unique, foreignKey }

/// A write to the store broke a unique or foreign-key rule.
///
/// The acceptor turns a unique violation into a `Conflict` and a foreign-key
/// violation into a `Rejected` result.
class SyncConstraintError extends Error {
  SyncConstraintError(this.kind, this.message);

  final SyncConstraintKind kind;
  final String message;

  @override
  String toString() => 'SyncConstraintError(${kind.name}): $message';
}
