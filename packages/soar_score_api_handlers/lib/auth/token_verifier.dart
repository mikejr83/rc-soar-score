/// What a verified access token says about who signed in.
///
/// The pair of [issuer] and [subject] is the key of an `AccountIdentity`;
/// neither means anything alone.
class VerifiedToken {
  const VerifiedToken({required this.issuer, required this.subject});

  /// The token's `iss` claim, for example `https://tenant.us.auth0.com/`.
  final String issuer;

  /// The token's `sub` claim.
  final String subject;
}

/// Thrown by a [TokenVerifier] when a token is not acceptable: malformed,
/// badly signed, expired, or issued for another issuer or audience.
///
/// [reason] is for the log; the response to the client only says the token is
/// invalid.
class TokenRejectedException implements Exception {
  const TokenRejectedException(this.reason);

  final String reason;

  @override
  String toString() => 'TokenRejectedException: $reason';
}

/// Checks a bearer token and says who it belongs to.
///
/// The hosted server's implementation verifies Auth0 access tokens against
/// the tenant's public keys; tests supply their own.
abstract interface class TokenVerifier {
  /// The identity in [token].
  ///
  /// Throws a [TokenRejectedException] when [token] is not acceptable.
  Future<VerifiedToken> verify(String token);
}
