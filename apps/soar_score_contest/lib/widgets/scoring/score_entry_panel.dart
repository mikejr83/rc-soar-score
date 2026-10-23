import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/scoring/row_save.dart';
import '../../services/scoring/score_check.dart';
import '../../services/scoring/score_row_draft.dart';
import '../../services/scoring/scoring_page_data.dart';
import '../../services/scoring/scoring_row.dart';
import '../page_states/page_banner.dart';
import 'focus_step.dart';
import 'score_landing_chips.dart';
import 'score_penalty_cards.dart';
import 'score_row_banners.dart';
import 'score_row_tile.dart';
import 'score_toggle_tile.dart';

/// The band under the active row: messages, the landing choice, the four
/// toggles, the two penalties and Save row. Time and height stay in the row.
class ScoreEntryPanel extends StatelessWidget {
  const ScoreEntryPanel({
    super.key,
    required this.row,
    required this.draft,
    required this.save,
    required this.block,
    required this.landings,
    required this.landingTableName,
    required this.theirs,
    required this.findings,
    required this.actions,
    required this.penaltyController,
    required this.penaltyNode,
    required this.landingNode,
    required this.cumulativePenaltyController,
    required this.cumulativePenaltyNode,
    required this.readOnly,
    required this.keyOf,
    this.focusOrder = false,
  });

  final ScoringRow row;
  final ScoreRowDraft draft;
  final RowSave save;
  final EntryBlock? block;
  final List<LandingResult> landings;
  final String? landingTableName;
  final Map<String, Object?>? theirs;
  final List<ScoreFinding> findings;
  final ScoreRowActions actions;
  final TextEditingController penaltyController;
  final FocusNode penaltyNode;
  final FocusNode landingNode;
  final TextEditingController cumulativePenaltyController;
  final FocusNode cumulativePenaltyNode;
  final bool readOnly;
  final String Function(String name) keyOf;

  /// Draws the keyboard path numbers over the controls.
  final bool focusOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = save.isBusy;
    final enabled = !readOnly && !busy;
    final settings = draft.settings;
    final problems = draft.problems;
    final canSave =
        enabled &&
        problems.isEmpty &&
        (draft.isDirty || !row.isScored) &&
        (!draft.needsZeroConfirmation || draft.zeroConfirmed);
    final landingReason = draft.landingOffReason;

    var step = 3;
    Widget toggle(
      String name,
      String label,
      bool value,
      String? off,
      String note,
      ValueChanged<bool> set,
    ) {
      step++;
      return SizedBox(
        width: 236,
        child: FocusStep(
          order: step.toDouble(),
          badge: focusOrder ? '$step' : null,
          corner: FocusBadgeCorner.topLeft,
          child: ScoreToggleTile(
            key: ValueKey(keyOf(name)),
            label: label,
            value: value,
            offReason: off,
            note: note,
            enabled: enabled,
            onChanged: set,
          ),
        ),
      );
    }

