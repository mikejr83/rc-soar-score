/// A claim of a Local account was refused because of what is already stored,
/// not because the request was malformed.
///
/// [code] is a short stable name callers can switch on.
class AccountClaimError extends Error {
  AccountClaimError(this.code, this.message);

  /// The Local account id was already claimed into a different account.
  AccountClaimError.alreadyClaimed()
    : this(
        'already_claimed',
        'This Local account was already claimed into another account.',
      );

  final String code;
  final String message;

  @override
  String toString() => 'AccountClaimError($code): $message';
}
