import 'package:flutter/material.dart';

import 'page_banner.dart';

/// The banner an editor shows when a save did not go through. The form stays
/// as it was with every entered value, so the director never retypes.
///
/// What it offers depends on the failure ([retryable] is
/// `ApiFailure.retryable`): an unreachable or failing server can recover, so
/// it offers `Retry`; a rejected request, a conflict or a missing permission
/// cannot be fixed by sending the same thing again, so there is no Retry and
/// the message (the server's words) says why. The text promises no recovery
/// the banner cannot give: what resolves a conflict or an authorization
/// failure depends on the flow (#523). `Dismiss` only closes the banner; it
/// neither leaves the editor nor discards anything (the page's own Cancel
/// and leave guard do that, with their confirmation).
class SaveFailedBanner extends StatelessWidget {
  const SaveFailedBanner({
    super.key,
    required this.message,
    required this.retryable,
    required this.onRetry,
    required this.onDismiss,
    this.what = 'save',
    this.messageKey,
  });

  /// Why it failed, in the server's words when it sent any.
  final String message;
  final bool retryable;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  /// The verb in "Couldn't save", such as `save` or `create`.
  final String what;

  /// Key of the message text.
  final Key? messageKey;

  @override
  Widget build(BuildContext context) => PageBanner(
    kind: PageBannerKind.alert,
    icon: Icons.error_outline,
    textKey: messageKey,
    text: "Couldn't $what. $message Everything you entered is kept.",
    actionLabel: retryable ? 'Retry' : null,
    onAction: retryable ? onRetry : null,
    secondaryLabel: 'Dismiss',
    onSecondary: onDismiss,
  );
}
