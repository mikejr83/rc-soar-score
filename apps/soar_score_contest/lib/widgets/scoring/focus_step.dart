import 'package:flutter/material.dart';

/// Where a step's number sits on its control.
enum FocusBadgeCorner { topRight, topLeft }

/// One stop of the keyboard path through a score row. [order] puts the
/// control at its place in the Tab order; [badge] draws the number the design
/// shows in its keyboard-order view (`Scoring Screen Canvas.dc.html`, 4e):
/// amber for the Enter path, grey for stops reached with Tab only.
///
/// Time, height, the landing choice and the flight penalty are on the Enter
/// path (1, 2, 3, 8); the four toggles (4 to 7) and the cumulative penalty
/// (9) are Tab only. Save row is 10, and saves then moves to the next
/// pilot's time.
class FocusStep extends StatelessWidget {
  const FocusStep({
    super.key,
    required this.order,
    required this.child,
    this.badge,
    this.enterPath = false,
    this.corner = FocusBadgeCorner.topRight,
  });

  /// The place in the Tab order within the row.
  final double order;

  /// The number to draw over the control, or null to draw none.
  final String? badge;

  /// True for a stop on the Enter path (amber), false for Tab only (grey).
  final bool enterPath;
  final FocusBadgeCorner corner;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ordered = FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
    final text = badge;
    if (text == null) return ordered;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final background = enterPath
        ? (dark ? const Color(0xFFB86E00) : const Color(0xFF8A5100))
        : scheme.onSurfaceVariant;
    final foreground = enterPath ? Colors.white : scheme.surface;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ordered,
        Positioned(
          right: corner == FocusBadgeCorner.topRight ? -6 : null,
          left: corner == FocusBadgeCorner.topLeft ? -8 : null,
          top: -8,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Container(
                key: ValueKey('focus-badge-$text'),
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
