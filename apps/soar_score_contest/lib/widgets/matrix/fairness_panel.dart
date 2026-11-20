import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../collapsible_areas_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/collapsible_areas/collapsible_area.dart';
import '../../services/matrix/fairness_view.dart';
import '../../services/preferences/director_time.dart';
import 'matrix_colors.dart';

/// The fairness summary above the grid: score with its meaning, the key
/// figures, a labelled histogram, and collapsed draw details. It starts open
/// on a tablet and as one line on a narrow screen until the user chooses; the
/// choice is remembered per account ([matrixSummaryArea]).
class FairnessPanel extends StatefulWidget {
  const FairnessPanel({
    super.key,
    required this.revision,
    required this.hasLanes,
    this.configurationRevision,
    this.startCollapsed = false,
  });

  final MatrixRevision revision;
  final bool hasLanes;

  /// The configuration revision the page is looking at, for the details.
  final int? configurationRevision;
  final bool startCollapsed;

  @override
  State<FairnessPanel> createState() => _FairnessPanelState();
}

class _FairnessPanelState extends State<FairnessPanel> {
  /// The user's choices when nothing remembers them (tests without the app).
  bool? _localOpen;
  bool? _localDetails;

  FairnessView get _fairness =>
      FairnessView.of(widget.revision.fairnessSummary);

