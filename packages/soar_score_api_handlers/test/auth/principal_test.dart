import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';

void main() {
  final account = Id.create();
  final principal = Principal(accountId: account);
  final request = Request('GET', Uri.parse('http://localhost/x'));

  group('Principal', () {
    test('acts as a director by default', () {
      expect(principal.authority, Authority.director);
    });

    test('makes mutation metadata naming it as the actor', () {
      final time = DateTime.utc(2026, 10, 6, 12);

      final metadata = principal.mutationMetadata(
        clientMutationId: 'create-1',
        clientTime: time,
      );

      expect(metadata.clientMutationId, 'create-1');
      expect(metadata.actorId, account);
      expect(metadata.authority, Authority.director);
      expect(metadata.clientTime, time);
    });
  });

  group('request principal', () {
    test('is absent when no auth layer ran', () {
      expect(principalOf(request), isNull);
      expect(() => requirePrincipal(request), throwsStateError);
    });

    test('fixedPrincipal sets it for every request', () async {
      Principal? seen;
      final handler = fixedPrincipal(principal)((request) {
        seen = requirePrincipal(request);
        return Response.ok('x');
      });

      expect((await handler(request)).statusCode, 200);
      expect(seen, principal);
      expect(principalOf(request), isNull);
    });

    test('fixedPrincipal plugs into buildApiHandler', () async {
      final handler = buildApiHandler(
        name: 'embedded',
        displayName: 'Embedded',
        version: '0.0.0',
        repository: StubRepository(StubContestRepository()),
        authMiddleware: fixedPrincipal(principal),
      );

      final ping = await handler(
        Request('GET', Uri.parse('http://localhost/api/v1/ping')),
      );
      expect(ping.statusCode, 200);
    });
  });
}
