import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/draft_validation.dart';
import '../../services/new_contest/scoring_settings.dart';
import '../../services/new_contest/wizard_discipline.dart';
import 'setting_row.dart';
import 'wizard_number_field.dart';

/// Labels for the step 5 values, shared with the summary.
abstract final class ScoringLabels {
  static String groupScore(GroupScoreMode mode) => switch (mode) {
    GroupScoreMode.raw => 'Raw',
    GroupScoreMode.normalized => 'Normalized',
    GroupScoreMode.time => 'Time',
  };

  static String rounding(RoundingMode mode) => switch (mode) {
    RoundingMode.round => 'Round',
    RoundingMode.truncate => 'Truncate',
  };

  static String publicUpdate(PublicUpdateMode mode) => switch (mode) {
    PublicUpdateMode.automatic => 'Automatic',
    PublicUpdateMode.roundCompletion => 'On round completion',
    PublicUpdateMode.manual => 'Manual',
  };

  static String publicUpdateDescription(PublicUpdateMode mode) =>
      switch (mode) {
        PublicUpdateMode.automatic =>
          'Public results update as scores are '
              'entered.',
        PublicUpdateMode.roundCompletion =>
          'Public results update when a '
              'round is complete.',
        PublicUpdateMode.manual =>
          'Public results update only when you '
              'publish.',
      };

  static String drops(ScoringSettings settings) =>
      switch (settings.dropPolicy) {
        DropPolicy.disabled => 'Disabled',
        DropPolicy.one => 'One dropped after round ${settings.firstDrop}',
        DropPolicy.two =>
          'Two dropped, after rounds ${settings.firstDrop} and '
              '${settings.secondDrop}',
      };

  /// [value] rounded or truncated to [places], as text.
  static String example(double value, int places, RoundingMode mode) {
    final scale = [1, 10, 100, 1000][places];
    final scaled = value * scale;
    final kept = mode == RoundingMode.round
        ? scaled.roundToDouble()
        : scaled.truncateToDouble();
    return (kept / scale).toStringAsFixed(places);
  }
}

/// Step 5: the discipline's scoring and publication defaults, editable.
///
/// Each value says whether it is the discipline default; a changed value can
/// be reset. The contest is created unpublished and private.
class ScoringStep extends StatelessWidget {
  const ScoringStep({super.key, required this.draft, required this.onChanged});

  final ContestDraft draft;
  final ValueChanged<ContestDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = draft.scoringSettings;
    final defaults = draft.scoringDefaults;
    final discipline = draft.discipline;
    final defaultLabel = '${discipline?.name ?? 'Platform'} default';
    final drops = DraftValidation.drops(draft);

    void set(ScoringSettings value) =>
        onChanged(draft.copyWith(scoring: value));

    ({String? defaultLabel, String? changedFrom, VoidCallback? onReset}) tag(
      bool same,
      String from,
      ScoringSettings Function() reset,
    ) => same
        ? (defaultLabel: defaultLabel, changedFrom: null, onReset: null)
        : (
            defaultLabel: null,
            changedFrom: 'Changed from $from',
            onReset: () => set(reset()),
          );

    Widget segmented<T>(
      Key key,
      List<(T, String)> options,
      T value,
      ValueChanged<T> onPick,
    ) => SegmentedButton<T>(
      key: key,
      segments: [
        for (final (option, label) in options)
          ButtonSegment(value: option, label: Text(label)),
      ],
      selected: {value},
      onSelectionChanged: (picked) => onPick(picked.single),
    );

