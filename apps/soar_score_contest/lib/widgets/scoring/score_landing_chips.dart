import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// One landing choice: its label over its points, 52 dp tall.
class ScoreLandingChip extends StatelessWidget {
  const ScoreLandingChip({
    super.key,
    required this.label,
    required this.points,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String points;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: '$label, $points',
      button: true,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          canRequestFocus: false,
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 60, minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) Icon(Icons.check, size: 16, color: fg),
                      Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(color: fg),
                      ),
                    ],
                  ),
                  Text(
                    points,
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bands of the contest's landing table as a radio group. They stay
/// clickable for touch and mouse but are out of the Tab order: the Landing
/// field in the row is the keyboard path. While that field has focus the
/// strip is outlined to show that it follows it.
class ScoreLandingChoice extends StatelessWidget {
  const ScoreLandingChoice({
    super.key,
    required this.landings,
    required this.selected,
    required this.enabled,
    required this.keyPrefix,
    required this.onSelected,
    this.followsField = false,
  });

  final List<LandingResult> landings;
  final String? selected;
  final bool enabled;
  final String keyPrefix;
  final ValueChanged<LandingResult> onSelected;

  /// True while the Landing field has focus.
  final bool followsField;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('$keyPrefix-strip'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: followsField ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final landing in landings)
            ScoreLandingChip(
              key: ValueKey('$keyPrefix-${landing.entryKey}'),
              label: landing.displayValue,
              points: '${landing.pointValue} pts',
              selected: selected == landing.entryKey,
              enabled: enabled,
              onTap: () => onSelected(landing),
            ),
        ],
      ),
    );
  }
}
