import 'package:flutter/material.dart';

import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/copy_mode.dart';
import '../../services/new_contest/draft_validation.dart';
import '../../services/new_contest/draw_settings.dart';
import '../../services/new_contest/participant_option.dart';
import '../../services/new_contest/participant_rules.dart';
import '../../services/new_contest/time_zones.dart';
import 'scoring_step.dart';

/// One summary section: its rows, the step that edits it, and what still
/// needs attention.
class _Section {
  const _Section(this.title, this.step, this.rows, [this.issue]);

  final String title;
  final int step;
  final List<(String, String)> rows;
  final String? issue;
}

/// Step 7: everything the contest will be created with, each section with
/// an Edit action that returns to its step.
class SummaryStep extends StatelessWidget {
  const SummaryStep({
    super.key,
    required this.draft,
    required this.onEdit,
    required this.busy,
  });

  final ContestDraft draft;
  final ValueChanged<int> onEdit;

  /// While creating, editing is disabled.
  final bool busy;

  static const double _minSectionWidth = 340;

  List<_Section> _sections() {
    final d = draft;
    final details = DraftValidation.details(d).length;
    final source = d.source;
    final scoring = d.scoringSettings;
    final draw = d.drawSettings;
    final plan = GroupPlan.of(d);
    final scoringPilots = d.scoringCount;
    final needing = d.participantsNeedingFixes.length;
    final on = [
      for (final option in ParticipantOption.values)
        if (d.has(option))
          option == ParticipantOption.teams
              ? '${option.title} (${d.teamPilotCount.trim()} count for team '
                    'score)'
              : option.title,
    ];
    final off = [
      for (final option in ParticipantOption.values)
        if (!d.has(option)) option.title,
    ];
    final classCounts = [
      for (final name in d.classes)
        '$name (${d.participants.where((p) => d.isScoring(p) && titleCase(p.classification) == name).length})',
    ];
    final location = [
      d.city,
      d.region,
      d.country,
    ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
    final dates = [
      d.startDate.trim(),
      if (d.endDate.trim().isNotEmpty && d.endDate.trim() != d.startDate.trim())
        d.endDate.trim(),
    ].where((s) => s.isNotEmpty).join(' – ');

    return [
      _Section(
        'Details',
        1,
        [
          ('Name', d.name.trim().isEmpty ? '—' : d.name.trim()),
          ('Dates', dates.isEmpty ? '—' : dates),
          ('Venue / host', d.venue.trim().isEmpty ? '—' : d.venue.trim()),
          ('Location', location.isEmpty ? '—' : location),
          ('Time zone', d.timeZone ?? TimeZones.device()),
        ],
        details == 0
            ? null
            : '$details field${details == 1 ? ' needs' : 's need'} attention',
      ),
      _Section(
        'Copy source',
        1,
        source == null || !d.copyMode.usesSource
            ? [('Source', 'Not copying')]
            : [
                ('Source', source.contest.name),
                ('Copies', d.copyMode.label),
                (
                  'Pilots',
                  switch (d.copyMode) {
                    CopyMode.selectedPilots =>
                      '${d.selectedPilots.length} of ${source.pilots.length} '
                          'selected',
                    CopyMode.allPilots => 'All ${source.pilots.length}',
                    _ => 'None',
                  },
                ),
              ],
      ),
      _Section(
        'Discipline',
        2,
        d.discipline == null
            ? [('Discipline', '—')]
            : [
                ('Discipline', d.discipline!.name),
                ('Task', d.discipline!.time ?? '—'),
                ('Landing', d.discipline!.landing ?? '—'),
              ],
        DraftValidation.discipline(d),
      ),
      _Section(
        'Participants',
        4,
        [
          ('People', '${d.participants.length}'),
          ('Scoring pilots', '$scoringPilots'),
          ('Non-flying', '${d.participants.length - scoringPilots}'),
        ],
        scoringPilots < DraftValidation.minScoringPilots
            ? 'Needs at least 2 scoring pilots'
            : needing > 0
            ? '$needing participant${needing == 1 ? ' needs' : 's need'} '
                  'fixing'
            : null,
      ),
      _Section('Enabled options', 3, [
        ('On', on.isEmpty ? 'None' : on.join(', ')),
        ('Off', off.isEmpty ? 'None' : off.join(', ')),
      ], DraftValidation.teamPilotCount(d)),
      _Section('Teams and classes', 4, [
        (
          'Teams',
          !d.has(ParticipantOption.teams)
              ? 'Off'
              : d.teams.isEmpty
              ? 'None assigned yet'
              : d.teams.map((t) => '${t.name} (${t.count})').join(', '),
        ),
        (
          'Classes',
          !d.has(ParticipantOption.classes)
              ? 'Off'
              : classCounts.isEmpty
              ? '—'
              : classCounts.join(', '),
        ),
        if (d.has(ParticipantOption.models))
          ('Models', 'Entered here, not saved with the contest yet'),
      ]),
      _Section('Scoring and publication', 5, [
        ('Group score', ScoringLabels.groupScore(scoring.groupScoreMode)),
        (
          'Precision',
          '${ScoringLabels.rounding(scoring.roundingMode)} to '
              '${scoring.decimalPlaces} dp',
        ),
        ('Dropped rounds', ScoringLabels.drops(scoring)),
        ('Review requests', scoring.reviewRequests ? 'On' : 'Off'),
        (
          'Public updates',
          ScoringLabels.publicUpdate(scoring.publicUpdateMode),
        ),
        ('Visibility', 'Unpublished and private'),
      ], DraftValidation.scoring(d) ? null : 'Dropped rounds need fixing'),
      _Section('Draw options', 6, [
        (
          'Mode',
          draw.seeded
              ? 'Seeded Man on Man (${draw.seededRounds.trim()} seeded)'
              : 'Man on Man',
        ),
        ('Team protection', plan.teamProtection ? 'On' : 'Off'),
        ('Lanes', draw.laneMode.name == 'none' ? 'None' : 'Random'),
        ('Back-to-back', draw.allowBackToBack ? 'Allowed' : 'Avoided'),
      ]),
      _Section('Rounds and groups', 6, [
        ('Rounds', '${d.roundsText.trim()} (rounds can be appended)'),
        ('Groups per round', '${plan.groups}'),
        ('Pilots per group', plan.groupsValid ? plan.perGroupText : '—'),
      ], DraftValidation.drawOptions(d) ? null : 'Group settings are blocked'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final discipline = draft.discipline?.name ?? 'discipline';
    final after = [
      (
        Icons.tune,
        'The contest opens on its configuration page in the Configuring '
            'state.',
      ),
      (Icons.lock, 'It stays unpublished and private until you publish it.'),
      (
        Icons.grid_view,
        'The flight matrix isn’t drawn yet. Draw it from configuration.',
      ),
      (
        Icons.rule,
        'Review $discipline discipline overrides and the remaining settings '
            'there.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                ((constraints.maxWidth + 16) / (_minSectionWidth + 16))
                    .floor()
                    .clamp(1, 3);
            final sections = _sections();
            // Each row of cards is as tall as its tallest card.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var start = 0; start < sections.length; start += columns)
                  Padding(
                    padding: EdgeInsets.only(top: start == 0 ? 0 : 16),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = start; i < start + columns; i++) ...[
                            if (i > start) const SizedBox(width: 16),
                            Expanded(
                              child: i < sections.length
                                  ? _SectionCard(
                                      section: sections[i],
                                      busy: busy,
                                      onEdit: () => onEdit(sections[i].step),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Semantics(
          container: true,
          label: 'After you create',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'After you create',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                for (final (icon, text) in after)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(text, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.busy,
    required this.onEdit,
  });

  final _Section section;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final issue = section.issue;
    final body = theme.textTheme.bodyMedium;
    return Semantics(
      container: true,
      label: section.title,
      child: Card(
        key: ValueKey('summary-${section.title}'),
        margin: EdgeInsets.zero,
        elevation: 1,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: issue == null
              ? BorderSide.none
              : BorderSide(color: scheme.error, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title,
                      style: body?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: ValueKey('edit-${section.title}'),
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'Edit',
                      semanticsLabel: 'Edit ${section.title}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    for (final (label, value) in section.rows)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 16,
                              bottom: 6,
                            ),
                            child: Text(
                              label,
                              style: body?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(value, style: body),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (issue != null) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error, size: 20, color: scheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue,
                        style: body?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
