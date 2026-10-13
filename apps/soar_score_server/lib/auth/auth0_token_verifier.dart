import 'dart:convert';

import 'package:jose/jose.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';

/// Verifies Auth0 access tokens against the tenant's public signing keys.
///
/// A token is accepted when its RS256 signature matches a key in the tenant's
/// JWKS, it has not expired, its `iss` is `https://<domain>/` and its `aud`
/// includes [audience]. No client secret is involved.
class Auth0TokenVerifier implements TokenVerifier {
  /// Verifies against the keys published by the tenant at [domain], for
  /// example `tenant.us.auth0.com` (no scheme).
  Auth0TokenVerifier({required String domain, required this.audience})
    : issuer = 'https://$domain/',
      _keys = JsonWebKeyStore()
        ..addKeySetUrl(Uri.https(domain, '/.well-known/jwks.json'));

  /// Verifies against [keys], for tests that sign their own tokens.
  Auth0TokenVerifier.withKeys({
    required String domain,
    required this.audience,
    required JsonWebKeySet keys,
  }) : issuer = 'https://$domain/',
       _keys = JsonWebKeyStore()..addKeySet(keys);

  /// The `iss` every accepted token carries.
  final String issuer;

  /// The API identifier every accepted token is issued for.
  final String audience;

  final JsonWebKeyStore _keys;

  static const _algorithm = 'RS256';

  @override
  Future<VerifiedToken> verify(String token) async {
    _requireAlgorithm(token);

    final JsonWebToken jwt;
    try {
      jwt = await JsonWebToken.decodeAndVerify(
        token,
        _keys,
        allowedArguments: const [_algorithm],
      );
    } on Object catch (e) {
      throw TokenRejectedException('signature or format check failed: $e');
    }

    final claims = jwt.claims.toJson();
    final expiry = claims['exp'];
    if (expiry is! num) {
      throw const TokenRejectedException('no exp claim');
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (expiry * 1000).toInt(),
      isUtc: true,
    );
    if (!DateTime.now().toUtc().isBefore(expiresAt)) {
      throw const TokenRejectedException('expired');
    }
    final notBefore = claims['nbf'];
    if (notBefore is num &&
        DateTime.now().toUtc().isBefore(
          DateTime.fromMillisecondsSinceEpoch(
            (notBefore * 1000).toInt(),
            isUtc: true,
          ),
        )) {
      throw const TokenRejectedException('not yet valid');
    }
    if (claims['iss'] != issuer) {
      throw TokenRejectedException('issuer is ${claims['iss']}');
    }
    final aud = claims['aud'];
    final audiences = aud is List ? aud : [aud];
    if (!audiences.contains(audience)) {
      throw const TokenRejectedException('audience does not match');
    }
    final subject = claims['sub'];
    if (subject is! String || subject.isEmpty) {
      throw const TokenRejectedException('no sub claim');
    }
    return VerifiedToken(issuer: issuer, subject: subject);
  }

  /// Refuses any header that does not say RS256 before a key is looked up, so
  /// `none` and HMAC tokens never reach the signature check.
  void _requireAlgorithm(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const TokenRejectedException('not a signed JWT');
    }
    try {
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );
      if (header is Map && header['alg'] == _algorithm) return;
      throw TokenRejectedException('algorithm is ${header['alg']}');
    } on TokenRejectedException {
      rethrow;
    } on Object {
      throw const TokenRejectedException('unreadable header');
    }
  }
}
