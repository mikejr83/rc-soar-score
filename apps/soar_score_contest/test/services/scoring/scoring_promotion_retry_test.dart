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
  const flight = {'time_flown': 540, 'launch_height': 120};

  group('a failed Confirm is bound to what it asked for', () {
    test('another director confirms first: the failure goes, Retry sends '
        'nothing', () async {
      final server = ScoringServer()..seedAutomaticScore(first, flight);
      server.promoteFailures[first] = (503, 'contest_busy');
      final c = await _open(server);

      expect(await c.confirmAutomatic(_row(c, 1)), isFalse);
      expect(c.saveOf(first).kind, RowSaveKind.failed);
      expect(c.saveOf(first).target?.confirm, isTrue);
      final requests = server.promoteRequests;

      // Meanwhile the score is confirmed elsewhere and a sync arrives.
      server.promoteFailures.clear();
      server.confirmAsDirector(first);
      await c.refreshAfterSync();

      expect(_row(c, 1).isAutomaticUnconfirmed, isFalse);
      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(await c.retryPromotion(_row(c, 1)), isFalse);
      expect(server.promoteRequests, requests);
    });

    test('a failure that no longer matches is dropped, not retried', () async {
      final server = ScoringServer()..seedAutomaticScore(first, flight);
      server.promoteFailures[first] = (503, 'contest_busy');
      final c = await _open(server);
      await c.confirmAutomatic(_row(c, 1));
      final requests = server.promoteRequests;

      // A correction arrives, but no sync pass has run yet.
      server.promoteFailures.clear();
      server.seedCorrection(first, {'time_flown': 500}, 'Timer misread');
      await c.refresh();
      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(await c.retryPromotion(_row(c, 1)), isFalse);
      expect(server.promoteRequests, requests);
      expect(server.confirmedAssignments, isEmpty);
    });

    test('a failure that still matches is retried as a confirm', () async {
      final server = ScoringServer()..seedAutomaticScore(first, flight);
      server.promoteFailures[first] = (503, 'contest_busy');
      final c = await _open(server);
      await c.confirmAutomatic(_row(c, 1));

      server.promoteFailures.clear();
      await c.refreshAfterSync();
      expect(c.saveOf(first).kind, RowSaveKind.failed);
      expect(await c.retryPromotion(_row(c, 1)), isTrue);
      expect(server.confirmedAssignments, [first]);
    });
  });

  group('a failed Mark official is bound to its submission', () {
    test('a new pilot entry replaces it: the failure goes and Retry does not '
        'mark the new entry', () async {
      final server = ScoringServer()..seedPendingSubmission(first, flight);
      server.promoteFailures[first] = (503, 'contest_busy');
      final c = await _open(server);

      expect(await c.markOfficial(_row(c, 1)), isFalse);
      expect(c.saveOf(first).target?.confirm, isFalse);
      final requests = server.promoteRequests;

      server.promoteFailures.clear();
      server.seedPendingSubmission(first, {'time_flown': 500});
      await c.refreshAfterSync();

      // No banner is left, so there is no Retry to press for the old entry.
      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(server.promoteRequests, requests);
    });
  });
}
