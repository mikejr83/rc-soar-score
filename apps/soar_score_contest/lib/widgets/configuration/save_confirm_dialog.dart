import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/readiness_summary.dart';

/// Asks before saving a change that has an impact: it makes the drawn matrix
/// out of date, or recalculates results. Closes with `true` to save.
class SaveConfirmDialog extends StatelessWidget {
  const SaveConfirmDialog({
    super.key,
    required this.draft,
    this.matrixRevision,
  });

  final ConfigurationDraft draft;

  /// The drawn matrix's revision, for the sentence about it.
  final int? matrixRevision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final matrix = draft.matrixChanges;
    final recalc = draft.recalcChanges;
    final other = draft.otherChanges;
    String names(List<SettingChange> changes) =>
        ReadinessSummary.lowerList([for (final c in changes) c.def.label]);

    final revision = matrixRevision;
    final revisionText =
        revision == null ? '' : l10n.configSaveMatrixRevision(revision);

    Widget item(IconData icon, String head, String text, Color bg, Color fg) =>
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      head,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return AlertDialog(
      icon: const Icon(Icons.save_outlined),
      title: Text(l10n.configSaveTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (matrix.isNotEmpty)
            item(
              Icons.sync_problem,
              l10n.configSaveMatrixHead,
              l10n.configSaveMatrixText(
                names(matrix),
                revisionText,
              ),
              scheme.tertiaryContainer,
              scheme.onTertiaryContainer,
            ),
          if (recalc.isNotEmpty) ...[
            if (matrix.isNotEmpty) const SizedBox(height: 12),
            item(
              Icons.calculate_outlined,
              l10n.contestParticipantsRecalculatedTitle,
              l10n.contestParticipantsRecalculatedText(names(recalc)),
              scheme.primaryContainer,
              scheme.onPrimaryContainer,
            ),
          ],
          if (other.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check, size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.configSaveOtherText(names(other)),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          key: const ValueKey('confirm-save'),
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.configSaveConfirm),
        ),
      ],
    );
  }
}
