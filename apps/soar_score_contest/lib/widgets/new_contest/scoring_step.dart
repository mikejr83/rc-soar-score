import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/draft_validation.dart';
import '../../services/new_contest/scoring_settings.dart';
import '../../services/new_contest/wizard_discipline.dart';
import 'setting_row.dart';
import 'wizard_number_field.dart';

/// Labels for the step 5 values, shared with the summary.
abstract final class ScoringLabels {
  static String groupScore(AppLocalizations l10n, GroupScoreMode mode) =>
      switch (mode) {
        GroupScoreMode.raw => l10n.wizardGroupScoreRaw,
        GroupScoreMode.normalized => l10n.wizardGroupScoreNormalized,
        GroupScoreMode.time => l10n.wizardGroupScoreTime,
      };

  static String rounding(AppLocalizations l10n, RoundingMode mode) =>
      switch (mode) {
        RoundingMode.round => l10n.wizardRoundingRound,
        RoundingMode.truncate => l10n.wizardRoundingTruncate,
      };

  static String publicUpdate(AppLocalizations l10n, PublicUpdateMode mode) =>
      switch (mode) {
        PublicUpdateMode.automatic => l10n.wizardPublicUpdateAutomatic,
        PublicUpdateMode.roundCompletion =>
          l10n.wizardPublicUpdateRoundCompletion,
        PublicUpdateMode.manual => l10n.wizardPublicUpdateManual,
      };

  static String publicUpdateDescription(
    AppLocalizations l10n,
    PublicUpdateMode mode,
  ) => switch (mode) {
    PublicUpdateMode.automatic => l10n.wizardPublicUpdateAutomaticDesc,
    PublicUpdateMode.roundCompletion =>
      l10n.wizardPublicUpdateRoundCompletionDesc,
    PublicUpdateMode.manual => l10n.wizardPublicUpdateManualDesc,
  };

  static String scoresBecomeOfficial(
    AppLocalizations l10n,
    OfficializationMode mode,
  ) => switch (mode) {
    OfficializationMode.endOfRound => l10n.scoresBecomeOfficialEndOfRound,
    OfficializationMode.endOfGroup => l10n.scoresBecomeOfficialEndOfGroup,
    OfficializationMode.manual => l10n.scoresBecomeOfficialManual,
  };

  static String scoresBecomeOfficialDescription(
    AppLocalizations l10n,
    OfficializationMode mode,
  ) => switch (mode) {
    OfficializationMode.endOfRound => l10n.scoresBecomeOfficialEndOfRoundHelp,
    OfficializationMode.endOfGroup => l10n.scoresBecomeOfficialEndOfGroupHelp,
    OfficializationMode.manual => l10n.scoresBecomeOfficialManualHelp,
  };