    Widget card(String title, List<Widget> rows) => Semantics(
      container: true,
      label: title,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        color: scheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            for (final (index, row) in rows.indexed) ...[
              if (index > 0) Divider(height: 1, color: scheme.outlineVariant),
              row,
            ],
          ],
        ),
      ),
    );

    final mode = tag(
      settings.groupScoreMode == defaults.groupScoreMode,
      ScoringLabels.groupScore(defaults.groupScoreMode),
      () => settings.copyWith(groupScoreMode: defaults.groupScoreMode),
    );
    final traditional =
        discipline == WizardDiscipline.ales ||
        discipline == WizardDiscipline.thermalDuration;
    final rounding = tag(
      settings.roundingMode == defaults.roundingMode,
      ScoringLabels.rounding(defaults.roundingMode),
      () => settings.copyWith(roundingMode: defaults.roundingMode),
    );
    final places = tag(
      settings.decimalPlaces == defaults.decimalPlaces,
      '${defaults.decimalPlaces}',
      () => settings.copyWith(decimalPlaces: defaults.decimalPlaces),
    );
    final dropPolicy = tag(
      settings.dropPolicy == defaults.dropPolicy,
      defaults.dropPolicy.label.toLowerCase(),
      () => settings.copyWith(dropPolicy: defaults.dropPolicy),
    );
    final first = tag(
      settings.firstDrop == defaults.firstDrop,
      'round ${defaults.firstDrop}',
      () => settings.copyWith(firstDrop: defaults.firstDrop),
    );
    final second = tag(
      settings.secondDrop == defaults.secondDrop,
      'round ${defaults.secondDrop}',
      () => settings.copyWith(secondDrop: defaults.secondDrop),
    );
    final review = tag(
      settings.reviewRequests == defaults.reviewRequests,
      defaults.reviewRequests ? 'on' : 'off',
      () => settings.copyWith(reviewRequests: defaults.reviewRequests),
    );
    final policy = tag(
      settings.publicUpdateMode == defaults.publicUpdateMode,
      ScoringLabels.publicUpdate(defaults.publicUpdateMode).toLowerCase(),
      () => settings.copyWith(publicUpdateMode: defaults.publicUpdateMode),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card('Scoring', [
          SettingRow(
            label: 'Group score',
            description: switch (settings.groupScoreMode) {
              GroupScoreMode.raw =>
                'Raw: flight points plus landing bonus, not normalized.',
              GroupScoreMode.normalized =>
                'Normalized: flight points plus landing bonus, normalized to '
                    '1000 in each group.',
              GroupScoreMode.time =>
                'Time: flight time is normalized to 1000 in each group, then '
                    'the landing bonus is added.',
            },
            defaultLabel: mode.defaultLabel,
            changedFrom: mode.changedFrom,
            onReset: mode.onReset,
            control: segmented(
              const ValueKey('group-score'),
              [
                for (final value in GroupScoreMode.values)
                  (value, ScoringLabels.groupScore(value)),
              ],
              settings.groupScoreMode,
              (value) => set(settings.copyWith(groupScoreMode: value)),
            ),
            notes: [
              if (traditional &&
                  settings.groupScoreMode != defaults.groupScoreMode)
                SettingNote.warning(
                  Icons.warning,
                  'No longer a traditional ${discipline!.name} contest',
                  '${discipline.name} uses '
                      '${ScoringLabels.groupScore(defaults.groupScoreMode)} '
                      'group scoring by default.',
                ),
            ],
          ),
          SettingRow(
            label: 'Rounding',
            description: 'What happens to digits beyond the chosen precision.',
            defaultLabel: rounding.defaultLabel,
            changedFrom: rounding.changedFrom,
            onReset: rounding.onReset,
            control: segmented(
              const ValueKey('rounding'),
              [
                for (final value in RoundingMode.values)
                  (value, ScoringLabels.rounding(value)),
              ],
              settings.roundingMode,
              (value) => set(settings.copyWith(roundingMode: value)),
            ),
          ),
          SettingRow(
            label: 'Decimal precision',
            description: 'Digits shown and stored after the decimal point.',
            defaultLabel: places.defaultLabel,
            changedFrom: places.changedFrom,
            onReset: places.onReset,
            hint:
                'Example: 987.4567 → '
                '${ScoringLabels.example(987.4567, settings.decimalPlaces, settings.roundingMode)}',
            control: segmented(
              const ValueKey('decimal-places'),
              [for (var n = 0; n <= 3; n++) (n, '$n')],
              settings.decimalPlaces,
              (value) => set(settings.copyWith(decimalPlaces: value)),
            ),
          ),
          SettingRow(
            label: 'Dropped rounds',
            description: 'Worst rounds left out of each pilot’s total.',
            defaultLabel: dropPolicy.defaultLabel,
            changedFrom: dropPolicy.changedFrom,
            onReset: dropPolicy.onReset,
            control: segmented(
              const ValueKey('drop-policy'),
              [for (final value in DropPolicy.values) (value, value.label)],
              settings.dropPolicy,
              (value) => set(settings.copyWith(dropPolicy: value)),
            ),
          ),
          if (settings.dropPolicy != DropPolicy.disabled)
            SettingRow(
              label: settings.dropPolicy == DropPolicy.two
                  ? 'First drop after round'
                  : 'Drop after round',
              description:
                  'Once this many rounds are complete, each pilot’s worst '
                  'round is left out.',
              defaultLabel: first.defaultLabel,
              changedFrom: first.changedFrom,
              onReset: first.onReset,
              control: WizardNumberField(
                key: const ValueKey('first-drop'),
                value: settings.firstDrop,
                error: drops.first != null,
                semanticLabel: 'Drop after round',
                onChanged: (value) => set(settings.copyWith(firstDrop: value)),
              ),
              notes: [
                if (drops.first != null)
                  SettingNote.error(Icons.error, drops.first!),
              ],
            ),
          if (settings.dropPolicy == DropPolicy.two)
            SettingRow(
              label: 'Second drop after round',
              description:
                  'Once this many rounds are complete, the second worst round '
                  'is also left out. Must be later than the first.',
              defaultLabel: second.defaultLabel,
              changedFrom: second.changedFrom,
              onReset: second.onReset,
              control: WizardNumberField(
                key: const ValueKey('second-drop'),
                value: settings.secondDrop,
                error: drops.second != null,
                semanticLabel: 'Second drop after round',
                onChanged: (value) => set(settings.copyWith(secondDrop: value)),
              ),
              notes: [
                if (drops.second != null)
                  SettingNote.error(
                    Icons.error,
                    drops.second!,
                    drops.second!.startsWith('Must')
                        ? 'The second drop has to come later than the first.'
                        : null,
                  ),
              ],
            ),
        ]),
        const SizedBox(height: 20),
        card('Participants and publication', [
          SettingRow(
            label: 'Score-review requests',
            description:
                'Let pilots ask the contest director to review a '
                'score.',
            defaultLabel: review.defaultLabel,
            changedFrom: review.changedFrom,
            onReset: review.onReset,
            control: Semantics(
              label: 'Score-review requests',
              child: Switch(
                key: const ValueKey('review-requests'),
                value: settings.reviewRequests,
                onChanged: (value) =>
                    set(settings.copyWith(reviewRequests: value)),
              ),
            ),
          ),
          SettingRow(
            label: 'Public update policy',
            description:
                'When public results refresh once the contest is published.',
            defaultLabel: policy.defaultLabel,
            changedFrom: policy.changedFrom,
            onReset: policy.onReset,
            control: const SizedBox.shrink(),
            below: RadioGroup<PublicUpdateMode>(
              groupValue: settings.publicUpdateMode,
              onChanged: (value) {
                if (value != null) {
                  set(settings.copyWith(publicUpdateMode: value));
                }
              },
              child: Column(
                children: [
                  for (final value in PublicUpdateMode.values)
                    RadioListTile<PublicUpdateMode>(
                      key: ValueKey('public-update-${value.name}'),
                      value: value,
                      contentPadding: EdgeInsets.zero,
                      title: Text(ScoringLabels.publicUpdate(value)),
                      subtitle: Text(
                        ScoringLabels.publicUpdateDescription(value),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]),
      ],
    );
  }
}
