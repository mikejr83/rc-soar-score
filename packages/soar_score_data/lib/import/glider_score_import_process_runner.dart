import 'dart:convert';
import 'dart:io' as io;

import 'package:soar_score_core/soar_score_core.dart';

/// Runs the GliderScore import helpers as child processes.
///
/// The helpers are the two `mdb-*` executables vendored in
/// `tools/gs_importer/`, installed by CMake into a `gs_importer/` folder
/// next to the application executable. This runner finds them there, or at
/// an override directory given at construction or in the `GS_IMPORTER_DIR`
/// environment variable, so tests and packaged installs can redirect them.
class GliderScoreImportProcessRunner implements GliderScoreImportRunner {
  GliderScoreImportProcessRunner({
    String? helperDirectory,
    String Function()? resolvedExecutable,
    Future<io.ProcessResult> Function(List<String>)? runProcess,
    bool Function(String path)? databaseFileExists,
  })  : _helperDirectoryOverride = helperDirectory,
        _resolvedExecutable = resolvedExecutable,
        _runProcess = runProcess ?? _systemProcessRun,
        _databaseFileExists = databaseFileExists ?? _isDatabaseFile;

  final String? _helperDirectoryOverride;
  final String Function()? _resolvedExecutable;
  final Future<io.ProcessResult> Function(List<String>) _runProcess;
  final bool Function(String path) _databaseFileExists;

  static bool _isDatabaseFile(String path) =>
      io.File(path).existsSync() && io.FileSystemEntity.typeSync(path) == io.FileSystemEntityType.file;

  static Future<io.ProcessResult> _systemProcessRun(List<String> args) =>
      io.Process.run(args.first, args.skip(1).toList());

  @override
  Future<ImportAvailability> availability() async {
    final dir = _helperDirectory();
    if (dir == null) {
      return ImportAvailability(
        available: false,
        reason: 'the gs_importer helpers were not found next to the app',
      );
    }
    final executable = '$dir${io.Platform.pathSeparator}mdb-json.exe';
    if (!io.File(executable).existsSync()) {
      return ImportAvailability(
        available: false,
        reason: 'mdb-json.exe was not found in $dir',
      );
    }
    return ImportAvailability(
      available: true,
      executablePath: executable,
    );
  }

  @override
  Future<List<String>> listTables(String dbPath) async {
    final dir = await _requireHelpers();
    _ensureDatabase(dbPath);
    final result = await _runHelper(
      '$dir${io.Platform.pathSeparator}mdb-tables.exe',
      [dbPath],
    );
    return _decode(result.stdout)
        .trim()
        .split(RegExp(r'\s+'))
        .where((name) => name.isNotEmpty)
        .toList();
  }

  @override
  Future<ImportTableStream> exportTable(String dbPath, String table) async {
    final dir = await _requireHelpers();
    _ensureDatabase(dbPath);
    final result = await _runHelper(
      '$dir${io.Platform.pathSeparator}mdb-json.exe',
      ['-T', '%Y-%m-%dT%H:%M:%S', dbPath, table],
    );
    final rows = <Map<String, Object?>>[];
    var lineNumber = 0;
    for (final line in const LineSplitter().convert(_decode(result.stdout))) {
      lineNumber++;
      if (line.trim().isEmpty) {
        continue;
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(line);
      } on FormatException catch (error) {
        throw ImportMalformedTableError(
          'row $lineNumber of table "$table" is not a JSON object: $error',
        );
      }
      if (decoded is! Map<String, Object?>) {
        throw ImportMalformedTableError(
          'row $lineNumber of table "$table" is not a JSON object',
        );
      }
      rows.add(decoded);
    }
    return ImportTableStream(
      table: table,
      rows: Stream.fromIterable(rows),
    );
  }

  /// The helper folder: the override, the environment variable, else the
  /// `gs_importer/` folder next to the executable.
  String? _helperDirectory() {
    final override =
        _helperDirectoryOverride ?? io.Platform.environment['GS_IMPORTER_DIR'];
    if (override != null) {
      return override;
    }
    final resolvedExecutable =
        _resolvedExecutable ?? () => io.Platform.resolvedExecutable;
    final executableDir = io.File(resolvedExecutable()).parent.path;
    return '$executableDir${io.Platform.pathSeparator}gs_importer';
  }

  Future<String> _requireHelpers() async {
    final state = await availability();
    if (!state.available) {
      throw ImportUnavailableError(
        state.reason ?? 'GliderScore import is unavailable on this machine',
      );
    }
    return _helperDirectory()!;
  }

  /// A missing or directory-valued [dbPath] is reported before the helpers
  /// run, so it maps to import_not_found rather than a corrupt database.
  void _ensureDatabase(String dbPath) {
    if (!_databaseFileExists(dbPath)) {
      throw ImportDatabaseNotFoundError('no database file at $dbPath');
    }
  }

  /// Runs [path] with [args]; a spawn failure is an availability problem and
  /// a non-zero exit a corrupt database, both carried with stderr.
  Future<io.ProcessResult> _runHelper(String path, List<String> args) async {
    final io.ProcessResult result;
    try {
      result = await _runProcess([path, ...args]);
    } on io.ProcessException catch (error) {
      throw ImportUnavailableError('could not start $path: ${error.message}');
    }
    if (result.exitCode != 0) {
      final stderrText = _decode(result.stderr).trim();
      throw ImportCorruptDatabaseError(
        'the helper exited with code ${result.exitCode}'
        '${stderrText.isEmpty ? '' : ': ${_truncate(stderrText)}'}',
      );
    }
    return result;
  }

  /// Decodes [data] from the helper, which writes UTF-8: a byte string as
  /// bytes, or a String [dart:io] already decoded from it.
  static String _decode(Object? data) {
    if (data == null) {
      return '';
    }
    if (data is String) {
      return data;
    }
    if (data is List<int>) {
      return const Utf8Decoder().convert(data);
    }
    throw StateError(
      'expected bytes or text from the helper, got ${data.runtimeType}',
    );
  }

  static String _truncate(String text, [int max = 500]) =>
      text.length <= max ? text : '${text.substring(0, max)}…';
}
