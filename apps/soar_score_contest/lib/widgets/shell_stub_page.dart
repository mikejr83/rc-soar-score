import 'package:flutter/material.dart';

/// The placeholder body of a shell destination that has not been built yet.
class ShellStubPage extends StatelessWidget {
  const ShellStubPage({super.key, required this.title});

  final String title;

  static const String notBuiltDetail =
      'This page has not been built yet. Please check back soon.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            notBuiltDetail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
