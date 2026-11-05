import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final codec = InvitationCodec.fromText('x' * 40);
  final id = Id.create();

  test('refuses a short secret', () {
    expect(() => InvitationCodec.fromText('short'), throwsArgumentError);
  });

  test('a credential is stable, names its invitation and is long', () {
    final credential = codec.credentialFor(id, 1);
    expect(codec.credentialFor(id, 1), credential);
    expect(codec.idOf(credential), id);
    // 24 tag bytes is 32 base64url characters: 192 bits.
    expect(credential.split('.').last, hasLength(32));
  });

  test('revision, id and secret each change the credential', () {
    final base = codec.credentialFor(id, 1);
    expect(codec.credentialFor(id, 2), isNot(base));
    expect(codec.credentialFor(Id.create(), 1), isNot(base));
    expect(
      InvitationCodec.fromText('y' * 40).credentialFor(id, 1),
      isNot(base),
    );
  });

  test('protect hides the credential and matches only it', () {
    final credential = codec.credentialFor(id, 1);
    final protected = codec.protect(credential);
    expect(protected.value, isNot(contains(credential)));
    expect(codec.matches(credential, protected), isTrue);
    expect(codec.matches('${credential}0', protected), isFalse);
    expect(codec.matches(codec.credentialFor(id, 2), protected), isFalse);
  });

  test('idOf rejects what is not shaped like a credential', () {
    expect(codec.idOf('nonsense'), isNull);
    expect(codec.idOf('not-an-id.tag'), isNull);
    expect(codec.idOf(''), isNull);
  });

  group('sessions', () {
    test('round trip', () {
      final token = codec.signSession({'a': 1, 'b': 'two'});
      expect(codec.verifySession(token), {'a': 1, 'b': 'two'});
    });

    test('a changed body, signature or key fails', () {
      final token = codec.signSession({'a': 1});
      final dot = token.indexOf('.');
      final other = codec.signSession({'a': 2});
      expect(
        codec.verifySession(
          '${other.substring(0, other.indexOf('.'))}'
          '${token.substring(dot)}',
        ),
        isNull,
      );
      expect(codec.verifySession('${token}x'), isNull);
      expect(codec.verifySession('$token.x'), isNull);
      expect(codec.verifySession('nodot'), isNull);
      expect(InvitationCodec.fromText('y' * 40).verifySession(token), isNull);
    });

    test('a credential is not a session', () {
      expect(codec.verifySession(codec.credentialFor(id, 1)), isNull);
    });
  });
}
