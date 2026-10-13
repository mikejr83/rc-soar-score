/// The details of a signed-in person that the identity provider holds.
class UserProfile {
  const UserProfile({
    this.givenName,
    this.familyName,
    this.name,
    this.email,
    this.emailVerified = false,
  });

  final String? givenName;
  final String? familyName;

  /// The full display name, used when the given and family names are missing.
  final String? name;

  final String? email;
  final bool emailVerified;
}

/// Thrown by a [UserProfileSource] when the provider cannot be reached or
/// refuses the token.
class UserProfileUnavailableException implements Exception {
  const UserProfileUnavailableException(this.reason);

  final String reason;

  @override
  String toString() => 'UserProfileUnavailableException: $reason';
}

/// Fetches the profile behind an access token.
///
/// Access tokens carry no name or email, so the first sign-in asks the
/// identity provider once, to fill in the new account.
abstract interface class UserProfileSource {
  Future<UserProfile> fetch(String accessToken);
}
