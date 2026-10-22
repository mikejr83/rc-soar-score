import 'dart:convert';

/// The format name written into every file.
const exchangeFormatName = 'rcsoar';

/// The shape of the file this build writes and reads. Raised when the layout
/// changes; a file with a higher number is refused ("update the app").
const exchangeFormatVersion = 1;

/// The most bytes of a file the importer reads.
const exchangeMaxBytes = 128 * 1024 * 1024;

/// The deepest JSON nesting the importer accepts.
const exchangeMaxDepth = 32;

/// Why a file or an export request was refused, as a stable code for tests
/// and screens plus a message for people.
class ExchangeException implements Exception {
  const ExchangeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ExchangeException($code): $message';
}

/// Whether the contest ever reached the service, as seen when exporting.
enum SourceSyncState {
  /// The contest belonged to the Local account, which never syncs.
  never,

  /// The service accepted at least one change of the contest.
  synced,

  /// An account owns it but nothing says it reached the service. Treated like
  /// [synced] wherever it matters.
  unknown;

  /// The state named by [text]; a missing or malformed value is [unknown].
  static SourceSyncState parse(Object? text) => values.firstWhere(
    (s) => s.name == text,
    orElse: () => SourceSyncState.unknown,
  );
}

/// Who owned the contest when it was exported.
enum SourceOwnerKind {
  /// The installation's Local account (or nobody).
  local,

  /// A real account.
  account;

  static SourceOwnerKind parse(Object? text) => values.firstWhere(
    (s) => s.name == text,
    orElse: () => SourceOwnerKind.account,
  );
}

/// The header of an export file: what it is, where it came from, and what the
/// reader needs to decide how to import it.
class ExchangeHeader {
  const ExchangeHeader({
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.contestId,
    required this.contestName,
    required this.redacted,
    required this.sourceOwnerKind,
    required this.sourceSyncState,
    this.sourceInstallationId,
    this.sourceAccountId,
    this.sourceLocalAccountId,
    this.sourceLabel,
    this.appVersion,
    this.systemReferences = const {},
  });

  /// Reads the header of a decoded file; throws an [ExchangeException] when a
  /// field the importer needs is missing.
  factory ExchangeHeader.fromJson(Map<String, Object?> json) {
    String? text(String key) => switch (json[key]) {
      final String s when s.isNotEmpty => s,
      _ => null,
    };
    String required(String key) =>
        text(key) ??
        (throw ExchangeException(
          'malformed_header',
          'The file header has no "$key".',
        ));
    int number(String key) => switch (json[key]) {
      final int n => n,
      _ => throw ExchangeException(
        'malformed_header',
        'The file header has no number "$key".',
      ),
    };
    final references = <String, List<String>>{};
    if (json['system_references'] case final Map<String, Object?> map) {
      for (final MapEntry(:key, :value) in map.entries) {
        if (value is List) references[key] = [for (final v in value) '$v'];
      }
    }
    return ExchangeHeader(
      formatVersion: number('format_version'),
      schemaVersion: number('schema_version'),
      exportedAt: required('exported_at'),
      contestId: required('contest_id'),
      contestName: text('contest_name') ?? '',
      redacted: json['redacted'] == true,
      sourceOwnerKind: SourceOwnerKind.parse(json['source_owner_kind']),
      sourceSyncState: SourceSyncState.parse(json['source_sync_state']),
      sourceInstallationId: text('source_installation_id'),
      sourceAccountId: text('source_account_id'),
      sourceLocalAccountId: text('source_local_account_id'),
      sourceLabel: text('source_label'),
      appVersion: text('app_version'),
      systemReferences: references,
    );
  }

  final int formatVersion;

  /// The synced database schema the rows belong to.
  final int schemaVersion;

  /// UTC ISO-8601.
  final String exportedAt;
  final String contestId;
  final String contestName;

  /// Whether contact details were removed from the file.
  final bool redacted;
  final SourceOwnerKind sourceOwnerKind;
  final SourceSyncState sourceSyncState;
  final String? sourceInstallationId;

  /// The contest owner when exported: a Local account id or a real account.
  final String? sourceAccountId;

  /// The exporting installation's Local account id, which stays as the alias
  /// of a claimed account.
  final String? sourceLocalAccountId;
  final String? sourceLabel;
  final String? appVersion;

