/// A request to link, confirm or end a participant-to-account link was
/// refused because of what is stored, not because the request was malformed.
///
/// [code] is a short stable name callers can switch on. The messages say
/// nothing about the other account, profile or director involved, so a
/// refusal never teaches the caller anything beyond the code.
class ParticipantLinkError extends Error {
  ParticipantLinkError(this.code, this.message);

  /// The profile already has a Confirmed link to another account.
  ParticipantLinkError.alreadyLinked()
    : this('already_linked', 'This participant is already linked.');

  /// No such link or candidate for this account: it does not exist, is not
  /// the caller's, or is not (or no longer) eligible. One answer for every
  /// reason.
  ParticipantLinkError.linkNotFound()
    : this('link_not_found', 'This link was not found.');

  /// A director tried to link a profile another director owns.
  ParticipantLinkError.profileNotOwned()
    : this('profile_not_owned', 'This participant is not yours.');

  final String code;
  final String message;

  @override
  String toString() => 'ParticipantLinkError($code)';
}
