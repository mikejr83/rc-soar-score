/// Whether the embedded server may serve the data of the account this
/// installation was claimed into.
enum ProfileAccess {
  /// Nobody is signed in, the signed-in user is the one who claimed the data,
  /// or nothing has been claimed yet.
  verified,

  /// Somebody is signed in whose identity does not match the claim (or is
  /// unknown), and the service has not yet said whether the data is theirs.
  /// Offline this lasts until they sign out or the service answers.
  unverified,

  /// The service refused the signed-in account's claim: the data is another
  /// account's.
  mismatched;

  /// The error code of a request refused in this state.
  String get errorCode => switch (this) {
    verified => 'profile_verified',
    unverified => profileUnverifiedCode,
    mismatched => profileAccountMismatchCode,
  };

  /// Text fit to show the director.
  String get message => switch (this) {
    verified => 'The profile is available.',
    unverified =>
      "This computer's data has not been checked against the account you "
          'are signed in as. Connect to the service, or sign out to work '
          'with the data stored here.',
    mismatched =>
      "This computer holds another account's data. Sign in as that "
          'account, or use a different Windows user.',
  };
}

/// The error code of a request refused while the signed-in account is not the
/// one this computer's data belongs to.
const String profileAccountMismatchCode = 'profile_account_mismatch';

/// The error code of a request refused while the signed-in account has not
/// yet been checked against the data's owner.
const String profileUnverifiedCode = 'profile_unverified';

/// An operation was refused because the profile's data may not be served to
/// the signed-in account (see [ProfileAccess]). Nothing was read or written.
class ProfileUnavailableError implements Exception {
  const ProfileUnavailableError(this.access);

  final ProfileAccess access;

  String get code => access.errorCode;

  String get message => access.message;

  @override
  String toString() => 'ProfileUnavailableError($code): $message';
}
