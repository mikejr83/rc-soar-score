import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../models/id.dart';
import '../../models/shared/protected_credential.dart';

/// Makes and checks invitation credentials, and signs guest sessions.
///
/// A credential is `<invitation id>.<tag>`, where the tag is 192 bits of an
/// HMAC-SHA256 under a server secret over the invitation's id and revision.
/// Nobody without the secret can make a tag, so one participant cannot guess
/// another's link, and the invitation id (a random UUIDv7) says nothing
/// about the participant, contest or account. Because the server can
/// recompute the credential, the director can retrieve the same link to
/// resend or print it ("resend sends the same link"), while the database
/// holds only a hash ([protect]) that is never logged.
///
/// Rotating the secret ends every link and session. Guest session tokens are
/// signed with a key derived separately from the secret, so a credential can
/// never be passed off as a session.
class InvitationCodec {
  /// [secret] must be at least 32 bytes.
  InvitationCodec(List<int> secret)
    : _credentialKey = _derive(secret, 'credential'),
      _sessionKey = _derive(secret, 'session');

  /// A codec for a secret given as text, as configured in the environment.
  factory InvitationCodec.fromText(String secret) =>
      InvitationCodec(utf8.encode(secret));

  static const minimumSecretBytes = 32;
  static const _tagBytes = 24;

  final List<int> _credentialKey;
  final List<int> _sessionKey;

  static List<int> _derive(List<int> secret, String purpose) {
    if (secret.length < minimumSecretBytes) {
      throw ArgumentError.value(
        secret.length,
        'secret',
        'must be at least $minimumSecretBytes bytes',
      );
    }
    return Hmac(
      sha256,
      secret,
    ).convert(utf8.encode('soar-score:invitation:$purpose')).bytes;
  }

  /// The credential of invitation [id] at [revision].
  String credentialFor(Id id, int revision) {
    final tag = Hmac(
      sha256,
      _credentialKey,
    ).convert(utf8.encode('${id.value}:$revision')).bytes.sublist(0, _tagBytes);
    return '${id.value}.${_b64(tag)}';
  }

  /// The invitation id named by [credential], or null when it is not shaped
  /// like one. A name is not proof: check it with [matches].
  Id? idOf(String credential) {
    final dot = credential.indexOf('.');
    if (dot < 0) return null;
    try {
      return Id.parse(credential.substring(0, dot));
    } on ArgumentError {
      return null;
    }
  }

  /// The form of [credential] kept in the database.
  ProtectedCredential protect(String credential) => ProtectedCredential(
    'sha256:${sha256.convert(utf8.encode('soar-score:credential:$credential'))}',
  );

  /// Whether [credential] is the one stored as [stored], compared in
  /// constant time.
  bool matches(String credential, ProtectedCredential stored) =>
      _constantTimeEquals(protect(credential).value, stored.value);

  /// Signs [payload] as a session token.
  String signSession(Map<String, Object?> payload) {
    final body = _b64(utf8.encode(jsonEncode(payload)));
    return '$body.${_b64(Hmac(sha256, _sessionKey).convert(utf8.encode(body)).bytes)}';
  }

  /// The payload of a token [signSession] signed, or null when [token] is
  /// malformed or its signature does not match.
  Map<String, Object?>? verifySession(String token) {
    final dot = token.indexOf('.');
    if (dot < 0 || token.indexOf('.', dot + 1) >= 0) return null;
    final body = token.substring(0, dot);
    final expected = _b64(
      Hmac(sha256, _sessionKey).convert(utf8.encode(body)).bytes,
    );
    if (!_constantTimeEquals(expected, token.substring(dot + 1))) return null;
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(_pad(body))));
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static String _pad(String s) => s.padRight((s.length + 3) ~/ 4 * 4, '=');

  static bool _constantTimeEquals(String a, String b) {
    final x = utf8.encode(a);
    final y = utf8.encode(b);
    var diff = x.length ^ y.length;
    for (var i = 0; i < x.length; i++) {
      diff |= x[i] ^ (i < y.length ? y[i] : 0);
    }
    return diff == 0;
  }
}
