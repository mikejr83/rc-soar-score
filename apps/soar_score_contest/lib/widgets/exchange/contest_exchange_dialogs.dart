import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/exchange/contest_exchange.dart';

/// What the director is told about a file that is not encrypted.
const exportNotice =
    'The file is not encrypted. Anyone who has it can read the contest. '
    'Send it only to people you trust.';

/// Asks how to export [contest], saves the file where the director chooses
/// and says so. Does nothing when the build has no exchange.
Future<void> exportContest(BuildContext context, Contest contest) async {
  final exchange = ContestExchange.current;
  if (exchange == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final redact = await showDialog<bool>(
    context: context,
    builder: (_) => _ExportDialog(contest: contest),
  );
  if (redact == null) return;
  try {
    final export = await exchange.export(contest.id, redact: redact);
    final name = await ExchangeFiles.current.save(
      export.fileName,
      export.bytes,
    );
    if (name != null) {
      messenger.showSnackBar(SnackBar(content: Text('Saved $name')));
    }
  } on ExchangeFailure catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('The contest could not be exported. ${e.message}'),
      ),
    );
  } on Exception catch (e) {
    // The file could not be written: a full disk, a folder that is not
    // writable, a file dialog that failed.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'The contest could not be saved to a file. ${_describe(e)}',
        ),
      ),
    );
  }
}

/// A sentence for a failure of the system file dialogs or the file system.
String _describe(Exception error) => switch (error) {
  PlatformException(:final message?) when message.isNotEmpty => message,
  FileSystemException(:final message, :final osError) =>
    osError?.message.isNotEmpty == true
        ? '$message (${osError!.message})'
        : message,
  _ => 'Choose another place and try again.',
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
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('export-dialog'),
    title: Text('Export ${widget.contest.name}'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saves the whole contest to a .rcsoar file, for support or as a '
            'backup. Nothing is sent anywhere.',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            key: const ValueKey('export-redact'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _redact,
            onChanged: (value) => setState(() => _redact = value ?? true),
            title: const Text('Remove email addresses'),
            subtitle: const Text(
              'Turn this off for a full backup. Names, clubs and scores are '
              'kept either way.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exportNotice,
            key: const ValueKey('export-notice'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('export-save'),
        onPressed: () => Navigator.pop(context, _redact),
        child: const Text('Save file…'),
      ),
    ],
  );
}

/// Asks for a contest file, shows what importing it would do and imports it
/// in the mode the director picks. Answers what was imported, or `null` when
/// the director cancelled or the file was refused.
Future<ExchangeImported?> importContest(BuildContext context) async {
  final exchange = ContestExchange.current;
  if (exchange == null) return null;
  final messenger = ScaffoldMessenger.of(context);
  final ChosenExchangeFile? chosen;
  try {
    chosen = await ExchangeFiles.current.choose();
  } on Exception catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('The file could not be opened. ${_describe(e)}')),
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
        content: Text('${chosen.name} cannot be imported. ${e.message}'),
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
      SnackBar(content: Text('The contest was not imported. ${e.message}')),
    );
    return null;
  }
}

/// The notice that goes with each way of holding an imported contest.
String importModeNotice(ExchangeImportMode mode) => switch (mode) {
  ExchangeImportMode.inspection =>
    'Kept on this computer only. Nothing you do with it is sent to the '
        'service, whoever is signed in.',
  ExchangeImportMode.editable =>
    'Owned by the account in use, like a contest made here. The original '
        'installation may still run the contest until it is moved here, and '
        'sync can be refused until then.',
};

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.preview});

  final ExchangePreview preview;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  late ExchangeImportMode? _mode = widget.preview.available.firstOrNull;

  static const _titles = {
    ExchangeImportMode.inspection: 'Open as a local copy for inspection',
    ExchangeImportMode.editable: 'Import as an editable copy',
  };

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final theme = Theme.of(context);
    final exported = DateFormat.yMMMd().add_jm().format(
      preview.exportedAt.toLocal(),
    );
    return AlertDialog(
      key: const ValueKey('import-dialog'),
      title: Text('Import ${preview.contestName}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exported $exported'
                '${preview.sourceLabel == null ? '' : ' from ${preview.sourceLabel}'}. '
                '${preview.counts['participants'] ?? 0} participants, '
                '${preview.counts['rounds'] ?? 0} rounds, '
                '${preview.counts['scores'] ?? 0} scores. '
                '${preview.redacted ? 'Email addresses were removed.' : 'Email addresses are included.'}',
              ),
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
                        _option(mode, preview, theme),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('import-confirm'),
          onPressed: preview.canImport && _mode != null
              ? () => Navigator.pop(context, _mode)
              : null,
          child: const Text('Import'),
        ),
      ],
    );
  }

  Widget _option(
    ExchangeImportMode mode,
    ExchangePreview preview,
    ThemeData theme,
  ) {
    final reason = preview.unavailable[mode];
    final enabled = preview.available.contains(mode);
    return RadioListTile<ExchangeImportMode>(
      key: ValueKey('import-mode-${mode.name}'),
      contentPadding: EdgeInsets.zero,
      value: mode,
      enabled: enabled,
      title: Text(_titles[mode]!),
      subtitle: Text(
        reason != null && !enabled ? reason : importModeNotice(mode),
      ),
    );
  }
}
