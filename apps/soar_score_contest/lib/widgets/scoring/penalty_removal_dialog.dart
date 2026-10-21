import 'package:flutter/material.dart';

/// Asks for a correction reason before applied cumulative penalties are
/// removed (saved as 0). Removal is an official revision and must record
/// why (ticket 020). [pilots] is the pilot or pilots whose applied penalty
/// the save removes when their reasons are blank. Returns null when the
/// director cancels or leaves the reason blank.
Future<String?> askPenaltyRemovalReason(
  BuildContext context, {
  required List<String> pilots,
}) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => _PenaltyRemovalDialog(pilots: pilots),
  );
  return reason == null || reason.trim().isEmpty ? null : reason.trim();
}

class _PenaltyRemovalDialog extends StatefulWidget {
  const _PenaltyRemovalDialog({required this.pilots});

  final List<String> pilots;

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
    final single = widget.pilots.length == 1 ? widget.pilots.single : null;
    return AlertDialog(
      key: const ValueKey('penalty-removal-dialog'),
      title: Text(
        single != null
            ? "Remove $single's penalty?"
            : 'Remove ${widget.pilots.length} penalties?',
      ),
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
            if (single == null) ...[
              const SizedBox(height: 8),
              Text(
                widget.pilots.join(', '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('penalty-removal-reason'),
              controller: _reason,
              autofocus: true,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Correction reason'),
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
