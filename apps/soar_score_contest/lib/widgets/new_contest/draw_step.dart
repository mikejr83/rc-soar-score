import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

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

  static const String whyExclusive =
      'Seeded draws place pilots by ranking, so they can’t also keep '
      'teammates in separate groups.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = draft.drawSettings;
    final plan = GroupPlan.of(draft);
    final errors = DraftValidation.draw(draft);
    final teamsOn = draft.has(ParticipantOption.teams);
    final protection = settings.teamProtection;

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
      'Draw mode',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Draw mode', style: title),
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
                      'Man on Man',
                      'Random groups each round, mixed so pilots meet as many '
                          'others as possible.',
                    ),
                    (
                      DrawMode.seededManOnMan,
                      'Seeded Man on Man',
                      'After the seeded rounds, pilots with similar scores '
                          'fly together.',
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
                            ? 'Unavailable while team protection is on. '
                                  '$whyExclusive Turn off team protection to '
                                  'choose it.'
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
        Text('Groups per round', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        WizardNumberField(
          key: const ValueKey('groups-per-round'),
          value: settings.groups ?? '${plan.groups}',
          steppers: true,
          max: plan.maxGroups < plan.minGroups
              ? plan.minGroups
              : plan.maxGroups,
          error: errors.groups != null,
          semanticLabel: 'Groups per round',
          onChanged: (value) => set(settings.copyWith(groups: value)),
        ),
        const SizedBox(height: 8),
        Text(
          errors.groups ??
              (plan.teamProtection && plan.groups == plan.minGroups
                  ? 'Minimum ${plan.minGroups}: team protection keeps the '
                        '${plan.largestTeam} pilots of your largest team in '
                        'separate groups.'
                  : 'Between ${plan.minGroups} and ${plan.maxGroups} for '
                        '${plan.scoring} scoring pilots.'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: errors.groups != null ? scheme.error : muted,
          ),
        ),
        const SizedBox(height: 20),
        Text('Preliminary rounds', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        WizardNumberField(
          key: const ValueKey('preliminary-rounds'),
          value: draft.roundsText,
          error: errors.rounds != null,
          semanticLabel: 'Preliminary rounds',
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
                errors.rounds ??
                    'Rounds can be appended after the contest starts.',
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
      'Groups and rounds',
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
          label: 'Seeded rounds',
          description:
              'Man-on-man rounds flown before seeding starts. Minimum 1.',
          control: WizardNumberField(
            key: const ValueKey('seeded-rounds'),
            value: settings.seededRounds,
            error: errors.seededRounds != null,
            semanticLabel: 'Seeded rounds',
            onChanged: (value) => set(settings.copyWith(seededRounds: value)),
          ),
          notes: [
            if (errors.seededRounds != null)
              const SettingNote.error(
                Icons.error,
                'At least 1 seeded round',
                'Enter 1 or more.',
              ),
          ],
        ),
      SettingRow(
        label: 'Lane mode',
        description: 'Whether pilots get a launch lane within their group.',
        control: SegmentedButton<LaneMode>(
          key: const ValueKey('lane-mode'),
          segments: const [
            ButtonSegment(value: LaneMode.none, label: Text('None')),
            ButtonSegment(value: LaneMode.random, label: Text('Random')),
          ],
          selected: {settings.laneMode},
          onSelectionChanged: (picked) =>
              set(settings.copyWith(laneMode: picked.single)),
        ),
      ),
      SettingRow(
        label: 'Team protection',
        enabled: teamsOn && !settings.seeded,
        description: teamsOn && !settings.seeded
            ? 'Keeps teammates out of the same group. Needs at least as many '
                  'groups as your largest team has pilots '
                  '(${draft.largestTeamPilots}).'
            : 'Keeps teammates out of the same group.',
        control: Semantics(
          label: 'Team protection',
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
            const SettingNote.info(
              Icons.info,
              'Teams are off',
              'Turn on Teams in Participant options to use team protection.',
            )
          else if (settings.seeded)
            const SettingNote.info(
              Icons.block,
              'Unavailable with Seeded Man on Man',
              '$whyExclusive Choose Man on Man to use team protection.',
            )
          else if (protection)
            const SettingNote.info(
              Icons.info,
              'Seeded Man on Man is now unavailable',
              'The two can’t be combined. Turn this off if you want a seeded '
                  'draw.',
            ),
        ],
      ),
      SettingRow(
        label: 'Allow back-to-back flights',
        description:
            'A pilot may fly the last group of one round and the first group '
            'of the next.',
        control: Semantics(
          label: 'Allow back-to-back flights',
          child: Switch(
            key: const ValueKey('back-to-back'),
            value: settings.allowBackToBack,
            onChanged: (on) => set(settings.copyWith(allowBackToBack: on)),
          ),
        ),
        notes: [
          if (!settings.allowBackToBack) ...[
            const SettingNote.warning(
              Icons.balance,
              'Draw fairness decreases',
              'Keeping pilots out of consecutive flights limits how the draw '
                  'can mix pilots, so some match-ups repeat more often.',
            ),
            if (plan.tooSmallForBackToBack)
              SettingNote.error(
                Icons.warning,
                'This contest is too small for the constraint',
                'With ${plan.groups} group${plan.groups == 1 ? '' : 's'}, a '
                    'pilot in the last group of one round would also fly in '
                    'the first group of the next. Use at least 3 groups or '
                    'allow back-to-back flights.',
              ),
          ],
        ],
      ),
    ];

    final constraintsCard = card(
      'Constraints',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('Constraints', style: title),
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
