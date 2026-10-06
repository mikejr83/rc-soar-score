import 'package:flutter/material.dart';

/// Shown when a feature (e.g. `Sign in` or `Create account`) is tapped before
/// its backend integration is complete (tickets 021 and 010).
///
/// [detail] replaces the default authentication explanation for features
/// that are waiting on something else, such as a page not built yet.
void showNotWiredUpDialog(
  BuildContext context,
  String action, {
  String detail =
      'Authentication through the identity provider has not been '
      'wired up yet. Please check back soon.',
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      title: Text('$action is not available yet'),
      content: Text(detail),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
