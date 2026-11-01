import 'package:flutter/material.dart';

/// The mark on a pilot whom a director moved: an icon and the word, so it
/// never relies on colour.
class MovedLabel extends StatelessWidget {
  const MovedLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      key: const ValueKey('moved-label'),
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(Icons.swap_horiz, size: 14, color: scheme.onSurfaceVariant),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
