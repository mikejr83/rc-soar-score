import 'dart:convert';

import 'package:jose/jose.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_server/auth/auth0_token_verifier.dart';
import 'package:test/test.dart';

void main() {
  const domain = 'tenant.us.auth0.com';
  const audience = 'https://soar-score.com/server';
  const issuer = 'https://$domain/';

  final signingKey = JsonWebKey.generate('RS256');
  final otherKey = JsonWebKey.generate('RS256');
  final verifier = Auth0TokenVerifier.withKeys(
    domain: domain,
    audience: audience,
    keys: JsonWebKeySet.fromKeys([signingKey]),
  );

  int inSeconds(Duration offset) =>
      DateTime.now().add(offset).millisecondsSinceEpoch ~/ 1000;

  Map<String, Object?> claims({
    Object? iss = issuer,
    Object? aud = audience,
    Object? sub = 'auth0|abc',
    Object? exp,
    bool omitExp = false,
  }) => {
    'iss': iss,
    'aud': aud,
    'sub': sub,
    if (!omitExp) 'exp': exp ?? inSeconds(const Duration(hours: 1)),
  };

  Future<String> sign(
    Map<String, Object?> payload, {
    JsonWebKey? key,
    String algorithm = 'RS256',
  }) async {
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = payload
      ..addRecipient(key ?? signingKey, algorithm: algorithm);
    return builder.build().toCompactSerialization();
  }

  Future<void> expectRejected(String token, [String? reasonPart]) =>
      expectLater(
        verifier.verify(token),
        throwsA(
          isA<TokenRejectedException>().having(
            (e) => e.reason,
            'reason',
            contains(reasonPart ?? ''),
          ),
        ),
      );

  test('accepts a valid token and returns issuer and subject', () async {
    final verified = await verifier.verify(await sign(claims()));

    expect(verified.issuer, issuer);
    expect(verified.subject, 'auth0|abc');
  });

  test('accepts an audience list that includes the API', () async {
    final token = await sign(
      claims(aud: ['https://$domain/userinfo', audience]),
    );

    expect((await verifier.verify(token)).subject, 'auth0|abc');
  });

  test('rejects an expired token', () async {
    final token = await sign(
      claims(exp: inSeconds(const Duration(minutes: -1))),
    );

    await expectRejected(token, 'expired');
  });

  test('rejects a token with no expiry', () async {
    await expectRejected(await sign(claims(omitExp: true)), 'exp');
  });

  test('rejects another issuer', () async {
    await expectRejected(
      await sign(claims(iss: 'https://evil.example/')),
      'issuer',
    );
  });

  test('rejects another audience', () async {
    await expectRejected(
      await sign(claims(aud: 'https://other.example/api')),
      'audience',
    );
  });

  test('rejects a token with no subject', () async {
    await expectRejected(await sign(claims(sub: null)), 'sub');
  });

  test('rejects a signature from an unknown key', () async {
    await expectRejected(await sign(claims(), key: otherKey));
  });

  test('rejects an unsigned token', () async {
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final token = '${part({'alg': 'none', 'typ': 'JWT'})}.${part(claims())}.';

    await expectRejected(token, 'algorithm');
  });

  test('rejects a token signed with a symmetric algorithm', () async {
    final hmacKey = JsonWebKey.fromJson({
      'kty': 'oct',
      'k': base64Url.encode(List.filled(32, 7)).replaceAll('=', ''),
    });
    final token = await sign(claims(), key: hmacKey, algorithm: 'HS256');

    await expectRejected(token, 'algorithm');
  });

  test('rejects text that is not a JWT', () async {
    await expectRejected('not-a-token');
    await expectRejected('a.b.c');
  });
}
