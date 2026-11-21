import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/draft_validation.dart';
import '../../services/new_contest/draw_settings.dart';
import '../../services/participants/participant_option.dart';
import 'group_calculation_panel.dart';
import 'setting_row.dart';
import 'wizard_number_field.dart';

/// Step 6: how pilots are grouped. The matrix is not drawn here.
///
/// Groups per round shows the live pilots-per-group calculation and blocks
/// groups with fewer than 2 scoring pilots. Team protection and a seeded
/// draw can't be combined: choosing one disables the other and says why.
class DrawStep extends StatelessWidget {
  const DrawStep({super.key, required this.draft, required this.onChanged});

  final ContestDraft draft;
  final ValueChanged<ContestDraft> onChanged;

  static String whyExclusive(AppLocalizations l10n) =>
      l10n.wizardDrawModeWhyExclusive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = draft.drawSettings;
    final plan = GroupPlan.of(draft);
    final errors = DraftValidation.draw(draft, l10n);
    final teamsOn = draft.has(ParticipantOption.teams);
    final protection = settings.teamProtection;
    final exclusive = whyExclusive(l10n);

    void set(DrawSettings value) => onChanged(draft.copyWith(draw: value));

    Widget card(String title, Widget child, {EdgeInsets? padding}) => Semantics(
      container: true,
      label: title,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: child,
        ),
      ),
    );

    final title = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
    );
    final muted = scheme.onSurfaceVariant;

    final modes = card(
      l10n.wizardDrawMode,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.wizardDrawMode, style: title),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 532 ? 2 : 1;
              final width =
                  (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (mode, name, description) in [
                    (
                      DrawMode.standardManOnMan,
                      l10n.wizardDrawModeManOnMan,
                      l10n.wizardDrawModeManOnManDesc,
                    ),
                    (
                      DrawMode.seededManOnMan,
                      l10n.wizardDrawModeSeeded,
                      l10n.wizardDrawModeSeededDesc,
                    ),
                  ])
                    SizedBox(
                      width: width,
                      child: _DrawModeTile(
                        key: ValueKey('draw-mode-${mode.name}'),
                        name: name,
                        description: description,
                        selected: settings.drawMode == mode,
                        disabledReason:
                            mode == DrawMode.seededManOnMan && protection
                            ? l10n.wizardDrawModeUnavailable(exclusive)
                            : null,
                        onTap: () => set(settings.copyWith(drawMode: mode)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );

    final inputs = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.wizardGroupsPerRound, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        WizardNumberField(
          key: const ValueKey('groups-per-round'),
          value: settings.groups ?? '${plan.groups}',
          steppers: true,
          max: plan.maxGroups < plan.minGroups
              ? plan.minGroups
              : plan.maxGroups,
          error: errors.groups != null,
          semanticLabel: l10n.wizardGroupsPerRound,
          onChanged: (value) => set(settings.copyWith(groups: value)),
        ),
        const SizedBox(height: 8),
        Text(
          errors.groups ??
              (plan.teamProtection && plan.groups == plan.minGroups
                  ? l10n.wizardMinimumGroups(plan.minGroups, plan.largestTeam)
                  : l10n.wizardGroupsRange(
                      plan.minGroups,
                      plan.maxGroups,
                      plan.scoring,
                    )),
          style: theme.textTheme.bodySmall?.copyWith(
            color: errors.groups != null ? scheme.error : muted,
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.wizardPreliminaryRounds, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        WizardNumberField(
          key: const ValueKey('preliminary-rounds'),
          value: draft.roundsText,
          error: errors.rounds != null,
          semanticLabel: l10n.wizardPreliminaryRounds,
          onChanged: (value) => set(settings.copyWith(rounds: value)),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.edit_calendar, size: 16, color: muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                errors.rounds ?? l10n.wizardRoundsAppendNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: errors.rounds != null ? scheme.error : muted,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final groupsCard = card(
      l10n.wizardGroupsAndRounds,
      LayoutBuilder(
        builder: (context, constraints) {
          final panel = GroupCalculationPanel(plan: plan, teamsOn: teamsOn);
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [inputs, const SizedBox(height: 20), panel],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: inputs),
              const SizedBox(width: 32),
              Expanded(child: panel),
            ],
          );
        },
      ),
    );

    final constraintRows = <Widget>[
      if (settings.seeded)
        SettingRow(
          label: l10n.wizardSeededRounds,
          description: l10n.wizardSeededRoundsDesc,
          control: WizardNumberField(
            key: const ValueKey('seeded-rounds'),
            value: settings.seededRounds,
            error: errors.seededRounds != null,
            semanticLabel: l10n.wizardSeededRounds,
            onChanged: (value) => set(settings.copyWith(seededRounds: value)),
          ),
          notes: [
            if (errors.seededRounds != null)
              SettingNote.error(
                Icons.error,
                l10n.wizardSeededRoundsAtLeast1,
                l10n.wizardValidationSeededRounds,
              ),
          ],
        ),
      SettingRow(
        label: l10n.wizardLaneMode,
        description: l10n.wizardLaneModeDesc,
        control: SegmentedButton<LaneMode>(
          key: const ValueKey('lane-mode'),
          segments: [
            ButtonSegment(
              value: LaneMode.none,
              label: Text(l10n.wizardLaneNone),
            ),
            ButtonSegment(
              value: LaneMode.random,
              label: Text(l10n.wizardLaneRandom),
            ),
          ],
          selected: {settings.laneMode},
          onSelectionChanged: (picked) =>
              set(settings.copyWith(laneMode: picked.single)),
        ),
      ),
      SettingRow(
        label: l10n.wizardTeamProtection,
        enabled: teamsOn && !settings.seeded,
        description: teamsOn && !settings.seeded
            ? l10n.wizardTeamProtectionDesc(draft.largestTeamPilots)
            : l10n.wizardTeamProtectionDescOff,
        control: Semantics(
          label: l10n.wizardTeamProtection,
          child: Switch(
            key: const ValueKey('team-protection'),
            value: protection,
            onChanged: teamsOn && !settings.seeded
                ? (on) {
                    var updated = settings.copyWith(teamProtection: on);
                    if (on && plan.groups < draft.largestTeamPilots) {
                      updated = updated.copyWith(
                        groups: '${draft.largestTeamPilots}',
                      );
                    }
                    set(updated);
                  }
                : null,
          ),
        ),
        notes: [
          if (!teamsOn)
            SettingNote.info(
              Icons.info,
              l10n.wizardTeamsOffNote,
              l10n.wizardTeamsOffNoteBody,
            )
          else if (settings.seeded)
            SettingNote.info(
              Icons.block,
              l10n.wizardSeededUnavailableNote,
              l10n.wizardSeededUnavailableNoteBody(exclusive),
            )
          else if (protection)
            SettingNote.info(
              Icons.info,
              l10n.wizardSeededUnavailableNote2,
              l10n.wizardSeededUnavailableNote2Body,
            ),
        ],
      ),
      SettingRow(
        label: l10n.wizardBackToBack,
        description: l10n.wizardBackToBackDesc,
        control: Semantics(
          label: l10n.wizardBackToBack,
          child: Switch(
            key: const ValueKey('back-to-back'),
            value: settings.allowBackToBack,
            onChanged: (on) => set(settings.copyWith(allowBackToBack: on)),
          ),
        ),
        notes: [
          if (!settings.allowBackToBack) ...[
            SettingNote.warning(
              Icons.balance,
              l10n.wizardBackToBackFairness,
              l10n.wizardBackToBackFairnessBody,
            ),
            if (plan.tooSmallForBackToBack)
              SettingNote.error(
                Icons.warning,
                l10n.wizardBackToBackTooSmall,
                l10n.wizardBackToBackTooSmallBody(
                  plan.groups,
                  plan.groups == 1 ? '' : 's',
                ),
              ),
          ],
        ],
      ),
    ];

    final constraintsCard = card(
      l10n.wizardConstraints,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(l10n.wizardConstraints, style: title),
          ),
          for (final (index, row) in constraintRows.indexed) ...[
            if (index > 0) Divider(height: 1, color: scheme.outlineVariant),
            row,
          ],
        ],
      ),
      padding: EdgeInsets.zero,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        modes,
        const SizedBox(height: 20),
        groupsCard,
        const SizedBox(height: 20),
        constraintsCard,
      ],
    );
  }
}

class _DrawModeTile extends StatelessWidget {
  const _DrawModeTile({
    super.key,
    required this.name,
    required this.description,
    required this.selected,
    required this.onTap,
    this.disabledReason,
  });

  final String name;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  /// Why the mode can't be chosen; `null` when it can.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = disabledReason == null;
    final disabled = scheme.onSurface.withValues(alpha: 0.38);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: enabled ? '$name. $description' : '$name. $disabledReason',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled && !selected ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: !enabled
                      ? disabled
                      : selected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: enabled ? null : disabled,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: enabled ? scheme.onSurfaceVariant : disabled,
                        ),
                      ),
                      if (!enabled) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.block, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                disabledReason!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
