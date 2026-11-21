import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/configuration/configuration_draft.dart';
import 'config_chip.dart';

/// The bar docked at the bottom of the page while the draft differs from the
/// saved configuration: the change count, what saving will do, the errors
/// that stop it, `Discard changes` and `Save configuration`.
class ConfigSaveBar extends StatelessWidget {
  const ConfigSaveBar({
    super.key,
    required this.draft,
    required this.saving,
    required this.saveError,
    required this.onSave,
    required this.onDiscard,
    required this.onShowError,
  });

  final ConfigurationDraft draft;

  /// A save is running: the bar shows progress and ignores taps.
  final bool saving;

  /// What went wrong with the last save; the values are kept.
  final String? saveError;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  /// Scrolls to the setting with [key] and focuses it.
  final ValueChanged<String> onShowError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final errors = draft.errors;
    final changes = draft.changes.length;
    final failed = saveError != null && !saving;
    final blocked = errors.isNotEmpty || saving;

    final (icon, title, sub, color) = saving
        ? (
            Icons.sync,
            l10n.configBarSaving,
            l10n.configBarSavingLocked,
            scheme.onSurface,
          )
        : failed
        ? (
            Icons.error,
            l10n.configBarSaveFailed,
            l10n.configBarSaveFailedSub('$saveError '),
            scheme.error,
          )
        : (
            Icons.edit_note,
            l10n.configBarUnsaved(changes),
            null,
            scheme.onSurface,
          );

    final matrix = draft.matrixChanges.isNotEmpty;
    final recalc = draft.recalcChanges.isNotEmpty;

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 3,
      child: Semantics(
        container: true,
        label: l10n.configBarUnsavedLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (saving)
              LinearProgressIndicator(
                minHeight: 4,
                semanticsLabel: l10n.configBarSavingProgress,
                backgroundColor: scheme.primaryContainer,
              ),
            if (errors.isNotEmpty && !saving) _errorSummary(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 280,
                      maxWidth: 640,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          liveRegion: failed,
                          child: Row(
                            children: [
                              Icon(icon, size: 22, color: color),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sub != null)
                          Text(sub, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (matrix)
                              ConfigChip(
                                icon: Icons.sync_problem,
                                text: l10n.configBarMatrixChip,
                                background: scheme.tertiaryContainer,
                                foreground: scheme.onTertiaryContainer,
                                dense: false,
                              ),
                            if (recalc)
                              ConfigChip(
                                icon: Icons.calculate_outlined,
                                text: l10n.configBarRecalcChip,
                                background: scheme.primaryContainer,
                                foreground: scheme.onPrimaryContainer,
                                dense: false,
                              ),
                            if (!matrix && !recalc)
                              ConfigChip(
                                icon: Icons.check,
                                text: l10n.configBarNoEffectChip,
                                foreground: scheme.onSurface,
                                outline: scheme.outline,
                                dense: false,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (errors.isNotEmpty && !saving)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, size: 18, color: scheme.error),
                            const SizedBox(width: 6),
                            Text(
                              l10n.configBarFixErrors(errors.length),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      OutlinedButton(
                        onPressed: saving ? null : onDiscard,
                        child: Text(l10n.contestParticipantsSaveDiscard),
                      ),
                      FilledButton.icon(
                        onPressed: blocked ? null : onSave,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                failed ? Icons.refresh : Icons.save_outlined,
                              ),
                        label: Text(
                          saving
                              ? l10n.configBarSaveShort
                              : failed
                              ? l10n.configBarRetry
                              : l10n.configSaveConfirm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorSummary(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final errors = draft.errors;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.configBarSettingsNeedFixing(errors.length),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Wrap(
                    spacing: 20,
                    children: [
                      for (final entry in errors.entries)
                        InkWell(
                          key: ValueKey('error-link-${entry.key}'),
                          onTap: () => onShowError(entry.key),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  size: 16,
                                  color: scheme.onErrorContainer,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    l10n.configBarErrorItem(
                                      draft.catalog.byKey[entry.key]!.label,
                                      entry.value,
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onErrorContainer,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
