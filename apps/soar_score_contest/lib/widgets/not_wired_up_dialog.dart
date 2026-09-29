import 'package:flutter/material.dart';

/// Shown when a feature (e.g. `Sign in` or `Create account`) is tapped before
/// its backend integration is complete (tickets 021 and 010).
void showNotWiredUpDialog(BuildContext context, String action) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      title: Text('$action is not available yet'),
      content: const Text(
        'Authentication through the identity provider has not been '
        'wired up yet. Please check back soon.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
