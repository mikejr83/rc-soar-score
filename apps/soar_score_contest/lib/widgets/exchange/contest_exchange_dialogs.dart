import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/exchange/contest_exchange.dart';

/// Asks how to export [contest], saves the file where the director chooses
/// and says so. Does nothing when the build has no exchange.
Future<void> exportContest(BuildContext context, Contest contest) async {
  final exchange = ContestExchange.current;
  if (exchange == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final redact = await showDialog<bool>(
    context: context,
    builder: (_) => _ExportDialog(contest: contest),
  );
  if (redact == null) return;
  final ExchangeExport export;
  try {
    export = await exchange.export(contest.id, redact: redact);
  } on ExchangeFailure catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.exportFailedWithReason(e.message))),
    );
    return;
  } on Exception {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.exportFailed)),
    );
    return;
  }
  try {
    final name = await ExchangeFiles.current.save(
      export.fileName,
      export.bytes,
    );
    if (name != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportSaved(name))));
    }
  } on PlatformException catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.exportFileSaveFailed(_describe(e, l10n))),
      ),
    );
  } on FileSystemException catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.exportFileSaveFailed(_describe(e, l10n))),
      ),
    );
  }
}

/// A sentence for a failure of the system file dialogs or the file system.
String _describe(Exception error, AppLocalizations l10n) => switch (error) {
  PlatformException(:final message?) when message.isNotEmpty => message,
  FileSystemException(:final message, :final osError) =>
      osError?.message.isNotEmpty == true
          ? '$message (${osError!.message})'
          : message,
  _ => l10n.fileOperationRetryHint,
};

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.contest});

  final Contest contest;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  bool _redact = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const ValueKey('export-dialog'),
      title: Text(l10n.exportDialogTitle(widget.contest.name)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.exportDialogDescription),
            const SizedBox(height: 12),
            CheckboxListTile(
              key: const ValueKey('export-redact'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _redact,
              onChanged: (value) => setState(() => _redact = value ?? true),
              title: Text(l10n.exportRedactionTitle),
              subtitle: Text(l10n.exportRedactionSubtitle),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.exportNotice,
              key: const ValueKey('export-notice'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          key: const ValueKey('export-save'),
          onPressed: () => Navigator.pop(context, _redact),
          child: Text(l10n.exportSaveButton),
        ),
      ],
    );
  }
}

/// Asks for a contest file, shows what importing it would do and imports it
/// in the mode the director picks. Answers what was imported, or `null` when
/// the director cancelled or the file was refused.
Future<ExchangeImported?> importContest(BuildContext context) async {
  final exchange = ContestExchange.current;
  if (exchange == null) return null;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final ChosenExchangeFile? chosen;
  try {
    chosen = await ExchangeFiles.current.choose();
  } on PlatformException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importOpenFailed(_describe(e, l10n)))),
    );
    return null;
  } on FileSystemException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importOpenFailed(_describe(e, l10n)))),
    );
    return null;
  }
  if (chosen == null || !context.mounted) return null;
  final ExchangePreview preview;
  try {
    preview = await exchange.preview(chosen.bytes);
  } on ExchangeFailure catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.importFileRefused(chosen.name, e.message)),
      ),
    );
    return null;
  }
  if (!context.mounted) return null;
  final mode = await showDialog<ExchangeImportMode>(
    context: context,
    builder: (_) => _ImportDialog(preview: preview),
  );
  if (mode == null) return null;
  try {
    return await exchange.import(chosen.bytes, mode, fileName: chosen.name);
  } on ExchangeFailure catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importFailed(e.message))),
    );
    return null;
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.preview});

  final ExchangePreview preview;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  late ExchangeImportMode? _mode = widget.preview.available.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final exported = DateFormat.yMMMd().add_jm().format(
      preview.exportedAt.toLocal(),
    );
    final participants = preview.counts['participants'] ?? 0;
    final rounds = preview.counts['rounds'] ?? 0;
    final scores = preview.counts['scores'] ?? 0;
    final source = preview.sourceLabel;
    final String summary;
    if (source == null) {
      summary = preview.redacted
          ? l10n.importPreviewRedacted(exported, participants, rounds, scores)
          : l10n.importPreviewIncluded(exported, participants, rounds, scores);
    } else {
      summary = preview.redacted
          ? l10n.importPreviewRedactedFromSource(
              exported,
              source,
              participants,
              rounds,
              scores,
            )
          : l10n.importPreviewIncludedFromSource(
              exported,
              source,
              participants,
              rounds,
              scores,
            );
    }
    return AlertDialog(
      key: const ValueKey('import-dialog'),
      title: Text(l10n.importDialogTitle(preview.contestName)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary),
              const SizedBox(height: 12),
              for (final refusal in preview.refusals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    refusal,
                    key: const ValueKey('import-refusal'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              if (preview.refusals.isEmpty)
                RadioGroup<ExchangeImportMode>(
                  groupValue: _mode,
                  onChanged: (value) => setState(() => _mode = value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final mode in ExchangeImportMode.values)
                        _option(mode, preview, l10n),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          key: const ValueKey('import-confirm'),
          onPressed: preview.canImport && _mode != null
              ? () => Navigator.pop(context, _mode)
              : null,
          child: Text(l10n.importConfirmButton),
        ),
      ],
    );
  }

  Widget _option(
    ExchangeImportMode mode,
    ExchangePreview preview,
    AppLocalizations l10n,
  ) {
    final reason = preview.unavailable[mode];
    final enabled = preview.available.contains(mode);
    final title = mode == ExchangeImportMode.inspection
        ? l10n.importModeInspectionTitle
        : l10n.importModeEditableTitle;
    final notice = mode == ExchangeImportMode.inspection
        ? l10n.importModeInspectionNotice
        : l10n.importModeEditableNotice;
    return RadioListTile<ExchangeImportMode>(
      key: ValueKey('import-mode-${mode.name}'),
      contentPadding: EdgeInsets.zero,
      value: mode,
      enabled: enabled,
      title: Text(title),
      subtitle: Text(reason != null && !enabled ? reason : notice),
    );
  }
}
