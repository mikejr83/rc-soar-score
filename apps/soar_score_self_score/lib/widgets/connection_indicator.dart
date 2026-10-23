import 'package:flutter/material.dart';

/// Icon plus word for the connection state, so it never relies on colour.
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({this.online = true, super.key});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          online ? 'Online' : 'Offline',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
