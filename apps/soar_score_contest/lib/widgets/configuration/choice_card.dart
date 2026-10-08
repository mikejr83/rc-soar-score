import 'package:flutter/material.dart';

/// The rounded outlined card around a radio choice. The selected card has a
/// thick outline. It is a [Material] so the tile inside paints its ink on the
/// card.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.selected,
    required this.child,
    this.enabled = true,
  });

  final bool selected;

  /// A disabled selected card is outlined faintly.
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outline = selected
        ? (enabled ? scheme.primary : scheme.onSurface.withValues(alpha: 0.12))
        : scheme.outlineVariant;
    return Material(
      color: selected && enabled ? scheme.surface : Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outline, width: selected ? 2 : 1),
      ),
      child: child,
    );
  }
}
