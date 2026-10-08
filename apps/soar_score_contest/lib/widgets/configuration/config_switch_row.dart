import 'package:flutter/material.dart';

/// An on/off option. Read-only while [onChanged] is null.
class ConfigSwitchRow extends StatelessWidget {
  const ConfigSwitchRow({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: onChanged,
  );
}
