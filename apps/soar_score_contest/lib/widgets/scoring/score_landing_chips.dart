import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// The landing choice of the contest's landing table as a radio group. The
/// arrow keys pick, Enter moves on.
class ScoreLandingChoice extends StatelessWidget {
  const ScoreLandingChoice({
    super.key,
    required this.landings,
    required this.selected,
    required this.enabled,
    required this.focusNode,
    required this.keyPrefix,
    required this.onSelected,
    required this.onEnter,
  });

  final List<LandingResult> landings;
  final String? selected;
  final bool enabled;
  final FocusNode focusNode;
  final String keyPrefix;
  final ValueChanged<String?> onSelected;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    void move(int delta) {
      final keys = [for (final l in landings) l.entryKey];
      final at = selected == null ? -1 : keys.indexOf(selected!);
      onSelected(keys[(at + delta).clamp(0, keys.length - 1)]);
    }

    return Focus(
      focusNode: focusNode,
      canRequestFocus: enabled,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.arrowDown) {
          move(1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowUp) {
          move(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          onEnter();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Wrap(
        key: ValueKey(keyPrefix),
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
              onTap: () => onSelected(
                selected == landing.entryKey ? null : landing.entryKey,
              ),
            ),
        ],
      ),
    );
  }
}
