import 'dart:math';

import 'package:drift/native.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import 'backends.dart';

/// A fresh database on one backend, with the pieces under test.
///
/// SQLite is in memory and uses the native profile. PostgreSQL is a new
/// database on the configured server, dropped by [close], and uses the server
/// profile.
class Installation {
  Installation._(this.backend, this.db, this.stores, this._dropDatabase) {
    unitOfWork = DriftUnitOfWork(
      db,
      stores,
      clock: () => DateTime.utc(2026, 5, 1, 12),
    );
    applier = DriftReplicatedChangeApplier(db, stores);
    syncStore = DriftSyncStore(db);
  }

  /// Opens a fresh database on [backend].
  ///
  /// SQLite uses the native profile unless [profile] says otherwise; a test
  /// that needs the backend-only tables passes [DatabaseProfile.server], so it
  /// runs the same schema on SQLite as on PostgreSQL.
  static Future<Installation> open(
    Backend backend, {
    DatabaseProfile? profile,
  }) async {
    switch (backend) {
      case Backend.sqlite:
        final db = SoarScoreDatabase(
          NativeDatabase.memory(),
          profile: profile ?? DatabaseProfile.native,
        );
        return Installation._(backend, db, EntityStores.forDatabase(db), null);
      case Backend.postgres:
        final config = postgresConfig!;
        final name =
            'soar_test_${DateTime.now().microsecondsSinceEpoch}_'
            '${Random().nextInt(1 << 30)}';
        final admin = await pg.Connection.open(
          config.named('postgres').toEndpoint(),
          settings: config.toSettings(),
        );
        await admin.execute('CREATE DATABASE "$name"');
        final db = SoarScoreDatabase(
          config.named(name).toPgDatabase(),
          profile: DatabaseProfile.server,
        );
        return Installation._(
          backend,
          db,
          EntityStores.forDatabase(db),
          () async {
            await admin.execute('DROP DATABASE "$name" WITH (FORCE)');
            await admin.close();
          },
        );
    }
  }

  final Backend backend;
  final SoarScoreDatabase db;
  final EntityStores stores;
  final Future<void> Function()? _dropDatabase;
  late final DriftUnitOfWork unitOfWork;
  late final DriftReplicatedChangeApplier applier;
  late final DriftSyncStore syncStore;

  /// Whether this database has the client-only tables (an installation does,
  /// the server does not).
  bool get hasClientTables => db.profile.groups.contains(TableGroup.clientOnly);

  Future<void> close() async {
    await db.close();
    await _dropDatabase?.call();
  }

  /// The names of the tables in the database.
  Future<Set<String>> tableNames() async {
    final sql = backend == Backend.sqlite
        ? "SELECT name FROM sqlite_master WHERE type = 'table'"
        : "SELECT table_name AS name FROM information_schema.tables "
              "WHERE table_schema = 'public'";
    final rows = await db.customSelect(sql).get();
    return {for (final row in rows) row.read<String>('name')};
  }

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');
}

var _requests = 0;

core.MutationMetadata metadata({String? requestId}) => core.MutationMetadata(
  clientMutationId: requestId ?? 'request-${_requests++}',
  authority: core.Authority.director,
  clientTime: DateTime.utc(2026, 5, 1, 11),
);

core.Contest contest({
  String name = 'Spring Meet',
  int revision = 0,
  core.Id? id,
}) => core.Contest(
  id: id ?? core.Id.create(),
  name: name,
  startDateTime: DateTime.utc(2026, 4, 15, 10, 30),
  endDateTime: DateTime.utc(2026, 4, 16, 20),
  timezone: 'America/Denver',
  createdAt: DateTime.utc(2026, 4),
  updatedAt: DateTime.utc(2026, 4),
  revision: revision,
);
