import 'package:flutter/material.dart';

/// A switch with a check thumb and an `On` or `Off` label, so the state is
/// not carried by colour alone.
class SettingToggle extends StatelessWidget {
  const SettingToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.focusNode,
  });

  final bool value;

  /// `null` disables the switch.
  final ValueChanged<bool>? onChanged;
  final String label;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Semantics(
            label: label,
            child: Switch(
              value: value,
              focusNode: focusNode,
              onChanged: onChanged,
              thumbIcon: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Icon(Icons.check)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value ? 'On' : 'Off',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
