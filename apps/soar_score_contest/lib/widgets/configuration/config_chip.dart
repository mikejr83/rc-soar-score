import 'package:flutter/material.dart';

/// A small label with an icon: a row tag (`Unsaved`, `House rule`, `Fixed`),
/// a section kind chip or an impact chip on the save bar. The meaning is in
/// the text and icon, never the colour alone.
class ConfigChip extends StatelessWidget {
  const ConfigChip({
    super.key,
    required this.icon,
    required this.text,
    this.background,
    this.foreground,
    this.outline,
    this.dashed = false,
    this.dense = true,
    this.tooltip,
  });

  /// `Unsaved`: the setting differs from the saved one.
  factory ConfigChip.unsaved(BuildContext context, {bool dense = true}) {
    final scheme = Theme.of(context).colorScheme;
    return ConfigChip(
      icon: Icons.edit_outlined,
      text: 'Unsaved',
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      dense: dense,
    );
  }

  /// `House rule`: the value differs from the official profile.
  factory ConfigChip.houseRule(
    BuildContext context, {
    String text = 'House rule',
    bool dense = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ConfigChip(
      icon: Icons.home_outlined,
      text: text,
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      dense: dense,
    );
  }

  /// `Error`: the value cannot be saved.
  factory ConfigChip.error(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConfigChip(
      icon: Icons.error_outline,
      text: 'Error',
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
    );
  }

  /// A neutral outlined chip.
  factory ConfigChip.neutral(
    BuildContext context, {
    required IconData icon,
    required String text,
    String? tooltip,
    bool dashed = false,
    bool dense = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ConfigChip(
      icon: icon,
      text: text,
      foreground: scheme.onSurfaceVariant,
      outline: scheme.outlineVariant,
      dashed: dashed,
      dense: dense,
      tooltip: tooltip,
    );
  }

  final IconData icon;
  final String text;
  final Color? background;
  final Color? foreground;
  final Color? outline;
  final bool dashed;
  final bool dense;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = foreground ?? theme.colorScheme.onSurfaceVariant;
    final chip = Container(
      height: dense ? 24 : 28,
      padding: EdgeInsets.only(left: dense ? 6 : 8, right: dense ? 8 : 10),
      decoration: ShapeDecoration(
        color: background,
        shape: dashed
            ? _DashedBorder(outline ?? color)
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: outline == null
                    ? BorderSide.none
                    : BorderSide(color: outline!),
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 14 : 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
  }
}

/// A rounded rectangle with a dashed outline, for the kind chips that name
/// what a setting does without being a status.
class _DashedBorder extends ShapeBorder {
  const _DashedBorder(this.color);

  final Color color;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      getInnerPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in getOuterPath(rect).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 3), paint);
        distance += 6;
      }
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}
