import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final errors = draft.errors;
    final changes = draft.changes.length;
    final failed = saveError != null && !saving;
    final blocked = errors.isNotEmpty || saving;

    final (icon, title, sub, color) = saving
        ? (
            Icons.sync,
            'Saving configuration…',
            'The page is locked until the save finishes.',
            scheme.onSurface,
          )
        : failed
        ? (
            Icons.error,
            'Couldn’t save the configuration',
            '$saveError Every value you entered is kept.',
            scheme.error,
          )
        : (
            Icons.edit_note,
            '$changes unsaved change${changes == 1 ? '' : 's'}',
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
        label: 'Unsaved changes',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (saving)
              LinearProgressIndicator(
                minHeight: 4,
                semanticsLabel: 'Saving configuration',
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
                                text: 'Makes the drawn matrix out of date',
                                background: scheme.tertiaryContainer,
                                foreground: scheme.onTertiaryContainer,
                                dense: false,
                              ),
                            if (recalc)
                              ConfigChip(
                                icon: Icons.calculate_outlined,
                                text: 'Recalculates all results',
                                background: scheme.primaryContainer,
                                foreground: scheme.onPrimaryContainer,
                                dense: false,
                              ),
                            if (!matrix && !recalc)
                              ConfigChip(
                                icon: Icons.check,
                                text: 'No effect on the matrix or results',
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
                              'Fix ${errors.length} error'
                              '${errors.length == 1 ? '' : 's'} to save',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      OutlinedButton(
                        onPressed: saving ? null : onDiscard,
                        child: const Text('Discard changes'),
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
                              ? 'Saving…'
                              : failed
                              ? 'Retry'
                              : 'Save configuration',
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
                    '${errors.length} setting'
                    '${errors.length == 1 ? ' needs' : 's need'} fixing before '
                    'you can save',
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
                                    '${draft.catalog.byKey[entry.key]!.label}: '
                                    '${entry.value}',
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
