import 'package:flutter/material.dart';

/// Asks for a correction reason before an applied cumulative penalty is
/// removed (saved as 0). Removal is an official revision and must record
/// why (ticket 020). Returns null when the director cancels or leaves the
/// reason blank.
Future<String?> askPenaltyRemovalReason(
  BuildContext context, {
  required String pilot,
}) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => _PenaltyRemovalDialog(pilot: pilot),
  );
  return reason == null || reason.trim().isEmpty ? null : reason.trim();
}

class _PenaltyRemovalDialog extends StatefulWidget {
  const _PenaltyRemovalDialog({required this.pilot});

  final String pilot;

  @override
  State<_PenaltyRemovalDialog> createState() => _PenaltyRemovalDialogState();
}

class _PenaltyRemovalDialogState extends State<_PenaltyRemovalDialog> {
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild so the confirm button enables as the reason is typed.
    _reason.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('penalty-removal-dialog'),
      title: Text("Remove ${widget.pilot}'s penalty?"),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Removal is an official score correction. Enter the reason '
              'to record it.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('penalty-removal-reason'),
              controller: _reason,
              autofocus: true,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Correction reason',
              ),
              onSubmitted: (_) => _done(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('penalty-removal-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('penalty-removal-confirm'),
          onPressed: _reason.text.trim().isEmpty ? null : _done,
          child: const Text('Remove penalty'),
        ),
      ],
    );
  }

  void _done() => Navigator.of(context).pop(_reason.text);
}
