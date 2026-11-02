import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import 'publication_text.dart';

/// Asks the director to confirm publishing [contest]: the contest revision
/// that goes out, who can see it afterwards and the update policy. Resolves
/// to true when confirmed.
Future<bool> confirmPublish(
  BuildContext context, {
  required Contest contest,
  required PublicationVisibility visibility,
  required PublicUpdateMode? policy,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('publish-dialog'),
      title: Text(l10n.publishDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.publishDialogBody),
          const SizedBox(height: 12),
          Text(
            key: const ValueKey('publish-dialog-revision'),
            l10n.publishDialogRevision('${contest.revision}'),
          ),
          Text(
            key: const ValueKey('publish-dialog-visibility'),
            l10n.publishDialogVisibility(l10n.visibilityName(visibility)),
          ),
          Text(
            key: const ValueKey('publish-dialog-policy'),
            l10n.updatePolicy(policy),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('publish-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.publicationDialogCancel),
        ),
        FilledButton(
          key: const ValueKey('publish-dialog-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.publishDialogConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Asks the director to confirm listing the publication on the public site.
Future<bool> confirmMakePublic(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('public-dialog'),
      title: Text(l10n.publicDialogTitle),
      content: Text(l10n.publicDialogBody),
      actions: [
        TextButton(
          key: const ValueKey('public-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.publicationDialogCancel),
        ),
        FilledButton(
          key: const ValueKey('public-dialog-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.publicDialogConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
