import 'package:flutter/material.dart';

import 'wizard_step_indicator.dart';
import 'wizard_step_status.dart';

/// The horizontal step markers above the wizard content on narrow windows.
/// The content header names the current step; each marker carries the full
/// step name and state as its tooltip and accessible label.
class WizardDotStepper extends StatelessWidget {
  const WizardDotStepper({
    super.key,
    required this.steps,
    required this.onSelect,
  });

  final List<WizardStepEntry> steps;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Wizard steps',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            for (final step in steps) ...[
              _Dot(step: step, onSelect: onSelect),
              if (step.number < steps.length)
                Expanded(
                  child: Container(
                    height: 2,
                    constraints: const BoxConstraints(minWidth: 6),
                    color: step.status == WizardStepStatus.complete
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.step, required this.onSelect});

  final WizardStepEntry step;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = step.status;
    final enabled = !status.locked && !status.isCurrent;
    return Semantics(
      button: true,
      enabled: !status.locked,
      selected: status.isCurrent,
      label: step.semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: step.semanticLabel,
        child: Material(
          color: status.isCurrent
              ? scheme.secondaryContainer
              : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('wizard-dot-${step.number}'),
            onTap: enabled ? () => onSelect(step.number) : null,
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: WizardStepIndicator(number: step.number, status: status),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
