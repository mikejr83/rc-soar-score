import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final complete = steps
        .where((step) => step.status == WizardStepStatus.complete)
        .length;
    final progressText = l10n.wizardStepsComplete(complete, steps.length);
    return Semantics(
      container: true,
      label: l10n.wizardStepListLabel,
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
                l10n.wizardNewContest,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Text(
                progressText,
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
                  semanticsLabel: progressText,
                ),
              ),
            ),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _StepRow(
                  step: step,
                  total: steps.length,
                  onSelect: onSelect,
                ),
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
                      l10n.wizardDraftKeptNote,
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
  const _StepRow({
    required this.step,
    required this.total,
    required this.onSelect,
  });

  final WizardStepEntry step;
  final int total;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = step.status;
    final current = status.isCurrent;
    final enabled = !status.locked && !current;
    return Semantics(
      button: true,
      enabled: !status.locked,
      selected: current,
      label: step.semanticLabel(l10n, total),
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
                          status.label(l10n),
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
