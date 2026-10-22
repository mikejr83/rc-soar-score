import 'package:flutter/material.dart';

import '../../services/api_failure.dart';

/// The notice above scores that are already showing when reloading them
/// failed. The scores stay usable; Retry is offered only when trying again
/// can help (not for a refused or missing contest).
class ScoringRefreshFailedBanner extends StatelessWidget {
  const ScoringRefreshFailedBanner({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = ApiFailure.of(error);
    return MaterialBanner(
      key: const ValueKey('scoring-refresh-failed'),
      content: Text(failure.message),
      leading: const Icon(Icons.error_outline),
      // MaterialBanner insists on an action; without Retry it gets an empty one.
      actions: [
        if (failure.retryable)
          TextButton(onPressed: onRetry, child: const Text('Retry'))
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
