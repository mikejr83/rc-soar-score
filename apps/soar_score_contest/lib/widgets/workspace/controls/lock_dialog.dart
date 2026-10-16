import 'package:flutter/material.dart';

/// Asks the director to confirm locking administration, naming what the lock
/// blocks. Resolves to true when confirmed.
Future<bool> confirmLock(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('lock-dialog'),
      title: const Text('Lock administration?'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Administration: Unlocked → Locked'),
          SizedBox(height: 12),
          Text('While locked, these changes are rejected:'),
          SizedBox(height: 4),
          Text('• Contest configuration'),
          Text('• Participants and their roles'),
          Text('• The matrix and its assignments'),
          Text('• Scores'),
          SizedBox(height: 12),
          Text(
            'The contest can still be viewed and published. Locking does '
            'not complete it or close participant scoring.',
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('lock-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('lock-dialog-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Lock administration'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
