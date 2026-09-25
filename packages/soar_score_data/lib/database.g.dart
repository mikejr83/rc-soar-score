// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ContestsTable extends Contests
    with TableInfo<$ContestsTable, ContestData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, startedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contests';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContestData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContestData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContestData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      )!,
    );
  }

  @override
  $ContestsTable createAlias(String alias) {
    return $ContestsTable(attachedDatabase, alias);
  }
}

class ContestData extends DataClass implements Insertable<ContestData> {
  /// Stable opaque UUIDv7 identifier.
  final String id;

  /// Contest display name.
  final String name;

  /// Contest start time (UTC, ISO-8601).
  final String startedAt;
  const ContestData({
    required this.id,
    required this.name,
    required this.startedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['started_at'] = Variable<String>(startedAt);
    return map;
  }

  ContestsCompanion toCompanion(bool nullToAbsent) {
    return ContestsCompanion(
      id: Value(id),
      name: Value(name),
      startedAt: Value(startedAt),
    );
  }

  factory ContestData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContestData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<String>(startedAt),
    };
  }

  ContestData copyWith({String? id, String? name, String? startedAt}) =>
      ContestData(
        id: id ?? this.id,
        name: name ?? this.name,
        startedAt: startedAt ?? this.startedAt,
      );
  ContestData copyWithCompanion(ContestsCompanion data) {
    return ContestData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContestData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, startedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContestData &&
          other.id == this.id &&
          other.name == this.name &&
          other.startedAt == this.startedAt);
}

class ContestsCompanion extends UpdateCompanion<ContestData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> startedAt;
  final Value<int> rowid;
  const ContestsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContestsCompanion.insert({
    required String id,
    required String name,
    required String startedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startedAt = Value(startedAt);
  static Insertable<ContestData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? startedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContestsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? startedAt,
    Value<int>? rowid,
  }) {
    return ContestsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContestsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SoarScoreDatabase extends GeneratedDatabase {
  _$SoarScoreDatabase(QueryExecutor e) : super(e);
  $SoarScoreDatabaseManager get managers => $SoarScoreDatabaseManager(this);
  late final $ContestsTable contests = $ContestsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [contests];
}

typedef $$ContestsTableCreateCompanionBuilder = ContestsCompanion Function({
  required String id,
  required String name,
  required String startedAt,
  Value<int> rowid,
});
typedef $$ContestsTableUpdateCompanionBuilder = ContestsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> startedAt,
  Value<int> rowid,
});

class $$ContestsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $ContestsTable> {
  $$ContestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContestsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $ContestsTable> {
  $$ContestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContestsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $ContestsTable> {
  $$ContestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
}

class $$ContestsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $ContestsTable,
          ContestData,
          $$ContestsTableFilterComposer,
          $$ContestsTableOrderingComposer,
          $$ContestsTableAnnotationComposer,
          $$ContestsTableCreateCompanionBuilder,
          $$ContestsTableUpdateCompanionBuilder,
          (
            ContestData,
            BaseReferences<_$SoarScoreDatabase, $ContestsTable, ContestData>,
          ),
          ContestData,
          PrefetchHooks Function()
        > {
  $$ContestsTableTableManager(_$SoarScoreDatabase db, $ContestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestsCompanion(
                id: id,
                name: name,
                startedAt: startedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String startedAt,
                Value<int> rowid = const Value.absent(),
              }) => ContestsCompanion.insert(
                id: id,
                name: name,
                startedAt: startedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContestsTable, ContestData>(table),
                  BaseReferences<
                    _$SoarScoreDatabase,
                    $ContestsTable,
                    ContestData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContestsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $ContestsTable,
      ContestData,
      $$ContestsTableFilterComposer,
      $$ContestsTableOrderingComposer,
      $$ContestsTableAnnotationComposer,
      $$ContestsTableCreateCompanionBuilder,
      $$ContestsTableUpdateCompanionBuilder,
      (
        ContestData,
        BaseReferences<_$SoarScoreDatabase, $ContestsTable, ContestData>,
      ),
      ContestData,
      PrefetchHooks Function()
    >;

class $SoarScoreDatabaseManager {
  final _$SoarScoreDatabase _db;
  $SoarScoreDatabaseManager(this._db);
  $$ContestsTableTableManager get contests =>
      $$ContestsTableTableManager(_db, _db.contests);
}
