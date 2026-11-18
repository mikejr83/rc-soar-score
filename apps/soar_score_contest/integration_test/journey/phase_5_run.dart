import 'dart:math' show min;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/scoring/scoring_row.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show ScorePlaceholderState;

import '../support/configuration_fields.dart';
import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/open_demo_contest.dart';
import '../support/pilot_submission.dart';
import '../support/pump_until_gone.dart';
import 'journey.dart';
import 'scoring_steps.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// The text of the status summary value [id].
String _status(WidgetTester tester, String id) =>
    tester.widget<Text>(_key('status-$id-value')).data!;

Finder _inTile(int ordinal, String text) => find.descendant(
  of: _key('progress-tile-$ordinal'),
  matching: find.text(text),
);

const _longStep = Duration(minutes: 8);

/// Pilots who get a cumulative penalty in round 2, one removed from the row
/// and one from the group's Save, so both reasons paths run.
const _penalised = {'Owen Quinn': 30, 'Priya Raman': 30};

/// Phase 5: run the contest as a director would: scoring round by round with
/// the workspace, the round status and the state controls checked on the way,
/// a correction, penalties with reasons, a retirement and the controls
/// participants and the lock.
Future<void> runRunPhase(Journey journey, JourneyContext data) async {
  final tester = journey.tester;

  Future<void> inContest(Future<void> Function() body) async {
    await goToMainPage(tester);
    await openContest(tester, data.contestName);
    await body();
  }

  await journey.step(
    'Workspace of the ready contest: checklist, next step and round status',
    () async {
      await goToMainPage(tester);
      // Outside a contest there is no status panel.
      expect(_key('shell-status-panel'), findsNothing);
      await openContest(tester, data.contestName);
      await pumpUntilFound(tester, _key('next-step-card'));
      await pumpUntilFound(tester, _key('setup-checklist-card'));
      expect(
        tester.widget<Text>(_key('next-step-title')).data,
        isNot(contains('Continue scoring')),
      );
      expect(_key('attention-card'), findsNothing);
      // The activity card is on every workspace, empty or not. The ready
      // contest already drew its matrix and saved its configuration (twice:
      // once in the wizard, once in the setup phase), so the card lists the
      // newest of each, newest first. Only the native app knows which account
      // it acts as, so only it can say "you".
      await pumpUntilFound(tester, _key('activity-card'));
      await pumpUntilFound(
        tester,
        _either('The matrix was drawn', 'You drew the matrix'),
      );
      expect(
        _either(
          'The contest configuration was saved',
          'You saved the contest configuration',
        ),
        findsWidgets,
      );

      // The checklist rows open the pages that fix them.
      await tapVisible(tester, _key('checklist-row-pilots'));
      await pumpUntilFound(tester, _key('participants-count'));
      await tapRail(tester, 'Workspace');
      await pumpUntilFound(tester, _key('checklist-row-matrix'));
      await tapVisible(tester, _key('checklist-row-matrix'));
      await pumpUntilFound(tester, _key('fairness-score'));
      await tapRail(tester, 'Workspace');

      // A contest that is not running yet explains why it cannot complete.
      await pumpUntilFound(tester, _key('status-summary'));
      expect(
        tester.widget<FilledButton>(_key('control-complete')).onPressed,
        isNull,
      );
      expect(
        tester.widget<Text>(_key('control-lifecycle-reason')).data,
        contains('Only a running contest can be completed'),
      );

      // The header names the round to be scored; choosing it opens Scoring.
      final round = _key('shell-round-status');
      await pumpUntilFound(tester, round);
      expect(
        find.descendant(of: round, matching: find.text('Not started')),
        findsOneWidget,
      );
      await tapVisible(tester, round);
      await pumpUntilFound(tester, find.textContaining('Round 1 of'));
    },
  );

  await journey.step(
    'Round 1: the first saved score moves the workspace on',
    () => inContest(() async {
      await pumpUntilFound(tester, _key('next-step-card'));
      final secondary = _key('next-step-secondary');
      await tapVisible(
        tester,
        secondary.evaluate().isNotEmpty ? secondary : _key('next-step-primary'),
      );
      await pumpUntilFound(tester, find.textContaining('Round 1 of'));
      await pumpUntilFound(tester, _key('scoring-context-strip'));

      final scored = await scoreOpenRows(tester, data, only: 1);
      expect(scored, hasLength(1));
      await pumpUntilFound(tester, find.textContaining('1 official'));
      await pumpUntilFound(tester, find.text('Lock…'));

      // Back on the workspace the contest is running: no checklist, the next
      // step continues scoring, and the header names where scoring stands.
      await tapRail(tester, 'Workspace');
      await pumpUntilFound(tester, _key('next-step-card'));
      await pumpUntilFound(tester, find.textContaining('Continue scoring'));
      expect(_key('setup-checklist-card'), findsNothing);
      expect(find.text('Running'), findsWidgets);
      final round = _key('shell-round-status');
      await pumpUntilFound(
        tester,
        find.descendant(of: round, matching: find.textContaining(', group A')),
      );
      expect(
        find.descendant(of: round, matching: find.textContaining('1 of ')),
        findsOneWidget,
      );
      await tapVisible(tester, round);
      await pumpUntilFound(tester, find.textContaining('Round 1 of'));
    }),
  );

  await journey.step(
    'Round 1: every group is scored, found through the group picker',
    () => inContest(() async {
      await openRoundGroup(tester, 1, 1);
      await scoreOpenRows(tester, data);
      expectGroupScored(tester);

      // The picker lists every group of the round and nothing more.
      await tapVisible(tester, _key('group-picker'));
      await pumpUntilFound(tester, _key('picker-item-2'));
      expect(_key('picker-item-1'), findsOneWidget);
      expect(_key('picker-item-${data.groupsPerRound + 1}'), findsNothing);
      await tapVisible(tester, _key('picker-item-2'));
      await pumpUntilFound(tester, find.textContaining('Group B of'));

      await scoreOpenRows(tester, data);
      expectGroupScored(tester);
      await pumpUntilFound(tester, find.text('Round scored'));
    }),
    timeout: _longStep,
  );

  await journey.step(
    'Round 1: a correction is a new revision in the history',
    () => inContest(() async {
      await openRoundGroup(tester, 1, 1);
      final row = anyRow(tester);
      final id = row.id.value;
      final corrected = flightOf(data, row.pilot.name, bonusSeconds: 5);
      final time = fieldWithKey('score-time-$id');
      // A saved row shows its values until it is opened again.
      await tapVisible(tester, _key('score-row-$id'));
      await pumpUntilFound(tester, time);
      await tapVisible(tester, time);
      await enterIn(tester, time, corrected.time);
      await pumpUntilFound(tester, find.text('1 unsaved row'));
      await tapVisible(tester, _key('score-save-$id'));
      await pumpUntilGone(tester, find.text('1 unsaved row'));

      // The history lists both revisions and the reason of the correction.
      await openRowHistory(tester, row);
      await pumpUntilFound(tester, find.text('Revision 2'));
      expect(find.text('Revision 1'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Replaced'), findsOneWidget);
      expect(
        find.text('Reason: Corrected on the scoring page'),
        findsOneWidget,
      );
      await closeHistory(tester);

      // The group history shows the same pilot.
      await tapVisible(tester, _key('group-more'));
      await pumpUntilFound(tester, _key('menu-group-history'));
      await tapVisible(tester, _key('menu-group-history'));
      await pumpUntilFound(tester, find.text('Group history'));
      expect(find.text('Revision 2'), findsOneWidget);
      await closeHistory(tester);

      // The correction, not the routine first entries before it, is on the
      // Recent activity card of the workspace.
      await tapRail(tester, 'Workspace');
      await pumpUntilFound(
        tester,
        _either('A score was corrected for pilot', 'You corrected a score'),
      );
      expect(
        _either('A score was corrected', 'You corrected a score'),
        findsOneWidget,
      );
      expect(find.textContaining('in round 1'), findsOneWidget);

      // View all opens the full activity page, which lists the correction too
      // and narrows to one kind of event.
      await tapVisible(tester, _key('activity-view-all'));
      await pumpUntilFound(tester, _key('activity-list'));
      expect(find.textContaining('in round 1'), findsOneWidget);
      await tapVisible(tester, _key('activity-filter-matrix'));
      await pumpUntilFound(tester, find.textContaining('matrix'));
      expect(find.textContaining('in round 1'), findsNothing);
      await tapVisible(tester, _key('activity-filter-scores'));
      await pumpUntilFound(tester, find.textContaining('in round 1'));
      await tapRail(tester, 'Workspace');
      await pumpUntilFound(tester, _key('activity-card'));
    }),
  );

  await journey.step(
    'Round 2: the first group is scored, two pilots with a penalty',
    () => inContest(() async {
      await openRoundGroup(tester, 2, 1);
      await scoreOpenRows(tester, data, penalties: _penalised);
      expectGroupScored(tester);
    }),
    timeout: _longStep,
  );

  await journey.step(
    'Workspace mid-run: progress tiles, attention and the links to Scoring',
    () => inContest(() async {
      await pumpUntilFound(tester, _key('progress-card'));
      await pumpUntilFound(tester, _key('progress-where'));
      for (var round = 1; round <= data.rounds; round++) {
        expect(_key('progress-tile-$round'), findsOneWidget);
      }
      final pilots = data.pilotNames.length;
      expect(_inTile(1, 'Scored'), findsOneWidget);
      expect(_inTile(1, '$pilots/$pilots'), findsOneWidget);
      expect(_inTile(2, 'In progress'), findsOneWidget);
      expect(_inTile(3, 'Not flown'), findsOneWidget);

      // A running contest shows what needs attention and no checklist.
      expect(_key('attention-card'), findsOneWidget);
      expect(_key('setup-checklist-card'), findsNothing);
      expect(_key('activity-card'), findsOneWidget);

      // The next step and a progress tile open Scoring at their round.
      await tapVisible(tester, _key('next-step-primary'));
      await pumpUntilFound(tester, find.textContaining('Round 2 of'));
      await tapRail(tester, 'Workspace');
      await pumpUntilFound(tester, _key('progress-tile-1'));
      await tapVisible(tester, _key('progress-tile-1'));
      await pumpUntilFound(tester, find.textContaining('Round 1 of'));
    }),
  );

  await journey.step(
    'Contest state controls: scoring access, the lock and a cancelled Complete',
    () => inContest(() async {
      await pumpUntilFound(tester, _key('status-summary'));

      // The status summary labels each state on its own.
      expect(_status(tester, 'lifecycle'), 'Running');
      expect(_key('status-deletion'), findsNothing);
      for (final id in [
        'scoring',
        'administration',
        'publication',
        'results',
        'archive',
      ]) {
        expect(_key('status-$id-value'), findsOneWidget);
      }

      // Participant scoring: whichever way it is now, the other control flips
      // it.
      final opening = _key('control-openScoring').evaluate().isNotEmpty;
      final wasOpen = _status(tester, 'scoring');
      await tapVisible(
        tester,
        _key(opening ? 'control-openScoring' : 'control-closeScoring'),
      );
      await pumpUntilFound(
        tester,
        _key(opening ? 'control-closeScoring' : 'control-openScoring'),
      );
      expect(_status(tester, 'scoring'), isNot(wasOpen));

      // Locking asks first, and cancel changes nothing.
      expect(_status(tester, 'administration'), 'Unlocked');
      await tapVisible(tester, _key('control-lock'));
      await pumpUntilFound(tester, _key('lock-dialog'));
      expect(find.text('• Contest configuration'), findsOneWidget);
      await tester.tap(_key('lock-dialog-cancel'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_status(tester, 'administration'), 'Unlocked');

      await tapVisible(tester, _key('control-lock'));
      await pumpUntilFound(tester, _key('lock-dialog'));
      await tester.tap(_key('lock-dialog-confirm'));
      await pumpUntilFound(tester, _key('control-unlock'));
      expect(_status(tester, 'administration'), 'Locked');
      // The next-step card names who locked and when, from the audit trail.
      final blocked = find.textContaining(
        'administration locked',
        findRichText: true,
      );
      await pumpUntilFound(tester, blocked);
      final reason = tester
          .widgetList<RichText>(blocked)
          .map((w) => w.text.toPlainText())
          .join(' | ');
      // The wording depends on whether the app knows its own account ("by
      // you") or only names the time.
      expect(
        RegExp(r'administration locked (by you )?at').hasMatch(reason),
        isTrue,
        reason: reason,
      );
      await tapVisible(tester, _key('control-unlock'));
      await pumpUntilFound(tester, _key('control-lock'));
      expect(_status(tester, 'administration'), 'Unlocked');

      // Completing now lists what is still open: unscored flights and a round
      // not flown. Cancelling leaves the contest running.
      await tapVisible(tester, _key('control-complete'));
      await pumpUntilFound(tester, _key('complete-dialog'));
      await pumpUntilFound(tester, _key('complete-dialog-missing'));
      expect(_key('complete-dialog-unflown'), findsOneWidget);
      await tapVisible(tester, _key('complete-dialog-cancel'));
      await pumpUntilGone(tester, _key('complete-dialog'));
      expect(_status(tester, 'lifecycle'), 'Running');
    }),
  );

  await journey.step(
    'Overall results card: hide, show and undo, with the status in step',
    () => inContest(() async {
      await pumpUntilFound(tester, _key('workspace-control-results'));
      expect(find.textContaining('goes here'), findsNothing);
      expect(_status(tester, 'results'), 'Off');
      expect(
        tester
            .widget<Text>(_key('control-results-current'))
            .textSpan!
            .toPlainText(),
        'Now: Visible',
      );

      // Hiding takes effect at once; the card names the round and the end of
      // the 24 hours, and the status summary follows.
      await tapVisible(tester, _key('control-hideResults'));
      await pumpUntilFound(tester, _key('control-showResults'));
      expect(_status(tester, 'results'), startsWith('Hidden through round'));
      expect(
        tester
            .widget<Text>(_key('control-results-current'))
            .textSpan!
            .toPlainText(),
        contains('ends at'),
      );
      expect(
        find.textContaining('24 hours after it was turned on'),
        findsOneWidget,
      );

      // Undo in the snackbar puts it back.
      await tapVisible(tester, find.text('Undo'));
      await pumpUntilFound(tester, _key('control-hideResults'));
      expect(_status(tester, 'results'), 'Off');

      // Hide again and show with the card's own button.
      await tapVisible(tester, _key('control-hideResults'));
      await pumpUntilFound(tester, _key('control-showResults'));
      await tapVisible(tester, _key('control-showResults'));
      await pumpUntilFound(tester, _key('control-hideResults'));
      expect(_status(tester, 'results'), 'Off');
    }),
  );

  await journey.step(
    'Round 2: the rest of the round is scored',
    () => inContest(() async {
      await scoreRound(tester, data, 2, penalties: _penalised);
    }),
    timeout: _longStep,
  );

  await journey.step(
    'Round 2: removing a penalty needs a reason, from the row and from Save',
    () => inContest(() async {
      const rowReason = 'Timer slip misread on the timekeeper board';
      const groupReason = 'GliderScore import: the slip was a timer misread';

      // From the row's own Save.
      await openGroupOf(tester, data, 2, 'Owen Quinn');
      final owen = (await rowOf(tester, 'Owen Quinn'))!;
      await openRowHistory(tester, owen);
      await pumpUntilFound(
        tester,
        find.textContaining('Cumulative penalty 30'),
      );
      await closeHistory(tester);
      await tapVisible(tester, _key('score-row-${owen.id.value}'));
      await pumpUntilFound(tester, _key('cumulative-penalty'));
      await enterIn(tester, _key('cumulative-penalty'), '0');
      await pumpUntilFound(tester, find.text('Applied, then removed.'));
      await tapVisible(tester, _key('score-save-${owen.id.value}'));
      await pumpUntilFound(tester, _key('penalty-removal-dialog'));
      await enterIn(tester, _key('penalty-removal-reason'), rowReason);
      await tapVisible(tester, _key('penalty-removal-confirm'));
      await pumpUntilFound(tester, _key('scoring-context-strip'));
      await openRowHistory(tester, owen);
      await pumpUntilFound(
        tester,
        find.textContaining('Cumulative penalty removed'),
      );
      await pumpUntilFound(tester, find.text('Reason: $rowReason'));
      await closeHistory(tester);

      // From the group's Save, which asks once for the pending removals.
      await openGroupOf(tester, data, 2, 'Priya Raman');
      final priya = (await rowOf(tester, 'Priya Raman'))!;
      await tapVisible(tester, _key('score-row-${priya.id.value}'));
      await pumpUntilFound(tester, _key('cumulative-penalty'));
      await enterIn(tester, _key('cumulative-penalty'), '0');
      await pumpUntilFound(tester, find.text('Applied, then removed.'));
      await tapVisible(tester, _key('score-save-all'));
      await pumpUntilFound(tester, _key('penalty-removal-dialog'));
      // One pending removal asks about that pilot, not a count.
      expect(
        find.descendant(
          of: _key('penalty-removal-dialog'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data?.startsWith('Remove ') ?? false) &&
                (w.data?.endsWith("'s penalty?") ?? false),
          ),
        ),
        findsOneWidget,
      );
      await enterIn(tester, _key('penalty-removal-reason'), groupReason);
      await tapVisible(tester, _key('penalty-removal-confirm'));
      await pumpUntilFound(tester, _key('scoring-context-strip'));
      await openRowHistory(tester, priya);
      await pumpUntilFound(
        tester,
        find.textContaining('Cumulative penalty removed'),
      );
      await pumpUntilFound(tester, find.text('Reason: $groupReason'));
      await closeHistory(tester);
    }),
    timeout: _longStep,
  );

  await journey.step(
    'Round 3: several rows are saved together with the group Save',
    () => inContest(() async {
      await openRoundGroup(tester, 3, 1);
      // Tess retires in the next step, so she stays unscored here.
      final scored = await scoreOpenRowsTogether(
        tester,
        data,
        2,
        skip: {'Tess Valdez'},
      );
      expect(scored, hasLength(2));
      await pumpUntilFound(tester, find.text('Saved 2 rows.'));
      // The saving indicator is gone once the rows are saved.
      expect(find.byKey(const ValueKey('score-saving-progress')), findsNothing);
    }),
    timeout: _longStep,
  );

  // A pilot's submission arrives through the hosted server's invitations,
  // which only the web run's E2E server has; the Windows build's embedded
  // server gets one by sync, which this signed-out journey cannot show.
  await journey.step(
    'Round 3: a pilot\'s own entry shows as Pilot entry until the director saves',
    () => inContest(() async {
      // Tess retires in the next step, and the draw decides who the group
      // Save above took, so the first pilot without a score submits.
      final pilot = await submitAsPilot(
        contestName: data.contestName,
        candidates: [
          for (final name in data.pilotNames)
            if (name != 'Tess Valdez') name,
        ],
        round: 3,
        timeFlown: 480,
      );
      await openGroupOf(tester, data, 3, pilot);
      final row = (await rowOf(tester, pilot))!;
      final chip = find.descendant(
        of: _key('score-row-${row.id.value}'),
        matching: find.text('Pilot entry'),
      );
      await pumpUntilFound(tester, chip);
      expect(row.hasPendingSubmission, isTrue);
      expect(find.text('Pilot entry'), findsOneWidget);

      // The director checks the values and saves: the chip goes.
      await tapVisible(tester, _key('score-row-${row.id.value}'));
      final time = fieldWithKey('score-time-${row.id.value}');
      await pumpUntilFound(tester, time);
      expect(tester.widget<TextField>(time).controller!.text, isNotEmpty);
      await saveFlightOf(tester, data, row);
      // The list builds only the rows near the screen and saving moves on
      // to the next pilot, so the saved row may be gone from the tree: bring
      // it back and check that row itself.
      await pumpUntilGone(tester, chip);
      final saved = await rowOf(tester, pilot);
      expect(saved, isNotNull, reason: 'the saved row is built again');
      expect(saved!.hasPendingSubmission, isFalse);
      expect(saved.status, RowStatus.official);
      expect(_key('score-row-${row.id.value}'), findsOneWidget);
      expect(chip, findsNothing);
    }),
    webOnly: true,
  );

  // Same web-only hook: the pilot's own entry, accepted without retyping it.
  await journey.step(
    'Round 3: Mark official accepts a pilot\'s entry as it is',
    () => inContest(() async {
      final pilot = await submitAsPilot(
        contestName: data.contestName,
        candidates: [
          for (final name in data.pilotNames)
            if (name != 'Tess Valdez') name,
        ],
        round: 3,
        timeFlown: 470,
      );
      await openGroupOf(tester, data, 3, pilot);
      final row = (await rowOf(tester, pilot))!;
      final mark = _key('score-mark-official-${row.id.value}');
      await pumpUntilFound(tester, mark);
      expect(row.hasPendingSubmission, isTrue);

      // Typing over the pilot's values turns it off and says what to do;
      // reverting brings it back.
      await tapVisible(tester, _key('score-row-${row.id.value}'));
      final height = fieldWithKey('score-height-${row.id.value}');
      await pumpUntilFound(tester, height);
      await enterIn(tester, height, '99');
      await pumpUntilFound(
        tester,
        find.text('Save or revert your edits first.'),
      );
      expect(tester.widget<OutlinedButton>(mark).onPressed, isNull);
      await tapVisible(tester, _key('score-revert-${row.id.value}'));
      await pumpUntilGone(
        tester,
        find.text('Save or revert your edits first.'),
      );

      await tapVisible(tester, mark);
      await pumpUntilGone(tester, mark);
      final saved = await rowOf(tester, pilot);
      expect(saved, isNotNull);
      expect(saved!.hasPendingSubmission, isFalse);
      expect(saved.status, RowStatus.official);
    }),
    webOnly: true,
  );

  // The helpers the UI PRs for counts, the row action, the group action and
  // automatic officialization use: several pending submissions and a review.
  // The journey's contest is not seeded: the E2E server's hooks store what a
  // pilot's invitation page would, through the real service, at this point of
  // the same contest. Web run only, like the step above. The contest has three
  // rounds, so this runs in round 3 before the rest of it is scored. The
  // pilots are in one group and wait in [waiting] (the last one is under
  // review) for the steps that follow, which decide them; the step after those
  // adopts what is still pending so the round can be completed.
  var waiting = <String>[];
  await journey.step(
    'Round 3: several pilot entries and a review wait for the director',
    () => inContest(() async {
      // All of them fly in one group, so the page never asks about unsaved
      // rows of another one. Tess retires in the next step, so she stays out.
      // The draw decides who flies where, so the group with the most open
      // rows is used (the next steps need three).
      var group = 0;
      var inGroup = <String>[];
      for (var g = 1; g <= data.groupsPerRound; g++) {
        await openRoundGroup(tester, 3, g);
        final open = openRowNames(tester, skip: {'Tess Valdez'});
        if (open.length > inGroup.length) {
          inGroup = open;
          group = g;
        }
      }
      await openRoundGroup(tester, 3, group);
      // Mark official, Mark all and the review need a plain, a second plain
      // and a reviewed entry in one group.
      expect(inGroup.length, greaterThanOrEqualTo(3), reason: 'rows to fill');
      final pilots = waiting = await submitAsPilots(
        contestName: data.contestName,
        candidates: inGroup,
        round: 3,
        count: min(3, inGroup.length),
        timeFlown: 470,
      );
      await requestReviewAsPilot(
        contestName: data.contestName,
        pilot: pilots.last,
        round: 3,
        timeFlown: 495,
      );
      // The status bar's Refresh loads the page again, as the poll does when
      // pilots' scores arrive: an untouched form follows the reload.
      await tapVisible(tester, find.text('Refresh'));
      await tester.pump(const Duration(seconds: 2));
      await openRoundGroup(tester, 3, group);
      for (final name in pilots) {
        final row = (await rowOf(tester, name))!;
        expect(row.hasPendingSubmission, isTrue, reason: name);
        expect(row.status, RowStatus.submitted, reason: name);
        expect(row.slot!.officialScore, isNull, reason: name);
        expect(
          row.slot!.placeholder.state,
          name == pilots.last
              ? ScorePlaceholderState.inReview
              : ScorePlaceholderState.submitted,
          reason: name,
        );
      }
      // #929: the strip counts the waiting entries as entered, apart from the
      // official scores the group already has.
      final (entered, total, official) = groupStripCounts(tester);
      expect(entered - official, pilots.length, reason: 'waiting entries');
      expect(entered, lessThanOrEqualTo(total));
      // A group opens with its pending rows filled in for the director, so
      // leaving it asks about the unsaved rows. Discarding keeps the
      // submissions: they stay pending on the server.
      await tapRail(tester, 'Workspace');
      await tester.pump(const Duration(seconds: 1));
      if (find.text('Unsaved scores').evaluate().isNotEmpty) {
        await tapVisible(tester, find.text('Discard'));
      }
      await pumpUntilFound(tester, _key('activity-card'));
    }),
    webOnly: true,
    timeout: _longStep,
  );

  await journey.step(
    'Round 3: Mark official accepts a waiting pilot entry from its row',
    () => inContest(() async {
      final pilot = waiting.first;
      await openGroupOf(tester, data, 3, pilot);
      final row = (await rowOf(tester, pilot))!;
      final mark = _key('score-mark-official-${row.id.value}');
      await pumpUntilFound(tester, mark);

      // Typing over the pilot's values turns it off and says what to do;
      // reverting brings it back.
      await tapVisible(tester, _key('score-row-${row.id.value}'));
      final height = fieldWithKey('score-height-${row.id.value}');
      await pumpUntilFound(tester, height);
      await enterIn(tester, height, '99');
      await pumpUntilFound(
        tester,
        find.text('Save or revert your edits first.'),
      );
      expect(tester.widget<OutlinedButton>(mark).onPressed, isNull);
      await tapVisible(tester, _key('score-revert-${row.id.value}'));
      await pumpUntilGone(
        tester,
        find.text('Save or revert your edits first.'),
      );

      await tapVisible(tester, mark);
      await pumpUntilGone(tester, mark);
      final saved = await rowOf(tester, pilot);
      expect(saved, isNotNull);
      expect(saved!.hasPendingSubmission, isFalse);
      expect(saved.status, RowStatus.official);
      await leaveGroupDiscardingPending(tester);
    }),
    webOnly: true,
  );

  await journey.step(
    'Round 3: Mark all valid rows official leaves the review for the director',
    () => inContest(() async {
      expect(waiting.length, 3, reason: 'a plain, a second plain, a review');
      final plain = waiting[1];
      final reviewed = waiting.last;
      await openGroupOf(tester, data, 3, plain);
      final row = (await rowOf(tester, plain))!;
      await pumpUntilFound(tester, _key('score-mark-official-${row.id.value}'));

      // One tap, no confirmation: the group request goes out.
      await tapVisible(tester, _key('score-mark-all-official'));
      await pumpUntilFound(tester, find.textContaining('Marked '));
      final saved = await rowOf(tester, plain);
      expect(saved!.status, RowStatus.official);

      // A pilot under review is held back from the group action.
      final held = (await rowOf(tester, reviewed))!;
      expect(held.slot!.placeholder.state, ScorePlaceholderState.inReview);
      expect(held.slot!.officialScore, isNull);
      await leaveGroupDiscardingPending(tester);
    }),
    webOnly: true,
  );

  await journey.step(
    'Round 3: what is still pending is adopted so the round can be completed',
    () => inContest(() async {
      // The director's "mark official" for everything left (a review is
      // superseded with the adoption); the page follows the next Refresh.
      await adoptPendingAsDirector(contestName: data.contestName, round: 3);
      for (final name in waiting) {
        await openGroupOf(tester, data, 3, name);
        for (var i = 0; i < 30; i++) {
          if ((await rowOf(tester, name))?.status == RowStatus.official) break;
          await tapVisible(tester, find.text('Refresh'));
          await tester.pump(const Duration(seconds: 1));
        }
        final saved = (await rowOf(tester, name))!;
        expect(saved.status, RowStatus.official, reason: name);
        expect(saved.hasPendingSubmission, isFalse, reason: name);
      }
    }),
    webOnly: true,
    timeout: _longStep,
  );

  var automatic = <String>[];

  await journey.step(
    'Round 3: a pilot retires, the rest of the round is scored',
    () => inContest(() async {
      const retiring = 'Tess Valdez';
      await openGroupOf(tester, data, 3, retiring);
      final row = (await rowOf(tester, retiring))!;
      await tapVisible(tester, _key('row-menu-${row.id.value}'));
      await pumpUntilFound(tester, _key('menu-retire'));
      await tapVisible(tester, _key('menu-retire'));
      await pumpUntilFound(tester, _key('retire-dialog'));
      expect(find.textContaining('flights instead of'), findsWidgets);
      await tapVisible(tester, _key('retire-confirm'));
      await pumpUntilFound(tester, find.text('Retired'));
      expect(find.text('Retired from round 3'), findsOneWidget);

      // The retirement is on the Recent activity card too. On the web run the
      // pilots' waiting entries filled the group's rows, so leaving can ask
      // about them.
      await tapRail(tester, 'Workspace');
      await tester.pump(const Duration(seconds: 1));
      if (find.text('Unsaved scores').evaluate().isNotEmpty) {
        await tapVisible(tester, find.text('Discard'));
      }
      // The Scoring page's snackbar can still be up, and it says the same, so
      // count only the activity entry's own wording.
      final retired = _either('was retired from round 3', 'You retired pilot');
      await pumpUntilFound(tester, retired);
      expect(retired, findsOneWidget);

      // On the web run the pilots enter the rest of the round next, and the
      // contest accepts their entries; the native run scores it here.
      if (!kIsWeb) await scoreRound(tester, data, 3);
    }),
    timeout: _longStep,
  );
  await journey.step(
    'Round 3: the contest accepts the last entries itself, the director '
    'confirms one',
    () => inContest(() async {
      // The set-up phase left scores to become official manually; the
      // director switches back to the end of the round for these last flights.
      await openConfiguration(tester);
      await tapRadio(tester, 'scores_become_official', 'At end of round');
      // The page cannot save while the first drop lies after the last round,
      // so a stored value past round 3 is brought back to it.
      final drop = find.descendant(
        of: settingField('drop1'),
        matching: find.byType(TextField),
      );
      if (drop.evaluate().isNotEmpty &&
          find.textContaining('the last round drawn').evaluate().isNotEmpty) {
        await enterIn(tester, drop, '${data.rounds}');
      }
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Save configuration'),
      );
      // Changing a drop recalculates the results, which asks first.
      await tester.pump(const Duration(seconds: 1));
      if (_key('confirm-save').evaluate().isNotEmpty) {
        await tapVisible(tester, _key('confirm-save'));
      }
      await pumpUntilFound(
        tester,
        find.textContaining('Configuration saved as revision'),
      );
      // Every flight but the last waits: scores become official at the end
      // of the round. The last pilot's entry completes it, and the contest
      // accepts them all without a director.
      final all = <String>[];
      for (var g = 1; g <= data.groupsPerRound; g++) {
        await openRoundGroup(tester, 3, g);
        all.addAll(openRowNames(tester));
      }
      expect(all, isNotEmpty, reason: 'rows still open in round 3');
      final early = all.take(all.length - 1).toList();
      if (early.isNotEmpty) {
        await submitAsPilots(
          contestName: data.contestName,
          candidates: early,
          round: 3,
          count: early.length,
          timeFlown: 430,
        );
      }
      // Before the last flight arrives nothing may be official: an early
      // entry still waits.
      if (early.isNotEmpty) {
        await openGroupOf(tester, data, 3, early.first);
        final entry = (await rowOf(tester, early.first))!;
        expect(entry.hasPendingSubmission, isTrue, reason: early.first);
        expect(entry.status, RowStatus.submitted, reason: early.first);
        expect(entry.isAutomaticUnconfirmed, isFalse, reason: early.first);
      }
      await submitAsPilots(
        contestName: data.contestName,
        candidates: [all.last],
        round: 3,
        count: 1,
        timeFlown: 440,
      );
      automatic = all;
      await leaveGroupDiscardingPending(tester);
      for (final name in automatic) {
        await openGroupOf(tester, data, 3, name);
        final row = (await rowOf(tester, name))!;
        expect(row.hasPendingSubmission, isFalse, reason: name);
        expect(row.status, RowStatus.official, reason: name);
        expect(row.isAutomaticUnconfirmed, isTrue, reason: name);
        expect(find.text('Accepted automatically'), findsWidgets);
        expect(_key('score-confirm-automatic-${row.id.value}'), findsOneWidget);
      }

      // The history names the system, not a director.
      final pilot = automatic.first;
      await openGroupOf(tester, data, 3, pilot);
      var row = (await rowOf(tester, pilot))!;
      await openRowHistory(tester, row);
      expect(find.text('Made official by System (automatic)'), findsOneWidget);
      expect(find.text('Confirmed by the director'), findsNothing);
      await closeHistory(tester);

      // Confirming records the decision without a second version.
      final revision = row.slot!.placeholder.scoreRevision;
      final confirm = _key('score-confirm-automatic-${row.id.value}');
      await tapVisible(tester, confirm);
      await pumpUntilGone(tester, confirm);
      row = (await rowOf(tester, pilot))!;
      expect(row.isAutomaticUnconfirmed, isFalse);
      expect(row.status, RowStatus.official);
      expect(row.slot!.placeholder.scoreRevision, revision);
      await openRowHistory(tester, row);
      expect(find.text('Made official by System (automatic)'), findsOneWidget);
      expect(find.text('Confirmed by the director'), findsOneWidget);
      await closeHistory(tester);
    }),
    webOnly: true,
    timeout: _longStep,
  );
}

/// Text that contains either wording: the activity card and the lock status
/// say "You ..." where the app knows which account it acts as and name the
/// event alone where it does not, and which one a run gets depends on the
/// sign-in of that run.
Finder _either(String anonymous, String you) => find.textContaining(
  RegExp('${RegExp.escape(anonymous)}|${RegExp.escape(you)}'),
);

/// Leaves the scoring page for the workspace. A group opens with its pending
/// rows filled in for the director, so leaving asks about the unsaved rows;
/// discarding keeps the submissions pending on the server.
Future<void> leaveGroupDiscardingPending(WidgetTester tester) async {
  await tapRail(tester, 'Workspace');
  await tester.pump(const Duration(seconds: 1));
  if (find.text('Unsaved scores').evaluate().isNotEmpty) {
    await tapVisible(tester, find.text('Discard'));
  }
  await pumpUntilFound(tester, _key('activity-card'));
}
