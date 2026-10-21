import 'package:flutter/material.dart';

/// A labelled checkbox with an optional line of help, for a report's options.
/// Changes apply at once.
class ReportCheckOption extends StatelessWidget {
  const ReportCheckOption({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.help,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      subtitle: help == null
          ? null
          : Text(
              help!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

/// A labelled dropdown of [items] (value to label), for a report's filters.
/// [errorText] marks it invalid with text, not colour alone.
class ReportDropdown extends StatelessWidget {
  const ReportDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    // A new key when the value changes keeps the field in step with a reset
    // or a link that sets it.
    key: ValueKey('$label:$value'),
    initialValue: items.containsKey(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      error: errorText == null ? null : const SizedBox.shrink(),
    ),
    items: [
      for (final entry in items.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: (chosen) {
      if (chosen != null) {
        onChanged(chosen);
      }
    },
  );
}

/// A message under a control: informational, or an error with an icon so it
/// never relies on colour.
class ReportFieldMessage extends StatelessWidget {
  const ReportFieldMessage({
    super.key,
    required this.text,
    this.isError = false,
  });

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: isError,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (isError) Icon(Icons.error, size: 16, color: color),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
