import 'package:flutter/material.dart';

/// How a [StatusChip] is filled.
enum StatusChipStyle {
  /// `brand-deep` fill: the one orange fill of a screen region.
  filled,

  /// Ink outline, no fill.
  outlined,

  /// Sunken neutral fill.
  tonal,

  /// Hairline outline and muted text, for things that are not happening.
  quiet,
}

/// Status as colour, icon and word together; rows never change ground by
/// state, so this chip carries it.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.icon,
    this.style = StatusChipStyle.outlined,
    super.key,
  });

  final String label;
  final IconData icon;
  final StatusChipStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color? fill, Color text, BorderSide? border) = switch (style) {
      StatusChipStyle.filled => (scheme.primary, scheme.onPrimary, null),
      StatusChipStyle.outlined => (
        null,
        scheme.onSurface,
        BorderSide(color: scheme.onSurface, width: 1.5),
      ),
      StatusChipStyle.tonal => (
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        null,
      ),
      StatusChipStyle.quiet => (
        null,
        scheme.onSurfaceVariant,
        BorderSide(color: scheme.outlineVariant),
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(side: border ?? BorderSide.none),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: text),
          const SizedBox(width: 4),
          // Flexible so a width-constrained chip (the group-results name
          // column) wraps the label instead of overflowing.
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