  Future<void> _toggleSummary(bool open) async {
    final l10n = AppLocalizations.of(context);
    final areas = collapsibleAreasOf(context);
    if (areas == null) {
      setState(() => _localOpen = !open);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (await areas.setOpen(matrixSummaryArea, !open)) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.matrixSummarySaveFailed)),
    );
  }

  Future<void> _toggleDetails(bool open) async {
    final l10n = AppLocalizations.of(context);
    final areas = collapsibleAreasOf(context);
    if (areas == null) {
      setState(() => _localDetails = !open);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (await areas.setOpen(drawDetailsArea, !open)) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.matrixSummarySaveFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fairness = _fairness;
    final startOpen = !widget.startCollapsed;
    final areas = collapsibleAreasOf(context);
    final open = areas == null
        ? _localOpen ?? startOpen
        : areas.isOpen(matrixSummaryArea, fallback: startOpen);
    final details = areas == null
        ? _localDetails ?? false
        : areas.isOpen(drawDetailsArea, fallback: false);
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  _Score(fairness: fairness),
                  _Stats(fairness: fairness, hasLanes: widget.hasLanes),
                  _Histogram(fairness: fairness),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
            child: LayoutBuilder(
              builder: (context, box) {
                final left = [
                  if (!open) _Compact(fairness: fairness),
                  TextButton.icon(
                    key: const ValueKey('draw-details-toggle'),
                    onPressed: () => _toggleDetails(details),
                    icon: Icon(
                      details ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(l10n.matrixDrawDetails),
                  ),
                ];
                final toggle = TextButton.icon(
                  key: const ValueKey('summary-toggle'),
                  onPressed: () => _toggleSummary(open),
                  icon: Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(open ? l10n.matrixHideSummary : l10n.matrixShowSummary),
                );
                // As in the design, "Hide summary" sits at the right end.
                // There is no room for that on a narrow bar, so it wraps in
                // with the rest.
                if (box.maxWidth < 700) {
                  return Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [...left, toggle],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          children: left,
                        ),
                      ),
                    ),
                    toggle,
                  ],
                );
              },
            ),
          ),
          if (details) ...[
            Divider(height: 1, color: scheme.outlineVariant),
            _Details(
              revision: widget.revision,
              configurationRevision: widget.configurationRevision,
            ),
          ],
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier});

  final FairnessTier? tier;

  @override
  Widget build(BuildContext context) {
    final tier = this.tier;
    if (tier == null) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final colors = MatrixColors.of(context);
    final (icon, background, foreground) = switch (tier) {
      FairnessTier.poor => (
        Icons.warning_amber,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      FairnessTier.average => (
        Icons.remove,
        scheme.surfaceContainerHigh,
        scheme.onSurface,
      ),
      FairnessTier.good => (
        Icons.verified_outlined,
        colors.successContainer,
        colors.onSuccessContainer,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(icon, size: 18, color: foreground),
            Text(
              tier.label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.fairness});

  final FairnessView fairness;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 270),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.matrixFairnessScore,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: .5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(
                fairness.scoreText,
                key: const ValueKey('fairness-score'),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              _TierChip(tier: fairness.tier),
            ],
          ),
          Text(
            l10n.matrixFairnessScale,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.fairness, required this.hasLanes});

  final FairnessView fairness;
  final bool hasLanes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = MatrixColors.of(context);
    final unmet = fairness.unmet;
    final maxRepeats = fairness.maxRepeats;
    final stats = <(String, String, String, bool)>[
      (
        l10n.matrixUnmetLabel,
        unmet?.toString() ?? '–',
        l10n.matrixUnmetSub,
        unmet != null && unmet > 0 && (fairness.tier == FairnessTier.poor),
      ),
      (
        l10n.matrixMaxRepeatsLabel,
        maxRepeats == null ? '–' : '$maxRepeats×',
        l10n.matrixMaxRepeatsSub,
        maxRepeats != null && fairness.tier == FairnessTier.poor,
      ),
      if (hasLanes && fairness.laneUniformity != null)
        (
          l10n.matrixLaneUniformityLabel,
          fairness.laneUniformity!.toStringAsFixed(2),
          l10n.matrixLaneUniformitySub,
          false,
        ),
    ];
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        for (final (label, value, sub, warn) in stats)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 112, maxWidth: 170),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (warn)
                      Semantics(
                        label: l10n.matrixNeedsAttention,
                        child: Icon(
                          Icons.warning_amber,
                          size: 18,
                          color: colors.warn,
                        ),
                      ),
                  ],
                ),
                Text(
                  sub,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Histogram extends StatelessWidget {
  const _Histogram({required this.fairness});

  final FairnessView fairness;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bars = fairness.bars;
    final most = bars.fold(0, (a, b) => b.$2 > a ? b.$2 : a);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            l10n.matrixFairnessPairsTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (final (label, count) in bars)
            Row(
              spacing: 8,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(label, style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: most == 0 ? 0 : count / most,
                      minHeight: 10,
                      backgroundColor: scheme.surfaceContainerHigh,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          Text(
            l10n.matrixMeanAbsDeviation(
              fairness.meanAbsoluteDeviation?.toStringAsFixed(2) ?? '–',
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Compact extends StatelessWidget {
  const _Compact({required this.fairness});

  final FairnessView fairness;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          l10n.matrixFairnessCompact(fairness.scoreText),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        _TierChip(tier: fairness.tier),
        Text(
          l10n.matrixFairnessCompactStats(
            '${fairness.unmet ?? '–'}',
            '${fairness.maxRepeats ?? '–'}',
            fairness.meanAbsoluteDeviation?.toStringAsFixed(2) ?? '–',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.revision, this.configurationRevision});

  final MatrixRevision revision;
  final int? configurationRevision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rows = <(String, String, bool)>[
      (l10n.matrixDetailMatrixRevision, '${revision.revisionNumber}', false),
      (
        l10n.matrixDetailConfigurationRevision,
        '${configurationRevision ?? '–'}',
        false,
      ),
      (l10n.matrixDetailAlgorithm, revision.algorithmVersion, false),
      (l10n.matrixDetailRandomSeed, '${revision.randomSeed}', true),
      (l10n.matrixDetailDrawn, DirectorTime.of(context)(revision.createdAt), false),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: [
          for (final (label, value, copyable) in rows)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value, key: ValueKey('detail-$label')),
                      if (copyable)
                        IconButton(
                          tooltip: l10n.matrixCopySeedTooltip,
                          icon: const Icon(Icons.content_copy, size: 18),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: value));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.matrixSeedCopied),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
