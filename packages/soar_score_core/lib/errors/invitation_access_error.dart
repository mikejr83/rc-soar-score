/// An invitation link or guest session was refused.
///
/// One class for every reason (unknown, replaced, revoked, expired, wrong
/// contest, forged), so the answer never tells an attacker which of them it
/// was (`plan/architecture-requirements/self-scoring-invites.md`, delivery
/// and audit item 5).
class InvitationAccessError extends Error {
  InvitationAccessError._(this.code, this.message);

  /// The link did not open an invitation. Answered 404.
  InvitationAccessError.invalidLink()
    : this._('invalid_invitation', 'This link is not valid.');

  /// The guest session no longer authorizes the request. Answered 401.
  InvitationAccessError.invalidSession()
    : this._('session_invalid', 'This session is not valid.');

  final String code;
  final String message;

  @override
  String toString() => 'InvitationAccessError($code)';
}
