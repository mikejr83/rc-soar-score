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
  required String policyText,
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
          Text(key: const ValueKey('publish-dialog-policy'), policyText),
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

/// Asks the director to confirm requesting delisting, with an optional
/// reason for the administrator. Resolves to null when cancelled, otherwise
/// to the reason (empty when none was given).
Future<String?> confirmRequestDelisting(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (context) => const _DelistDialog(),
    );

class _DelistDialog extends StatefulWidget {
  const _DelistDialog();

  @override
  State<_DelistDialog> createState() => _DelistDialogState();
}

class _DelistDialogState extends State<_DelistDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const ValueKey('delist-dialog'),
      title: Text(l10n.delistDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.delistDialogBody),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('delist-dialog-reason'),
            controller: _reason,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.delistDialogReasonLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('delist-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.publicationDialogCancel),
        ),
        FilledButton(
          key: const ValueKey('delist-dialog-confirm'),
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          child: Text(l10n.delistDialogConfirm),
        ),
      ],
    );
  }
}
