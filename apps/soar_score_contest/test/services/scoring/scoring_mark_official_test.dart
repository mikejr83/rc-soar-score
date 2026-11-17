import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/row_save.dart';
import 'package:soar_score_contest/services/scoring/scoring_controller.dart';
import 'package:soar_score_contest/services/scoring/scoring_row.dart';

import '../../support/matrix_test_support.dart';
import '../../support/scoring_test_support.dart';

Future<ScoringController> _open(ScoringServer server, {int group = 1}) async {
  final c = ScoringController(
    client: ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      httpClient: MockClient(server.handle),
    ),
    contestId: contestId,
    round: 1,
    group: group,
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
  final third = scoringAssignmentId(1, 3);
  final fourth = scoringAssignmentId(1, 4);
  const a = {'time_flown': 540, 'launch_height': 120};
  const b = {'time_flown': 500, 'launch_height': 130};

  group('one row', () {
    test('adopts the pilot submission without sending components', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      final c = await _open(server);
      expect(c.markOfficialSkip(_row(c, 1)), isNull);

      expect(await c.markOfficial(_row(c, 1)), isTrue);

      expect(server.entries, isEmpty);
      // Only what the director saw is sent; the server adopts its own copy.
      expect(server.promotedBodies.single.keys.toSet(), {
        'source_attempt_id',
        'expected_score_revision',
      });
      expect(_row(c, 1).status, RowStatus.official);
      expect(_row(c, 1).hasPendingSubmission, isFalse);
      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(c.dirtyCount, 0);
    });

    test('is off for a row with nothing waiting or edits typed', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      final c = await _open(server);
      expect(c.markOfficialSkip(_row(c, 2)), MarkOfficialSkip.noSubmission);

      c.draftOf(_row(c, 1)).setHeight('99');
      expect(c.markOfficialSkip(_row(c, 1)), MarkOfficialSkip.edited);
      expect(await c.markOfficial(_row(c, 1)), isFalse);
      expect(server.promoteRequests, 0);

      c.revert(_row(c, 1));
      // Reverting hides the submission's values, not the submission.
      expect(c.markOfficialSkip(_row(c, 1)), isNull);
    });

    test(
      'a review does not stop a single row, only the group action',
      () async {
        final server = ScoringServer()
          ..seedPendingSubmission(first, a, inReview: true);
        final c = await _open(server);
        expect(c.markOfficialSkip(_row(c, 1)), isNull);
        expect(
          c.markOfficialSkip(_row(c, 1), forGroup: true),
          MarkOfficialSkip.inReview,
        );
      },
    );

    test('a changed submission shows the newer values to check', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      final c = await _open(server);
      server.seedPendingSubmission(first, b);

      expect(await c.markOfficial(_row(c, 1)), isFalse);

      final save = c.saveOf(first);
      expect(save.kind, RowSaveKind.refused);
      expect(save.promotion, isTrue);
      expect(save.changed, isTrue);
      expect(_row(c, 1).status, RowStatus.submitted);
      expect(c.draftOf(_row(c, 1)).timeText, '8:20');

      // Marking again adopts what the director now sees.
      expect(await c.markOfficial(_row(c, 1)), isTrue);
      expect(_row(c, 1).status, RowStatus.official);
    });

    test('a change that cannot be re-read offers Refresh', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      final c = await _open(server);
      server.seedPendingSubmission(first, b);
      server.readFailure = 500;

      expect(await c.markOfficial(_row(c, 1)), isFalse);

      final save = c.saveOf(first);
      expect(save.kind, RowSaveKind.failed);
      expect(save.networkProblem, isFalse);
      expect(save.message, isNull);
    });

    test('a change that already made it official leaves no banner', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      final c = await _open(server);
      server.officialDuringPromote.add(first);

      expect(await c.markOfficial(_row(c, 1)), isFalse);
      expect(server.promotedItems, hasLength(1));

      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(_row(c, 1).status, RowStatus.official);
    });

    test('a locked slot is refused with the server reason', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      server.promoteFailures[first] = (409, 'score_locked');
      final c = await _open(server);

      expect(await c.markOfficial(_row(c, 1)), isFalse);

      final save = c.saveOf(first);
      expect(save.kind, RowSaveKind.refused);
      expect(save.changed, isFalse);
      expect(save.message, contains('score_locked'));
    });

    test('a busy server (503) means try again, not a failed save', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      server.promoteFailures[first] = (503, 'contest_busy');
      final c = await _open(server);

      expect(await c.markOfficial(_row(c, 1)), isFalse);
      final save = c.saveOf(first);
      expect(save.kind, RowSaveKind.failed);
      expect(save.networkProblem, isTrue);
      expect(save.promotion, isTrue);
      expect(_row(c, 1).status, RowStatus.submitted);

      server.promoteFailures.clear();
      expect(await c.markOfficial(_row(c, 1)), isTrue);
    });

    test('an unreachable server keeps the row and offers a retry', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      final c = await _open(server);
      server.offlineOnEntry = true;

      expect(await c.markOfficial(_row(c, 1)), isFalse);
      expect(c.saveOf(first).networkProblem, isTrue);
    });
  });

  group('mark all', () {
    test('adopts every valid row in one request, row by row', () async {
      final server = ScoringServer()
        ..seedPendingSubmission(first, a)
        ..seedPendingSubmission(second, b);
      final c = await _open(server);
      c.draftOf(_row(c, 2)).setHeight('99');

      final summary = await c.markAllOfficial();

      expect(server.promoteRequests, 1);
      expect(summary.adopted, 1);
      expect(summary.skipped, {MarkOfficialSkip.edited: 1});
      expect(_row(c, 1).status, RowStatus.official);
      expect(_row(c, 2).status, RowStatus.submitted);
      expect(c.draftOf(_row(c, 2)).heightText, '99');
    });

    test('holds back a row with an open review', () async {
      final server = ScoringServer()
        ..seedPendingSubmission(third, a, inReview: true)
        ..seedPendingSubmission(fourth, b);
      final c = await _open(server, group: 2);

      final summary = await c.markAllOfficial();

      expect(summary.adopted, 1);
      expect(summary.skipped, {MarkOfficialSkip.inReview: 1});
      expect(_row(c, 3).hasPendingSubmission, isTrue);
      expect(_row(c, 4).status, RowStatus.official);
    });

    test(
      'a row that changed or was refused does not stop the others',
      () async {
        final server = ScoringServer()
          ..seedPendingSubmission(first, a)
          ..seedPendingSubmission(second, a);
        final c = await _open(server);
        server.seedPendingSubmission(first, b);
        server.promoteFailures[second] = (409, 'score_locked');

        final summary = await c.markAllOfficial();

        expect(summary.adopted, 0);
        expect(summary.changed, 1);
        expect(summary.refused, 1);
        expect(summary.retry, 0);
        expect(summary.nothingAccepted, isTrue);
        expect(c.saveOf(first).changed, isTrue);
        expect(c.saveOf(second).kind, RowSaveKind.refused);
        expect(c.draftOf(_row(c, 1)).timeText, '8:20');
      },
    );

    test(
      'a row another operator already made official leaves no banner',
      () async {
        final server = ScoringServer()
          ..seedPendingSubmission(first, a)
          ..seedPendingSubmission(second, a);
        final c = await _open(server);
        server.seedScore(first, b);

        final summary = await c.markAllOfficial();

        expect(summary.changed, 0);
        expect(summary.adopted, 1);
        expect(c.saveOf(first).kind, RowSaveKind.idle);
        expect(_row(c, 1).status, RowStatus.official);
      },
    );

    test('one busy row does not stop the rest', () async {
      final server = ScoringServer()
        ..seedPendingSubmission(first, a)
        ..seedPendingSubmission(second, a);
      server.promoteFailures[second] = (503, 'contest_busy');
      final c = await _open(server);

      final summary = await c.markAllOfficial();

      expect(summary.adopted, 1);
      expect(summary.retry, 1);
      expect(c.saveOf(second).networkProblem, isTrue);
    });

    test(
      'busy rows are counted to try again; nothing accepted says so',
      () async {
        final server = ScoringServer()..seedPendingSubmission(first, a);
        server.promoteFailures[first] = (503, 'contest_busy');
        final c = await _open(server);

        final summary = await c.markAllOfficial();

        expect(summary.retry, 1);
        expect(summary.nothingAccepted, isTrue);
        expect(c.saveOf(first).networkProblem, isTrue);
      },
    );

    test('with no valid row nothing is sent', () async {
      final server = ScoringServer()..seedPendingSubmission(first, a);
      final c = await _open(server);
      c.draftOf(_row(c, 1)).setHeight('99');

      final summary = await c.markAllOfficial();

      expect(server.promoteRequests, 0);
      expect(summary.nothingAccepted, isTrue);
      expect(summary.skipped, {MarkOfficialSkip.edited: 1});
    });
  });
}
