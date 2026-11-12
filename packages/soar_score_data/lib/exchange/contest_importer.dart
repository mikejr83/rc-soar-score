import 'dart:convert';

import 'package:soar_score_core/services/services.dart' as services;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../repositories/repository.dart';
import '../schema/database_profile.dart';
import '../sync/entity_stores.dart';
import 'exchange_file.dart';
import 'exchange_tables.dart';
import 'exchange_transforms.dart';
import 'inspection_owners.dart';

/// How an imported contest is held.
enum ImportMode {
  /// Every row belongs to an inspection owner: the contest never syncs, even
  /// when someone is signed in. Meant for looking at a contest someone else
  /// sent, such as to debug it.
  inspection,

  /// The rows belong to the importing account, like a contest made here. It
  /// does not take over the administration: the original installation may
  /// still administer the contest until it is activated here, and sync may be
  /// refused until then.
  editable,
}

/// Who is importing: this installation's Local account and, when someone is
/// signed in, that account.
class ImportTarget {
  const ImportTarget({required this.localAccountId, this.signedInAccountId});

  final core.Id localAccountId;
  final core.Id? signedInAccountId;

  /// The account the app acts as.
  core.Id get actingAccountId => signedInAccountId ?? localAccountId;
}

/// One reason an import cannot happen, with a stable [code].
class ImportRefusal {
  const ImportRefusal(this.code, this.message, {this.table, this.rowId});

  final String code;
  final String message;

  /// The row the refusal names, when it names one.
  final String? table;
  final String? rowId;

  @override
  String toString() => '$code: $message';
}

/// Thrown by [ContestImporter.import] when the preview checks refuse.
class ImportRefusedException extends ExchangeException {
  ImportRefusedException(this.refusals)
    : super('refused', refusals.map((r) => r.message).join(' '));

  final List<ImportRefusal> refusals;
}

/// What an import would do, worked out before anything is written.
class ImportPreview {
  const ImportPreview({
    required this.header,
    required this.counts,
    required this.refusals,
    required this.modeRefusals,
    required this.unavailableModes,
    this.existingCopyName,
  });

  final ExchangeHeader header;

  /// Row counts to show: `participants`, `rounds`, `scores`, `attempts`.
  final Map<String, int> counts;

  /// Reasons that refuse the import in every mode.
  final List<ImportRefusal> refusals;

  /// Reasons that refuse one mode only (a director row that differs).
  final Map<ImportMode, List<ImportRefusal>> modeRefusals;

  /// Modes that cannot be offered, with the reason to show.
  final Map<ImportMode, String> unavailableModes;

  /// The name of the copy that already holds this contest id, if any.
  final String? existingCopyName;

  /// Whether the file's contact details were removed.
  bool get redacted => header.redacted;

  /// Every refusal that applies to [mode].
  List<ImportRefusal> refusalsFor(ImportMode mode) => [
    ...refusals,
    ...?modeRefusals[mode],
  ];

  /// Whether [mode] can be used for this file.
  bool canImport(ImportMode mode) =>
      !unavailableModes.containsKey(mode) && refusalsFor(mode).isEmpty;

  /// The modes that can be used.
  List<ImportMode> get availableModes => [
    for (final mode in ImportMode.values)
      if (canImport(mode)) mode,
  ];
}

/// One difference between the results the director's installation showed and
/// the ones recomputed here.
class ExchangeDifference {
  const ExchangeDifference({
    required this.table,
    required this.key,
    required this.kind,
    this.column,
    this.seen,
    this.recomputed,
  });

  final String table;
  final String key;

  /// `changed`, `missing` (seen there, not computed here) or `extra`.
  final String kind;
  final String? column;
  final Object? seen;
  final Object? recomputed;

  @override
  String toString() =>
      '$kind $table[$key]${column == null ? '' : '.$column'}'
      '${kind == 'changed' ? ': $seen -> $recomputed' : ''}';
}

/// The outcome of an import.
class ImportResult {
  const ImportResult({
    required this.contestId,
    required this.mode,
    required this.ownerId,
    required this.reusedRows,
    required this.differences,
    this.recalculationNote,
  });

  final core.Id contestId;
  final ImportMode mode;

  /// The account (or inspection owner) that owns the imported rows.
  final core.Id ownerId;

