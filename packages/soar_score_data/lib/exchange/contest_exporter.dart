import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../repositories/local_account_repository.dart';
import '../schema/database_profile.dart';
import '../sync/entity_stores.dart';
import '../sync/sql_placeholders.dart';
import 'exchange_file.dart';
import 'exchange_tables.dart';
import 'exchange_transforms.dart';

/// What the exporting app knows and the database does not.
class ExportSource {
  const ExportSource({
    this.installationId,
    this.appVersion,
    this.label,
    this.diagnostics = const {},
  });

  /// The installation's id (the file beside the database).
  final String? installationId;
  final String? appVersion;

  /// How the person receiving the file should call the source, such as the
  /// director's account name or the machine name.
  final String? label;

  /// The app's own diagnostics: platform and OS, whether signed in, the
  /// current sync problem. Written under `diagnostics.app`.
  final Map<String, Object?> diagnostics;
}

/// Writes one contest of a native database to an [ExchangeFile].
///
/// Everything is read in one transaction, so a score entered while exporting
/// is either wholly in the file or wholly out of it.
class ContestExporter {
  ContestExporter(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SoarScoreDatabase _db;
  final DateTime Function() _clock;

  /// The export of [contestId], with contact details removed when [redact].
  ///
  /// Throws an [ExchangeException] (`contest_not_found`) when the contest is
  /// not in the database.
  Future<ExchangeFile> export(
    core.Id contestId, {
    bool redact = true,
    ExportSource source = const ExportSource(),
  }) => _db.transaction(() async {
    if (_db.profile != DatabaseProfile.native) {
      throw const ExchangeException(
        'not_native',
        'Only an installation exports a contest.',
      );
    }
    final stores = EntityStores.forDatabase(_db);
    final contest = await stores.of('Contest').findJson(contestId);
    if (contest == null) {
      throw ExchangeException(
        'contest_not_found',
        'The contest is not in this database.',
      );
    }
    final tables = <String, List<Map<String, Object?>>>{};
    for (final spec in contestExchangeTables) {
      final store = stores.of(spec.entityType);
      final rows = spec.table == 'contests'
          ? [contest]
          : await store.whereIdJson(spec.contestColumn, contestId);
      tables[spec.table] = _sorted(rows);
    }

    final systemReferences = await _collectDirectorRows(stores, tables);

    final owner = contest['owner_account_id'] as String?;
    final localRepository = LocalAccountRepository(_db);
    final localAccount = await localRepository.find();
    final contestMutations = [...tables['mutation_records']!];
    final isLocal = owner == null || owner == localAccount?.value;
    // Pending changes of the director's own rows the contest points at, so
    // an editable copy can send them (a copy for inspection never does).
    if (owner != null) {
      final directorIds = {
        for (final table in directorExchangeTables)
          for (final row in tables[table.table] ?? const [])
            if (row['id'] case final String id) id,
      };
      final mutations = stores.of('MutationRecord');
      for (final row in await mutations.whereIdJson(
        'owner_account_id',
        core.Id.parse(owner),
      )) {
        if (directorIds.contains(row['entity_id'])) {
          tables['mutation_records']!.add(row);
        }
      }
      tables['mutation_records'] = _sorted(tables['mutation_records']!);
    }

    final syncState = isLocal
        ? SourceSyncState.never
        : await _syncState(contestId, contestMutations);

    final derived = <String, List<Map<String, Object?>>>{
      for (final spec in derivedExchangeTables)
        spec.table: _sorted(
          await stores
              .of(spec.entityType)
              .whereIdJson(spec.contestColumn, contestId),
        ),
    };

    final preferences = await localRepository.preferences();
    final diagnostics = <String, Object?>{
      'schema_version': _db.schemaVersion,
      'sync': await _syncDiagnostics(contestId, contestMutations),
      'preferences': {
        'time_zone': preferences.preferredTimeZone,
        'locale': preferences.preferredLocale,
      },
      'app': source.diagnostics,
      'derived_as_seen': derived,
    };

    final header = ExchangeHeader(
      formatVersion: exchangeFormatVersion,
      schemaVersion: _db.schemaVersion,
      exportedAt: _clock().toUtc().toIso8601String(),
      contestId: contestId.value,
      contestName: contest['name'] as String? ?? '',
      redacted: redact,
      sourceOwnerKind: isLocal
          ? SourceOwnerKind.local
          : SourceOwnerKind.account,
      sourceSyncState: syncState,
      sourceInstallationId: source.installationId,
      sourceAccountId: owner,
      sourceLocalAccountId: localAccount?.value,
      sourceLabel: source.label,
      appVersion: source.appVersion,
      systemReferences: systemReferences,
    );
    return ExchangeFile(
      header: header,
      tables: redact ? redactTables(tables) : tables,
      diagnostics: redact ? redactDiagnostics(diagnostics) : diagnostics,
    );
  });

  /// Adds the director rows the contest rows point at to [tables] and returns
  /// the system rows it points at, which are not exported.
  Future<Map<String, List<String>>> _collectDirectorRows(
    EntityStores stores,
    Map<String, List<Map<String, Object?>>> tables,
  ) async {
    final system = <String, Set<String>>{};
    final landing = <String>{};
    final presets = <String>{};
    final profiles = <String>{};
    final roles = <String>{};
    final models = <String>{};
    void add(Set<String> into, Object? id) {
      if (id is String) into.add(id);
    }

    for (final row in tables['contest_configuration_revisions']!) {
      add(landing, row['landing_table_id']);
      add(presets, row['source_preset_id']);
      add(
        system.putIfAbsent('discipline_profiles', () => {}),
        row['discipline_profile_id'],
      );
    }
    for (final row in tables['contest_participations']!) {
      add(profiles, row['participant_profile_id']);
      add(roles, row['role_id']);
    }
    for (final row in tables['contest_model_links']!) {
      add(models, row['model_catalog_id']);
    }

    final presetRows = <Map<String, Object?>>[];
    for (final id in presets) {
      final row = await stores
          .of('ContestConfigurationPreset')
          .findJson(core.Id.parse(id));
      if (row == null) continue;
      presetRows.add(row);
      add(landing, row['landing_table_id']);
      add(
        system.putIfAbsent('discipline_profiles', () => {}),
        row['discipline_profile_id'],
      );
    }

    final landingRows = <Map<String, Object?>>[];
    final landingResults = <Map<String, Object?>>[];
    for (final id in landing) {
      final row = await stores.of('LandingTable').findJson(core.Id.parse(id));
      if (row == null) continue;
      if (row['owner_account_id'] == null) {
        system.putIfAbsent('landing_tables', () => {}).add(id);
        continue;
      }
      landingRows.add(row);
      landingResults.addAll(
        await stores
            .of('LandingResult')
            .whereIdJson('landing_table_id', core.Id.parse(id)),
      );
    }

    Future<List<Map<String, Object?>>> owned(
      String type,
      Set<String> ids, {
      String? systemTable,
    }) async {
      final rows = <Map<String, Object?>>[];
      for (final id in ids) {
        final row = await stores.of(type).findJson(core.Id.parse(id));
        if (row == null) continue;
        if (row['owner_account_id'] == null) {
          system.putIfAbsent(systemTable ?? type, () => {}).add(id);
        } else {
          rows.add(row);
        }
      }
      return rows;
    }

    tables['landing_tables'] = _sorted(landingRows);
    tables['landing_results'] = _sorted(landingResults);
    tables['contest_configuration_presets'] = _sorted(presetRows);
    tables['participant_profiles'] = _sorted(
      await owned('ParticipantProfile', profiles),
    );
    tables['roles'] = _sorted(await owned('Role', roles, systemTable: 'roles'));
    tables['model_catalogs'] = _sorted(await owned('ModelCatalog', models));
    return {
      for (final MapEntry(:key, :value) in system.entries)
        if (value.isNotEmpty) key: (value.toList()..sort()),
    };
  }

  Future<SourceSyncState> _syncState(
    core.Id contestId,
    List<Map<String, Object?>> mutations,
  ) async {
    final position = await _syncPosition(contestId);
    final accepted = mutations.any((m) => m['sequence'] != null);
    return (position != null && position > 0) || accepted
        ? SourceSyncState.synced
        : SourceSyncState.unknown;
  }

  Future<int?> _syncPosition(core.Id contestId) async {
    try {
      final row = await _db
          .customSelect(
            portableSql(
              _db,
              'SELECT last_synced_sequence FROM local_sync_positions '
              "WHERE scope_kind = 'Contest' AND scope_id = ?",
            ),
            variables: [Variable<String>(contestId.value)],
          )
          .getSingleOrNull();
      return row?.read<int>('last_synced_sequence');
    } on Object {
      // The table missing or unreadable counts as no evidence.
      return null;
    }
  }

  Future<Map<String, Object?>> _syncDiagnostics(
    core.Id contestId,
    List<Map<String, Object?>> mutations,
  ) async {
    int count(String outcome) =>
        mutations.where((m) => m['outcome'] == outcome).length;
    return {
      'last_synced_sequence': await _syncPosition(contestId),
      'pending_mutations': count('Pending'),
      'rejected_mutations': count('Rejected'),
      'conflicted_mutations': count('Conflict'),
      'accepted_mutations': count('Accepted'),
    };
  }

  List<Map<String, Object?>> _sorted(List<Map<String, Object?>> rows) =>
      [...rows]..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
}
