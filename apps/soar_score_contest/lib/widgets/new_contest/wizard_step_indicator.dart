import 'package:flutter/material.dart';

import 'wizard_step_status.dart';

/// The 28 px marker for a wizard step.
///
/// Each state differs in shape and content, not only color: a filled circle
/// with a check is Complete, a filled circle with the number is Current, a
/// rounded square with `!` needs attention, a solid outline is Visited and a
/// dashed outline is Not started.
class WizardStepIndicator extends StatelessWidget {
  const WizardStepIndicator({
    super.key,
    required this.number,
    required this.status,
  });

  final int number;
  final WizardStepStatus status;

  static const double size = 28;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color background, Color foreground) = switch (status) {
      WizardStepStatus.needsAttention ||
      WizardStepStatus.currentNeedsAttention => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      WizardStepStatus.current => (scheme.primary, scheme.onPrimary),
      WizardStepStatus.complete => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      WizardStepStatus.visited || WizardStepStatus.notStarted => (
        Colors.transparent,
        scheme.onSurfaceVariant,
      ),
    };
    final Widget content = switch (status) {
      WizardStepStatus.complete => Icon(
        Icons.check,
        size: 18,
        color: foreground,
      ),
      WizardStepStatus.needsAttention ||
      WizardStepStatus.currentNeedsAttention => Icon(
        Icons.priority_high,
        size: 18,
        color: foreground,
      ),
      _ => Text(
        '$number',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    };
    final ShapeBorder shape = switch (status) {
      WizardStepStatus.needsAttention ||
      WizardStepStatus.currentNeedsAttention => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(color: scheme.error, width: 2),
      ),
      WizardStepStatus.visited => CircleBorder(
        side: BorderSide(color: scheme.outline, width: 2),
      ),
      _ => const CircleBorder(),
    };

    final marker = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: background, shape: shape),
      child: content,
    );
    if (status != WizardStepStatus.notStarted) {
      return marker;
    }
    return CustomPaint(
      painter: _DashedCirclePainter(color: scheme.outline),
      child: marker,
    );
  }
}

/// A 1 px dashed circle around the marker of a step not started yet.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  static const int _dashes = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;
    const sweep = 2 * 3.141592653589793 / _dashes;
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect.deflate(0.5), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color;
}
