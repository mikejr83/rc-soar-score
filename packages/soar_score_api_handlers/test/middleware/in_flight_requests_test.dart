import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

Request get _request => Request('GET', Uri.parse('http://localhost/x'));

void main() {
  test('drain waits for a running request and then refuses new ones', () async {
    final tracker = InFlightRequests();
    final release = Completer<void>();
    final handler = tracker.middleware((request) async {
      await release.future;
      return Response.ok('done');
    });

    final running = handler(_request);
    await Future<void>.delayed(Duration.zero);
    expect(tracker.count, 1);

    var drained = false;
    final draining = tracker.drain().then((ok) => drained = ok);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(drained, isFalse);

    // A request that arrives while draining is refused, not run.
    final refused = await handler(_request);
    expect(refused.statusCode, 503);
    expect(tracker.count, 1);

    release.complete();
    expect((await running).statusCode, 200);
    expect(await draining, isTrue);
    expect(tracker.count, 0);
  });

  test('drain gives up after the timeout', () async {
    final tracker = InFlightRequests();
    final never = Completer<void>();
    final handler = tracker.middleware((request) async {
      await never.future;
      return Response.ok('never');
    });
    unawaited(Future.sync(() => handler(_request)));
    await Future<void>.delayed(Duration.zero);
    expect(
      await tracker.drain(timeout: const Duration(milliseconds: 50)),
      isFalse,
    );
  });

  test('drain with nothing running returns at once', () async {
    expect(await InFlightRequests().drain(), isTrue);
  });
}
