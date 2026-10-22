import 'package:flutter/material.dart';

/// Asks whether to throw away unsaved edits. Returns `true` to discard and
/// `false` (also when dismissed) to keep editing.
///
/// The copy is the caller's: editors that only lose what is on the form use
/// the defaults, while a page whose draft is kept elsewhere or that can name
/// what changed (configuration, the New Contest wizard) passes its own text.
Future<bool> confirmDiscard(
  BuildContext context, {
  String title = 'Discard changes?',
  String body = 'Your unsaved changes will be lost.',
  String keepLabel = 'Keep editing',
  String discardLabel = 'Discard',
}) async {
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(keepLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(discardLabel),
        ),
      ],
    ),
  );
  return discard ?? false;
}
