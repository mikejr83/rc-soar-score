import 'package:flutter/material.dart';

import '../../../services/workspace/next_step/next_step_reason.dart';
import 'next_step_icons.dart';

/// The line under a step that says why it is the step: an icon, a bold lead
/// and the text.
class NextStepReasonLine extends StatelessWidget {
  const NextStepReasonLine({super.key, required this.reason});

  final NextStepReason reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = nextStepToneColor(theme.colorScheme, reason.tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(nextStepToneIcon(reason.tone), size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: reason.lead,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                TextSpan(text: ' ${reason.text}'),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
