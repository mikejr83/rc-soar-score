import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

import 'fake_account_repositories.dart';

class _Verifier implements TokenVerifier {
  String? lastToken;

  @override
  Future<VerifiedToken> verify(String token) async {
    lastToken = token;
    if (token != 'good') throw const TokenRejectedException('bad signature');
    return const VerifiedToken(issuer: 'https://t/', subject: 'sub-1');
  }
}

class _Profiles implements UserProfileSource {
  bool down = false;

  @override
  Future<UserProfile> fetch(String accessToken) async {
    if (down) throw const UserProfileUnavailableException('down');
    return const UserProfile(givenName: 'Ada', familyName: 'Lovelace');
  }
}

void main() {
  late _Verifier verifier;
  late _Profiles profiles;
  late FakeAccountRepository accounts;
  late Handler handler;
  Principal? seen;

  setUp(() {
    verifier = _Verifier();
    profiles = _Profiles();
    accounts = FakeAccountRepository();
    seen = null;
    final auth = bearerAuth(
      verifier: verifier,
      resolver: AccountPrincipalResolver(
        accounts: accounts,
        identities: FakeAccountIdentityRepository(),
        profiles: profiles,
      ),
    );
    handler = auth((request) {
      seen = principalOf(request);
      return Response.ok('ok');
    });
  });

  Future<Response> call([String? authorization]) => Future.value(
    handler(
      Request(
        'GET',
        Uri.parse('http://localhost/api/v1/x'),
        headers: {'authorization': ?authorization},
      ),
    ),
  );

  Future<String> errorCode(Response response) async =>
      ((jsonDecode(await response.readAsString()) as Map)['error']
              as Map)['code']
          as String;

  test('runs the route with the account principal for a good token', () async {
    final response = await call('Bearer good');

    expect(response.statusCode, 200);
    expect(seen, isNotNull);
    expect(accounts.byId.keys, contains(seen!.accountId.value));
    expect(verifier.lastToken, 'good');
  });

  test('accepts the scheme in any case', () async {
    expect((await call('bearer good')).statusCode, 200);
  });

  test('answers 401 when there is no Authorization header', () async {
    final response = await call();

    expect(response.statusCode, 401);
    expect(response.headers['www-authenticate'], 'Bearer');
    expect(await errorCode(response), 'unauthorized');
    expect(seen, isNull);
  });

  test('answers 401 for a header that is not a bearer token', () async {
    for (final header in ['Basic abc', 'Bearer', 'Bearer a b']) {
      expect((await call(header)).statusCode, 401, reason: header);
    }
  });

  test('answers 401 without leaking the reason for a rejected token', () async {
    final response = await call('Bearer bad');

    expect(response.statusCode, 401);
    expect(await response.readAsString(), isNot(contains('signature')));
    expect(seen, isNull);
  });

  test('answers 503 when a new sign-in cannot get its profile', () async {
    profiles.down = true;

    final response = await call('Bearer good');

    expect(response.statusCode, 503);
    expect(await errorCode(response), 'sign_in_unavailable');
    expect(seen, isNull);
  });
}
