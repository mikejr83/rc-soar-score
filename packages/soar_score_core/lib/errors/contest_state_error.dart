/// A change was refused because of the contest's current state, not because
/// the request was malformed.
///
/// [code] is a short stable name callers can switch on.
class ContestStateError extends Error {
  ContestStateError(this.code, this.message);

  /// The action is not allowed from the contest's lifecycle state or control
  /// value.
  ContestStateError.invalidTransition(String message)
    : this('invalid_transition', message);

  final String code;
  final String message;

  @override
  String toString() => 'ContestStateError($code): $message';
}
