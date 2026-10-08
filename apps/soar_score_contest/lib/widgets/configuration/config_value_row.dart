import 'package:flutter/material.dart';

/// A read-only label and value.
class ConfigValueRow extends StatelessWidget {
  const ConfigValueRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value),
  );
}
