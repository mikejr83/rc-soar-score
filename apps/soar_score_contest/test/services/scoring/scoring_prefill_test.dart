import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/scoring/score_entry_settings.dart';
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

  test('an untouched pilot prefill follows a later submission', () async {
    final server = ScoringServer()..seedPendingSubmission(first, a);
    final c = await _open(server);
    expect(c.draftOf(_row(c, 1)).timeText, '9:00');

    server.seedPendingSubmission(first, b);
    await c.refresh();

    expect(c.draftOf(_row(c, 1)).timeText, '8:20');
    expect(c.draftOf(_row(c, 1)).heightText, '130');
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

    test(
      'revert clears a $state prefill and a reload keeps it cleared',
      () async {
        final server = ScoringServer()
          ..seedPendingSubmission(first, a, inReview: inReview);
        final c = await _open(server);
        expect(c.draftOf(_row(c, 1)).timeText, '9:00');
        expect(c.dirtyCount, 1);

        c.revert(_row(c, 1));
        expect(c.draftOf(_row(c, 1)).timeText, '');
        expect(c.dirtyCount, 0);

        await c.refresh();
        expect(c.draftOf(_row(c, 1)).timeText, '');
        expect(c.dirtyCount, 0);
        expect(_row(c, 1).status, RowStatus.submitted);
      },
    );

    test('discard all clears a $state prefill', () async {
      final server = ScoringServer()
        ..seedPendingSubmission(first, a, inReview: inReview);
      final c = await _open(server);
      expect(c.draftOf(_row(c, 1)).timeText, '9:00');
      expect(c.dirtyCount, 1);

      c.discardAll();

      expect(c.draftOf(_row(c, 1)).timeText, '');
      expect(c.dirtyCount, 0);
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
