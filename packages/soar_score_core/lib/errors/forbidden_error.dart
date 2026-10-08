/// The caller is known but may not do this.
///
/// [code] is a short stable name callers can switch on.
class ForbiddenError extends Error {
  ForbiddenError(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ForbiddenError($code): $message';
}
