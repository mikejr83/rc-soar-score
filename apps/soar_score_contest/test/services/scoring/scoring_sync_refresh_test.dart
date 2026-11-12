import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/row_save.dart';
import 'package:soar_score_contest/services/scoring/scoring_controller.dart';
import 'package:soar_score_contest/services/scoring/scoring_row.dart';

import '../../support/matrix_test_support.dart';
import '../../support/scoring_test_support.dart';

Future<ScoringController> _open(ScoringServer server) async {
  final c = ScoringController(
    client: ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      httpClient: MockClient(server.handle),
    ),
    contestId: contestId,
    round: 1,
    group: 1,
  );
  addTearDown(c.dispose);
  await c.load();
  return c;
}

ScoringRow _row(ScoringController c, int pilot) =>
    c.rows.firstWhere((r) => r.id == scoringAssignmentId(1, pilot));

void main() {
  final first = scoringAssignmentId(1, 1);
  final second = scoringAssignmentId(1, 2);
  const a = {'time_flown': 540, 'launch_height': 120};
  const b = {'time_flown': 500, 'launch_height': 130};

  test('an untouched row shows a submission that arrived by sync', () async {
    final server = ScoringServer();
    final c = await _open(server);
    expect(c.draftOf(_row(c, 1)).timeText, '');

    server.seedPendingSubmission(first, a);
    await c.refreshAfterSync();

    expect(c.draftOf(_row(c, 1)).timeText, '9:00');
    expect(c.round, 1);
    expect(c.group, 1);
  });

  test('a row with typed values keeps them and a changed official score marks '
      'it stale', () async {
    final server = ScoringServer()..seedScore(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');
    expect(c.isDirty(_row(c, 1)), isTrue);

    // Another operator corrected it meanwhile.
    server.seedCorrection(first, b, 'Corrected elsewhere');
    await c.refreshAfterSync();

    expect(c.draftOf(_row(c, 1)).heightText, '99');
    expect(c.saveOf(first).kind, RowSaveKind.stale);
    expect(c.theirsOf(first), isNotNull);
    expect(c.theirsOf(first)!['time_flown'], 500);
  });

  test(
    'a row with typed values and an unchanged score is left as typed',
    () async {
      final server = ScoringServer()..seedScore(first, a);
      final c = await _open(server);
      c.draftOf(_row(c, 1)).setHeight('99');

      server.seedPendingSubmission(second, b);
      await c.refreshAfterSync();

      expect(c.draftOf(_row(c, 1)).heightText, '99');
      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(c.draftOf(_row(c, 2)).timeText, '8:20');
    },
  );

  test('a failed read keeps the rows and says they may be behind', () async {
    final server = ScoringServer()..seedScore(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');

    server.readFailure = 503;
    await c.refreshAfterSync();

    // The notice with its Retry shows, since later checks will not repeat
    // the news that the read missed.
    expect(c.loadError, isNotNull);
    expect(c.data, isNotNull);
    expect(c.draftOf(_row(c, 1)).heightText, '99');

    server.readFailure = null;
    await c.refreshAfterSync();

    expect(c.loadError, isNull);
    expect(c.draftOf(_row(c, 1)).heightText, '99');
  });

  test(
    'retrying a failed read after a sync still marks a changed row stale',
    () async {
      final server = ScoringServer()..seedScore(first, a);
      final c = await _open(server);
      c.draftOf(_row(c, 1)).setHeight('99');

      server.readFailure = 503;
      await c.refreshAfterSync();
      expect(c.syncRefreshFailed, isTrue);

      // Another operator corrected the row while the read kept failing.
      server.seedCorrection(first, b, 'Corrected elsewhere');
      server.readFailure = null;
      await c.refreshAfterSync();

      expect(c.syncRefreshFailed, isFalse);
      expect(c.draftOf(_row(c, 1)).heightText, '99');
      expect(c.saveOf(first).kind, RowSaveKind.stale);
    },
  );

  test(
    'a save that answers while the read is out is not rolled back',
    () async {
      final server = ScoringServer();
      final gate = Completer<void>();
      var hold = false;
      final c = ScoringController(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient((request) async {
            // The answer is taken now, so it is the old slot when it arrives.
            final answer = await server.handle(request);
            if (hold && request.method == 'GET') await gate.future;
            return answer;
          }),
        ),
        contestId: contestId,
        round: 1,
        group: 1,
      );
      addTearDown(c.dispose);
      await c.load();
      final draft = c.draftOf(_row(c, 1));
      draft.setTime('9:00');
      draft.setHeight('120');

      hold = true;
      final refresh = c.refreshAfterSync();
      await Future<void>.delayed(Duration.zero);
      // Reads already out stay held; the save's own requests go through.
      hold = false;
      expect(await c.save(_row(c, 1)), isTrue);
      gate.complete();
      await refresh;

      expect(c.isDirty(_row(c, 1)), isFalse);
      expect(c.draftOf(_row(c, 1)).heightText, '120');
      expect(_row(c, 1).baseRevision, isNot(0));
    },
  );

  test('invalid typed text survives a refresh', () async {
    final server = ScoringServer();
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('abc');
    expect(c.isDirty(_row(c, 1)), isFalse, reason: 'parses to nothing');

    await c.refreshAfterSync();

    expect(c.draftOf(_row(c, 1)).heightText, 'abc');
  });

  test('a later sync is not lost behind a read that is still out', () async {
    final server = ScoringServer();
    final gate = Completer<void>();
    var hold = false;
    var reads = 0;
    final c = ScoringController(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient((request) async {
          final answer = await server.handle(request);
          if (request.method == 'GET') reads++;
          if (hold && request.method == 'GET') await gate.future;
          return answer;
        }),
      ),
      contestId: contestId,
      round: 1,
      group: 1,
    );
    addTearDown(c.dispose);
    await c.load();

    hold = true;
    final first = c.refreshAfterSync(); // reads the old scores
    await Future<void>.delayed(Duration.zero);
    hold = false;
    server.seedPendingSubmission(scoringAssignmentId(1, 1), a);
    final during = reads;
    final second = c.refreshAfterSync(); // joins behind the first
    await Future<void>.delayed(Duration.zero);
    expect(reads, during, reason: 'no second read runs beside the first');
    gate.complete();
    await Future.wait([first, second]);

    expect(c.draftOf(_row(c, 1)).timeText, '9:00');
  });

  test('a sync that arrives while the page loads is read afterwards', () async {
    final server = ScoringServer();
    final gate = Completer<void>();
    var hold = true;
    final c = ScoringController(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient((request) async {
          final answer = await server.handle(request);
          if (hold && request.method == 'GET') await gate.future;
          return answer;
        }),
      ),
      contestId: contestId,
      round: 1,
      group: 1,
    );
    addTearDown(c.dispose);
    final loading = c.load(); // reads the scores as they are now
    await Future<void>.delayed(Duration.zero);
    hold = false;
    server.seedPendingSubmission(scoringAssignmentId(1, 1), a);
    await c.refreshAfterSync();
    gate.complete();
    await loading;

    expect(c.draftOf(_row(c, 1)).timeText, '9:00');
  });
}
