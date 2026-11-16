import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

const _contestId = '019c0000-0000-7000-8000-0000000000c1';

/// A denied publish whose body never finishes still reaches the client as a
/// 403 over a real connection: the response is delivered, not lost to the
/// connection closing under it.
void main() {
  test('the 403 reaches the client when the body stops short', () async {
    final owner = Id.parse('019c0000-0000-7000-8000-000000000001');
    final owned = HandlerHarness(owner, publishingEnabled: true);
    await owned.contests.save(
      Contest(
        id: Id.parse(_contestId),
        name: 'Spring Open',
        startDateTime: DateTime.utc(2026, 10, 17, 14),
        endDateTime: DateTime.utc(2026, 10, 18, 22),
        timezone: 'America/Denver',
        ownerAccountId: owner,
        createdAt: DateTime.utc(2026, 9),
        updatedAt: DateTime.utc(2026, 9),
      ),
      metadata: MutationMetadata(
        clientMutationId: 'seed',
        authority: Authority.director,
        clientTime: DateTime.utc(2026, 9),
      ),
    );
    final stranger = HandlerHarness(
      Id.parse('019c0000-0000-7000-8000-000000000002'),
      publishingEnabled: true,
      contests: owned.contests,
    );
    final server = await shelf_io.serve(stranger.handler, 'localhost', 0);
    addTearDown(() => server.close(force: true));

    final socket = await Socket.connect('localhost', server.port);
    addTearDown(socket.destroy);
    socket.write(
      'POST /api/v1/contests/$_contestId/publication HTTP/1.1\r\n'
      'Host: localhost\r\n'
      'Content-Type: application/json\r\n'
      'Content-Length: 200\r\n'
      '\r\n'
      '{"client_mutation_id":',
    );
    await socket.flush();

    final received = StringBuffer();
    final reply = Completer<void>();
    socket.listen(
      (data) {
        received.write(latin1.decode(data));
        if (received.toString().contains('\r\n') && !reply.isCompleted) {
          reply.complete();
        }
      },
      onDone: () {
        if (!reply.isCompleted) reply.complete();
      },
    );
    await reply.future.timeout(const Duration(seconds: 15));

    expect(received.toString(), startsWith('HTTP/1.1 403'));
  });
}
