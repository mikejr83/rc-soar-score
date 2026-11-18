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

  group('after a refusal as changed', () {
    test(
      'the row button sends the new submission, an old Retry cannot',
      () async {
        final server = ScoringServer()..seedPendingSubmission(first, flight);
        final c = await _open(server);
        final attemptA = _row(c, 1).slot!.pendingAttempt!.id.value;
        // The pilot enters again before the director's tap.
        server.seedPendingSubmission(first, {'time_flown': 500});

        expect(await c.promote(_row(c, 1)), isFalse);
        final attemptB = _row(c, 1).slot!.pendingAttempt!.id.value;
        expect(attemptB, isNot(attemptA));
        // The refusal keeps the request it was for.
        expect(c.saveOf(first).target?.attemptId, attemptA);
        final requests = server.promoteRequests;

        // The banner's Retry is for attempt A and sends nothing for B.
        expect(await c.retryPromotion(_row(c, 1)), isFalse);
        expect(server.promoteRequests, requests);

        // The row's own button sends B on its first click.
        expect(await c.promote(_row(c, 1)), isTrue);
        expect(server.promotedBodies.last['source_attempt_id'], attemptB);
        expect(_row(c, 1).status, RowStatus.official);
      },
    );

    test(
      'a failed reload keeps the request, so a later sync retires it',
      () async {
        final server = ScoringServer()..seedAutomaticScore(first, flight);
        server.promoteFailures[first] = (409, 'stale_revision');
        final c = await _open(server);
        server.readFailure = 503;

        expect(await c.confirmAutomatic(_row(c, 1)), isFalse);
        expect(c.saveOf(first).kind, RowSaveKind.failed);
        expect(c.saveOf(first).target?.confirm, isTrue);

        // Another director confirms and the next sync reads fine.
        server.readFailure = null;
        server.promoteFailures.clear();
        server.confirmAsDirector(first);
        await c.refreshAfterSync();

        expect(c.saveOf(first).kind, RowSaveKind.idle);
      },
    );
  });

  group('a lock or retirement ends a failed confirmation', () {
    test('the retirement of the pilot drops the Retry', () async {
      final server = ScoringServer()..seedAutomaticScore(first, flight);
      server.promoteFailures[first] = (503, 'contest_busy');
      final c = await _open(server);
      await c.confirmAutomatic(_row(c, 1));
      expect(c.saveOf(first).kind, RowSaveKind.failed);

      // Same attempt and revision, but the pilot retired from this round.
      server.promoteFailures.clear();
      server.matrixServer.retirements[1] = 1;
      await c.refreshAfterSync();

      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(await c.retryPromotion(_row(c, 1)), isFalse);
      expect(server.confirmedAssignments, isEmpty);
    });
  });

  test('a sync that ran during a failed Confirm retires it', () async {
    final server = ScoringServer()..seedAutomaticScore(first, flight);
    final hold = server.holdPromote = Completer<void>();
    final c = await _open(server);

    final sent = c.confirmAutomatic(_row(c, 1));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(server.promoteRequests, 1);

    // Another director confirms and a sync is applied: the row is busy, so
    // the page keeps its own copy.
    server.confirmAsDirector(first);
    await c.refreshAfterSync();
    expect(_row(c, 1).isAutomaticUnconfirmed, isTrue);

    // The local request then fails.
    server.promoteFailures[first] = (503, 'contest_busy');
    hold.complete();
    expect(await sent, isFalse);

    expect(_row(c, 1).isAutomaticUnconfirmed, isFalse);
    expect(c.saveOf(first).kind, RowSaveKind.idle);
    expect(await c.retryPromotion(_row(c, 1)), isFalse);
  });

  test('a failed catch-up read leaves Refresh, not a stale Retry', () async {
    final server = ScoringServer()..seedAutomaticScore(first, flight);
    final hold = server.holdPromote = Completer<void>();
    final c = await _open(server);

    final sent = c.confirmAutomatic(_row(c, 1));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    server.confirmAsDirector(first);
    await c.refreshAfterSync();

    // The request fails and the catch-up read fails too.
    server.promoteFailures[first] = (503, 'contest_busy');
    server.readFailure = 503;
    hold.complete();
    expect(await sent, isFalse);

    final save = c.saveOf(first);
    expect(save.kind, RowSaveKind.failed);
    expect(save.networkProblem, isFalse, reason: 'Refresh, not Retry');
    expect(save.target?.confirm, isTrue);

    // A later read settles it.
    server.readFailure = null;
    await c.refreshAfterSync();
    expect(c.saveOf(first).kind, RowSaveKind.idle);
    expect(_row(c, 1).isAutomaticUnconfirmed, isFalse);
  });

  test(
    'a failed Mark all after an overlapping sync drops settled rows',
    () async {
      final second = scoringAssignmentId(1, 2);
      final server = ScoringServer()
        ..seedPendingSubmission(first, flight)
        ..seedPendingSubmission(second, flight);
      final hold = server.holdPromote = Completer<void>();
      final c = await _open(server);

      final all = c.markAllOfficial();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(server.promoteRequests, 1);

      // Another director marks Ann official; the sync keeps the busy rows.
      server.seedScore(first, flight);
      await c.refreshAfterSync();

      // The batch then fails for both rows.
      server.promoteFailures[first] = (503, 'contest_busy');
      server.promoteFailures[second] = (503, 'contest_busy');
      hold.complete();
      final summary = await all;

      // Ann's failure is gone; Bo's remains and is the only one to retry.
      expect(c.saveOf(first).kind, RowSaveKind.idle);
      expect(c.saveOf(second).kind, RowSaveKind.failed);
      expect(summary.retry, 1);
    },
  );

  test('a Confirm in flight cannot be sent again', () async {
    final server = ScoringServer()..seedAutomaticScore(first, flight);
    final hold = server.holdPromote = Completer<void>();
    final c = await _open(server);

    final sent = c.confirmAutomatic(_row(c, 1));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(server.promoteRequests, 1);

    expect(c.confirmAutomaticSkip(_row(c, 1)), MarkOfficialSkip.busy);
    expect(await c.confirmAutomatic(_row(c, 1)), isFalse);
    expect(server.promoteRequests, 1, reason: 'no second request');

    hold.complete();
    await sent;
  });

  test('an older read arriving after a newer sync does not restore the '
      'old row', () async {
    final server = ScoringServer()..seedAutomaticScore(first, flight);
    final hold = server.holdPromote = Completer<void>();
    final c = await _open(server);

    final sent = c.confirmAutomatic(_row(c, 1));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    // A sync applied while the request is out makes the catch-up necessary.
    await c.refreshAfterSync();

    // The request fails; its catch-up read is held with the old answer.
    server.promoteFailures[first] = (503, 'contest_busy');
    hold.complete();
    final readHeld = server.holdNextScoresRead = Completer<void>();
    final done = sent;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // Meanwhile another director confirms and a newer sync is applied.
    server.confirmAsDirector(first);
    await c.refreshAfterSync();
    readHeld.complete();
    await done;

    expect(_row(c, 1).isAutomaticUnconfirmed, isFalse);
    expect(c.saveOf(first).kind, RowSaveKind.idle);
  });

  group('Mark all when the whole request fails', () {
    test('a failed catch-up read leaves Refresh for every row', () async {
      final second = scoringAssignmentId(1, 2);
      final server = ScoringServer()
        ..seedPendingSubmission(first, flight)
        ..seedPendingSubmission(second, flight);
      final hold = server.holdPromote = Completer<void>();
      final c = await _open(server);

      final all = c.markAllOfficial();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await c.refreshAfterSync();

      server.groupPromoteFailure = 503;
      server.readFailure = 503;
      hold.complete();
      await all;
      for (final pilot in [1, 2]) {
        expect(
          c.saveOf(scoringAssignmentId(1, pilot)).kind,
          RowSaveKind.failed,
        );
        expect(
          c.markOfficialSkip(_row(c, pilot)),
          MarkOfficialSkip.busy,
          reason: 'Refresh first, no new request',
        );
        expect(await c.retryPromotion(_row(c, pilot)), isFalse);
      }
      expect(server.promoteRequests, 1);

      server.readFailure = null;
      server.groupPromoteFailure = null;
      await c.refreshAfterSync();
      // Refresh worked: the rows wait plainly again, with no stale failure.
      for (final pilot in [1, 2]) {
        expect(c.saveOf(scoringAssignmentId(1, pilot)).kind, RowSaveKind.idle);
        expect(c.markOfficialSkip(_row(c, pilot)), isNull);
      }
    });
  });

  group('a row that is behind the service stays blocked', () {
    // Ann's and Bo's confirms are out when a sync is applied; both then
    // fail, Ann's catch-up read fails and Bo's works.
    Future<(ScoringController, ScoringServer)> annBehind() async {
      final second = scoringAssignmentId(1, 2);
      final server = ScoringServer()
        ..seedAutomaticScore(first, flight)
        ..seedAutomaticScore(second, flight);
      final c = await _open(server);
      final hold = server.holdPromote = Completer<void>();
      final ann = c.confirmAutomatic(_row(c, 1));
      final bo = c.confirmAutomatic(_row(c, 2));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await c.refreshAfterSync();
      server.promoteFailures[first] = (503, 'contest_busy');
      server.promoteFailures[second] = (503, 'contest_busy');
      server.failNextReads = 1;
      hold.complete();
      await Future.wait([ann, bo]);
      return (c, server);
    }

    test('a read of another row does not free it', () async {
      final (c, server) = await annBehind();
      expect(c.saveOf(first).needsRefresh, isTrue);
      expect(
        c.saveOf(scoringAssignmentId(1, 2)).needsRefresh,
        isFalse,
        reason: "Bo's own read worked",
      );

      final before = server.promoteRequests;
      expect(c.confirmAutomaticSkip(_row(c, 1)), MarkOfficialSkip.busy);
      expect(await c.retryPromotion(_row(c, 1)), isFalse);
      expect(await c.confirmAutomatic(_row(c, 1)), isFalse);
      expect(server.promoteRequests, before, reason: 'nothing sent for Ann');

      // A sync that applies a fresh slot of Ann frees her.
      await c.refreshAfterSync();
      expect(c.confirmAutomaticSkip(_row(c, 1)), isNull);
    });

    test('moving to another group and back keeps it', () async {
      final (c, server) = await annBehind();

      await c.open(2, 1);
      await c.open(1, 1);
      expect(c.confirmAutomaticSkip(_row(c, 1)), MarkOfficialSkip.busy);
      expect(c.saveOf(first).needsRefresh, isTrue, reason: 'still shows it');
      final before = server.promoteRequests;
      expect(await c.confirmAutomatic(_row(c, 1)), isFalse);
      expect(server.promoteRequests, before);
    });

    test('no second request while the catch-up read is out', () async {
      final server = ScoringServer()..seedAutomaticScore(first, flight);
      final hold = server.holdPromote = Completer<void>();
      final c = await _open(server);

      final sent = c.confirmAutomatic(_row(c, 1));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await c.refreshAfterSync();

      // The request fails and its catch-up read is held.
      server.promoteFailures[first] = (503, 'contest_busy');
      final read = server.holdNextScoresRead = Completer<void>();
      hold.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(server.promoteRequests, 1);

      expect(c.confirmAutomaticSkip(_row(c, 1)), MarkOfficialSkip.busy);
      expect(await c.retryPromotion(_row(c, 1)), isFalse);
      expect(await c.confirmAutomatic(_row(c, 1)), isFalse);
      expect(server.promoteRequests, 1, reason: 'no second request');

      read.complete();
      await sent;
      expect(c.confirmAutomaticSkip(_row(c, 1)), isNull);
    });
  });

  test('a manual refresh also outranks an older catch-up read', () async {
    final server = ScoringServer()..seedAutomaticScore(first, flight);
    final hold = server.holdPromote = Completer<void>();
    final c = await _open(server);

    final sent = c.confirmAutomatic(_row(c, 1));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await c.refreshAfterSync();

    // The request fails; its catch-up read is held with the old answer.
    server.promoteFailures[first] = (503, 'contest_busy');
    final read = server.holdNextScoresRead = Completer<void>();
    hold.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // Another director confirms; the page is refreshed by hand, which does
    // not count as a sync.
    server.confirmAsDirector(first);
    await c.refresh();
    expect(_row(c, 1).isAutomaticUnconfirmed, isFalse);

    read.complete();
    await sent;
    expect(_row(c, 1).isAutomaticUnconfirmed, isFalse);
    expect(c.saveOf(first).kind, RowSaveKind.idle);
  });

  test('Mark all blocks every affected row before its first read', () async {
    final second = scoringAssignmentId(1, 2);
    final server = ScoringServer()
      ..seedPendingSubmission(first, flight)
      ..seedPendingSubmission(second, flight);
    final hold = server.holdPromote = Completer<void>();
    final c = await _open(server);

    final all = c.markAllOfficial();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await c.refreshAfterSync();

    // Ann is refused as changed, Bo fails; Ann's read is held.
    server.promoteFailures[first] = (409, 'stale_revision');
    server.promoteFailures[second] = (503, 'contest_busy');
    final read = server.holdNextScoresRead = Completer<void>();
    hold.complete();
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final before = server.promoteRequests;

    expect(c.markOfficialSkip(_row(c, 2)), MarkOfficialSkip.busy);
    expect(await c.retryPromotion(_row(c, 2)), isFalse);
    expect(await c.markOfficial(_row(c, 2)), isFalse);
    final again = await c.markAllOfficial();
    expect(again.adopted, 0);
    expect(server.promoteRequests, before, reason: 'no write for Bo');

    read.complete();
    await all;
  });

  test('an older full refresh does not undo a newer targeted read', () async {
    final server = ScoringServer()..seedAutomaticScore(first, flight);
    final c = await _open(server);

    // A passive refresh reads the page and is held with the old answer.
    final read = server.holdNextScoresRead = Completer<void>();
    final passive = c.refreshAfterSync();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // Another director confirms; a Confirm refused as changed reads the
    // newer slot.
    server.confirmAsDirector(first);
    server.promoteFailures[first] = (409, 'stale_revision');
    await c.confirmAutomatic(_row(c, 1));
    expect(_row(c, 1).isAutomaticUnconfirmed, isFalse);

    read.complete();
    await passive;
    expect(_row(c, 1).isAutomaticUnconfirmed, isFalse);
    expect(c.confirmAutomaticSkip(_row(c, 1)), MarkOfficialSkip.noSubmission);
  });

  test('a failed catch-up read that a refresh already covered leaves no '
      'Refresh', () async {
    final server = ScoringServer()..seedAutomaticScore(first, flight);
    final hold = server.holdPromote = Completer<void>();
    final c = await _open(server);

    final sent = c.confirmAutomatic(_row(c, 1));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await c.refreshAfterSync();

    // The request fails; its catch-up read is held and will fail.
    server.promoteFailures[first] = (503, 'contest_busy');
    final read = server.holdNextScoresRead = Completer<void>();
    server.failHeldScoresRead = true;
    hold.complete();
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    // The director refreshes by hand; the score still needs confirming.
    await c.refresh();
    read.complete();
    await sent;

    expect(c.saveOf(first).needsRefresh, isFalse);
    expect(c.syncRefreshFailed, isFalse);
    expect(c.confirmAutomaticSkip(_row(c, 1)), isNull);
  });

  test(
    'a manual refresh that skips an unread slot leaves it blocked',
    () async {
      final server = ScoringServer()..seedAutomaticScore(first, flight);
      final c = await _open(server);

      // A manual refresh is held with the old answer; a passive sync applies
      // a newer slot meanwhile.
      final manualRead = server.holdNextScoresRead = Completer<void>();
      final manual = c.refresh();
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      await c.refreshAfterSync();

      // Confirm is refused as changed and its catch-up read is held.
      server.promoteFailures[first] = (409, 'stale_revision');
      final catchUp = server.holdNextScoresRead = Completer<void>();
      final confirm = c.confirmAutomatic(_row(c, 1));
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(server.promoteRequests, 1);

      // The older manual response keeps the newer slot and clears saves.
      manualRead.complete();
      await manual;
      expect(c.confirmAutomaticSkip(_row(c, 1)), MarkOfficialSkip.busy);
      expect(await c.confirmAutomatic(_row(c, 1)), isFalse);
      expect(server.promoteRequests, 1, reason: 'no second POST');

      // The catch-up read fails: Refresh is offered.
      server.failHeldScoresRead = true;
      catchUp.complete();
      await confirm;
      expect(c.saveOf(first).needsRefresh, isTrue);
      expect(c.confirmAutomaticSkip(_row(c, 1)), MarkOfficialSkip.busy);
    },
  );
}
