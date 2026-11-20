import 'package:material_ui/material_ui.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../landings/landing_unit_text.dart';

/// The key-to-points table of a landing table, shown in the landing section
/// and in the picker preview.
class LandingEntriesTable extends StatelessWidget {
  const LandingEntriesTable({super.key, required this.view});

  final LandingTableView view;

  /// The header over the keys: `Distance (m)`, `Distance (ft)`, `Landing key`.
  static String keyHeader(AppLocalizations l10n, LandingInputUnit unit) =>
      switch (unit) {
        LandingInputUnit.meters => l10n.configLandingKeyHeaderMeters,
        LandingInputUnit.feet => l10n.configLandingKeyHeaderFeet,
        LandingInputUnit.points => l10n.configLandingKeyHeaderPoints,
      };

  /// `1 to 50 points`, or `No entries`.
  static String pointsRange(AppLocalizations l10n, LandingTableView view) {
    if (view.results.isEmpty) {
      return l10n.configLandingNoEntries;
    }
    final points = view.results.map((r) => r.pointValue);
    final low = points.reduce((a, b) => a < b ? a : b);
    final high = points.reduce((a, b) => a > b ? a : b);
    return l10n.configLandingPointsRangeValue(low, high);
  }

  /// `Meters · 10 entries · 5–50 points`.
  static String summary(AppLocalizations l10n, LandingTableView view) =>
      '${landingUnitLabel(l10n, view.table.inputUnit)} · '
      '${l10n.configLandingEntriesCount(view.results.length)} · '
      '${pointsRange(l10n, view)}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = [...view.results]
      ..sort((a, b) => a.ordinalPosition.compareTo(b.ordinalPosition));
    final header = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final numbers = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: l10n.configLandingEntriesLabel(view.table.name),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Container(
                  color: scheme.surfaceContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                            keyHeader(l10n, view.table.inputUnit),
                            style: header,
                          ),
                      ),
                      Expanded(
                          child: Text(
                            l10n.landingsPointsHeading,
                            textAlign: TextAlign.end,
                            style: header,
                          ),
                      ),
                    ],
                  ),
                ),
                for (final entry in entries) ...[
                  Divider(height: 1, color: scheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(entry.displayValue, style: numbers),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.pointValue}',
                            textAlign: TextAlign.end,
                            style: numbers,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
