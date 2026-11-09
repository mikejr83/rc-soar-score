import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';

/// A service that refuses every link and session, to test the HTTP side:
/// the sign-in carve-out, the rate limit and the 401/404 answers. What the
/// service does with real data is covered over the real repositories in
/// `soar_score_server`'s `invitations_slice_test.dart`.
class _RefusingService implements core.InvitationService {
  @override
  Future<core.InvitationResolution> resolve(String credential) async =>
      throw core.InvitationAccessError.invalidLink();

  @override
  Future<core.ParticipantAccess> authorize(
    String sessionToken, {
    bool write = false,
  }) async => throw core.InvitationAccessError.invalidSession();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  cookieTests();
  var now = DateTime.utc(2026, 11, 5, 12);
  Handler build({core.InvitationService? service}) => buildApiHandler(
    name: 'soar_score_server',
    displayName: 'Soar Score API Server',
    version: '0.1.0',
    repository: StubRepository(StubContestRepository()),
    // Everything else under /api/v1 is refused, so an answer other than 401
    // from the participant routes shows they sit outside the sign-in.
    authMiddleware: (inner) =>
        (request) => Response(401, body: 'account sign-in'),
    invitations: service,
    invitationRateLimiter: FailureRateLimiter(maxFailures: 2, clock: () => now),
  );

  Future<Response> send(
    Handler handler,
    String method,
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) async => handler(
    Request(
      method,
      Uri.parse('http://localhost/api/v1/self-scoring$path'),
      body: body == null ? null : jsonEncode(body),
      headers: headers,
    ),
  );

  Future<String> codeOf(Response response) async =>
      ((jsonDecode(await response.readAsString())
                  as Map<String, Object?>)['error']!
              as Map<String, Object?>)['code']!
          as String;

  group('without an invitation service', () {
    test('every participant route answers 409', () async {
      final handler = build();
      final resolve = await send(
        handler,
        'POST',
        '/invitations/resolve',
        body: {'credential': 'x'},
      );
      expect(resolve.statusCode, 409);
      expect(await codeOf(resolve), 'invitations_not_available');
      final session = await send(handler, 'GET', '/session');
      expect(session.statusCode, 409);
    });
  });

  group('resolve', () {
    test('a refused link is a 404 invalid_invitation', () async {
      final response = await send(
        build(service: _RefusingService()),
        'POST',
        '/invitations/resolve',
        body: {'credential': 'nope'},
      );
      expect(response.statusCode, 404);
      expect(await codeOf(response), 'invalid_invitation');
    });

    test('a body without a credential is a 400', () async {
      final response = await send(
        build(service: _RefusingService()),
        'POST',
        '/invitations/resolve',
        body: {'device_id': 'd'},
      );
      expect(response.statusCode, 400);
    });

    test('too many failures from one address are a 429 with a wait', () async {
      final handler = build(service: _RefusingService());
      Future<Response> attempt(String ip) => send(
        handler,
        'POST',
        '/invitations/resolve',
        body: {'credential': 'nope'},
        headers: {'fly-client-ip': ip},
      );
      expect((await attempt('1.1.1.1')).statusCode, 404);
      expect((await attempt('1.1.1.1')).statusCode, 404);
      final blocked = await attempt('1.1.1.1');
      expect(blocked.statusCode, 429);
      expect(await codeOf(blocked), 'rate_limited');
      expect(int.parse(blocked.headers['retry-after']!), greaterThan(0));
      // Another address is unaffected, and the window ends.
      expect((await attempt('2.2.2.2')).statusCode, 404);
      now = now.add(const Duration(minutes: 11));
      expect((await attempt('1.1.1.1')).statusCode, 404);
    });
  });

  group('session', () {
    test('needs a bearer token', () async {
      final response = await send(
        build(service: _RefusingService()),
        'GET',
        '/session',
      );
      expect(response.statusCode, 401);
      expect(await codeOf(response), 'session_invalid');
    });

    test('a token the service refuses is the same 401', () async {
      final response = await send(
        build(service: _RefusingService()),
        'GET',
        '/session',
        headers: {'authorization': 'Bearer abc'},
      );
      expect(response.statusCode, 401);
      expect(await codeOf(response), 'session_invalid');
    });
  });

  test('a participant is not a director principal', () {
    final request = Request('GET', Uri.parse('http://localhost/'));
    expect(participantPrincipalOf(request), isNull);
    expect(() => requireParticipant(request), throwsStateError);
    expect(() => requirePrincipal(request), throwsStateError);
  });
}

void cookieTests() {
  group('guest session cookie', () {
    test('is read out of a Cookie header', () {
      expect(
        guestSessionFromCookieHeader('a=1; __Host-soar_guest=tok.en; b=2'),
        'tok.en',
      );
      expect(guestSessionFromCookieHeader('a=1'), isNull);
      expect(guestSessionFromCookieHeader('__Host-soar_guest='), isNull);
      expect(guestSessionFromCookieHeader('x__Host-soar_guest=1'), isNull);
      expect(guestSessionFromCookieHeader(null), isNull);
    });

    test('a cookie write needs the header and an allowed origin', () {
      const allowed = {'https://score.rcsoarscore.com'};
      Request post(Map<String, String> headers) =>
          Request('POST', Uri.parse('http://localhost/x'), headers: headers);
      expect(requireCookieWriteIsSameSite(post({}), allowed)?.statusCode, 403);
      expect(
        requireCookieWriteIsSameSite(
          post({'x-requested-with': 'a', 'origin': 'https://evil.example'}),
          allowed,
        )?.statusCode,
        403,
      );
      expect(
        requireCookieWriteIsSameSite(
          post({
            'x-requested-with': 'a',
            'origin': 'https://score.rcsoarscore.com',
          }),
          allowed,
        ),
        isNull,
      );
    });
  });
}
