import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';
import 'matrix_test_support.dart';

const _drawId = '019c0000-0000-7000-8000-000000000501';
const _otherId = '019c0000-0000-7000-8000-000000000502';

void main() {
  final owner = Id.parse('019c0000-0000-7000-8000-000000000001');
  final path = '/contests/$matrixTestContestId/matrix/draws';

  test('a running draw reports its progress and can be cancelled', () async {
    final runner = HeldDrawRunner();
    final api = HandlerHarness(owner, drawRunner: runner);
    await drawnContest(api, skipDraw: true);

    final drawing = api.send(
      'POST',
      path,
      body: {'id': _drawId, 'rounds': 3, 'groups_per_round': 2},
    );
    await runner.reported.future;

    final status = await api.send('GET', '$path/$_drawId');
    expect(status.statusCode, 200);
    expect(await api.json(status), {
      'id': _drawId,
      'state': 'running',
      'percent': 40,
      'seed': 2,
      'seed_count': 3,
    });

    final cancelled = await api.send('DELETE', '$path/$_drawId');
    expect(cancelled.statusCode, 200);

    final response = await drawing;
    expect(response.statusCode, 409);
    expect((await api.errorOf(response))['code'], 'draw_cancelled');
    expect(
      (await api.json(await api.send('GET', '$path/$_drawId')))['state'],
      'cancelled',
    );

    // Nothing was stored: no matrix, the contest can still be drawn.
    final matrix = await api.json(
      await api.send('GET', '/contests/$matrixTestContestId/matrix'),
    );
    expect(matrix['revision'], isNull);
    expect(api.repository.scorePlaceholders.stored, isEmpty);
    final contest = await api.json(
      await api.send('GET', '/contests/$matrixTestContestId'),
    );
    expect(contest['lifecycle_state'], 'Configuring');

    // The same draw can be sent again and completes.
    runner.release.complete();
    final again = await api.send(
      'POST',
      path,
      body: {'id': _drawId, 'rounds': 3, 'groups_per_round': 2},
    );
    expect(again.statusCode, 201);
    expect(
      (await api.json(await api.send('GET', '$path/$_drawId')))['state'],
      'completed',
    );
  });

  test('a draw nobody started is a 404 to look up or cancel', () async {
    final api = HandlerHarness(owner);
    await drawnContest(api, skipDraw: true);

    expect((await api.send('GET', '$path/$_otherId')).statusCode, 404);
    expect((await api.send('DELETE', '$path/$_otherId')).statusCode, 404);
  });

  test('cancelling a finished draw leaves the matrix', () async {
    final api = HandlerHarness(owner);
    await drawnContest(api, skipDraw: true);
    final drawn = await api.send(
      'POST',
      path,
      body: {'id': _drawId, 'rounds': 3, 'groups_per_round': 2},
    );
    expect(drawn.statusCode, 201);

    final cancel = await api.send('DELETE', '$path/$_drawId');

    expect(cancel.statusCode, 200);
    expect((await api.json(cancel))['state'], 'completed');
    final matrix = await api.json(
      await api.send('GET', '/contests/$matrixTestContestId/matrix'),
    );
    expect(matrix['revision'], isNotNull);
  });

  test('another contest cannot read or cancel a draw', () async {
    final runner = HeldDrawRunner();
    final api = HandlerHarness(owner, drawRunner: runner);
    await drawnContest(api, skipDraw: true);
    const elsewhere = '019c0000-0000-7000-8000-000000000099';
    final drawing = api.send(
      'POST',
      path,
      body: {'id': _drawId, 'rounds': 3, 'groups_per_round': 2},
    );
    await runner.reported.future;

    final other = '/contests/$elsewhere/matrix/draws/$_drawId';
    expect((await api.send('GET', other)).statusCode, 404);
    expect((await api.send('DELETE', other)).statusCode, 404);

    // The draw itself was not cancelled.
    expect(
      (await api.json(await api.send('GET', '$path/$_drawId')))['state'],
      'running',
    );
    runner.release.complete();
    expect((await drawing).statusCode, 201);
  });

  test('cancelling a redraw leaves the existing matrix intact', () async {
    final runner = HeldDrawRunner()..hold = false;
    final api = HandlerHarness(owner, drawRunner: runner);
    await drawnContest(api);
    Future<Map<String, Object?>> matrix() async => api.json(
      await api.send('GET', '/contests/$matrixTestContestId/matrix'),
    );
    final before = await matrix();

    runner.hold = true;
    final redrawing = api.send(
      'POST',
      '/contests/$matrixTestContestId/matrix/redraws',
      body: {
        'id': _otherId,
        'first_round': 4,
        'rounds': 2,
        'groups_per_round': 2,
        'base_matrix_revision': 1,
      },
    );
    await runner.reported.future;
    expect((await api.send('DELETE', '$path/$_otherId')).statusCode, 200);

    final response = await redrawing;
    expect(response.statusCode, 409);
    expect((await api.errorOf(response))['code'], 'draw_cancelled');
    final after = await matrix();
    expect(after['revision'], before['revision']);
    expect(after['rounds'], before['rounds']);
    expect(after['assignments'], before['assignments']);
  });
}
