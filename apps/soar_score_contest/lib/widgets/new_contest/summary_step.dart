import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/copy_mode.dart';
import '../../services/new_contest/draft_validation.dart';
import '../../services/new_contest/draw_settings.dart';
import '../../services/participants/participant_option.dart';
import '../../services/participants/participant_row.dart';
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

  List<_Section> _sections(AppLocalizations l10n) {
    final d = draft;
    final details = DraftValidation.details(d, l10n).length;
    final source = d.source;
    final scoring = d.scoringSettings;
    final draw = d.drawSettings;
    final plan = GroupPlan.of(d);
    final scoringPilots = d.scoringCount;
    final needing = d.participantsNeedingFixes.length;
    final modelCount = d.participants
        .where(d.isScoring)
        .fold<int>(0, (count, p) => count + p.models.length);
    final on = [
      for (final option in ParticipantOption.values)
        if (d.has(option))
          option == ParticipantOption.teams
              ? '${option.title(l10n)} (${l10n.wizardTeamCount(d.teamPilotCount.trim())})'
              : option.title(l10n),
    ];
    final off = [
      for (final option in ParticipantOption.values)
        if (!d.has(option)) option.title(l10n),
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
        l10n.wizardDetails,
        1,
        [
          (l10n.wizardName, d.name.trim().isEmpty ? '—' : d.name.trim()),
          (l10n.wizardDates, dates.isEmpty ? '—' : dates),
          (l10n.wizardVenueHost, d.venue.trim().isEmpty ? '—' : d.venue.trim()),
          (l10n.wizardLocation, location.isEmpty ? '—' : location),
          (
            l10n.wizardTimeZoneLabel,
            ContestTimeZones.label(
              TimeZones.effective(d.timeZone, d.country),
              at: DraftValidation.parseDate(d.startDate),
            ),
          ),
        ],
        details == 0
            ? null
            : l10n.wizardFieldsNeedAttentionSummary(details),
      ),
      _Section(
        l10n.wizardCopySourceSection,
        1,
        source == null || !d.copyMode.usesSource
            ? [(l10n.wizardCopySourceLabel, l10n.wizardNotCopying)]
            : [
                (l10n.wizardCopySourceLabel, source.contest.name),
                (l10n.wizardCopyCopiesLabel, d.copyMode.label(l10n)),
                (
                  l10n.wizardCopyPilotsLabel,
                  switch (d.copyMode) {
                    CopyMode.selectedPilots =>
                      '${d.selectedPilots.length} of ${source.pilots.length} '
                          'selected',
                    CopyMode.allPilots => l10n.wizardCopyAllPilots(source.pilots.length),
                    _ => l10n.wizardCopyNone,
                  },
                ),
              ],
      ),
      _Section(
        l10n.wizardDisciplineSection,
        2,
        d.discipline == null
            ? [(l10n.wizardDisciplineSection, '—')]
            : [
                (l10n.wizardDisciplineSection, d.discipline!.name),
                (l10n.wizardTask, d.discipline!.time ?? '—'),
                (l10n.wizardLanding, d.discipline!.landing ?? '—'),
              ],
        DraftValidation.discipline(d, l10n),
      ),
      _Section(
        l10n.wizardParticipantsSection,
        4,
        d.has(ParticipantOption.roles)
            ? [
                (l10n.wizardPeople, '${d.participants.length}'),
                (l10n.wizardScoringPilots, '$scoringPilots'),
                (l10n.wizardNonFlying, '${d.participants.length - scoringPilots}'),
              ]
            : [(l10n.wizardPilots, '$scoringPilots')],
        scoringPilots < DraftValidation.minScoringPilots
            ? l10n.wizardNeedsAtLeast2
            : needing > 0
            ? l10n.wizardParticipantsNeedFixing(needing)
            : null,
      ),
      _Section(l10n.wizardEnabledOptions, 3, [
        (l10n.wizardOn, on.isEmpty ? l10n.wizardCopyNone : on.join(', ')),
        (l10n.wizardOff, off.isEmpty ? l10n.wizardCopyNone : off.join(', ')),
      ], DraftValidation.teamPilotCount(d, l10n)),
      _Section(l10n.wizardTeamsClasses, 4, [
        (
          l10n.wizardTeams,
          !d.has(ParticipantOption.teams)
              ? l10n.wizardOff
              : d.teams.isEmpty
              ? l10n.wizardNoneAssigned
              : d.teams.map((t) => '${t.name} (${t.count})').join(', '),
        ),
        (
          l10n.wizardClasses,
          !d.has(ParticipantOption.classes)
              ? l10n.wizardOff
              : classCounts.isEmpty
              ? '—'
              : classCounts.join(', '),
        ),
        if (d.has(ParticipantOption.models))
          (
            l10n.wizardModels,
            d.participants.any((p) => d.isScoring(p) && p.models.isEmpty)
                ? l10n.wizardModelsEntered(modelCount)
                : l10n.wizardModelsEnteredSimple(modelCount),
          ),
      ]),
      _Section(l10n.wizardParticipantsPublication, 5, [
        (l10n.wizardGroupScoreLabel, ScoringLabels.groupScore(l10n, scoring.groupScoreMode)),
        (
          l10n.wizardPrecisionLabel,
          '${ScoringLabels.rounding(l10n, scoring.roundingMode)} to '
              '${scoring.decimalPlaces} dp',
        ),
        (l10n.wizardDroppedRoundsLabel, ScoringLabels.drops(l10n, scoring)),
        (l10n.wizardReviewRequestsLabel, scoring.reviewRequests ? 'On' : 'Off'),
        (
          l10n.scoresBecomeOfficialLabel,
          ScoringLabels.scoresBecomeOfficial(
            l10n,
            scoring.scoresBecomeOfficial,
          ),
        ),
        (
          l10n.wizardPublicUpdateLabel,
          ScoringLabels.publicUpdate(l10n, scoring.publicUpdateMode),
        ),
        (l10n.wizardVisibility, 'Unpublished and private'),
      ], DraftValidation.scoring(d, l10n) ? null : l10n.wizardDroppedRoundsNeedFixing),
      _Section(l10n.wizardStepDrawOptions, 6, [
        (
          l10n.wizardDrawMode,
          draw.seeded
               ? '${l10n.wizardDrawModeSeeded} (${draw.seededRounds.trim()} seeded)'
              : l10n.wizardDrawModeManOnMan,
        ),
        (l10n.wizardTeamProtection, plan.teamProtection ? l10n.wizardOn : l10n.wizardOff),
        (
          l10n.wizardLanes,
          draw.laneMode.name == 'none' ? l10n.wizardNoLaneAssignment : l10n.wizardLaneRandom,
        ),
        (l10n.wizardBackToBack, draw.allowBackToBack ? l10n.wizardAllowed : l10n.wizardAvoided),
      ]),
      _Section(l10n.wizardRoundsGroups, 6, [
        (l10n.wizardRounds, '${d.roundsText.trim()} (${l10n.wizardRoundsAppendNote})'),
        (l10n.wizardGroupsPerRound, '${plan.groups}'),
        (l10n.wizardPilotsPerGroup, plan.groupsValid ? plan.perGroupText : '—'),
      ], DraftValidation.drawOptions(d, l10n) ? null : l10n.wizardGroupSettingsBlocked),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final discipline = draft.discipline?.name ?? 'discipline';
    final after = [
      (Icons.tune, l10n.wizardAfterCreateConfig),
      (Icons.lock, l10n.wizardAfterCreatePrivate),
      (Icons.grid_view, l10n.wizardAfterCreateMatrix),
      (
        Icons.rule,
        l10n.wizardAfterCreateReview(discipline),
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
            final sections = _sections(AppLocalizations.of(context));
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
          label: l10n.wizardAfterCreate,
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
