import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:soar_score_core/soar_score_core.dart';

/// How an imported contest is held.
enum ExchangeImportMode {
  /// Owned by an inspection owner; never synced.
  inspection,

  /// Owned by the importing account, like a contest made here.
  editable,
}

/// A contest file ready to be saved.
class ExchangeExport {
  const ExchangeExport({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

/// What an import would do, in the words of the dialog.
class ExchangePreview {
  const ExchangePreview({
    required this.contestName,
    required this.exportedAt,
    required this.counts,
    required this.redacted,
    required this.refusals,
    required this.available,
    required this.unavailable,
    this.sourceLabel,
    this.existingCopyName,
  });

  final String contestName;
  final String? sourceLabel;
  final DateTime exportedAt;
  final bool redacted;

  /// `participants`, `rounds`, `scores` and `attempts`.
  final Map<String, int> counts;

  /// Why the file cannot be imported at all, one sentence each.
  final List<String> refusals;

  /// The modes that can be used.
  final List<ExchangeImportMode> available;

  /// The modes that cannot, with the reason to show.
  final Map<ExchangeImportMode, String> unavailable;

  /// The name of the copy that already holds this contest, if any.
  final String? existingCopyName;

  bool get canImport => refusals.isEmpty && available.isNotEmpty;
}

/// What an import did.
class ExchangeImported {
  const ExchangeImported({
    required this.contestId,
    required this.mode,
    required this.differences,
    this.recalculationNote,
  });

  final Id contestId;
  final ExchangeImportMode mode;

  /// How many recomputed results differ from the ones in the file.
  final int differences;
  final String? recalculationNote;
}

/// A refused or unreadable file or export, in a sentence for the director.
class ExchangeFailure implements Exception {
  const ExchangeFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exports a contest to a `.rcsoar` file and imports one. The native build
/// has it; the web build holds no contest data and has none.
abstract class ContestExchange {
  /// The exchange of this build, or `null` when it has none. A test swaps in
  /// its own.
  static ContestExchange? current;

  /// The file of [contestId], with contact details removed when [redact].
  Future<ExchangeExport> export(Id contestId, {required bool redact});

  /// Reads [bytes] and says what importing them would do. Throws an
  /// [ExchangeFailure] when they are not a contest file.
  Future<ExchangePreview> preview(Uint8List bytes);

  /// Imports [bytes] in [mode]. Throws an [ExchangeFailure] when refused.
  Future<ExchangeImported> import(
    Uint8List bytes,
    ExchangeImportMode mode, {
    String? fileName,
  });

  /// The contests here that were imported for inspection.
  Future<Set<Id>> inspectionContests();
}

/// A file the director chose to import.
class ChosenExchangeFile {
  const ChosenExchangeFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// The two system file dialogs the exchange uses. A journey cannot drive
/// them, so it swaps in recorders.
class ExchangeFiles {
  const ExchangeFiles({required this.choose, required this.save});

  /// The file chooser; `null` when the director cancelled.
  final Future<ChosenExchangeFile?> Function() choose;

  /// The save dialog; answers the name written, or `null` when cancelled.
  final Future<String?> Function(String fileName, Uint8List bytes) save;

  static ExchangeFiles current = const ExchangeFiles(
    choose: _systemChoose,
    save: _systemSave,
  );
}

const _typeGroup = XTypeGroup(
  label: 'RC Soar Score contest',
  extensions: ['rcsoar'],
);

Future<ChosenExchangeFile?> _systemChoose() async {
  final file = await openFile(acceptedTypeGroups: const [_typeGroup]);
  if (file == null) return null;
  return ChosenExchangeFile(name: file.name, bytes: await file.readAsBytes());
}

Future<String?> _systemSave(String fileName, Uint8List bytes) async {
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const [_typeGroup],
  );
  if (location == null) return null;
  await File(location.path).writeAsBytes(bytes);
  return p.basename(location.path);
}
