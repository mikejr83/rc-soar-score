import 'package:flutter/material.dart';

import '../../services/api_failure.dart';
import '../page_states/page_banner.dart';

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
    return PageBanner(
      key: const ValueKey('scoring-refresh-failed'),
      kind: PageBannerKind.alert,
      icon: Icons.error_outline,
      text: failure.message,
      actionLabel: failure.retryable ? 'Retry' : null,
      onAction: failure.retryable ? onRetry : null,
    );
  }
}
