import 'package:flutter/material.dart';

import '../../../services/workspace/next_step/next_step.dart';
import '../../../services/workspace/next_step/next_step_action.dart';
import 'next_step_buttons.dart';
import 'next_step_reason_line.dart';

/// The text under the buttons when part of the facts could not be loaded.
const String nextStepUnavailableText = 'Some information could not be loaded.';

/// The workspace's "what to do next" card: eyebrow, title, body, the reason,
/// the buttons and an optional note.
///
/// Presentation only; [NextStepSection] decides the step and what each button
/// does.
class NextStepCard extends StatelessWidget {
  const NextStepCard({
    super.key,
    required this.step,
    required this.busy,
    required this.onPressed,
    this.factsUnavailable = false,
    this.onRetryFacts,
  });

  final NextStep step;

  /// True while the primary button's in-place action runs.
  final bool busy;

  final void Function(NextStepAction action) onPressed;

  /// True when part of the facts failed to load; the step uses its fallbacks.
  final bool factsUnavailable;

  final VoidCallback? onRetryFacts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reason = step.reason;
    final note = step.note;
    final disabledNote = step.primary.enabled
        ? null
        : step.primary.disabledNote;
    return Card.filled(
      key: const ValueKey('next-step-card'),
      margin: EdgeInsets.zero,
      elevation: 2,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  step.isSuggestion
                      ? Icons.lightbulb_outline
                      : Icons.flag_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    step.eyebrow,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step.title,
              key: const ValueKey('next-step-title'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              step.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (reason != null) ...[
              const SizedBox(height: 12),
              NextStepReasonLine(reason: reason),
            ],
            const SizedBox(height: 16),
            NextStepButtons(step: step, busy: busy, onPressed: onPressed),
            if (disabledNote != null) ...[
              const SizedBox(height: 12),
              Text(
                disabledNote,
                key: const ValueKey('next-step-disabled-note'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 12),
              Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (factsUnavailable) ...[
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    nextStepUnavailableText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (onRetryFacts != null)
                    TextButton(
                      key: const ValueKey('next-step-retry'),
                      onPressed: onRetryFacts,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
