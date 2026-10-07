import 'package:flutter/material.dart';

/// A centered message with optional detail and a Retry button, for loading
/// failures and empty lists. An empty list can offer its own [action]
/// instead (such as `Create contest`).
class MessageView extends StatelessWidget {
  const MessageView({
    required this.text,
    this.detail,
    this.onRetry,
    this.action,
    super.key,
  });

  final String text;
  final String? detail;
  final VoidCallback? onRetry;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