  /// Ids of system rows the contest points at, by table. Import checks that
  /// they exist locally.
  final Map<String, List<String>> systemReferences;

  /// The ids that name the person the file came from.
  Set<String> get sourceIdentities => {?sourceAccountId, ?sourceLocalAccountId};

  Map<String, Object?> toJson() => {
    'format_version': formatVersion,
    'schema_version': schemaVersion,
    'exported_at': exportedAt,
    'contest_id': contestId,
    'contest_name': contestName,
    'redacted': redacted,
    'source_owner_kind': sourceOwnerKind.name,
    'source_sync_state': sourceSyncState.name,
    'source_installation_id': sourceInstallationId,
    'source_account_id': sourceAccountId,
    'source_local_account_id': sourceLocalAccountId,
    'source_label': sourceLabel,
    'app_version': appVersion,
    'system_references': systemReferences,
  };
}

/// A whole export: header, the rows by table, and the diagnostics block.
class ExchangeFile {
  const ExchangeFile({
    required this.header,
    required this.tables,
    required this.diagnostics,
  });

  /// Decodes [bytes], enforcing the size and depth limits; throws an
  /// [ExchangeException] for anything that is not a well-formed export.
  factory ExchangeFile.decode(List<int> bytes) {
    if (bytes.length > exchangeMaxBytes) {
      throw const ExchangeException(
        'too_large',
        'The file is larger than a contest export can be.',
      );
    }
    final Object? root;
    try {
      root = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ExchangeException(
        'not_a_contest_file',
        'The file is not a contest export.',
      );
    }
    if (root is! Map<String, Object?> || root['format'] != exchangeFormatName) {
      throw const ExchangeException(
        'not_a_contest_file',
        'The file is not a contest export.',
      );
    }
    if (_depth(root) > exchangeMaxDepth) {
      throw const ExchangeException(
        'too_deep',
        'The file is nested deeper than a contest export is.',
      );
    }
    if (root['header'] case {'format_version': final int version}
        when version > exchangeFormatVersion) {
      throw ExchangeException(
        'format_too_new',
        'This file was written by a newer version of the app (file format '
            '$version, this app reads up to $exchangeFormatVersion). Update '
            'the app to open it.',
      );
    }
    final header = switch (root['header']) {
      final Map<String, Object?> map => ExchangeHeader.fromJson(map),
      _ => throw const ExchangeException(
        'malformed_header',
        'The file has no header.',
      ),
    };
    final tables = <String, List<Map<String, Object?>>>{};
    switch (root['tables']) {
      case final Map<String, Object?> map:
        for (final MapEntry(:key, :value) in map.entries) {
          if (value is! List || value.any((row) => row is! Map)) {
            throw ExchangeException(
              'malformed_table',
              'The rows of "$key" are not a list of records.',
            );
          }
          tables[key] = [
            for (final row in value) Map<String, Object?>.from(row as Map),
          ];
        }
      default:
        throw const ExchangeException(
          'malformed_table',
          'The file has no tables.',
        );
    }
    final diagnostics = switch (root['diagnostics']) {
      final Map<String, Object?> map => map,
      _ => const <String, Object?>{},
    };
    return ExchangeFile(
      header: header,
      tables: tables,
      diagnostics: diagnostics,
    );
  }

  final ExchangeHeader header;

  /// The exported rows by table, as the sync stores' JSON.
  final Map<String, List<Map<String, Object?>>> tables;

  /// Everything about how the director's installation saw the contest that is
  /// not contest data: derived rows as stored, sync state, versions.
  final Map<String, Object?> diagnostics;

  /// The rows of [table], or none.
  List<Map<String, Object?>> rows(String table) => tables[table] ?? const [];

  Map<String, Object?> toJson() => {
    'format': exchangeFormatName,
    'header': header.toJson(),
    'tables': tables,
    'diagnostics': diagnostics,
  };

  /// The file as UTF-8 JSON, ready to save.
  List<int> encode() =>
      utf8.encode(const JsonEncoder.withIndent(' ').convert(toJson()));

  static int _depth(Object? node) => switch (node) {
    Map() => 1 + node.values.fold(0, (m, v) => _max(m, _depth(v))),
    List() => 1 + node.fold(0, (m, v) => _max(m, _depth(v))),
    _ => 0,
  };

  static int _max(int a, int b) => a > b ? a : b;
}
