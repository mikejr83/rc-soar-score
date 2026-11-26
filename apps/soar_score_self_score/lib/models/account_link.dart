/// A pilot the signed-in account is linked to (#654): the profile a contest
/// director typed, which the account reaches through confirmed links.
class AccountLink {
  const AccountLink({required this.id, required this.pilotName});

  /// The id to end the link with.
  final String id;

  /// The name as the contest director typed it.
  final String pilotName;
}
