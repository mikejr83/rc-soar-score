/// A mutation's entity does not decode into the entity type it names.
///
/// The acceptor turns it into a `Rejected` result with `invalid_payload`.
class SyncPayloadError extends Error {
  SyncPayloadError(this.message);

  final String message;

  @override
  String toString() => 'SyncPayloadError: $message';
}
