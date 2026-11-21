import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// What the director chose when leaving a group with unsaved rows.
enum UnsavedChoice { save, discard, stay }

Future<UnsavedChoice> askUnsavedEdits(
  BuildContext context, {
  required int rows,
  bool closingApp = false,
}) async {
  final words = AppLocalizations.of(context);
  final choice = await showDialog<UnsavedChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        closingApp ? words.scoreUnsavedCloseTitle : words.scoreUnsavedTitle,
      ),
      content: Text(
        words.scoreUnsavedBody(
          rows,
          closingApp
              ? words.scoreUnsavedActionClose
              : words.scoreUnsavedActionLeave,
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('unsaved-stay'),
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.stay),
          child: Text(
            closingApp ? words.commonKeepOpen : words.scoreUnsavedStay,
          ),
        ),
        TextButton(
          key: const ValueKey('unsaved-discard'),
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.discard),
          child: Text(words.scoreUnsavedDiscard),
        ),
        FilledButton(
          key: const ValueKey('unsaved-save'),
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.save),
          child: Text(words.commonSave),
        ),
      ],
    ),
  );
  return choice ?? UnsavedChoice.stay;
}
