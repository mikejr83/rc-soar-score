import 'package:flutter/material.dart';

/// One on/off flag of the entry form, with an optional explanation.
class EntryToggleRow extends StatelessWidget {
  const EntryToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    super.key,
  });

  final String label;
  final String? hint;
  final bool value;

  /// Null makes the row read-only.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 56,
        title: Text(label, style: theme.textTheme.bodyLarge),
        subtitle: hint == null
            ? null
            : Text(
                hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
