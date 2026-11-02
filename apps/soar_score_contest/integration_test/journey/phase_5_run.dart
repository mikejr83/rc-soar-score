import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/open_demo_contest.dart';
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
        find.text(kIsWeb ? 'The matrix was drawn' : 'You drew the matrix'),
      );
      expect(
        find.text(
          kIsWeb
              ? 'The contest configuration was saved'
              : 'You saved the contest configuration',
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
        find.textContaining(
          kIsWeb ? 'A score was corrected for pilot' : 'You corrected a score',
        ),
      );
      expect(
        find.textContaining(
          kIsWeb ? 'A score was corrected' : 'You corrected a score',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('in round 1'), findsOneWidget);
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
      // Only the native app knows which account it acts as, so only it can
      // say "by you"; the web app names the time alone.
      expect(
        reason,
        contains(
          kIsWeb
              ? 'administration locked at'
              : 'administration locked by you at',
        ),
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

      // The retirement is on the Recent activity card too.
      await tapRail(tester, 'Workspace');
      await pumpUntilFound(
        tester,
        find.textContaining(
          kIsWeb ? 'was retired from round 3' : 'You retired pilot',
        ),
      );
      expect(find.textContaining('from round 3'), findsOneWidget);

      await scoreRound(tester, data, 3);
    }),
    timeout: _longStep,
  );
}
