import 'package:flutter/material.dart';

/// A toggle in a 52 dp tappable tile. When a rule turns it off, the reason is
/// written under the label rather than only greying the switch.
class ScoreToggleTile extends StatelessWidget {
  const ScoreToggleTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
    this.offReason,
    this.note,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  /// Why the toggle cannot be changed now, or null.
  final String? offReason;

  /// What turning it on does.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usable = enabled && offReason == null;
    final sub = offReason ?? (value ? note : null);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: Material(
        color: value
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: usable ? () => onChanged(!value) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: theme.textTheme.titleSmall),
                        if (sub != null)
                          Text(sub, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Semantics(
                    label: label,
                    toggled: value,
                    child: ExcludeSemantics(
                      child: Switch(
                        value: value,
                        onChanged: usable ? onChanged : null,
                      ),
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