  static String drops(AppLocalizations l10n, ScoringSettings settings) =>
      switch (settings.dropPolicy) {
        DropPolicy.disabled => l10n.wizardDropDisabled,
        DropPolicy.one =>
          '${l10n.wizardDropOne} after round ${settings.firstDrop}',
        DropPolicy.two =>
          '${l10n.wizardDropTwo}, after rounds ${settings.firstDrop} and '
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = draft.scoringSettings;
    final defaults = draft.scoringDefaults;
    final discipline = draft.discipline;
    final defaultLabel = discipline != null
        ? '${discipline.name} ${l10n.wizardDisciplineDefault}'
        : l10n.wizardPlatformDefault;
    final drops = DraftValidation.drops(draft, l10n);

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
            changedFrom: l10n.wizardChangedFrom(from),
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
      ScoringLabels.groupScore(l10n, defaults.groupScoreMode),
      () => settings.copyWith(groupScoreMode: defaults.groupScoreMode),
    );
    final traditional =
        discipline == WizardDiscipline.ales ||
        discipline == WizardDiscipline.thermalDuration;
    final rounding = tag(
      settings.roundingMode == defaults.roundingMode,
      ScoringLabels.rounding(l10n, defaults.roundingMode),
      () => settings.copyWith(roundingMode: defaults.roundingMode),
    );
    final places = tag(
      settings.decimalPlaces == defaults.decimalPlaces,
      '${defaults.decimalPlaces}',
      () => settings.copyWith(decimalPlaces: defaults.decimalPlaces),
    );
    final dropPolicy = tag(
      settings.dropPolicy == defaults.dropPolicy,
      defaults.dropPolicy.label(l10n).toLowerCase(),
      () => settings.copyWith(dropPolicy: defaults.dropPolicy),
    );
    final standard = '${discipline?.name ?? 'platform'} standard';
    final first = defaults.dropPolicy == DropPolicy.disabled
        ? tag(
            false,
            '$standard (${defaults.dropPolicy.label(l10n).toLowerCase()})',
            () => settings.copyWith(dropPolicy: defaults.dropPolicy),
          )
        : tag(
            settings.firstDrop == defaults.firstDrop,
            'round ${defaults.firstDrop}',
            () => settings.copyWith(firstDrop: defaults.firstDrop),
          );
    final second = defaults.dropPolicy == DropPolicy.two
        ? tag(
            settings.secondDrop == defaults.secondDrop,
            'round ${defaults.secondDrop}',
            () => settings.copyWith(secondDrop: defaults.secondDrop),
          )
        : tag(
            false,
            '$standard (${defaults.dropPolicy.label(l10n).toLowerCase()})',
            () => settings.copyWith(dropPolicy: defaults.dropPolicy),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(l10n.wizardScoringCard, [
          SettingRow(
            label: l10n.wizardGroupScoreLabel,
            description: switch (settings.groupScoreMode) {
              GroupScoreMode.raw => l10n.wizardGroupScoreRawDesc,
              GroupScoreMode.normalized => l10n.wizardGroupScoreNormalizedDesc,
              GroupScoreMode.time => l10n.wizardGroupScoreTimeDesc,
            },
            defaultLabel: mode.defaultLabel,
            changedFrom: mode.changedFrom,
            onReset: mode.onReset,
            control: segmented(
              const ValueKey('group-score'),
              [
                for (final value in GroupScoreMode.values)
                  (value, ScoringLabels.groupScore(l10n, value)),
              ],
              settings.groupScoreMode,
              (value) => set(settings.copyWith(groupScoreMode: value)),
            ),
            notes: [
              if (traditional &&
                  settings.groupScoreMode != defaults.groupScoreMode)
                SettingNote.warning(
                  Icons.warning,
                  l10n.wizardGroupScoreTraditional(discipline!.name),
                  l10n.wizardGroupScoreTraditionalBody(
                    discipline.name,
                    ScoringLabels.groupScore(l10n, defaults.groupScoreMode),
                  ),
                ),
            ],
          ),
          SettingRow(
            label: l10n.wizardRoundingLabel,
            description: l10n.wizardRoundingDesc,
            defaultLabel: rounding.defaultLabel,
            changedFrom: rounding.changedFrom,
            onReset: rounding.onReset,
            control: segmented(
              const ValueKey('rounding'),
              [
                for (final value in RoundingMode.values)
                  (value, ScoringLabels.rounding(l10n, value)),
              ],
              settings.roundingMode,
              (value) => set(settings.copyWith(roundingMode: value)),
            ),
          ),
          SettingRow(
            label: l10n.wizardPrecisionLabel,
            description: l10n.wizardPrecisionDesc,
            defaultLabel: places.defaultLabel,
            changedFrom: places.changedFrom,
            onReset: places.onReset,
            hint: l10n.wizardPrecisionExample(
              ScoringLabels.example(
                987.4567,
                settings.decimalPlaces,
                settings.roundingMode,
              ),
            ),
            control: segmented(
              const ValueKey('decimal-places'),
              [for (var n = 0; n <= 3; n++) (n, '$n')],
              settings.decimalPlaces,
              (value) => set(settings.copyWith(decimalPlaces: value)),
            ),
          ),
          SettingRow(
            label: l10n.wizardDroppedRoundsLabel,
            description: l10n.wizardDroppedRoundsDesc,
            defaultLabel: dropPolicy.defaultLabel,
            changedFrom: dropPolicy.changedFrom,
            onReset: dropPolicy.onReset,
            control: segmented(
              const ValueKey('drop-policy'),
              [
                for (final value in DropPolicy.values)
                  (value, value.label(l10n)),
              ],
              settings.dropPolicy,
              (value) => set(settings.copyWith(dropPolicy: value)),
            ),
          ),
          if (settings.dropPolicy != DropPolicy.disabled)
            SettingRow(
              label: settings.dropPolicy == DropPolicy.two
                  ? l10n.wizardFirstDropLabel
                  : l10n.wizardDropAfterRound,
              description: l10n.wizardDropAfterRoundDesc,
              defaultLabel: first.defaultLabel,
              changedFrom: first.changedFrom,
              onReset: first.onReset,
              control: WizardNumberField(
                key: const ValueKey('first-drop'),
                value: settings.firstDrop,
                error: drops.first != null,
                semanticLabel: l10n.wizardDropAfterRound,
                onChanged: (value) => set(settings.copyWith(firstDrop: value)),
              ),
              notes: [
                if (drops.first != null)
                  SettingNote.error(Icons.error, drops.first!),
              ],
            ),
          if (settings.dropPolicy == DropPolicy.two)
            SettingRow(
              label: l10n.wizardSecondDropAfterRound,
              description: l10n.wizardSecondDropDesc,
              defaultLabel: second.defaultLabel,
              changedFrom: second.changedFrom,
              onReset: second.onReset,
              control: WizardNumberField(
                key: const ValueKey('second-drop'),
                value: settings.secondDrop,
                error: drops.second != null,
                semanticLabel: l10n.wizardSecondDropAfterRound,
                onChanged: (value) => set(settings.copyWith(secondDrop: value)),
              ),
              notes: [
                if (drops.second != null)
                  SettingNote.error(
                    Icons.error,
                    drops.second!,
                    drops.second!.startsWith('Must')
                        ? l10n.wizardSecondDropLater
                        : null,
                  ),
              ],
            ),
        ]),
        const SizedBox(height: 20),
        card(l10n.wizardParticipantsPublication, [
          SettingRow(
            label: l10n.wizardReviewRequestsLabel,
            description: l10n.wizardReviewRequestsDesc,
            control: Semantics(
              label: l10n.wizardReviewRequestsLabel,
              child: Switch(
                key: const ValueKey('review-requests'),
                value: settings.reviewRequests,
                onChanged: (value) =>
                    set(settings.copyWith(reviewRequests: value)),
              ),
            ),
          ),
          SettingRow(
            label: l10n.scoresBecomeOfficialLabel,
            description: l10n.scoresBecomeOfficialHelp,
            control: const SizedBox.shrink(),
            below: RadioGroup<OfficializationMode>(
              groupValue: settings.scoresBecomeOfficial,
              onChanged: (value) {
                if (value != null) {
                  set(settings.copyWith(scoresBecomeOfficial: value));
                }
              },
              child: Column(
                children: [
                  for (final value in OfficializationMode.values)
                    RadioListTile<OfficializationMode>(
                      key: ValueKey('scores-become-official-${value.name}'),
                      value: value,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        ScoringLabels.scoresBecomeOfficial(l10n, value),
                      ),
                      subtitle: Text(
                        ScoringLabels.scoresBecomeOfficialDescription(
                          l10n,
                          value,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SettingRow(
            label: l10n.wizardPublicUpdateLabel,
            description: l10n.wizardPublicUpdateDesc,
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
                      title: Text(ScoringLabels.publicUpdate(l10n, value)),
                      subtitle: Text(
                        ScoringLabels.publicUpdateDescription(l10n, value),
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