    return Container(
      key: ValueKey(keyOf('band')),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (draft.time.error != null && !draft.zeroing)
            ScoreErrorBanner(
              key: const ValueKey('score-time-error'),
              text: draft.time.error!,
            ),
          if (draft.heightUnusual)
            ScoreInlineNote(
              icon: Icons.help_outline,
              kind: PageBannerKind.status,
              text:
                  '${draft.height} m is a high launch. Is this correct? '
                  'You can still save.',
            ),
          if (draft.heightZero)
            ScoreInlineNote(
              icon: Icons.help_outline,
              kind: PageBannerKind.status,
              text:
                  '0 m is not a launch height. Saving it as No altitude '
                  'recorded scores 0.',
              actionLabel: 'Turn on No altitude recorded',
              onAction: enabled ? () => draft.setNoAltitude(true) : null,
            ),
          for (final finding in findings)
            ScoreInlineNote(
              icon: Icons.fact_check_outlined,
              kind: PageBannerKind.status,
              text: finding.message,
            ),
          if (draft.needsZeroConfirmation &&
              !readOnly &&
              (draft.isDirty || !row.isScored))
            _zeroConfirm(context, enabled),
          if (save.kind != RowSaveKind.idle && !busy)
            ScoreSaveBanner(
              save: save,
              theirs: theirs,
              mine: draft.components,
              onRetry: actions.onSave,
              onRefresh: actions.onRefresh,
              onKeepMine: actions.onKeepMine,
              onTakeTheirs: actions.onTakeTheirs,
            ),
          if (block != null)
            ScoreInlineNote(
              icon: Icons.lock_outline,
              kind: PageBannerKind.neutral,
              text: block!.message,
            ),
          if (row.retired)
            ScoreInlineNote(
              icon: Icons.person_off_outlined,
              kind: PageBannerKind.neutral,
              text:
                  '${row.pilot.name} retired from round '
                  '${row.pilot.retiredAtRound}. Entry is closed for this flight.',
            ),
          // Landing.
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                'Landing',
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
              ),
              if (landingTableName != null)
                Text(landingTableName!, style: theme.textTheme.bodySmall),
              if (landingReason != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(landingReason, style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (landings.isEmpty)
            Text(
              'The contest has no landing table. Choose one on the '
              'Configuration page.',
              style: theme.textTheme.bodySmall,
            )
          else
            FocusStep(
              order: 3,
              badge: focusOrder ? '3↵' : null,
              enterPath: true,
              corner: FocusBadgeCorner.topLeft,
              child: ScoreLandingChoice(
                landings: landings,
                selected: draft.landing,
                enabled: enabled && landingReason == null,
                focusNode: landingNode,
                keyPrefix: keyOf('landing'),
                onSelected: draft.setLanding,
                onEnter: penaltyNode.requestFocus,
              ),
            ),
          // Toggles.
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              toggle(
                'late',
                'Late landing',
                draft.lateLanding,
                draft.lateLandingOffReason,
                'Landing bonus is not given.',
                draft.setLateLanding,
              ),
              if (settings.restartsAllowed)
                toggle(
                  'restart',
                  'Motor restart',
                  draft.motorRestart,
                  draft.motorRestartOffReason,
                  settings.restartsNonDroppable
                      ? 'Scores 0, and the zero cannot be dropped.'
                      : 'Scores 0.',
                  draft.setMotorRestart,
                ),
              toggle(
                'oob',
                'Out of bounds',
                draft.outOfBounds,
                draft.outOfBoundsOffReason,
                'Landed more than 75 m from the marker. Scores 0.',
                draft.setOutOfBounds,
              ),
              toggle(
                'noalt',
                'No altitude recorded',
                draft.noAltitude,
                draft.noAltitudeOffReason,
                'Scores 0.',
                draft.setNoAltitude,
              ),
            ],
          ),
          // Penalties.
          const SizedBox(height: 14),
          ScorePenaltyCards(
            fieldKey: ValueKey(keyOf('penalty')),
            focusOrder: focusOrder,
            controller: penaltyController,
            focusNode: penaltyNode,
            enabled: enabled,
            errorText: problems
                .where((p) => p.field == 'flight_penalty')
                .map((p) => p.message)
                .firstOrNull,
            onChanged: draft.setPenalty,
            onSubmitted: () {
              if (canSave) actions.onSave();
            },
            cumulativeController: cumulativePenaltyController,
            cumulativeFocusNode: cumulativePenaltyNode,
            cumulativeOnChanged: draft.setCumulativePenalty,
            cumulativeErrorText: problems
                .where((p) => p.field == 'cumulative_penalty')
                .map((p) => p.message)
                .firstOrNull,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FocusStep(
                      order: 10,
                      badge: focusOrder ? '10 → next pilot 1' : null,
                      enterPath: true,
                      child: FilledButton.icon(
                        key: ValueKey(keyOf('save')),
                        onPressed: canSave ? actions.onSave : null,
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save, size: 20),
                        label: Text(busy ? 'Saving…' : 'Save row'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FocusStep(
                      order: 11,
                      child: TextButton(
                        key: ValueKey(keyOf('revert')),
                        onPressed: enabled && draft.isDirty
                            ? actions.onRevert
                            : null,
                        child: const Text('Revert'),
                      ),
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    'Enter moves on. Enter on the penalty saves and opens the '
                    'next pilot.',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zeroConfirm(BuildContext context, bool enabled) {
    final why = draft.isBlank
        ? 'Nothing is entered. Saving records No flight, a zero.'
        : 'Saving scores 0 for this pilot.';
    if (draft.zeroConfirmed) {
      return ScoreInlineNote(
        icon: Icons.check_circle_outline,
        kind: PageBannerKind.success,
        text: 'Zero confirmed. Save the row to record it.',
      );
    }
    return ScoreInlineNote(
      icon: Icons.help_outline,
      kind: PageBannerKind.status,
      text: why,
      actionLabel: 'Confirm zero',
      onAction: enabled ? draft.confirmZero : null,
      actionKey: ValueKey(keyOf('confirm-zero')),
    );
  }
}
