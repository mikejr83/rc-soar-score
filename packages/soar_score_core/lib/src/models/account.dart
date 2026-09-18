/// Represents an authenticated account that can own contests.
///
/// Accounts store identity data and are linked to participant profiles
/// through explicit account-participant links.
class Account {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String identityProviderSubject;

  Account({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.identityProviderSubject,
  });
}