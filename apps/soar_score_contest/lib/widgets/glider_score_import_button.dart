import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api_client_provider.dart';
import 'api_error_text.dart';

/// Testing entry point for the GliderScore `.mdb` import. The director picks a
/// GliderScore database file and the snapshot travels through the app's
/// `ApiClient` to `POST /api/v1/imports/gliderscore`, exactly the path the
/// final flow will take; the result is summarized here instead of fed to a
/// wizard.
class GliderScoreImportButton extends StatefulWidget {
  const GliderScoreImportButton({super.key});

  @override
  State<GliderScoreImportButton> createState() =>
      _GliderScoreImportButtonState();
}

class _GliderScoreImportButtonState extends State<GliderScoreImportButton> {
  static const _mdbFilter =
      XTypeGroup(label: 'GliderScore database', extensions: ['mdb']);

  bool _working = false;
  String? _status;

  Future<void> _import(BuildContext context) async {
    final client = apiClientOf(context);
    if (client == null) {
      return;
    }

    final file = await openFile(acceptedTypeGroups: const [_mdbFilter]);
    final path = file?.path;
    if (path == null || !context.mounted) {
      return;
    }

    setState(() {
      _working = true;
      _status = null;
    });
    try {
      final result = await client.importGliderScore(path);
      if (!context.mounted) {
        return;
      }
      final tables = result.tables
          .map((table) => '${table.name} (${table.rowCount} rows)')
          .join(', ');
      setState(() => _status = 'Imported ${result.sourceDbFile}: $tables');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      setState(() => _status = 'Import failed: ${apiErrorText(error)}');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Import only exists on the native Windows build, where the local API
    // client is always present.
    final canImport = !kIsWeb && apiClientOf(context) != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: canImport && !_working ? () => _import(context) : null,
          icon: _working
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.folder_open, size: 16),
          label: Text(
            _working ? 'Importing GliderScore data…' : 'Import GliderScore database',
          ),
        ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _status!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
