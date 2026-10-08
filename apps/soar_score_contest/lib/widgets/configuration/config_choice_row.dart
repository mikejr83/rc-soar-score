import 'package:flutter/material.dart';

/// A one-of-several option shown as a drop-down. Read-only while
/// [onChanged] is null.
class ConfigChoiceRow<T> extends StatelessWidget {
  const ConfigChoiceRow({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    this.onChanged,
  });

  final String label;
  final T value;

  /// Each choice and the text shown for it.
  final Map<T, String> options;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: DropdownButton<T>(
      value: value,
      onChanged: onChanged == null
          ? null
          : (choice) {
              if (choice != null) {
                onChanged!(choice);
              }
            },
      items: [
        for (final entry in options.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
    ),
  );
}
