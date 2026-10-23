import 'package:flutter/material.dart';

/// What the director chose when leaving a group with unsaved rows.
enum UnsavedChoice { save, discard, stay }

Future<UnsavedChoice> askUnsavedEdits(
  BuildContext context, {
  required int rows,
  bool closingApp = false,
}) async {
  final choice = await showDialog<UnsavedChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(closingApp ? 'Close RC Soar Score?' : 'Unsaved scores'),
      content: Text(
        '$rows ${rows == 1 ? 'row has' : 'rows have'} scores that are not '
        'saved. Save them before you ${closingApp ? 'close the app' : 'leave this group'}?',
      ),
      actions: [
        TextButton(
          key: const ValueKey('unsaved-stay'),
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.stay),
          child: Text(closingApp ? 'Keep open' : 'Stay'),
        ),
        TextButton(
          key: const ValueKey('unsaved-discard'),
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.discard),
          child: const Text('Discard'),
        ),
        FilledButton(
          key: const ValueKey('unsaved-save'),
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.save),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  return choice ?? UnsavedChoice.stay;
}
