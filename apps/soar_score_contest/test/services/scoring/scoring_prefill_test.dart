import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/score_entry_settings.dart';
import 'package:soar_score_contest/services/scoring/row_save.dart';
import 'package:soar_score_contest/services/scoring/score_row_draft.dart';
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
  const a = {'time_flown': 540, 'launch_height': 120};
  const b = {'time_flown': 500, 'launch_height': 130};
  const h120 = {'time_flown': 540, 'launch_height': 120};
  const h130 = {'time_flown': 540, 'launch_height': 130};

  test('an untouched pilot prefill follows a later submission', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    expect(c.draftOf(_row(c, 1)).timeText, '9:00');

    server.seedPendingSubmission(first, b);
    await c.refresh();

    expect(c.draftOf(_row(c, 1)).timeText, '8:20');
    expect(c.draftOf(_row(c, 1)).heightText, '130');
  });

  test('revert returns an edited pilot prefill to the pilot values', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');
    expect(c.hasUnsavedInput(_row(c, 1)), isTrue);

    c.revert(_row(c, 1));

    expect(c.draftOf(_row(c, 1)).timeText, '9:00');
    expect(c.draftOf(_row(c, 1)).heightText, '120');
    expect(c.hasUnsavedInput(_row(c, 1)), isFalse);
    expect(c.unsavedCount, 0);
  });

  test('discard all returns a pending and a saved row to their own starting values', () async {
    final server = ScoringServer()
      ..seedPendingSubmission(first, a)
      ..seedScore(scoringAssignmentId(1, 2), b);
    final c = await _open(server);
    for (final pilot in [1, 2]) {
      c.draftOf(_row(c, pilot)).setHeight('99');
    }
    expect(c.unsavedCount, 2);

    c.discardAll();

    expect(c.unsavedCount, 0);
    expect(c.draftOf(_row(c, 1)).heightText, '120');
    expect(c.draftOf(_row(c, 2)).heightText, '130');
    // The waiting submission can still be marked official.
    expect(await c.markOfficial(_row(c, 1)), isTrue);
  });

  test('refresh moves what Revert compares to and restores', () async {
    final server = ScoringServer()..seedScore(first, h120);
    final c = await _open(server);
    final draft = c.draftOf(_row(c, 1));
    draft.setHeight('99');
    expect(draft.canRevert, isTrue);

    server.seedCorrection(first, h130, 'Corrected elsewhere');
    await c.refresh();

    // What was typed stays; the saved values are the newer ones.
    expect(draft.heightText, '99');
    expect(draft.canRevert, isTrue);
    draft.setHeight('120');
    expect(draft.canRevert, isTrue);
    draft.setHeight('130');
    expect(draft.canRevert, isFalse);
    draft.setHeight('99');
    c.revert(_row(c, 1));
    expect(c.draftOf(_row(c, 1)).heightText, '130');
    expect(c.draftOf(_row(c, 1)).canRevert, isFalse);
  });

  test('refresh after another director made the entry official', () async {
    final server = ScoringServer()..seedPendingSubmission(first, h120);
    final c = await _open(server);
    final draft = c.draftOf(_row(c, 1));
    draft.setHeight('99');

    server.seedScore(first, h130);
    await c.refresh();

    expect(draft.heightText, '99');
    expect(draft.canRevert, isTrue);
    draft.setHeight('130');
    expect(draft.canRevert, isFalse);
    draft.setHeight('99');
    c.revert(_row(c, 1));
    expect(c.draftOf(_row(c, 1)).heightText, '130');
    expect(_row(c, 1).savedComponents, isNotEmpty);
  });

  test('refresh keeps a newer pilot submission recognizable', () async {
    final server = ScoringServer()..seedPendingSubmission(first, h120);
    final c = await _open(server);
    final draft = c.draftOf(_row(c, 1));
    draft.setHeight('99');

    server.seedPendingSubmission(first, h130);
    await c.refresh();

    // The director's text stays and still differs from the submission.
    expect(draft.heightText, '99');
    expect(c.hasUnsavedInput(_row(c, 1)), isTrue);
    expect(c.markOfficialSkip(_row(c, 1)), isNotNull);

    // Typing the submitted values back leaves an untouched prefill.
    draft.setHeight('130');
    expect(draft.canRevert, isFalse);
    expect(c.hasUnsavedInput(_row(c, 1)), isFalse);
    expect(c.markOfficialSkip(_row(c, 1)), isNull);
    expect(await c.markOfficial(_row(c, 1)), isTrue);
    expect(server.entries, isEmpty);
  });

  test('a newer submission after a sync is adopted by Mark official '
      'only after Revert shows it', () async {
    final server = ScoringServer()..seedPendingSubmission(first, h120);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');

    server.seedPendingSubmission(first, h130);
    await c.refreshAfterSync();

    expect(c.draftOf(_row(c, 1)).heightText, '99');
    expect(c.markOfficialSkip(_row(c, 1)), isNotNull);

    // Typing the old height back is still an edit: Revert shows 130.
    c.draftOf(_row(c, 1)).setHeight('120');
    expect(c.draftOf(_row(c, 1)).canRevert, isTrue);
    expect(c.markOfficialSkip(_row(c, 1)), isNotNull);

    c.revert(_row(c, 1));
    expect(c.draftOf(_row(c, 1)).heightText, '130');
    expect(c.markOfficialSkip(_row(c, 1)), isNull);
    expect(await c.markOfficial(_row(c, 1)), isTrue);
  });

  test('a sync that advances the official revision keeps typed text '
      'and marks the row stale', () async {
    final server = ScoringServer()..seedScore(first, h120);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');

    server.seedCorrection(first, h130, 'Corrected elsewhere');
    await c.refreshAfterSync();

    expect(c.draftOf(_row(c, 1)).heightText, '99');
    expect(c.saveOf(first).kind, RowSaveKind.stale);
    expect(c.theirsOf(first), h130);

    // Revert goes to the newer values, so typing the old value is an edit.
    c.draftOf(_row(c, 1)).setHeight('120');
    expect(c.draftOf(_row(c, 1)).canRevert, isTrue);
    c.draftOf(_row(c, 1)).setHeight('130');
    expect(c.draftOf(_row(c, 1)).canRevert, isFalse);
  });

  test('an untouched pilot prefill is not unsaved', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);

    expect(c.draftOf(_row(c, 1)).timeText, '9:00');
    expect(c.unsavedCount, 0);
    expect(c.hasUnsaved, isFalse);
    // Save all still makes the waiting entry official.
    expect(c.dirtyCount, 1);
  });

  test('typing over a prefill makes the row unsaved', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');

    expect(c.unsavedCount, 1);
    expect(c.hasUnsaved, isTrue);
  });

  test('saving edited rows only leaves a waiting entry unofficial', () async {
    final server = ScoringServer()
      ..seedPendingSubmission(first, a)
      ..seedPendingSubmission(scoringAssignmentId(1, 2), a);
    final c = await _open(server);
    c.draftOf(_row(c, 2)).setHeight('99');

    expect(await c.saveAll(editedOnly: true), 1);

    expect(_row(c, 1).status, RowStatus.submitted);
    expect(_row(c, 2).status, RowStatus.official);
  });

  test('discarding edits keeps the pilot prefill', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');

    c.discardEdits();

    expect(c.draftOf(_row(c, 1)).heightText, '120');
    expect(c.unsavedCount, 0);
  });

  test('invalid text typed over a prefill is unsaved input', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setTime('abc');

    expect(c.hasUnsaved, isTrue);
    expect(c.unsavedCount, 1);
  });

  test('input that parses back to the saved score is unsaved input', () async {
    final server = ScoringServer()..seedScore(first, a);
    final c = await _open(server);
    expect(c.hasUnsaved, isFalse);

    c.draftOf(_row(c, 1)).setTime('09:00');
    expect(c.draftOf(_row(c, 1)).isDirty, isFalse);
    expect(c.hasUnsaved, isTrue);

    // Nothing to write; saving settles the row so the director can leave.
    expect(await c.saveAll(editedOnly: true), 0);
    expect(c.hasUnsaved, isFalse);
    expect(server.entries, isEmpty);
  });

  test('typing the original text again is not unsaved', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    final d = c.draftOf(_row(c, 1));
    d.setTime('1:00');
    expect(c.hasUnsaved, isTrue);

    d.setTime('9:00');

    expect(c.hasUnsaved, isFalse);
  });

  test('checks for an edited-only save skip untouched prefills', () async {
    final server = ScoringServer()
      ..seedPendingSubmission(first, {'out_of_bounds': true})
      ..seedPendingSubmission(scoringAssignmentId(1, 2), a);
    final c = await _open(server);
    c.draftOf(_row(c, 1));
    c.draftOf(_row(c, 2)).setHeight('99');

    expect(c.unconfirmedZeroRows(), hasLength(1));
    expect(c.unconfirmedZeroRows(editedOnly: true), isEmpty);
    expect(c.saveCandidates(editedOnly: true).map((r) => r.id), [
      scoringAssignmentId(1, 2),
    ]);
    expect(await c.saveAll(editedOnly: true), 1);
    expect(_row(c, 1).status, RowStatus.submitted);
  });

  test('a formatting-only edit on a stale row stays unsaved', () async {
    final server = ScoringServer()..seedScore(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setTime('09:00');
    server.seedCorrection(first, b, 'Corrected elsewhere');
    await c.refreshAfterSync();
    expect(c.saveOf(first).kind, RowSaveKind.stale);

    expect(await c.saveAll(editedOnly: true), 0);

    expect(c.hasUnsaved, isTrue);
    expect(c.draftOf(_row(c, 1)).timeText, '09:00');
  });

  test('an invalid penalty removal asks for no reason', () async {
    final server = ScoringServer()
      ..seedScore(first, {...a, 'cumulative_penalty': 10})
      ..seedScore(scoringAssignmentId(1, 2), a);
    final c = await _open(server);
    c.draftOf(_row(c, 1))
      ..setCumulativePenalty('0')
      ..setTime('abc');
    c.draftOf(_row(c, 2)).setHeight('99');

    expect(c.removalRows(editedOnly: true), isEmpty);
    expect(c.saveCandidates(editedOnly: true).map((r) => r.id), [
      scoringAssignmentId(1, 2),
    ]);
    expect(await c.saveAll(editedOnly: true), 1);
    expect(c.hasUnsaved, isTrue);
  });

  test('a failed removal asks for no zero confirmation', () async {
    final second = scoringAssignmentId(1, 2);
    final server = ScoringServer()
      ..seedScore(first, {...a, 'cumulative_penalty': 10})
      ..seedScore(second, a)
      ..entryFailures[first] = (500, 'internal');
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setCumulativePenalty('0');
    c.recordRemovalReason(first, 'Misapplied');
    await c.save(_row(c, 1));
    expect(c.saveOf(first).kind, RowSaveKind.failed);
    c.draftOf(_row(c, 1)).outOfBounds = true;
    c.draftOf(_row(c, 2)).setHeight('99');

    expect(c.unconfirmedZeroRows(editedOnly: true), isEmpty);
    expect(c.saveCandidates(editedOnly: true).map((r) => r.id), [second]);
  });

  test('what the director typed survives a later submission', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    c.draftOf(_row(c, 1)).setHeight('99');

    server.seedPendingSubmission(first, b);
    await c.refresh();

    expect(c.draftOf(_row(c, 1)).heightText, '99');
    expect(c.draftOf(_row(c, 1)).timeText, '9:00');
  });

  for (final inReview in [false, true]) {
    final state = inReview ? 'InReview' : 'Submitted';

    test('revert and discard all restore a $state prefill', () async {
      final server = ScoringServer()
        ..seedPendingSubmission(first, a, inReview: inReview);
      final c = await _open(server);
      c.draftOf(_row(c, 1)).setHeight('99');

      c.revert(_row(c, 1));
      expect(c.draftOf(_row(c, 1)).timeText, '9:00');
      expect(c.draftOf(_row(c, 1)).heightText, '120');
      expect(c.hasUnsavedInput(_row(c, 1)), isFalse);

      c.draftOf(_row(c, 1)).setHeight('99');
      c.discardAll();
      expect(c.draftOf(_row(c, 1)).heightText, '120');
      expect(c.hasUnsavedInput(_row(c, 1)), isFalse);

      await c.refresh();
      expect(c.draftOf(_row(c, 1)).heightText, '120');
      expect(_row(c, 1).status, RowStatus.submitted);
    });

    test('save all makes an untouched $state prefill official', () async {
      final server = ScoringServer()
        ..seedPendingSubmission(first, a, inReview: inReview);
      final c = await _open(server);
      expect(c.draftOf(_row(c, 1)).timeText, '9:00');
      expect(server.entries, isEmpty);

      expect(await c.saveAll(), 1);

      expect(server.entries, hasLength(1));
      expect(_row(c, 1).status, RowStatus.official);
      expect(c.dirtyCount, 0);
    });
  }

  test('an official score replaces a stale prefill on reload', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    expect(c.draftOf(_row(c, 1)).timeText, '9:00');

    server.seedScore(first, b);
    await c.refresh();

    expect(c.draftOf(_row(c, 1)).timeText, '8:20');
    expect(c.dirtyCount, 0);
    expect(_row(c, 1).pendingComponents, isEmpty);
  });

  group('a prefilled draft', () {
    ScoreRowDraft draft(Map<String, Object?> shown) =>
        ScoreRowDraft(settings: const ScoreEntrySettings(), shown: shown);

    test('holds every field of a normal flight', () {
      final d = draft({
        'time_flown': 540,
        'launch_height': 120,
        'landing': 'points_50',
        'flight_penalty': 25,
        'cumulative_penalty': 10,
      });

      expect(d.components, {
        'time_flown': 540,
        'launch_height': 120,
        'landing': 'points_50',
        'flight_penalty': 25,
        'cumulative_penalty': 10,
      });
      expect(d.isUntouchedPrefill, isTrue);
      expect(d.isDirty, isTrue);
    });

    test('holds a late landing without a landing bonus', () {
      final d = draft({
        'time_flown': 600,
        'launch_height': 120,
        'late_landing': true,
      });

      expect(d.lateLanding, isTrue);
      expect(d.landingOffReason, isNotNull);
      expect(d.components.containsKey('landing'), isFalse);
    });

    for (final flag in [
      'motor_restart',
      'out_of_bounds',
      'no_altitude_recorded',
    ]) {
      test('holds $flag as a zero with measurements off', () {
        final d = draft({flag: true});

        expect(d.zeroing, isTrue);
        expect(d.measurementsOffReason, isNotNull);
        expect(d.components, {flag: true});
      });
    }

    test('stops being an untouched prefill after an edit', () {
      final d = draft(a)..setHeight('99');

      expect(d.isUntouchedPrefill, isFalse);
    });
  });
}