  /// Director rows that were already here and identical, so not written.
  final int reusedRows;

  /// How the recomputed results differ from the ones in the file.
  final List<ExchangeDifference> differences;

  /// Why results were not recomputed, when they were not.
  final String? recalculationNote;
}

/// Reads an [ExchangeFile] into a native database.
///
/// Import rewrites only the records read from the file, in memory, before
/// anything is inserted; the claim of a Local account, which rewrites a whole
/// database, is never involved. All writes are one transaction; every check
/// that can refuse runs first and again inside it.
class ContestImporter {
  ContestImporter(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SoarScoreDatabase _db;
  final DateTime Function() _clock;

  static final _tableSpecs = {
    for (final spec in [...contestExchangeTables, ...directorExchangeTables])
      spec.table: spec,
  };

  /// Works out what importing [file] as [target] would do.
  Future<ImportPreview> preview(
    ExchangeFile file, {
    required ImportTarget target,
  }) async {
    final stores = EntityStores.forDatabase(_db);
    final header = file.header;
    final refusals = <ImportRefusal>[
      ..._versionRefusals(header),
      ..._structureRefusals(file),
    ];
    String? existing;
    final existingContest = refusals.isEmpty
        ? await _findContest(stores, header.contestId)
        : null;
    if (existingContest != null) {
      existing = existingContest['name'] as String?;
      refusals.add(
        ImportRefusal(
          'contest_exists',
          'This contest is already in this database as "$existing". '
              'Delete that copy first to import the file.',
          table: 'contests',
          rowId: header.contestId,
        ),
      );
    }
    if (refusals.isEmpty) {
      refusals.addAll(await _missingSystemRows(stores, file));
      refusals.addAll(await _rowCollisions(stores, file));
    }

    final modeRefusals = <ImportMode, List<ImportRefusal>>{};
    if (refusals.isEmpty) {
      final owners = await InspectionOwnerMarkers(_db).load();
      for (final mode in ImportMode.values) {
        final owner = _ownerFor(mode, file, target, owners);
        final plan = _rewrite(file, owner ?? core.Id.create());
        modeRefusals[mode] = await _directorRefusals(stores, plan, owner, mode);
      }
    }

    return ImportPreview(
      header: header,
      counts: {
        'participants': file.rows('contest_participations').length,
        'rounds': file.rows('rounds').length,
        'scores': file.rows('official_scores').length,
        'attempts': file.rows('score_attempts').length,
      },
      refusals: refusals,
      modeRefusals: modeRefusals,
      unavailableModes: {
        if (_editableUnavailable(header, target) case final reason?)
          ImportMode.editable: reason,
      },
      existingCopyName: existing,
    );
  }

  /// Imports [file] in [mode]. Throws an [ImportRefusedException] when the
  /// preview checks refuse, and an [ExchangeException] when the mode is not
  /// available; nothing is written then.
  Future<ImportResult> import(
    ExchangeFile file, {
    required ImportMode mode,
    required ImportTarget target,
    String? fileName,
  }) async {
    final header = file.header;
    final contestId = core.Id.parse(header.contestId);
    final owner = await _db.transaction(() async {
      final preview = await this.preview(file, target: target);
      if (preview.unavailableModes[mode] case final reason?) {
        throw ExchangeException('mode_unavailable', reason);
      }
      final refusals = preview.refusalsFor(mode);
      if (refusals.isNotEmpty) throw ImportRefusedException(refusals);
      return _write(file, mode: mode, target: target, fileName: fileName);
    });
    return _derive(
      file,
      mode: mode,
      contestId: contestId,
      owner: owner.$1,
    ).then(
      (derived) => ImportResult(
        contestId: contestId,
        mode: mode,
        ownerId: owner.$1,
        reusedRows: owner.$2,
        differences: derived.$1,
        recalculationNote: derived.$2,
      ),
    );
  }

  // --- checks ---------------------------------------------------------

  List<ImportRefusal> _versionRefusals(ExchangeHeader header) => [
    if (header.formatVersion > exchangeFormatVersion)
      ImportRefusal(
        'format_too_new',
        'This file was written by a newer version of the app '
            '(file format ${header.formatVersion}, this app reads up to '
            '$exchangeFormatVersion). Update the app to open it.',
      ),
    if (header.formatVersion < 1)
      ImportRefusal(
        'format_unsupported',
        'This file format (${header.formatVersion}) is not supported.',
      ),
    if (header.schemaVersion != _db.schemaVersion &&
        !(_db.schemaVersion == 2 && header.schemaVersion == 1))
      ImportRefusal(
        'schema_mismatch',
        'This file holds data of database version ${header.schemaVersion}; '
            'this app uses version ${_db.schemaVersion}. Ask for an export '
            'from the same app version.',
      ),
  ];

  List<ImportRefusal> _structureRefusals(ExchangeFile file) {
    if (_db.profile != DatabaseProfile.native) {
      return const [
        ImportRefusal('not_native', 'Only an installation imports a contest.'),
      ];
    }
    final refusals = <ImportRefusal>[];
    void refuse(String code, String message, [String? table, String? id]) =>
        refusals.add(ImportRefusal(code, message, table: table, rowId: id));
    final columns = {
      for (final table in _db.profileTables)
        table.actualTableName: {for (final c in table.$columns) c.$name},
    };
    final contestId = file.header.contestId;
    if (!_isId(contestId)) {
      refuse('invalid_id', 'The contest id in the file is not valid.');
    }
    final contestRows = file.rows('contests');
    if (contestRows.length != 1 || contestRows.single['id'] != contestId) {
      refuse(
        'malformed_contest',
        'The file must hold exactly the contest named in its header.',
      );
    }
    for (final spec in [...contestExchangeTables, ...directorExchangeTables]) {
      if (!file.tables.containsKey(spec.table)) {
        refuse(
          'missing_table',
          'The file has no "${spec.table}" table; it may be cut short.',
          spec.table,
        );
      }
    }
    refusals.addAll(_unreferencedDirectorRows(file));
    final directorIds = {
      for (final spec in directorExchangeTables)
        for (final id in idsOf(file, spec.table)) id,
    };
    for (final MapEntry(key: table, value: rows) in file.tables.entries) {
      final spec = _tableSpecs[table];
      if (spec == null) {
        refuse(
          'unknown_table',
          'The file has a table "$table" this app does '
              'not know.',
          table,
        );
        continue;
      }
      final expected = columns[table]!;
      final seen = <String>{};
      for (final row in rows) {
        final id = row['id'];
        if (id is! String || !_isId(id)) {
          refuse('invalid_id', 'A row of "$table" has no valid id.', table);
          continue;
        }
        if (table == 'audit_events' &&
            row['entity_type'] == inspectionOwnerEntityType) {
          refuse(
            'reserved_row',
            'A row of "$table" uses an identity only this app may write.',
            table,
            id,
          );
          continue;
        }
        if (!seen.add(id)) {
          refuse(
            'duplicate_id',
            'The file has two rows of "$table" with the id $id.',
            table,
            id,
          );
          continue;
        }
        if (row.keys.toSet().difference(expected).isNotEmpty ||
            expected.difference(row.keys.toSet()).isNotEmpty) {
          refuse(
            'malformed_row',
            'A row of "$table" does not have the columns of this app.',
            table,
            id,
          );
          continue;
        }
        if (!_isInContest(spec, table, row, contestId, directorIds)) {
          refuse(
            'foreign_row',
            'A row of "$table" belongs to another contest or owner.',
            table,
            id,
          );
        }
      }
    }
    return refusals;
  }

  /// Director rows the contest rows of [file] do not point at. A file holds
  /// only what its contest uses.
  List<ImportRefusal> _unreferencedDirectorRows(ExchangeFile file) {
    Set<String> column(String table, String name) => {
      for (final row in file.rows(table))
        if (row[name] case final String id) id,
    };
    final presets = column(
      'contest_configuration_revisions',
      'source_preset_id',
    );
    final landing = column(
      'contest_configuration_revisions',
      'landing_table_id',
    );
    for (final row in file.rows('contest_configuration_presets')) {
      final landingId = row['landing_table_id'];
      if (presets.contains(row['id']) && landingId is String) {
        landing.add(landingId);
      }
    }
    final allowed = <String, Set<String>>{
      'participant_profiles': column(
        'contest_participations',
        'participant_profile_id',
      ),
      'roles': column('contest_participations', 'role_id'),
      'model_catalogs': column('contest_model_links', 'model_catalog_id'),
      'contest_configuration_presets': presets,
      'landing_tables': landing,
    };
    return [
      for (final MapEntry(key: table, value: ids) in allowed.entries)
        for (final row in file.rows(table))
          if (!ids.contains(row['id']))
            ImportRefusal(
              'unreferenced_row',
              'A row of "$table" is not used by the contest.',
              table: table,
              rowId: '${row['id']}',
            ),
      for (final row in file.rows('landing_results'))
        if (!landing.contains(row['landing_table_id']))
          ImportRefusal(
            'unreferenced_row',
            'A landing result is not part of a table the contest uses.',
            table: 'landing_results',
            rowId: '${row['id']}',
          ),
    ];
  }

  /// Contest rows whose id is already taken here. Writing them would replace
  /// the other row, so they are refused. (Pending changes of director rows
  /// may repeat: the same change is the same row.)
  Future<List<ImportRefusal>> _rowCollisions(
    EntityStores stores,
    ExchangeFile file,
  ) async {
    final refusals = <ImportRefusal>[];
    for (final spec in contestExchangeTables) {
      final store = stores.of(spec.entityType);
      for (final row in file.rows(spec.table)) {
        if (spec.table == 'mutation_records' && row['contest_id'] == null) {
          continue;
        }
        final id = core.Id.parse(row['id'] as String);
        if (await store.findJson(id) != null) {
          refusals.add(
            ImportRefusal(
              'row_exists',
              'A row of "${spec.table}" (${id.value}) already exists here. '
                  'Importing would replace it.',
              table: spec.table,
              rowId: id.value,
            ),
          );
        }
      }
    }
    return refusals;
  }

  bool _isInContest(
    ExchangeTable spec,
    String table,
    Map<String, Object?> row,
    String contestId,
    Set<String> directorIds,
  ) {
    if (directorExchangeTables.any((t) => t.table == table)) return true;
    if (table == 'contests') return row['id'] == contestId;
    if (row[spec.contestColumn] == contestId) return true;
    // A pending change of a director row the contest points at.
    return table == 'mutation_records' &&
        row['contest_id'] == null &&
        row['owner_account_id'] != null &&
        directorIds.contains(row['entity_id']);
  }

  static final _idPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  bool _isId(String value) => _idPattern.hasMatch(value);

  Future<Map<String, Object?>?> _findContest(EntityStores stores, String id) =>
      stores.of('Contest').findJson(core.Id.parse(id));

  Future<List<ImportRefusal>> _missingSystemRows(
    EntityStores stores,
    ExchangeFile file,
  ) async {
    const typeByTable = {
      'discipline_profiles': 'DisciplineProfile',
      'roles': 'Role',
      'landing_tables': 'LandingTable',
    };
    final refusals = <ImportRefusal>[];
    for (final MapEntry(key: table, value: ids)
        in file.header.systemReferences.entries) {
      final type = typeByTable[table];
      if (type == null) {
        refusals.add(
          ImportRefusal(
            'unknown_system_table',
            'The file refers to system data "$table" this app does not know.',
            table: table,
          ),
        );
        continue;
      }
      for (final id in ids) {
        if (!_isId(id) ||
            await stores.of(type).findJson(core.Id.parse(id)) == null) {
          refusals.add(
            ImportRefusal(
              'missing_system_row',
              'This app does not have the shipped $table row $id the contest '
                  'uses. The two apps are on different versions.',
              table: table,
              rowId: id,
            ),
          );
        }
      }
    }
    return refusals;
  }

  /// The owner a director row must have to be reused: the matched inspection
  /// owner, or the importing account. Null when an inspection import has no
  /// matching owner yet, so no existing row can be reused.
  core.Id? _ownerFor(
    ImportMode mode,
    ExchangeFile file,
    ImportTarget target,
    InspectionOwnerSet owners,
  ) => switch (mode) {
    ImportMode.editable => target.actingAccountId,
    ImportMode.inspection => switch (owners.ownerFor(
      file.header.sourceIdentities,
    )) {
      final String owner => core.Id.parse(owner),
      null => null,
    },
  };

  String? _editableUnavailable(ExchangeHeader header, ImportTarget target) {
    if (header.sourceOwnerKind == SourceOwnerKind.local &&
        header.sourceSyncState == SourceSyncState.never) {
      return null;
    }
    final signedInAs = target.signedInAccountId?.value;
    if (signedInAs != null && signedInAs == header.sourceAccountId) return null;
    return 'This contest belongs to another account on the service. Only '
        'that account can keep an editable copy; you can open it for '
        'inspection.';
  }

  Future<List<ImportRefusal>> _directorRefusals(
    EntityStores stores,
    ExchangeTables rewritten,
    core.Id? owner,
    ImportMode mode,
  ) async {
    final refusals = <ImportRefusal>[];
    for (final spec in directorExchangeTables) {
      for (final row in rewritten[spec.table] ?? const []) {
        final id = row['id'] as String;
        final local = await stores
            .of(spec.entityType)
            .findJson(core.Id.parse(id));
        if (local == null) continue;
        final sameOwner =
            owner != null &&
            (!local.containsKey('owner_account_id') ||
                local['owner_account_id'] == owner.value);
        if (sameOwner && _same(local, row)) continue;
        refusals.add(
          ImportRefusal(
            'director_row_differs',
            'The ${spec.table.replaceAll('_', ' ')} row $id already exists '
                'here ${sameOwner ? 'with other content' : 'for another owner'}. '
                'Importing would change what it shows.',
            table: spec.table,
            rowId: id,
          ),
        );
      }
    }
    // Pending changes of director rows carry no contest: they may only be
    // repeated as they are, never replaced.
    final store = stores.of('MutationRecord');
    for (final row in rewritten['mutation_records'] ?? const []) {
      if (row['contest_id'] != null) continue;
      final id = row['id'] as String;
      final local = await store.findJson(core.Id.parse(id));
      if (local == null || _same(local, row)) continue;
      refusals.add(
        ImportRefusal(
          'row_exists',
          'A pending change ($id) already exists here with other content. '
              'Importing would replace it.',
          table: 'mutation_records',
          rowId: id,
        ),
      );
    }
    return refusals;
  }

  bool _same(Map<String, Object?> a, Map<String, Object?> b) =>
      _canonical(a) == _canonical(b);

  String _canonical(Object? node) => jsonEncode(_sortKeys(node));

  Object? _sortKeys(Object? node) => switch (node) {
    Map() => {
      for (final key in (node.keys.map((k) => '$k').toList()..sort()))
        key: _sortKeys(node[key]),
    },
    List() => [for (final item in node) _sortKeys(item)],
    double() when node == node.truncateToDouble() && node.abs() < 1e15 =>
      node.toInt(),
    _ => node,
  };

  // --- write ----------------------------------------------------------

  ExchangeTables _rewrite(ExchangeFile file, core.Id owner) =>
      rewriteAccountReferences(
        file.tables,
        from: file.header.sourceIdentities,
        to: owner.value,
      );

  /// Writes everything; returns the owner and the number of reused rows.
  Future<(core.Id, int)> _write(
    ExchangeFile file, {
    required ImportMode mode,
    required ImportTarget target,
    String? fileName,
  }) async {
    final header = file.header;
    final stores = EntityStores.forDatabase(_db);
    final markers = InspectionOwnerMarkers(_db);
    final owners = await markers.load();
    final now = _clock().toUtc();
    final identities = header.sourceIdentities;

    final core.Id owner;
    var markerIdentities = identities;
    switch (mode) {
      case ImportMode.editable:
        owner = target.actingAccountId;
      case ImportMode.inspection:
        final matched = owners.ownerFor(identities);
        owner = matched == null ? core.Id.create() : core.Id.parse(matched);
        markerIdentities = {...owners.identitiesOf(owner.value), ...identities};
    }

    final tables = _rewrite(file, owner);
    await _db.customStatement('PRAGMA defer_foreign_keys = ON');
    var reused = 0;
    for (final spec in [...directorExchangeTables, ...contestExchangeTables]) {
      final store = stores.of(spec.entityType);
      final isDirector = directorExchangeTables.contains(spec);
      for (final row in tables[spec.table] ?? const <Map<String, Object?>>[]) {
        if (isDirector) {
          final local = await store.findJson(
            core.Id.parse(row['id'] as String),
          );
          if (local != null) {
            // Identical, as the preview checked: nothing to write.
            reused++;
            continue;
          }
        }
        await store.upsertJson(row);
      }
    }

    final contestId = core.Id.parse(header.contestId);
    final audit = stores.of('AuditEvent');
    switch (mode) {
      case ImportMode.inspection:
        await audit.upsertJson(
          InspectionOwnerMarkers.markerRow(
            owner: owner,
            identities: markerIdentities,
            at: now,
            contestId: contestId,
            sourceLabel: header.sourceLabel,
            exportedAt: header.exportedAt,
            sourceInstallationId: header.sourceInstallationId,
            fileName: fileName,
          ),
        );
      case ImportMode.editable:
        await audit.upsertJson({
          'id': core.Id.create().value,
          'entity_type': 'Contest',
          'entity_id': contestId.value,
          'contest_id': contestId.value,
          'owner_account_id': null,
          'publication_id': null,
          'action': 'Restoration',
          'actor_id': owner.value,
          'authority': 'Director',
          'installation_id': null,
          'device': null,
          'base_revision': null,
          'resulting_revision': null,
          'server_timestamp': now.toIso8601String(),
          'client_timestamp': now.toIso8601String(),
          'reason': jsonEncode({
            'kind': 'import',
            'mode': 'editable',
            'source_account_id': header.sourceAccountId,
            'source_installation_id': header.sourceInstallationId,
            'exported_at': header.exportedAt,
            'file_name': fileName,
          }),
          'outcome': 'Success',
        });
    }

    final broken = await _db.customSelect('PRAGMA foreign_key_check').get();
    if (broken.isNotEmpty) {
      throw ExchangeException(
        'broken_references',
        'The file has rows that point at rows it does not hold '
            '(${broken.first.data['table']}).',
      );
    }
    return (owner, reused);
  }

  // --- derived rows ---------------------------------------------------

  static const _keyColumns = <String, List<String>>{
    'flight_results': ['official_score_id'],
    'participation_standings': ['contest_participation_id', 'as_of_round'],
    'team_standings': ['team_id', 'as_of_round'],
  };

  /// Recomputes the results of the imported contest and compares them with
  /// the ones the director's installation had stored, which the file keeps
  /// only in its diagnostics. Never fails the import.
  Future<(List<ExchangeDifference>, String?)> _derive(
    ExchangeFile file, {
    required ImportMode mode,
    required core.Id contestId,
    required core.Id owner,
  }) async {
    try {
      await services.ResultsService(Repository(_db)).recalculate(contestId);
    } on Object catch (error) {
      return (const <ExchangeDifference>[], 'Results not recomputed: $error');
    }
    final seen = file.diagnostics['derived_as_seen'];
    if (seen is! Map) return (const <ExchangeDifference>[], null);
    final stores = EntityStores.forDatabase(_db);
    final differences = <ExchangeDifference>[];
    for (final spec in derivedExchangeTables) {
      final then = seen[spec.table];
      if (then is! List) continue;
      final keys = _keyColumns[spec.table]!;
      String keyOf(Map row) => keys.map((k) => '${row[k]}').join('/');
      final now = {
        for (final row
            in await stores
                .of(spec.entityType)
                .whereIdJson('contest_id', contestId))
          keyOf(row): row,
      };
      final before = {for (final row in then.whereType<Map>()) keyOf(row): row};
      for (final MapEntry(:key, value: was) in before.entries) {
        final is_ = now[key];
        if (is_ == null) {
          differences.add(
            ExchangeDifference(table: spec.table, key: key, kind: 'missing'),
          );
          continue;
        }
        for (final column in was.keys) {
          if (column == 'id' || column == 'computed_at') continue;
          if (!_sameValue(was[column], is_[column])) {
            differences.add(
              ExchangeDifference(
                table: spec.table,
                key: key,
                kind: 'changed',
                column: '$column',
                seen: was[column],
                recomputed: is_[column],
              ),
            );
          }
        }
      }
      for (final key in now.keys) {
        if (!before.containsKey(key)) {
          differences.add(
            ExchangeDifference(table: spec.table, key: key, kind: 'extra'),
          );
        }
      }
    }
    return (differences, null);
  }

  bool _sameValue(Object? a, Object? b) {
    if (a is num && b is num) return (a - b).abs() < 1e-9;
    return _canonical(a) == _canonical(b);
  }
}
