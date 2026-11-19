import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

import '../stubs/stub_contest_repository.dart';
import '../stubs/stub_repository.dart';

/// The route boundary: only a server that supplies a support handler serves
/// `POST /public/support`. The embedded instance (no handler) answers 404.
void main() {
  Handler build({Handler? supportHandler}) => buildApiHandler(
    name: 'test',
    displayName: 'Test',
    version: '0.0.0',
    repository: StubRepository(StubContestRepository()),
    supportHandler: supportHandler,
  );

  Request post() => Request(
    'POST',
    Uri.parse('http://localhost/public/support'),
    body: '{}',
  );

  test('the embedded router (no support handler) answers 404', () async {
    final response = await build()(post());
    expect(response.statusCode, 404);
  });

  test('a router with a support handler serves the route anonymously', () async {
    var reached = 0;
    final handler = build(
      supportHandler: (request) {
        reached++;
        return Response.ok('{"accepted":true}');
      },
    );
    final response = await handler(post());
    expect(response.statusCode, 200);
    expect(reached, 1);
  });
}
