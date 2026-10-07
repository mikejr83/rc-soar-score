import 'package:flutter/material.dart';

import 'wizard_step_indicator.dart';
import 'wizard_step_status.dart';

/// The vertical step list beside the wizard content on wide windows: a
/// title, progress, one row per step with its state, and a note about the
/// draft.
class WizardStepList extends StatelessWidget {
  const WizardStepList({
    super.key,
    required this.steps,
    required this.onSelect,
  });

  final List<WizardStepEntry> steps;

  /// Called with the step number when a reachable step is chosen.
  final ValueChanged<int> onSelect;

  static const double width = 264;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final complete = steps
        .where((step) => step.status == WizardStepStatus.complete)
        .length;
    return Semantics(
      container: true,
      label: 'Wizard steps',
      child: Container(
        width: width,
        decoration: BoxDecoration(
          border: BorderDirectional(
            end: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'New contest',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Text(
                '$complete of ${steps.length} steps complete',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: complete / steps.length,
                  minHeight: 4,
                  backgroundColor: scheme.surfaceContainerHighest,
                  semanticsLabel: '$complete of ${steps.length} steps complete',
                ),
              ),
            ),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _StepRow(step: step, onSelect: onSelect),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Configuration in process is kept until the app is closed or '
                      'the contest is created.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.onSelect});

  final WizardStepEntry step;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = step.status;
    final current = status.isCurrent;
    final enabled = !status.locked && !current;
    return Semantics(
      button: true,
      enabled: !status.locked,
      selected: current,
      label: step.semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: current ? scheme.secondaryContainer : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('wizard-step-${step.number}'),
          onTap: enabled ? () => onSelect(step.number) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  WizardStepIndicator(number: step.number, status: status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: current
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: status.locked
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                        Text(
                          status.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: status.hasError
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
