/// The sync service refuses a whole request, not one mutation.
///
/// [code] is the text on the wire in the error body, usually a
/// `SyncReasonCode.code`; [statusCode] is the HTTP status. A problem with one
/// mutation is never a refusal: it is a result, so a bad mutation does not
/// fail its batch.
class SyncRefusal extends Error {
  SyncRefusal(this.code, this.statusCode, this.message);

  final String code;
  final int statusCode;
  final String message;

  @override
  String toString() => 'SyncRefusal($code, $statusCode): $message';
}
