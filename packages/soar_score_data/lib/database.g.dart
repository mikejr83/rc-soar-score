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
  static const VerificationMeta _startDateTimeMeta = const VerificationMeta(
    'startDateTime',
  );
  @override
  late final GeneratedColumn<String> startDateTime = GeneratedColumn<String>(
    'start_date_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateTimeMeta = const VerificationMeta(
    'endDateTime',
  );
  @override
  late final GeneratedColumn<String> endDateTime = GeneratedColumn<String>(
    'end_date_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lifecycleStateMeta = const VerificationMeta(
    'lifecycleState',
  );
  @override
  late final GeneratedColumn<String> lifecycleState = GeneratedColumn<String>(
    'lifecycle_state',
    aliasedName,
    false,
    check: () => lifecycleState.isIn(lifecycleStateValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoringAccessMeta = const VerificationMeta(
    'scoringAccess',
  );
  @override
  late final GeneratedColumn<String> scoringAccess = GeneratedColumn<String>(
    'scoring_access',
    aliasedName,
    false,
    check: () => scoringAccess.isIn(scoringAccessValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adminLockMeta = const VerificationMeta(
    'adminLock',
  );
  @override
  late final GeneratedColumn<String> adminLock = GeneratedColumn<String>(
    'admin_lock',
    aliasedName,
    false,
    check: () => adminLock.isIn(adminLockValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultsHiddenThroughRoundMeta =
      const VerificationMeta('resultsHiddenThroughRound');
  @override
  late final GeneratedColumn<int> resultsHiddenThroughRound =
      GeneratedColumn<int>(
        'results_hidden_through_round',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resultsHiddenAtMeta = const VerificationMeta(
    'resultsHiddenAt',
  );
  @override
  late final GeneratedColumn<String> resultsHiddenAt = GeneratedColumn<String>(
    'results_hidden_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localArchiveMeta = const VerificationMeta(
    'localArchive',
  );
  @override
  late final GeneratedColumn<bool> localArchive = GeneratedColumn<bool>(
    'local_archive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
      SqlDialect.sqlite: 'CHECK ("local_archive" IN (0, 1))',
      SqlDialect.postgres: '',
    }),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startDateTime,
    endDateTime,
    timezone,
    host,
    city,
    state,
    country,
    ownerAccountId,
    lifecycleState,
    scoringAccess,
    adminLock,
    resultsHiddenThroughRound,
    resultsHiddenAt,
    localArchive,
    createdAt,
    updatedAt,
    revision,
  ];
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
    if (data.containsKey('start_date_time')) {
      context.handle(
        _startDateTimeMeta,
        startDateTime.isAcceptableOrUnknown(
          data['start_date_time']!,
          _startDateTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startDateTimeMeta);
    }
    if (data.containsKey('end_date_time')) {
      context.handle(
        _endDateTimeMeta,
        endDateTime.isAcceptableOrUnknown(
          data['end_date_time']!,
          _endDateTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endDateTimeMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('lifecycle_state')) {
      context.handle(
        _lifecycleStateMeta,
        lifecycleState.isAcceptableOrUnknown(
          data['lifecycle_state']!,
          _lifecycleStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lifecycleStateMeta);
    }
    if (data.containsKey('scoring_access')) {
      context.handle(
        _scoringAccessMeta,
        scoringAccess.isAcceptableOrUnknown(
          data['scoring_access']!,
          _scoringAccessMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoringAccessMeta);
    }
    if (data.containsKey('admin_lock')) {
      context.handle(
        _adminLockMeta,
        adminLock.isAcceptableOrUnknown(data['admin_lock']!, _adminLockMeta),
      );
    } else if (isInserting) {
      context.missing(_adminLockMeta);
    }
    if (data.containsKey('results_hidden_through_round')) {
      context.handle(
        _resultsHiddenThroughRoundMeta,
        resultsHiddenThroughRound.isAcceptableOrUnknown(
          data['results_hidden_through_round']!,
          _resultsHiddenThroughRoundMeta,
        ),
      );
    }
    if (data.containsKey('results_hidden_at')) {
      context.handle(
        _resultsHiddenAtMeta,
        resultsHiddenAt.isAcceptableOrUnknown(
          data['results_hidden_at']!,
          _resultsHiddenAtMeta,
        ),
      );
    }
    if (data.containsKey('local_archive')) {
      context.handle(
        _localArchiveMeta,
        localArchive.isAcceptableOrUnknown(
          data['local_archive']!,
          _localArchiveMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
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
      startDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date_time'],
      )!,
      endDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date_time'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      ),
      lifecycleState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifecycle_state'],
      )!,
      scoringAccess: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_access'],
      )!,
      adminLock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}admin_lock'],
      )!,
      resultsHiddenThroughRound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}results_hidden_through_round'],
      ),
      resultsHiddenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}results_hidden_at'],
      ),
      localArchive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_archive'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
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

  /// Start (UTC, ISO-8601).
  final String startDateTime;

  /// End (UTC, ISO-8601).
  final String endDateTime;

  /// IANA timezone name.
  final String timezone;
  final String? host;
  final String? city;
  final String? state;
  final String? country;

  /// Owning account; null for anonymous or local contests.
  final String? ownerAccountId;

  /// `Created`, `Configuring`, `Ready`, `Running` or `Completed`.
  final String lifecycleState;

  /// `Closed` or `Open`.
  final String scoringAccess;

  /// `Unlocked` or `Locked`.
  final String adminLock;
  final int? resultsHiddenThroughRound;
  final String? resultsHiddenAt;
  final bool localArchive;
  final String createdAt;
  final String updatedAt;
  final int revision;
  const ContestData({
    required this.id,
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
    required this.timezone,
    this.host,
    this.city,
    this.state,
    this.country,
    this.ownerAccountId,
    required this.lifecycleState,
    required this.scoringAccess,
    required this.adminLock,
    this.resultsHiddenThroughRound,
    this.resultsHiddenAt,
    required this.localArchive,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['start_date_time'] = Variable<String>(startDateTime);
    map['end_date_time'] = Variable<String>(endDateTime);
    map['timezone'] = Variable<String>(timezone);
    if (!nullToAbsent || host != null) {
      map['host'] = Variable<String>(host);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || ownerAccountId != null) {
      map['owner_account_id'] = Variable<String>(ownerAccountId);
    }
    map['lifecycle_state'] = Variable<String>(lifecycleState);
    map['scoring_access'] = Variable<String>(scoringAccess);
    map['admin_lock'] = Variable<String>(adminLock);
    if (!nullToAbsent || resultsHiddenThroughRound != null) {
      map['results_hidden_through_round'] = Variable<int>(
        resultsHiddenThroughRound,
      );
    }
    if (!nullToAbsent || resultsHiddenAt != null) {
      map['results_hidden_at'] = Variable<String>(resultsHiddenAt);
    }
    map['local_archive'] = Variable<bool>(localArchive);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  ContestsCompanion toCompanion(bool nullToAbsent) {
    return ContestsCompanion(
      id: Value(id),
      name: Value(name),
      startDateTime: Value(startDateTime),
      endDateTime: Value(endDateTime),
      timezone: Value(timezone),
      host: host == null && nullToAbsent ? const Value.absent() : Value(host),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      ownerAccountId: ownerAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerAccountId),
      lifecycleState: Value(lifecycleState),
      scoringAccess: Value(scoringAccess),
      adminLock: Value(adminLock),
      resultsHiddenThroughRound:
          resultsHiddenThroughRound == null && nullToAbsent
          ? const Value.absent()
          : Value(resultsHiddenThroughRound),
      resultsHiddenAt: resultsHiddenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resultsHiddenAt),
      localArchive: Value(localArchive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
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
      startDateTime: serializer.fromJson<String>(json['startDateTime']),
      endDateTime: serializer.fromJson<String>(json['endDateTime']),
      timezone: serializer.fromJson<String>(json['timezone']),
      host: serializer.fromJson<String?>(json['host']),
      city: serializer.fromJson<String?>(json['city']),
      state: serializer.fromJson<String?>(json['state']),
      country: serializer.fromJson<String?>(json['country']),
      ownerAccountId: serializer.fromJson<String?>(json['ownerAccountId']),
      lifecycleState: serializer.fromJson<String>(json['lifecycleState']),
      scoringAccess: serializer.fromJson<String>(json['scoringAccess']),
      adminLock: serializer.fromJson<String>(json['adminLock']),
      resultsHiddenThroughRound: serializer.fromJson<int?>(
        json['resultsHiddenThroughRound'],
      ),
      resultsHiddenAt: serializer.fromJson<String?>(json['resultsHiddenAt']),
      localArchive: serializer.fromJson<bool>(json['localArchive']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startDateTime': serializer.toJson<String>(startDateTime),
      'endDateTime': serializer.toJson<String>(endDateTime),
      'timezone': serializer.toJson<String>(timezone),
      'host': serializer.toJson<String?>(host),
      'city': serializer.toJson<String?>(city),
      'state': serializer.toJson<String?>(state),
      'country': serializer.toJson<String?>(country),
      'ownerAccountId': serializer.toJson<String?>(ownerAccountId),
      'lifecycleState': serializer.toJson<String>(lifecycleState),
      'scoringAccess': serializer.toJson<String>(scoringAccess),
      'adminLock': serializer.toJson<String>(adminLock),
      'resultsHiddenThroughRound': serializer.toJson<int?>(
        resultsHiddenThroughRound,
      ),
      'resultsHiddenAt': serializer.toJson<String?>(resultsHiddenAt),
      'localArchive': serializer.toJson<bool>(localArchive),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  ContestData copyWith({
    String? id,
    String? name,
    String? startDateTime,
    String? endDateTime,
    String? timezone,
    Value<String?> host = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> state = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<String?> ownerAccountId = const Value.absent(),
    String? lifecycleState,
    String? scoringAccess,
    String? adminLock,
    Value<int?> resultsHiddenThroughRound = const Value.absent(),
    Value<String?> resultsHiddenAt = const Value.absent(),
    bool? localArchive,
    String? createdAt,
    String? updatedAt,
    int? revision,
  }) => ContestData(
    id: id ?? this.id,
    name: name ?? this.name,
    startDateTime: startDateTime ?? this.startDateTime,
    endDateTime: endDateTime ?? this.endDateTime,
    timezone: timezone ?? this.timezone,
    host: host.present ? host.value : this.host,
    city: city.present ? city.value : this.city,
    state: state.present ? state.value : this.state,
    country: country.present ? country.value : this.country,
    ownerAccountId: ownerAccountId.present
        ? ownerAccountId.value
        : this.ownerAccountId,
    lifecycleState: lifecycleState ?? this.lifecycleState,
    scoringAccess: scoringAccess ?? this.scoringAccess,
    adminLock: adminLock ?? this.adminLock,
    resultsHiddenThroughRound: resultsHiddenThroughRound.present
        ? resultsHiddenThroughRound.value
        : this.resultsHiddenThroughRound,
    resultsHiddenAt: resultsHiddenAt.present
        ? resultsHiddenAt.value
        : this.resultsHiddenAt,
    localArchive: localArchive ?? this.localArchive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
  );
  ContestData copyWithCompanion(ContestsCompanion data) {
    return ContestData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDateTime: data.startDateTime.present
          ? data.startDateTime.value
          : this.startDateTime,
      endDateTime: data.endDateTime.present
          ? data.endDateTime.value
          : this.endDateTime,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      host: data.host.present ? data.host.value : this.host,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      country: data.country.present ? data.country.value : this.country,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      lifecycleState: data.lifecycleState.present
          ? data.lifecycleState.value
          : this.lifecycleState,
      scoringAccess: data.scoringAccess.present
          ? data.scoringAccess.value
          : this.scoringAccess,
      adminLock: data.adminLock.present ? data.adminLock.value : this.adminLock,
      resultsHiddenThroughRound: data.resultsHiddenThroughRound.present
          ? data.resultsHiddenThroughRound.value
          : this.resultsHiddenThroughRound,
      resultsHiddenAt: data.resultsHiddenAt.present
          ? data.resultsHiddenAt.value
          : this.resultsHiddenAt,
      localArchive: data.localArchive.present
          ? data.localArchive.value
          : this.localArchive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContestData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDateTime: $startDateTime, ')
          ..write('endDateTime: $endDateTime, ')
          ..write('timezone: $timezone, ')
          ..write('host: $host, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('country: $country, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('lifecycleState: $lifecycleState, ')
          ..write('scoringAccess: $scoringAccess, ')
          ..write('adminLock: $adminLock, ')
          ..write('resultsHiddenThroughRound: $resultsHiddenThroughRound, ')
          ..write('resultsHiddenAt: $resultsHiddenAt, ')
          ..write('localArchive: $localArchive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startDateTime,
    endDateTime,
    timezone,
    host,
    city,
    state,
    country,
    ownerAccountId,
    lifecycleState,
    scoringAccess,
    adminLock,
    resultsHiddenThroughRound,
    resultsHiddenAt,
    localArchive,
    createdAt,
    updatedAt,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContestData &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDateTime == this.startDateTime &&
          other.endDateTime == this.endDateTime &&
          other.timezone == this.timezone &&
          other.host == this.host &&
          other.city == this.city &&
          other.state == this.state &&
          other.country == this.country &&
          other.ownerAccountId == this.ownerAccountId &&
          other.lifecycleState == this.lifecycleState &&
          other.scoringAccess == this.scoringAccess &&
          other.adminLock == this.adminLock &&
          other.resultsHiddenThroughRound == this.resultsHiddenThroughRound &&
          other.resultsHiddenAt == this.resultsHiddenAt &&
          other.localArchive == this.localArchive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision);
}

class ContestsCompanion extends UpdateCompanion<ContestData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> startDateTime;
  final Value<String> endDateTime;
  final Value<String> timezone;
  final Value<String?> host;
  final Value<String?> city;
  final Value<String?> state;
  final Value<String?> country;
  final Value<String?> ownerAccountId;
  final Value<String> lifecycleState;
  final Value<String> scoringAccess;
  final Value<String> adminLock;
  final Value<int?> resultsHiddenThroughRound;
  final Value<String?> resultsHiddenAt;
  final Value<bool> localArchive;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const ContestsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDateTime = const Value.absent(),
    this.endDateTime = const Value.absent(),
    this.timezone = const Value.absent(),
    this.host = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.country = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.lifecycleState = const Value.absent(),
    this.scoringAccess = const Value.absent(),
    this.adminLock = const Value.absent(),
    this.resultsHiddenThroughRound = const Value.absent(),
    this.resultsHiddenAt = const Value.absent(),
    this.localArchive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContestsCompanion.insert({
    required String id,
    required String name,
    required String startDateTime,
    required String endDateTime,
    required String timezone,
    this.host = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.country = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    required String lifecycleState,
    required String scoringAccess,
    required String adminLock,
    this.resultsHiddenThroughRound = const Value.absent(),
    this.resultsHiddenAt = const Value.absent(),
    this.localArchive = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startDateTime = Value(startDateTime),
       endDateTime = Value(endDateTime),
       timezone = Value(timezone),
       lifecycleState = Value(lifecycleState),
       scoringAccess = Value(scoringAccess),
       adminLock = Value(adminLock),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ContestData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? startDateTime,
    Expression<String>? endDateTime,
    Expression<String>? timezone,
    Expression<String>? host,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? country,
    Expression<String>? ownerAccountId,
    Expression<String>? lifecycleState,
    Expression<String>? scoringAccess,
    Expression<String>? adminLock,
    Expression<int>? resultsHiddenThroughRound,
    Expression<String>? resultsHiddenAt,
    Expression<bool>? localArchive,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDateTime != null) 'start_date_time': startDateTime,
      if (endDateTime != null) 'end_date_time': endDateTime,
      if (timezone != null) 'timezone': timezone,
      if (host != null) 'host': host,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (lifecycleState != null) 'lifecycle_state': lifecycleState,
      if (scoringAccess != null) 'scoring_access': scoringAccess,
      if (adminLock != null) 'admin_lock': adminLock,
      if (resultsHiddenThroughRound != null)
        'results_hidden_through_round': resultsHiddenThroughRound,
      if (resultsHiddenAt != null) 'results_hidden_at': resultsHiddenAt,
      if (localArchive != null) 'local_archive': localArchive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContestsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? startDateTime,
    Value<String>? endDateTime,
    Value<String>? timezone,
    Value<String?>? host,
    Value<String?>? city,
    Value<String?>? state,
    Value<String?>? country,
    Value<String?>? ownerAccountId,
    Value<String>? lifecycleState,
    Value<String>? scoringAccess,
    Value<String>? adminLock,
    Value<int?>? resultsHiddenThroughRound,
    Value<String?>? resultsHiddenAt,
    Value<bool>? localArchive,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return ContestsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      timezone: timezone ?? this.timezone,
      host: host ?? this.host,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      scoringAccess: scoringAccess ?? this.scoringAccess,
      adminLock: adminLock ?? this.adminLock,
      resultsHiddenThroughRound:
          resultsHiddenThroughRound ?? this.resultsHiddenThroughRound,
      resultsHiddenAt: resultsHiddenAt ?? this.resultsHiddenAt,
      localArchive: localArchive ?? this.localArchive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
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
    if (startDateTime.present) {
      map['start_date_time'] = Variable<String>(startDateTime.value);
    }
    if (endDateTime.present) {
      map['end_date_time'] = Variable<String>(endDateTime.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (lifecycleState.present) {
      map['lifecycle_state'] = Variable<String>(lifecycleState.value);
    }
    if (scoringAccess.present) {
      map['scoring_access'] = Variable<String>(scoringAccess.value);
    }
    if (adminLock.present) {
      map['admin_lock'] = Variable<String>(adminLock.value);
    }
    if (resultsHiddenThroughRound.present) {
      map['results_hidden_through_round'] = Variable<int>(
        resultsHiddenThroughRound.value,
      );
    }
    if (resultsHiddenAt.present) {
      map['results_hidden_at'] = Variable<String>(resultsHiddenAt.value);
    }
    if (localArchive.present) {
      map['local_archive'] = Variable<bool>(localArchive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
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
          ..write('startDateTime: $startDateTime, ')
          ..write('endDateTime: $endDateTime, ')
          ..write('timezone: $timezone, ')
          ..write('host: $host, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('country: $country, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('lifecycleState: $lifecycleState, ')
          ..write('scoringAccess: $scoringAccess, ')
          ..write('adminLock: $adminLock, ')
          ..write('resultsHiddenThroughRound: $resultsHiddenThroughRound, ')
          ..write('resultsHiddenAt: $resultsHiddenAt, ')
          ..write('localArchive: $localArchive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LandingTablesTable extends LandingTables
    with TableInfo<$LandingTablesTable, LandingTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LandingTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _inputUnitMeta = const VerificationMeta(
    'inputUnit',
  );
  @override
  late final GeneratedColumn<String> inputUnit = GeneratedColumn<String>(
    'input_unit',
    aliasedName,
    false,
    check: () => inputUnit.isIn(landingInputUnitValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerAccountId,
    name,
    inputUnit,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'landing_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<LandingTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('input_unit')) {
      context.handle(
        _inputUnitMeta,
        inputUnit.isAcceptableOrUnknown(data['input_unit']!, _inputUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_inputUnitMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LandingTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LandingTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      inputUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_unit'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LandingTablesTable createAlias(String alias) {
    return $LandingTablesTable(attachedDatabase, alias);
  }
}

class LandingTableData extends DataClass
    implements Insertable<LandingTableData> {
  final String id;
  final String? ownerAccountId;
  final String name;
  final String inputUnit;
  final String createdAt;
  const LandingTableData({
    required this.id,
    this.ownerAccountId,
    required this.name,
    required this.inputUnit,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ownerAccountId != null) {
      map['owner_account_id'] = Variable<String>(ownerAccountId);
    }
    map['name'] = Variable<String>(name);
    map['input_unit'] = Variable<String>(inputUnit);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  LandingTablesCompanion toCompanion(bool nullToAbsent) {
    return LandingTablesCompanion(
      id: Value(id),
      ownerAccountId: ownerAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerAccountId),
      name: Value(name),
      inputUnit: Value(inputUnit),
      createdAt: Value(createdAt),
    );
  }

  factory LandingTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LandingTableData(
      id: serializer.fromJson<String>(json['id']),
      ownerAccountId: serializer.fromJson<String?>(json['ownerAccountId']),
      name: serializer.fromJson<String>(json['name']),
      inputUnit: serializer.fromJson<String>(json['inputUnit']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerAccountId': serializer.toJson<String?>(ownerAccountId),
      'name': serializer.toJson<String>(name),
      'inputUnit': serializer.toJson<String>(inputUnit),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  LandingTableData copyWith({
    String? id,
    Value<String?> ownerAccountId = const Value.absent(),
    String? name,
    String? inputUnit,
    String? createdAt,
  }) => LandingTableData(
    id: id ?? this.id,
    ownerAccountId: ownerAccountId.present
        ? ownerAccountId.value
        : this.ownerAccountId,
    name: name ?? this.name,
    inputUnit: inputUnit ?? this.inputUnit,
    createdAt: createdAt ?? this.createdAt,
  );
  LandingTableData copyWithCompanion(LandingTablesCompanion data) {
    return LandingTableData(
      id: data.id.present ? data.id.value : this.id,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      name: data.name.present ? data.name.value : this.name,
      inputUnit: data.inputUnit.present ? data.inputUnit.value : this.inputUnit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LandingTableData(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('name: $name, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ownerAccountId, name, inputUnit, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LandingTableData &&
          other.id == this.id &&
          other.ownerAccountId == this.ownerAccountId &&
          other.name == this.name &&
          other.inputUnit == this.inputUnit &&
          other.createdAt == this.createdAt);
}

class LandingTablesCompanion extends UpdateCompanion<LandingTableData> {
  final Value<String> id;
  final Value<String?> ownerAccountId;
  final Value<String> name;
  final Value<String> inputUnit;
  final Value<String> createdAt;
  final Value<int> rowid;
  const LandingTablesCompanion({
    this.id = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.name = const Value.absent(),
    this.inputUnit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LandingTablesCompanion.insert({
    required String id,
    this.ownerAccountId = const Value.absent(),
    required String name,
    required String inputUnit,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       inputUnit = Value(inputUnit),
       createdAt = Value(createdAt);
  static Insertable<LandingTableData> custom({
    Expression<String>? id,
    Expression<String>? ownerAccountId,
    Expression<String>? name,
    Expression<String>? inputUnit,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (name != null) 'name': name,
      if (inputUnit != null) 'input_unit': inputUnit,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LandingTablesCompanion copyWith({
    Value<String>? id,
    Value<String?>? ownerAccountId,
    Value<String>? name,
    Value<String>? inputUnit,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return LandingTablesCompanion(
      id: id ?? this.id,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      name: name ?? this.name,
      inputUnit: inputUnit ?? this.inputUnit,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (inputUnit.present) {
      map['input_unit'] = Variable<String>(inputUnit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LandingTablesCompanion(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('name: $name, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LandingResultsTable extends LandingResults
    with TableInfo<$LandingResultsTable, LandingResultData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LandingResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _landingTableIdMeta = const VerificationMeta(
    'landingTableId',
  );
  @override
  late final GeneratedColumn<String> landingTableId = GeneratedColumn<String>(
    'landing_table_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES landing_tables (id)',
    ),
  );
  static const VerificationMeta _entryKeyMeta = const VerificationMeta(
    'entryKey',
  );
  @override
  late final GeneratedColumn<String> entryKey = GeneratedColumn<String>(
    'entry_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayValueMeta = const VerificationMeta(
    'displayValue',
  );
  @override
  late final GeneratedColumn<String> displayValue = GeneratedColumn<String>(
    'display_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointValueMeta = const VerificationMeta(
    'pointValue',
  );
  @override
  late final GeneratedColumn<int> pointValue = GeneratedColumn<int>(
    'point_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordinalPositionMeta = const VerificationMeta(
    'ordinalPosition',
  );
  @override
  late final GeneratedColumn<int> ordinalPosition = GeneratedColumn<int>(
    'ordinal_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    landingTableId,
    entryKey,
    displayValue,
    pointValue,
    ordinalPosition,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'landing_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<LandingResultData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('landing_table_id')) {
      context.handle(
        _landingTableIdMeta,
        landingTableId.isAcceptableOrUnknown(
          data['landing_table_id']!,
          _landingTableIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_landingTableIdMeta);
    }
    if (data.containsKey('entry_key')) {
      context.handle(
        _entryKeyMeta,
        entryKey.isAcceptableOrUnknown(data['entry_key']!, _entryKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entryKeyMeta);
    }
    if (data.containsKey('display_value')) {
      context.handle(
        _displayValueMeta,
        displayValue.isAcceptableOrUnknown(
          data['display_value']!,
          _displayValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayValueMeta);
    }
    if (data.containsKey('point_value')) {
      context.handle(
        _pointValueMeta,
        pointValue.isAcceptableOrUnknown(data['point_value']!, _pointValueMeta),
      );
    } else if (isInserting) {
      context.missing(_pointValueMeta);
    }
    if (data.containsKey('ordinal_position')) {
      context.handle(
        _ordinalPositionMeta,
        ordinalPosition.isAcceptableOrUnknown(
          data['ordinal_position']!,
          _ordinalPositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ordinalPositionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {landingTableId, entryKey},
    {landingTableId, ordinalPosition},
  ];
  @override
  LandingResultData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LandingResultData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      landingTableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}landing_table_id'],
      )!,
      entryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_key'],
      )!,
      displayValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_value'],
      )!,
      pointValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point_value'],
      )!,
      ordinalPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal_position'],
      )!,
    );
  }

  @override
  $LandingResultsTable createAlias(String alias) {
    return $LandingResultsTable(attachedDatabase, alias);
  }
}

class LandingResultData extends DataClass
    implements Insertable<LandingResultData> {
  final String id;
  final String landingTableId;
  final String entryKey;
  final String displayValue;
  final int pointValue;
  final int ordinalPosition;
  const LandingResultData({
    required this.id,
    required this.landingTableId,
    required this.entryKey,
    required this.displayValue,
    required this.pointValue,
    required this.ordinalPosition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['landing_table_id'] = Variable<String>(landingTableId);
    map['entry_key'] = Variable<String>(entryKey);
    map['display_value'] = Variable<String>(displayValue);
    map['point_value'] = Variable<int>(pointValue);
    map['ordinal_position'] = Variable<int>(ordinalPosition);
    return map;
  }

  LandingResultsCompanion toCompanion(bool nullToAbsent) {
    return LandingResultsCompanion(
      id: Value(id),
      landingTableId: Value(landingTableId),
      entryKey: Value(entryKey),
      displayValue: Value(displayValue),
      pointValue: Value(pointValue),
      ordinalPosition: Value(ordinalPosition),
    );
  }

  factory LandingResultData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LandingResultData(
      id: serializer.fromJson<String>(json['id']),
      landingTableId: serializer.fromJson<String>(json['landingTableId']),
      entryKey: serializer.fromJson<String>(json['entryKey']),
      displayValue: serializer.fromJson<String>(json['displayValue']),
      pointValue: serializer.fromJson<int>(json['pointValue']),
      ordinalPosition: serializer.fromJson<int>(json['ordinalPosition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'landingTableId': serializer.toJson<String>(landingTableId),
      'entryKey': serializer.toJson<String>(entryKey),
      'displayValue': serializer.toJson<String>(displayValue),
      'pointValue': serializer.toJson<int>(pointValue),
      'ordinalPosition': serializer.toJson<int>(ordinalPosition),
    };
  }

  LandingResultData copyWith({
    String? id,
    String? landingTableId,
    String? entryKey,
    String? displayValue,
    int? pointValue,
    int? ordinalPosition,
  }) => LandingResultData(
    id: id ?? this.id,
    landingTableId: landingTableId ?? this.landingTableId,
    entryKey: entryKey ?? this.entryKey,
    displayValue: displayValue ?? this.displayValue,
    pointValue: pointValue ?? this.pointValue,
    ordinalPosition: ordinalPosition ?? this.ordinalPosition,
  );
  LandingResultData copyWithCompanion(LandingResultsCompanion data) {
    return LandingResultData(
      id: data.id.present ? data.id.value : this.id,
      landingTableId: data.landingTableId.present
          ? data.landingTableId.value
          : this.landingTableId,
      entryKey: data.entryKey.present ? data.entryKey.value : this.entryKey,
      displayValue: data.displayValue.present
          ? data.displayValue.value
          : this.displayValue,
      pointValue: data.pointValue.present
          ? data.pointValue.value
          : this.pointValue,
      ordinalPosition: data.ordinalPosition.present
          ? data.ordinalPosition.value
          : this.ordinalPosition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LandingResultData(')
          ..write('id: $id, ')
          ..write('landingTableId: $landingTableId, ')
          ..write('entryKey: $entryKey, ')
          ..write('displayValue: $displayValue, ')
          ..write('pointValue: $pointValue, ')
          ..write('ordinalPosition: $ordinalPosition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    landingTableId,
    entryKey,
    displayValue,
    pointValue,
    ordinalPosition,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LandingResultData &&
          other.id == this.id &&
          other.landingTableId == this.landingTableId &&
          other.entryKey == this.entryKey &&
          other.displayValue == this.displayValue &&
          other.pointValue == this.pointValue &&
          other.ordinalPosition == this.ordinalPosition);
}

class LandingResultsCompanion extends UpdateCompanion<LandingResultData> {
  final Value<String> id;
  final Value<String> landingTableId;
  final Value<String> entryKey;
  final Value<String> displayValue;
  final Value<int> pointValue;
  final Value<int> ordinalPosition;
  final Value<int> rowid;
  const LandingResultsCompanion({
    this.id = const Value.absent(),
    this.landingTableId = const Value.absent(),
    this.entryKey = const Value.absent(),
    this.displayValue = const Value.absent(),
    this.pointValue = const Value.absent(),
    this.ordinalPosition = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LandingResultsCompanion.insert({
    required String id,
    required String landingTableId,
    required String entryKey,
    required String displayValue,
    required int pointValue,
    required int ordinalPosition,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       landingTableId = Value(landingTableId),
       entryKey = Value(entryKey),
       displayValue = Value(displayValue),
       pointValue = Value(pointValue),
       ordinalPosition = Value(ordinalPosition);
  static Insertable<LandingResultData> custom({
    Expression<String>? id,
    Expression<String>? landingTableId,
    Expression<String>? entryKey,
    Expression<String>? displayValue,
    Expression<int>? pointValue,
    Expression<int>? ordinalPosition,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (landingTableId != null) 'landing_table_id': landingTableId,
      if (entryKey != null) 'entry_key': entryKey,
      if (displayValue != null) 'display_value': displayValue,
      if (pointValue != null) 'point_value': pointValue,
      if (ordinalPosition != null) 'ordinal_position': ordinalPosition,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LandingResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? landingTableId,
    Value<String>? entryKey,
    Value<String>? displayValue,
    Value<int>? pointValue,
    Value<int>? ordinalPosition,
    Value<int>? rowid,
  }) {
    return LandingResultsCompanion(
      id: id ?? this.id,
      landingTableId: landingTableId ?? this.landingTableId,
      entryKey: entryKey ?? this.entryKey,
      displayValue: displayValue ?? this.displayValue,
      pointValue: pointValue ?? this.pointValue,
      ordinalPosition: ordinalPosition ?? this.ordinalPosition,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (landingTableId.present) {
      map['landing_table_id'] = Variable<String>(landingTableId.value);
    }
    if (entryKey.present) {
      map['entry_key'] = Variable<String>(entryKey.value);
    }
    if (displayValue.present) {
      map['display_value'] = Variable<String>(displayValue.value);
    }
    if (pointValue.present) {
      map['point_value'] = Variable<int>(pointValue.value);
    }
    if (ordinalPosition.present) {
      map['ordinal_position'] = Variable<int>(ordinalPosition.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LandingResultsCompanion(')
          ..write('id: $id, ')
          ..write('landingTableId: $landingTableId, ')
          ..write('entryKey: $entryKey, ')
          ..write('displayValue: $displayValue, ')
          ..write('pointValue: $pointValue, ')
          ..write('ordinalPosition: $ordinalPosition, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DisciplineProfilesTable extends DisciplineProfiles
    with TableInfo<$DisciplineProfilesTable, DisciplineProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisciplineProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    check: () => type.isIn(disciplineTypeValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    check: () => category.isIn(disciplineCategoryValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultLandingTableIdMeta =
      const VerificationMeta('defaultLandingTableId');
  @override
  late final GeneratedColumn<String> defaultLandingTableId =
      GeneratedColumn<String>(
        'default_landing_table_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES landing_tables (id)',
        ),
      );
  static const VerificationMeta _defaultOptionsMeta = const VerificationMeta(
    'defaultOptions',
  );
  @override
  late final GeneratedColumn<String> defaultOptions = GeneratedColumn<String>(
    'default_options',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(profileStatusValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersededByMeta = const VerificationMeta(
    'supersededBy',
  );
  @override
  late final GeneratedColumn<String> supersededBy = GeneratedColumn<String>(
    'superseded_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES discipline_profiles (id)',
    ),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    version,
    name,
    description,
    category,
    defaultLandingTableId,
    defaultOptions,
    status,
    supersededBy,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discipline_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisciplineProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('default_landing_table_id')) {
      context.handle(
        _defaultLandingTableIdMeta,
        defaultLandingTableId.isAcceptableOrUnknown(
          data['default_landing_table_id']!,
          _defaultLandingTableIdMeta,
        ),
      );
    }
    if (data.containsKey('default_options')) {
      context.handle(
        _defaultOptionsMeta,
        defaultOptions.isAcceptableOrUnknown(
          data['default_options']!,
          _defaultOptionsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('superseded_by')) {
      context.handle(
        _supersededByMeta,
        supersededBy.isAcceptableOrUnknown(
          data['superseded_by']!,
          _supersededByMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {type, version},
  ];
  @override
  DisciplineProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisciplineProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      defaultLandingTableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_landing_table_id'],
      ),
      defaultOptions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_options'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      supersededBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}superseded_by'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $DisciplineProfilesTable createAlias(String alias) {
    return $DisciplineProfilesTable(attachedDatabase, alias);
  }
}

class DisciplineProfileData extends DataClass
    implements Insertable<DisciplineProfileData> {
  final String id;
  final String type;
  final int version;
  final String name;
  final String? description;
  final String category;
  final String? defaultLandingTableId;
  final String? defaultOptions;
  final String status;
  final String? supersededBy;
  final String createdBy;
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;
  const DisciplineProfileData({
    required this.id,
    required this.type,
    required this.version,
    required this.name,
    this.description,
    required this.category,
    this.defaultLandingTableId,
    this.defaultOptions,
    required this.status,
    this.supersededBy,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['version'] = Variable<int>(version);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || defaultLandingTableId != null) {
      map['default_landing_table_id'] = Variable<String>(defaultLandingTableId);
    }
    if (!nullToAbsent || defaultOptions != null) {
      map['default_options'] = Variable<String>(defaultOptions);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || supersededBy != null) {
      map['superseded_by'] = Variable<String>(supersededBy);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  DisciplineProfilesCompanion toCompanion(bool nullToAbsent) {
    return DisciplineProfilesCompanion(
      id: Value(id),
      type: Value(type),
      version: Value(version),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: Value(category),
      defaultLandingTableId: defaultLandingTableId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultLandingTableId),
      defaultOptions: defaultOptions == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultOptions),
      status: Value(status),
      supersededBy: supersededBy == null && nullToAbsent
          ? const Value.absent()
          : Value(supersededBy),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory DisciplineProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisciplineProfileData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      version: serializer.fromJson<int>(json['version']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      defaultLandingTableId: serializer.fromJson<String?>(
        json['defaultLandingTableId'],
      ),
      defaultOptions: serializer.fromJson<String?>(json['defaultOptions']),
      status: serializer.fromJson<String>(json['status']),
      supersededBy: serializer.fromJson<String?>(json['supersededBy']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'version': serializer.toJson<int>(version),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String>(category),
      'defaultLandingTableId': serializer.toJson<String?>(
        defaultLandingTableId,
      ),
      'defaultOptions': serializer.toJson<String?>(defaultOptions),
      'status': serializer.toJson<String>(status),
      'supersededBy': serializer.toJson<String?>(supersededBy),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  DisciplineProfileData copyWith({
    String? id,
    String? type,
    int? version,
    String? name,
    Value<String?> description = const Value.absent(),
    String? category,
    Value<String?> defaultLandingTableId = const Value.absent(),
    Value<String?> defaultOptions = const Value.absent(),
    String? status,
    Value<String?> supersededBy = const Value.absent(),
    String? createdBy,
    String? createdAt,
    Value<String?> updatedBy = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => DisciplineProfileData(
    id: id ?? this.id,
    type: type ?? this.type,
    version: version ?? this.version,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    category: category ?? this.category,
    defaultLandingTableId: defaultLandingTableId.present
        ? defaultLandingTableId.value
        : this.defaultLandingTableId,
    defaultOptions: defaultOptions.present
        ? defaultOptions.value
        : this.defaultOptions,
    status: status ?? this.status,
    supersededBy: supersededBy.present ? supersededBy.value : this.supersededBy,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  DisciplineProfileData copyWithCompanion(DisciplineProfilesCompanion data) {
    return DisciplineProfileData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      version: data.version.present ? data.version.value : this.version,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      defaultLandingTableId: data.defaultLandingTableId.present
          ? data.defaultLandingTableId.value
          : this.defaultLandingTableId,
      defaultOptions: data.defaultOptions.present
          ? data.defaultOptions.value
          : this.defaultOptions,
      status: data.status.present ? data.status.value : this.status,
      supersededBy: data.supersededBy.present
          ? data.supersededBy.value
          : this.supersededBy,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineProfileData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('defaultLandingTableId: $defaultLandingTableId, ')
          ..write('defaultOptions: $defaultOptions, ')
          ..write('status: $status, ')
          ..write('supersededBy: $supersededBy, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    version,
    name,
    description,
    category,
    defaultLandingTableId,
    defaultOptions,
    status,
    supersededBy,
    createdBy,
    createdAt,
    updatedBy,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisciplineProfileData &&
          other.id == this.id &&
          other.type == this.type &&
          other.version == this.version &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.defaultLandingTableId == this.defaultLandingTableId &&
          other.defaultOptions == this.defaultOptions &&
          other.status == this.status &&
          other.supersededBy == this.supersededBy &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedBy == this.updatedBy &&
          other.updatedAt == this.updatedAt);
}

class DisciplineProfilesCompanion
    extends UpdateCompanion<DisciplineProfileData> {
  final Value<String> id;
  final Value<String> type;
  final Value<int> version;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> category;
  final Value<String?> defaultLandingTableId;
  final Value<String?> defaultOptions;
  final Value<String> status;
  final Value<String?> supersededBy;
  final Value<String> createdBy;
  final Value<String> createdAt;
  final Value<String?> updatedBy;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const DisciplineProfilesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.version = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.defaultLandingTableId = const Value.absent(),
    this.defaultOptions = const Value.absent(),
    this.status = const Value.absent(),
    this.supersededBy = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DisciplineProfilesCompanion.insert({
    required String id,
    required String type,
    required int version,
    required String name,
    this.description = const Value.absent(),
    required String category,
    this.defaultLandingTableId = const Value.absent(),
    this.defaultOptions = const Value.absent(),
    required String status,
    this.supersededBy = const Value.absent(),
    required String createdBy,
    required String createdAt,
    this.updatedBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       version = Value(version),
       name = Value(name),
       category = Value(category),
       status = Value(status),
       createdBy = Value(createdBy),
       createdAt = Value(createdAt);
  static Insertable<DisciplineProfileData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? version,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? defaultLandingTableId,
    Expression<String>? defaultOptions,
    Expression<String>? status,
    Expression<String>? supersededBy,
    Expression<String>? createdBy,
    Expression<String>? createdAt,
    Expression<String>? updatedBy,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (version != null) 'version': version,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (defaultLandingTableId != null)
        'default_landing_table_id': defaultLandingTableId,
      if (defaultOptions != null) 'default_options': defaultOptions,
      if (status != null) 'status': status,
      if (supersededBy != null) 'superseded_by': supersededBy,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DisciplineProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<int>? version,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? category,
    Value<String?>? defaultLandingTableId,
    Value<String?>? defaultOptions,
    Value<String>? status,
    Value<String?>? supersededBy,
    Value<String>? createdBy,
    Value<String>? createdAt,
    Value<String?>? updatedBy,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return DisciplineProfilesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      version: version ?? this.version,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      defaultLandingTableId:
          defaultLandingTableId ?? this.defaultLandingTableId,
      defaultOptions: defaultOptions ?? this.defaultOptions,
      status: status ?? this.status,
      supersededBy: supersededBy ?? this.supersededBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (defaultLandingTableId.present) {
      map['default_landing_table_id'] = Variable<String>(
        defaultLandingTableId.value,
      );
    }
    if (defaultOptions.present) {
      map['default_options'] = Variable<String>(defaultOptions.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (supersededBy.present) {
      map['superseded_by'] = Variable<String>(supersededBy.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineProfilesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('version: $version, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('defaultLandingTableId: $defaultLandingTableId, ')
          ..write('defaultOptions: $defaultOptions, ')
          ..write('status: $status, ')
          ..write('supersededBy: $supersededBy, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DisciplineConfigFieldsTable extends DisciplineConfigFields
    with TableInfo<$DisciplineConfigFieldsTable, DisciplineConfigFieldData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisciplineConfigFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disciplineProfileIdMeta =
      const VerificationMeta('disciplineProfileId');
  @override
  late final GeneratedColumn<String> disciplineProfileId =
      GeneratedColumn<String>(
        'discipline_profile_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discipline_profiles (id)',
        ),
      );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldTypeMeta = const VerificationMeta(
    'fieldType',
  );
  @override
  late final GeneratedColumn<String> fieldType = GeneratedColumn<String>(
    'field_type',
    aliasedName,
    false,
    check: () => fieldType.isIn(configFieldTypeValues),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiredMeta = const VerificationMeta(
    'required',
  );
  @override
  late final GeneratedColumn<bool> required = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
      SqlDialect.sqlite: 'CHECK ("required" IN (0, 1))',
      SqlDialect.postgres: '',
    }),
  );
  static const VerificationMeta _defaultValueMeta = const VerificationMeta(
    'defaultValue',
  );
  @override
  late final GeneratedColumn<String> defaultValue = GeneratedColumn<String>(
    'default_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validationMeta = const VerificationMeta(
    'validation',
  );
  @override
  late final GeneratedColumn<String> validation = GeneratedColumn<String>(
    'validation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    disciplineProfileId,
    fieldKey,
    fieldType,
    name,
    description,
    unit,
    required,
    defaultValue,
    options,
    validation,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discipline_config_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisciplineConfigFieldData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('discipline_profile_id')) {
      context.handle(
        _disciplineProfileIdMeta,
        disciplineProfileId.isAcceptableOrUnknown(
          data['discipline_profile_id']!,
          _disciplineProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disciplineProfileIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('field_type')) {
      context.handle(
        _fieldTypeMeta,
        fieldType.isAcceptableOrUnknown(data['field_type']!, _fieldTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('required')) {
      context.handle(
        _requiredMeta,
        required.isAcceptableOrUnknown(data['required']!, _requiredMeta),
      );
    } else if (isInserting) {
      context.missing(_requiredMeta);
    }
    if (data.containsKey('default_value')) {
      context.handle(
        _defaultValueMeta,
        defaultValue.isAcceptableOrUnknown(
          data['default_value']!,
          _defaultValueMeta,
        ),
      );
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    }
    if (data.containsKey('validation')) {
      context.handle(
        _validationMeta,
        validation.isAcceptableOrUnknown(data['validation']!, _validationMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {disciplineProfileId, fieldKey},
  ];
  @override
  DisciplineConfigFieldData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisciplineConfigFieldData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      disciplineProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discipline_profile_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      fieldType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      required: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      defaultValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_value'],
      ),
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      ),
      validation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validation'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DisciplineConfigFieldsTable createAlias(String alias) {
    return $DisciplineConfigFieldsTable(attachedDatabase, alias);
  }
}

class DisciplineConfigFieldData extends DataClass
    implements Insertable<DisciplineConfigFieldData> {
  final String id;
  final String disciplineProfileId;
  final String fieldKey;
  final String fieldType;
  final String name;
  final String? description;
  final String? unit;
  final bool required;
  final String? defaultValue;
  final String? options;
  final String? validation;
  final int displayOrder;
  final String createdAt;
  const DisciplineConfigFieldData({
    required this.id,
    required this.disciplineProfileId,
    required this.fieldKey,
    required this.fieldType,
    required this.name,
    this.description,
    this.unit,
    required this.required,
    this.defaultValue,
    this.options,
    this.validation,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['discipline_profile_id'] = Variable<String>(disciplineProfileId);
    map['field_key'] = Variable<String>(fieldKey);
    map['field_type'] = Variable<String>(fieldType);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['required'] = Variable<bool>(required);
    if (!nullToAbsent || defaultValue != null) {
      map['default_value'] = Variable<String>(defaultValue);
    }
    if (!nullToAbsent || options != null) {
      map['options'] = Variable<String>(options);
    }
    if (!nullToAbsent || validation != null) {
      map['validation'] = Variable<String>(validation);
    }
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DisciplineConfigFieldsCompanion toCompanion(bool nullToAbsent) {
    return DisciplineConfigFieldsCompanion(
      id: Value(id),
      disciplineProfileId: Value(disciplineProfileId),
      fieldKey: Value(fieldKey),
      fieldType: Value(fieldType),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      required: Value(required),
      defaultValue: defaultValue == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultValue),
      options: options == null && nullToAbsent
          ? const Value.absent()
          : Value(options),
      validation: validation == null && nullToAbsent
          ? const Value.absent()
          : Value(validation),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory DisciplineConfigFieldData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisciplineConfigFieldData(
      id: serializer.fromJson<String>(json['id']),
      disciplineProfileId: serializer.fromJson<String>(
        json['disciplineProfileId'],
      ),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      fieldType: serializer.fromJson<String>(json['fieldType']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      unit: serializer.fromJson<String?>(json['unit']),
      required: serializer.fromJson<bool>(json['required']),
      defaultValue: serializer.fromJson<String?>(json['defaultValue']),
      options: serializer.fromJson<String?>(json['options']),
      validation: serializer.fromJson<String?>(json['validation']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'disciplineProfileId': serializer.toJson<String>(disciplineProfileId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'fieldType': serializer.toJson<String>(fieldType),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'unit': serializer.toJson<String?>(unit),
      'required': serializer.toJson<bool>(required),
      'defaultValue': serializer.toJson<String?>(defaultValue),
      'options': serializer.toJson<String?>(options),
      'validation': serializer.toJson<String?>(validation),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DisciplineConfigFieldData copyWith({
    String? id,
    String? disciplineProfileId,
    String? fieldKey,
    String? fieldType,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    bool? required,
    Value<String?> defaultValue = const Value.absent(),
    Value<String?> options = const Value.absent(),
    Value<String?> validation = const Value.absent(),
    int? displayOrder,
    String? createdAt,
  }) => DisciplineConfigFieldData(
    id: id ?? this.id,
    disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
    fieldKey: fieldKey ?? this.fieldKey,
    fieldType: fieldType ?? this.fieldType,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    unit: unit.present ? unit.value : this.unit,
    required: required ?? this.required,
    defaultValue: defaultValue.present ? defaultValue.value : this.defaultValue,
    options: options.present ? options.value : this.options,
    validation: validation.present ? validation.value : this.validation,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  DisciplineConfigFieldData copyWithCompanion(
    DisciplineConfigFieldsCompanion data,
  ) {
    return DisciplineConfigFieldData(
      id: data.id.present ? data.id.value : this.id,
      disciplineProfileId: data.disciplineProfileId.present
          ? data.disciplineProfileId.value
          : this.disciplineProfileId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      unit: data.unit.present ? data.unit.value : this.unit,
      required: data.required.present ? data.required.value : this.required,
      defaultValue: data.defaultValue.present
          ? data.defaultValue.value
          : this.defaultValue,
      options: data.options.present ? data.options.value : this.options,
      validation: data.validation.present
          ? data.validation.value
          : this.validation,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineConfigFieldData(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('fieldType: $fieldType, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('unit: $unit, ')
          ..write('required: $required, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('options: $options, ')
          ..write('validation: $validation, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    disciplineProfileId,
    fieldKey,
    fieldType,
    name,
    description,
    unit,
    required,
    defaultValue,
    options,
    validation,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisciplineConfigFieldData &&
          other.id == this.id &&
          other.disciplineProfileId == this.disciplineProfileId &&
          other.fieldKey == this.fieldKey &&
          other.fieldType == this.fieldType &&
          other.name == this.name &&
          other.description == this.description &&
          other.unit == this.unit &&
          other.required == this.required &&
          other.defaultValue == this.defaultValue &&
          other.options == this.options &&
          other.validation == this.validation &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class DisciplineConfigFieldsCompanion
    extends UpdateCompanion<DisciplineConfigFieldData> {
  final Value<String> id;
  final Value<String> disciplineProfileId;
  final Value<String> fieldKey;
  final Value<String> fieldType;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> unit;
  final Value<bool> required;
  final Value<String?> defaultValue;
  final Value<String?> options;
  final Value<String?> validation;
  final Value<int> displayOrder;
  final Value<String> createdAt;
  final Value<int> rowid;
  const DisciplineConfigFieldsCompanion({
    this.id = const Value.absent(),
    this.disciplineProfileId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.unit = const Value.absent(),
    this.required = const Value.absent(),
    this.defaultValue = const Value.absent(),
    this.options = const Value.absent(),
    this.validation = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DisciplineConfigFieldsCompanion.insert({
    required String id,
    required String disciplineProfileId,
    required String fieldKey,
    required String fieldType,
    required String name,
    this.description = const Value.absent(),
    this.unit = const Value.absent(),
    required bool required,
    this.defaultValue = const Value.absent(),
    this.options = const Value.absent(),
    this.validation = const Value.absent(),
    required int displayOrder,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       disciplineProfileId = Value(disciplineProfileId),
       fieldKey = Value(fieldKey),
       fieldType = Value(fieldType),
       name = Value(name),
       required = Value(required),
       displayOrder = Value(displayOrder),
       createdAt = Value(createdAt);
  static Insertable<DisciplineConfigFieldData> custom({
    Expression<String>? id,
    Expression<String>? disciplineProfileId,
    Expression<String>? fieldKey,
    Expression<String>? fieldType,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? unit,
    Expression<bool>? required,
    Expression<String>? defaultValue,
    Expression<String>? options,
    Expression<String>? validation,
    Expression<int>? displayOrder,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (disciplineProfileId != null)
        'discipline_profile_id': disciplineProfileId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (fieldType != null) 'field_type': fieldType,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (unit != null) 'unit': unit,
      if (required != null) 'required': required,
      if (defaultValue != null) 'default_value': defaultValue,
      if (options != null) 'options': options,
      if (validation != null) 'validation': validation,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DisciplineConfigFieldsCompanion copyWith({
    Value<String>? id,
    Value<String>? disciplineProfileId,
    Value<String>? fieldKey,
    Value<String>? fieldType,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? unit,
    Value<bool>? required,
    Value<String?>? defaultValue,
    Value<String?>? options,
    Value<String?>? validation,
    Value<int>? displayOrder,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return DisciplineConfigFieldsCompanion(
      id: id ?? this.id,
      disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
      fieldKey: fieldKey ?? this.fieldKey,
      fieldType: fieldType ?? this.fieldType,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      validation: validation ?? this.validation,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (disciplineProfileId.present) {
      map['discipline_profile_id'] = Variable<String>(
        disciplineProfileId.value,
      );
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<String>(fieldType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (required.present) {
      map['required'] = Variable<bool>(required.value);
    }
    if (defaultValue.present) {
      map['default_value'] = Variable<String>(defaultValue.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (validation.present) {
      map['validation'] = Variable<String>(validation.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineConfigFieldsCompanion(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('fieldType: $fieldType, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('unit: $unit, ')
          ..write('required: $required, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('options: $options, ')
          ..write('validation: $validation, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DisciplineScoreFieldsTable extends DisciplineScoreFields
    with TableInfo<$DisciplineScoreFieldsTable, DisciplineScoreFieldData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisciplineScoreFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disciplineProfileIdMeta =
      const VerificationMeta('disciplineProfileId');
  @override
  late final GeneratedColumn<String> disciplineProfileId =
      GeneratedColumn<String>(
        'discipline_profile_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discipline_profiles (id)',
        ),
      );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldTypeMeta = const VerificationMeta(
    'fieldType',
  );
  @override
  late final GeneratedColumn<String> fieldType = GeneratedColumn<String>(
    'field_type',
    aliasedName,
    false,
    check: () => fieldType.isIn(scoreFieldTypeValues),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldKindMeta = const VerificationMeta(
    'fieldKind',
  );
  @override
  late final GeneratedColumn<String> fieldKind = GeneratedColumn<String>(
    'field_kind',
    aliasedName,
    false,
    check: () => fieldKind.isIn(scoreFieldKindValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precisionMeta = const VerificationMeta(
    'precision',
  );
  @override
  late final GeneratedColumn<int> precision = GeneratedColumn<int>(
    'precision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiredMeta = const VerificationMeta(
    'required',
  );
  @override
  late final GeneratedColumn<bool> required = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
      SqlDialect.sqlite: 'CHECK ("required" IN (0, 1))',
      SqlDialect.postgres: '',
    }),
  );
  static const VerificationMeta _defaultValueMeta = const VerificationMeta(
    'defaultValue',
  );
  @override
  late final GeneratedColumn<String> defaultValue = GeneratedColumn<String>(
    'default_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validationMeta = const VerificationMeta(
    'validation',
  );
  @override
  late final GeneratedColumn<String> validation = GeneratedColumn<String>(
    'validation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isZeroReasonMeta = const VerificationMeta(
    'isZeroReason',
  );
  @override
  late final GeneratedColumn<bool> isZeroReason = GeneratedColumn<bool>(
    'is_zero_reason',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
      SqlDialect.sqlite: 'CHECK ("is_zero_reason" IN (0, 1))',
      SqlDialect.postgres: '',
    }),
  );
  static const VerificationMeta _zeroReasonCodeMeta = const VerificationMeta(
    'zeroReasonCode',
  );
  @override
  late final GeneratedColumn<String> zeroReasonCode = GeneratedColumn<String>(
    'zero_reason_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    disciplineProfileId,
    fieldKey,
    fieldType,
    name,
    description,
    fieldKind,
    unit,
    precision,
    required,
    defaultValue,
    options,
    validation,
    displayOrder,
    isZeroReason,
    zeroReasonCode,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discipline_score_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisciplineScoreFieldData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('discipline_profile_id')) {
      context.handle(
        _disciplineProfileIdMeta,
        disciplineProfileId.isAcceptableOrUnknown(
          data['discipline_profile_id']!,
          _disciplineProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disciplineProfileIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('field_type')) {
      context.handle(
        _fieldTypeMeta,
        fieldType.isAcceptableOrUnknown(data['field_type']!, _fieldTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('field_kind')) {
      context.handle(
        _fieldKindMeta,
        fieldKind.isAcceptableOrUnknown(data['field_kind']!, _fieldKindMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKindMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('precision')) {
      context.handle(
        _precisionMeta,
        precision.isAcceptableOrUnknown(data['precision']!, _precisionMeta),
      );
    }
    if (data.containsKey('required')) {
      context.handle(
        _requiredMeta,
        required.isAcceptableOrUnknown(data['required']!, _requiredMeta),
      );
    } else if (isInserting) {
      context.missing(_requiredMeta);
    }
    if (data.containsKey('default_value')) {
      context.handle(
        _defaultValueMeta,
        defaultValue.isAcceptableOrUnknown(
          data['default_value']!,
          _defaultValueMeta,
        ),
      );
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    }
    if (data.containsKey('validation')) {
      context.handle(
        _validationMeta,
        validation.isAcceptableOrUnknown(data['validation']!, _validationMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('is_zero_reason')) {
      context.handle(
        _isZeroReasonMeta,
        isZeroReason.isAcceptableOrUnknown(
          data['is_zero_reason']!,
          _isZeroReasonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isZeroReasonMeta);
    }
    if (data.containsKey('zero_reason_code')) {
      context.handle(
        _zeroReasonCodeMeta,
        zeroReasonCode.isAcceptableOrUnknown(
          data['zero_reason_code']!,
          _zeroReasonCodeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {disciplineProfileId, fieldKey},
  ];
  @override
  DisciplineScoreFieldData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisciplineScoreFieldData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      disciplineProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discipline_profile_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      fieldType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      fieldKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_kind'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      precision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precision'],
      ),
      required: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      defaultValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_value'],
      ),
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      ),
      validation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validation'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      isZeroReason: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_zero_reason'],
      )!,
      zeroReasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zero_reason_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DisciplineScoreFieldsTable createAlias(String alias) {
    return $DisciplineScoreFieldsTable(attachedDatabase, alias);
  }
}

class DisciplineScoreFieldData extends DataClass
    implements Insertable<DisciplineScoreFieldData> {
  final String id;
  final String disciplineProfileId;
  final String fieldKey;
  final String fieldType;
  final String name;
  final String? description;
  final String fieldKind;
  final String? unit;
  final int? precision;
  final bool required;
  final String? defaultValue;
  final String? options;
  final String? validation;
  final int displayOrder;
  final bool isZeroReason;
  final String? zeroReasonCode;
  final String createdAt;
  const DisciplineScoreFieldData({
    required this.id,
    required this.disciplineProfileId,
    required this.fieldKey,
    required this.fieldType,
    required this.name,
    this.description,
    required this.fieldKind,
    this.unit,
    this.precision,
    required this.required,
    this.defaultValue,
    this.options,
    this.validation,
    required this.displayOrder,
    required this.isZeroReason,
    this.zeroReasonCode,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['discipline_profile_id'] = Variable<String>(disciplineProfileId);
    map['field_key'] = Variable<String>(fieldKey);
    map['field_type'] = Variable<String>(fieldType);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['field_kind'] = Variable<String>(fieldKind);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || precision != null) {
      map['precision'] = Variable<int>(precision);
    }
    map['required'] = Variable<bool>(required);
    if (!nullToAbsent || defaultValue != null) {
      map['default_value'] = Variable<String>(defaultValue);
    }
    if (!nullToAbsent || options != null) {
      map['options'] = Variable<String>(options);
    }
    if (!nullToAbsent || validation != null) {
      map['validation'] = Variable<String>(validation);
    }
    map['display_order'] = Variable<int>(displayOrder);
    map['is_zero_reason'] = Variable<bool>(isZeroReason);
    if (!nullToAbsent || zeroReasonCode != null) {
      map['zero_reason_code'] = Variable<String>(zeroReasonCode);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DisciplineScoreFieldsCompanion toCompanion(bool nullToAbsent) {
    return DisciplineScoreFieldsCompanion(
      id: Value(id),
      disciplineProfileId: Value(disciplineProfileId),
      fieldKey: Value(fieldKey),
      fieldType: Value(fieldType),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      fieldKind: Value(fieldKind),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      precision: precision == null && nullToAbsent
          ? const Value.absent()
          : Value(precision),
      required: Value(required),
      defaultValue: defaultValue == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultValue),
      options: options == null && nullToAbsent
          ? const Value.absent()
          : Value(options),
      validation: validation == null && nullToAbsent
          ? const Value.absent()
          : Value(validation),
      displayOrder: Value(displayOrder),
      isZeroReason: Value(isZeroReason),
      zeroReasonCode: zeroReasonCode == null && nullToAbsent
          ? const Value.absent()
          : Value(zeroReasonCode),
      createdAt: Value(createdAt),
    );
  }

  factory DisciplineScoreFieldData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisciplineScoreFieldData(
      id: serializer.fromJson<String>(json['id']),
      disciplineProfileId: serializer.fromJson<String>(
        json['disciplineProfileId'],
      ),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      fieldType: serializer.fromJson<String>(json['fieldType']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      fieldKind: serializer.fromJson<String>(json['fieldKind']),
      unit: serializer.fromJson<String?>(json['unit']),
      precision: serializer.fromJson<int?>(json['precision']),
      required: serializer.fromJson<bool>(json['required']),
      defaultValue: serializer.fromJson<String?>(json['defaultValue']),
      options: serializer.fromJson<String?>(json['options']),
      validation: serializer.fromJson<String?>(json['validation']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      isZeroReason: serializer.fromJson<bool>(json['isZeroReason']),
      zeroReasonCode: serializer.fromJson<String?>(json['zeroReasonCode']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'disciplineProfileId': serializer.toJson<String>(disciplineProfileId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'fieldType': serializer.toJson<String>(fieldType),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'fieldKind': serializer.toJson<String>(fieldKind),
      'unit': serializer.toJson<String?>(unit),
      'precision': serializer.toJson<int?>(precision),
      'required': serializer.toJson<bool>(required),
      'defaultValue': serializer.toJson<String?>(defaultValue),
      'options': serializer.toJson<String?>(options),
      'validation': serializer.toJson<String?>(validation),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'isZeroReason': serializer.toJson<bool>(isZeroReason),
      'zeroReasonCode': serializer.toJson<String?>(zeroReasonCode),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DisciplineScoreFieldData copyWith({
    String? id,
    String? disciplineProfileId,
    String? fieldKey,
    String? fieldType,
    String? name,
    Value<String?> description = const Value.absent(),
    String? fieldKind,
    Value<String?> unit = const Value.absent(),
    Value<int?> precision = const Value.absent(),
    bool? required,
    Value<String?> defaultValue = const Value.absent(),
    Value<String?> options = const Value.absent(),
    Value<String?> validation = const Value.absent(),
    int? displayOrder,
    bool? isZeroReason,
    Value<String?> zeroReasonCode = const Value.absent(),
    String? createdAt,
  }) => DisciplineScoreFieldData(
    id: id ?? this.id,
    disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
    fieldKey: fieldKey ?? this.fieldKey,
    fieldType: fieldType ?? this.fieldType,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    fieldKind: fieldKind ?? this.fieldKind,
    unit: unit.present ? unit.value : this.unit,
    precision: precision.present ? precision.value : this.precision,
    required: required ?? this.required,
    defaultValue: defaultValue.present ? defaultValue.value : this.defaultValue,
    options: options.present ? options.value : this.options,
    validation: validation.present ? validation.value : this.validation,
    displayOrder: displayOrder ?? this.displayOrder,
    isZeroReason: isZeroReason ?? this.isZeroReason,
    zeroReasonCode: zeroReasonCode.present
        ? zeroReasonCode.value
        : this.zeroReasonCode,
    createdAt: createdAt ?? this.createdAt,
  );
  DisciplineScoreFieldData copyWithCompanion(
    DisciplineScoreFieldsCompanion data,
  ) {
    return DisciplineScoreFieldData(
      id: data.id.present ? data.id.value : this.id,
      disciplineProfileId: data.disciplineProfileId.present
          ? data.disciplineProfileId.value
          : this.disciplineProfileId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      fieldKind: data.fieldKind.present ? data.fieldKind.value : this.fieldKind,
      unit: data.unit.present ? data.unit.value : this.unit,
      precision: data.precision.present ? data.precision.value : this.precision,
      required: data.required.present ? data.required.value : this.required,
      defaultValue: data.defaultValue.present
          ? data.defaultValue.value
          : this.defaultValue,
      options: data.options.present ? data.options.value : this.options,
      validation: data.validation.present
          ? data.validation.value
          : this.validation,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      isZeroReason: data.isZeroReason.present
          ? data.isZeroReason.value
          : this.isZeroReason,
      zeroReasonCode: data.zeroReasonCode.present
          ? data.zeroReasonCode.value
          : this.zeroReasonCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineScoreFieldData(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('fieldType: $fieldType, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('fieldKind: $fieldKind, ')
          ..write('unit: $unit, ')
          ..write('precision: $precision, ')
          ..write('required: $required, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('options: $options, ')
          ..write('validation: $validation, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('isZeroReason: $isZeroReason, ')
          ..write('zeroReasonCode: $zeroReasonCode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    disciplineProfileId,
    fieldKey,
    fieldType,
    name,
    description,
    fieldKind,
    unit,
    precision,
    required,
    defaultValue,
    options,
    validation,
    displayOrder,
    isZeroReason,
    zeroReasonCode,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisciplineScoreFieldData &&
          other.id == this.id &&
          other.disciplineProfileId == this.disciplineProfileId &&
          other.fieldKey == this.fieldKey &&
          other.fieldType == this.fieldType &&
          other.name == this.name &&
          other.description == this.description &&
          other.fieldKind == this.fieldKind &&
          other.unit == this.unit &&
          other.precision == this.precision &&
          other.required == this.required &&
          other.defaultValue == this.defaultValue &&
          other.options == this.options &&
          other.validation == this.validation &&
          other.displayOrder == this.displayOrder &&
          other.isZeroReason == this.isZeroReason &&
          other.zeroReasonCode == this.zeroReasonCode &&
          other.createdAt == this.createdAt);
}

class DisciplineScoreFieldsCompanion
    extends UpdateCompanion<DisciplineScoreFieldData> {
  final Value<String> id;
  final Value<String> disciplineProfileId;
  final Value<String> fieldKey;
  final Value<String> fieldType;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> fieldKind;
  final Value<String?> unit;
  final Value<int?> precision;
  final Value<bool> required;
  final Value<String?> defaultValue;
  final Value<String?> options;
  final Value<String?> validation;
  final Value<int> displayOrder;
  final Value<bool> isZeroReason;
  final Value<String?> zeroReasonCode;
  final Value<String> createdAt;
  final Value<int> rowid;
  const DisciplineScoreFieldsCompanion({
    this.id = const Value.absent(),
    this.disciplineProfileId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.fieldKind = const Value.absent(),
    this.unit = const Value.absent(),
    this.precision = const Value.absent(),
    this.required = const Value.absent(),
    this.defaultValue = const Value.absent(),
    this.options = const Value.absent(),
    this.validation = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.isZeroReason = const Value.absent(),
    this.zeroReasonCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DisciplineScoreFieldsCompanion.insert({
    required String id,
    required String disciplineProfileId,
    required String fieldKey,
    required String fieldType,
    required String name,
    this.description = const Value.absent(),
    required String fieldKind,
    this.unit = const Value.absent(),
    this.precision = const Value.absent(),
    required bool required,
    this.defaultValue = const Value.absent(),
    this.options = const Value.absent(),
    this.validation = const Value.absent(),
    required int displayOrder,
    required bool isZeroReason,
    this.zeroReasonCode = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       disciplineProfileId = Value(disciplineProfileId),
       fieldKey = Value(fieldKey),
       fieldType = Value(fieldType),
       name = Value(name),
       fieldKind = Value(fieldKind),
       required = Value(required),
       displayOrder = Value(displayOrder),
       isZeroReason = Value(isZeroReason),
       createdAt = Value(createdAt);
  static Insertable<DisciplineScoreFieldData> custom({
    Expression<String>? id,
    Expression<String>? disciplineProfileId,
    Expression<String>? fieldKey,
    Expression<String>? fieldType,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? fieldKind,
    Expression<String>? unit,
    Expression<int>? precision,
    Expression<bool>? required,
    Expression<String>? defaultValue,
    Expression<String>? options,
    Expression<String>? validation,
    Expression<int>? displayOrder,
    Expression<bool>? isZeroReason,
    Expression<String>? zeroReasonCode,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (disciplineProfileId != null)
        'discipline_profile_id': disciplineProfileId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (fieldType != null) 'field_type': fieldType,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (fieldKind != null) 'field_kind': fieldKind,
      if (unit != null) 'unit': unit,
      if (precision != null) 'precision': precision,
      if (required != null) 'required': required,
      if (defaultValue != null) 'default_value': defaultValue,
      if (options != null) 'options': options,
      if (validation != null) 'validation': validation,
      if (displayOrder != null) 'display_order': displayOrder,
      if (isZeroReason != null) 'is_zero_reason': isZeroReason,
      if (zeroReasonCode != null) 'zero_reason_code': zeroReasonCode,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DisciplineScoreFieldsCompanion copyWith({
    Value<String>? id,
    Value<String>? disciplineProfileId,
    Value<String>? fieldKey,
    Value<String>? fieldType,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? fieldKind,
    Value<String?>? unit,
    Value<int?>? precision,
    Value<bool>? required,
    Value<String?>? defaultValue,
    Value<String?>? options,
    Value<String?>? validation,
    Value<int>? displayOrder,
    Value<bool>? isZeroReason,
    Value<String?>? zeroReasonCode,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return DisciplineScoreFieldsCompanion(
      id: id ?? this.id,
      disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
      fieldKey: fieldKey ?? this.fieldKey,
      fieldType: fieldType ?? this.fieldType,
      name: name ?? this.name,
      description: description ?? this.description,
      fieldKind: fieldKind ?? this.fieldKind,
      unit: unit ?? this.unit,
      precision: precision ?? this.precision,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      validation: validation ?? this.validation,
      displayOrder: displayOrder ?? this.displayOrder,
      isZeroReason: isZeroReason ?? this.isZeroReason,
      zeroReasonCode: zeroReasonCode ?? this.zeroReasonCode,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (disciplineProfileId.present) {
      map['discipline_profile_id'] = Variable<String>(
        disciplineProfileId.value,
      );
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<String>(fieldType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (fieldKind.present) {
      map['field_kind'] = Variable<String>(fieldKind.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (precision.present) {
      map['precision'] = Variable<int>(precision.value);
    }
    if (required.present) {
      map['required'] = Variable<bool>(required.value);
    }
    if (defaultValue.present) {
      map['default_value'] = Variable<String>(defaultValue.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (validation.present) {
      map['validation'] = Variable<String>(validation.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (isZeroReason.present) {
      map['is_zero_reason'] = Variable<bool>(isZeroReason.value);
    }
    if (zeroReasonCode.present) {
      map['zero_reason_code'] = Variable<String>(zeroReasonCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineScoreFieldsCompanion(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('fieldType: $fieldType, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('fieldKind: $fieldKind, ')
          ..write('unit: $unit, ')
          ..write('precision: $precision, ')
          ..write('required: $required, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('options: $options, ')
          ..write('validation: $validation, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('isZeroReason: $isZeroReason, ')
          ..write('zeroReasonCode: $zeroReasonCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DisciplineValidationsTable extends DisciplineValidations
    with TableInfo<$DisciplineValidationsTable, DisciplineValidationData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisciplineValidationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disciplineProfileIdMeta =
      const VerificationMeta('disciplineProfileId');
  @override
  late final GeneratedColumn<String> disciplineProfileId =
      GeneratedColumn<String>(
        'discipline_profile_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discipline_profiles (id)',
        ),
      );
  static const VerificationMeta _fieldKeysMeta = const VerificationMeta(
    'fieldKeys',
  );
  @override
  late final GeneratedColumn<String> fieldKeys = GeneratedColumn<String>(
    'field_keys',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _constraintTypeMeta = const VerificationMeta(
    'constraintType',
  );
  @override
  late final GeneratedColumn<String> constraintType = GeneratedColumn<String>(
    'constraint_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appliesToMeta = const VerificationMeta(
    'appliesTo',
  );
  @override
  late final GeneratedColumn<String> appliesTo = GeneratedColumn<String>(
    'applies_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    disciplineProfileId,
    fieldKeys,
    constraintType,
    description,
    appliesTo,
    message,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discipline_validations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisciplineValidationData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('discipline_profile_id')) {
      context.handle(
        _disciplineProfileIdMeta,
        disciplineProfileId.isAcceptableOrUnknown(
          data['discipline_profile_id']!,
          _disciplineProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disciplineProfileIdMeta);
    }
    if (data.containsKey('field_keys')) {
      context.handle(
        _fieldKeysMeta,
        fieldKeys.isAcceptableOrUnknown(data['field_keys']!, _fieldKeysMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeysMeta);
    }
    if (data.containsKey('constraint_type')) {
      context.handle(
        _constraintTypeMeta,
        constraintType.isAcceptableOrUnknown(
          data['constraint_type']!,
          _constraintTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_constraintTypeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('applies_to')) {
      context.handle(
        _appliesToMeta,
        appliesTo.isAcceptableOrUnknown(data['applies_to']!, _appliesToMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {disciplineProfileId, fieldKeys, constraintType},
  ];
  @override
  DisciplineValidationData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisciplineValidationData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      disciplineProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discipline_profile_id'],
      )!,
      fieldKeys: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_keys'],
      )!,
      constraintType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}constraint_type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      appliesTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}applies_to'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DisciplineValidationsTable createAlias(String alias) {
    return $DisciplineValidationsTable(attachedDatabase, alias);
  }
}

class DisciplineValidationData extends DataClass
    implements Insertable<DisciplineValidationData> {
  final String id;
  final String disciplineProfileId;
  final String fieldKeys;
  final String constraintType;
  final String? description;
  final String? appliesTo;
  final String? message;
  final int displayOrder;
  final String createdAt;
  const DisciplineValidationData({
    required this.id,
    required this.disciplineProfileId,
    required this.fieldKeys,
    required this.constraintType,
    this.description,
    this.appliesTo,
    this.message,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['discipline_profile_id'] = Variable<String>(disciplineProfileId);
    map['field_keys'] = Variable<String>(fieldKeys);
    map['constraint_type'] = Variable<String>(constraintType);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || appliesTo != null) {
      map['applies_to'] = Variable<String>(appliesTo);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DisciplineValidationsCompanion toCompanion(bool nullToAbsent) {
    return DisciplineValidationsCompanion(
      id: Value(id),
      disciplineProfileId: Value(disciplineProfileId),
      fieldKeys: Value(fieldKeys),
      constraintType: Value(constraintType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      appliesTo: appliesTo == null && nullToAbsent
          ? const Value.absent()
          : Value(appliesTo),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory DisciplineValidationData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisciplineValidationData(
      id: serializer.fromJson<String>(json['id']),
      disciplineProfileId: serializer.fromJson<String>(
        json['disciplineProfileId'],
      ),
      fieldKeys: serializer.fromJson<String>(json['fieldKeys']),
      constraintType: serializer.fromJson<String>(json['constraintType']),
      description: serializer.fromJson<String?>(json['description']),
      appliesTo: serializer.fromJson<String?>(json['appliesTo']),
      message: serializer.fromJson<String?>(json['message']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'disciplineProfileId': serializer.toJson<String>(disciplineProfileId),
      'fieldKeys': serializer.toJson<String>(fieldKeys),
      'constraintType': serializer.toJson<String>(constraintType),
      'description': serializer.toJson<String?>(description),
      'appliesTo': serializer.toJson<String?>(appliesTo),
      'message': serializer.toJson<String?>(message),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DisciplineValidationData copyWith({
    String? id,
    String? disciplineProfileId,
    String? fieldKeys,
    String? constraintType,
    Value<String?> description = const Value.absent(),
    Value<String?> appliesTo = const Value.absent(),
    Value<String?> message = const Value.absent(),
    int? displayOrder,
    String? createdAt,
  }) => DisciplineValidationData(
    id: id ?? this.id,
    disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
    fieldKeys: fieldKeys ?? this.fieldKeys,
    constraintType: constraintType ?? this.constraintType,
    description: description.present ? description.value : this.description,
    appliesTo: appliesTo.present ? appliesTo.value : this.appliesTo,
    message: message.present ? message.value : this.message,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  DisciplineValidationData copyWithCompanion(
    DisciplineValidationsCompanion data,
  ) {
    return DisciplineValidationData(
      id: data.id.present ? data.id.value : this.id,
      disciplineProfileId: data.disciplineProfileId.present
          ? data.disciplineProfileId.value
          : this.disciplineProfileId,
      fieldKeys: data.fieldKeys.present ? data.fieldKeys.value : this.fieldKeys,
      constraintType: data.constraintType.present
          ? data.constraintType.value
          : this.constraintType,
      description: data.description.present
          ? data.description.value
          : this.description,
      appliesTo: data.appliesTo.present ? data.appliesTo.value : this.appliesTo,
      message: data.message.present ? data.message.value : this.message,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineValidationData(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('fieldKeys: $fieldKeys, ')
          ..write('constraintType: $constraintType, ')
          ..write('description: $description, ')
          ..write('appliesTo: $appliesTo, ')
          ..write('message: $message, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    disciplineProfileId,
    fieldKeys,
    constraintType,
    description,
    appliesTo,
    message,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisciplineValidationData &&
          other.id == this.id &&
          other.disciplineProfileId == this.disciplineProfileId &&
          other.fieldKeys == this.fieldKeys &&
          other.constraintType == this.constraintType &&
          other.description == this.description &&
          other.appliesTo == this.appliesTo &&
          other.message == this.message &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class DisciplineValidationsCompanion
    extends UpdateCompanion<DisciplineValidationData> {
  final Value<String> id;
  final Value<String> disciplineProfileId;
  final Value<String> fieldKeys;
  final Value<String> constraintType;
  final Value<String?> description;
  final Value<String?> appliesTo;
  final Value<String?> message;
  final Value<int> displayOrder;
  final Value<String> createdAt;
  final Value<int> rowid;
  const DisciplineValidationsCompanion({
    this.id = const Value.absent(),
    this.disciplineProfileId = const Value.absent(),
    this.fieldKeys = const Value.absent(),
    this.constraintType = const Value.absent(),
    this.description = const Value.absent(),
    this.appliesTo = const Value.absent(),
    this.message = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DisciplineValidationsCompanion.insert({
    required String id,
    required String disciplineProfileId,
    required String fieldKeys,
    required String constraintType,
    this.description = const Value.absent(),
    this.appliesTo = const Value.absent(),
    this.message = const Value.absent(),
    required int displayOrder,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       disciplineProfileId = Value(disciplineProfileId),
       fieldKeys = Value(fieldKeys),
       constraintType = Value(constraintType),
       displayOrder = Value(displayOrder),
       createdAt = Value(createdAt);
  static Insertable<DisciplineValidationData> custom({
    Expression<String>? id,
    Expression<String>? disciplineProfileId,
    Expression<String>? fieldKeys,
    Expression<String>? constraintType,
    Expression<String>? description,
    Expression<String>? appliesTo,
    Expression<String>? message,
    Expression<int>? displayOrder,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (disciplineProfileId != null)
        'discipline_profile_id': disciplineProfileId,
      if (fieldKeys != null) 'field_keys': fieldKeys,
      if (constraintType != null) 'constraint_type': constraintType,
      if (description != null) 'description': description,
      if (appliesTo != null) 'applies_to': appliesTo,
      if (message != null) 'message': message,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DisciplineValidationsCompanion copyWith({
    Value<String>? id,
    Value<String>? disciplineProfileId,
    Value<String>? fieldKeys,
    Value<String>? constraintType,
    Value<String?>? description,
    Value<String?>? appliesTo,
    Value<String?>? message,
    Value<int>? displayOrder,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return DisciplineValidationsCompanion(
      id: id ?? this.id,
      disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
      fieldKeys: fieldKeys ?? this.fieldKeys,
      constraintType: constraintType ?? this.constraintType,
      description: description ?? this.description,
      appliesTo: appliesTo ?? this.appliesTo,
      message: message ?? this.message,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (disciplineProfileId.present) {
      map['discipline_profile_id'] = Variable<String>(
        disciplineProfileId.value,
      );
    }
    if (fieldKeys.present) {
      map['field_keys'] = Variable<String>(fieldKeys.value);
    }
    if (constraintType.present) {
      map['constraint_type'] = Variable<String>(constraintType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (appliesTo.present) {
      map['applies_to'] = Variable<String>(appliesTo.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineValidationsCompanion(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('fieldKeys: $fieldKeys, ')
          ..write('constraintType: $constraintType, ')
          ..write('description: $description, ')
          ..write('appliesTo: $appliesTo, ')
          ..write('message: $message, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DisciplineFormulasTable extends DisciplineFormulas
    with TableInfo<$DisciplineFormulasTable, DisciplineFormulaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisciplineFormulasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disciplineProfileIdMeta =
      const VerificationMeta('disciplineProfileId');
  @override
  late final GeneratedColumn<String> disciplineProfileId =
      GeneratedColumn<String>(
        'discipline_profile_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discipline_profiles (id)',
        ),
      );
  static const VerificationMeta _formulaKeyMeta = const VerificationMeta(
    'formulaKey',
  );
  @override
  late final GeneratedColumn<String> formulaKey = GeneratedColumn<String>(
    'formula_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formulaTextMeta = const VerificationMeta(
    'formulaText',
  );
  @override
  late final GeneratedColumn<String> formulaText = GeneratedColumn<String>(
    'formula_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formulaTypeMeta = const VerificationMeta(
    'formulaType',
  );
  @override
  late final GeneratedColumn<String> formulaType = GeneratedColumn<String>(
    'formula_type',
    aliasedName,
    false,
    check: () => formulaType.isIn(formulaTypeValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputsMeta = const VerificationMeta('inputs');
  @override
  late final GeneratedColumn<String> inputs = GeneratedColumn<String>(
    'inputs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputsMeta = const VerificationMeta(
    'outputs',
  );
  @override
  late final GeneratedColumn<String> outputs = GeneratedColumn<String>(
    'outputs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependsOnMeta = const VerificationMeta(
    'dependsOn',
  );
  @override
  late final GeneratedColumn<String> dependsOn = GeneratedColumn<String>(
    'depends_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
      SqlDialect.sqlite: 'CHECK ("is_primary" IN (0, 1))',
      SqlDialect.postgres: '',
    }),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    disciplineProfileId,
    formulaKey,
    description,
    formulaText,
    formulaType,
    inputs,
    outputs,
    dependsOn,
    isPrimary,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discipline_formulas';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisciplineFormulaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('discipline_profile_id')) {
      context.handle(
        _disciplineProfileIdMeta,
        disciplineProfileId.isAcceptableOrUnknown(
          data['discipline_profile_id']!,
          _disciplineProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disciplineProfileIdMeta);
    }
    if (data.containsKey('formula_key')) {
      context.handle(
        _formulaKeyMeta,
        formulaKey.isAcceptableOrUnknown(data['formula_key']!, _formulaKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_formulaKeyMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('formula_text')) {
      context.handle(
        _formulaTextMeta,
        formulaText.isAcceptableOrUnknown(
          data['formula_text']!,
          _formulaTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formulaTextMeta);
    }
    if (data.containsKey('formula_type')) {
      context.handle(
        _formulaTypeMeta,
        formulaType.isAcceptableOrUnknown(
          data['formula_type']!,
          _formulaTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formulaTypeMeta);
    }
    if (data.containsKey('inputs')) {
      context.handle(
        _inputsMeta,
        inputs.isAcceptableOrUnknown(data['inputs']!, _inputsMeta),
      );
    } else if (isInserting) {
      context.missing(_inputsMeta);
    }
    if (data.containsKey('outputs')) {
      context.handle(
        _outputsMeta,
        outputs.isAcceptableOrUnknown(data['outputs']!, _outputsMeta),
      );
    }
    if (data.containsKey('depends_on')) {
      context.handle(
        _dependsOnMeta,
        dependsOn.isAcceptableOrUnknown(data['depends_on']!, _dependsOnMeta),
      );
    } else if (isInserting) {
      context.missing(_dependsOnMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    } else if (isInserting) {
      context.missing(_isPrimaryMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {disciplineProfileId, formulaKey},
  ];
  @override
  DisciplineFormulaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisciplineFormulaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      disciplineProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discipline_profile_id'],
      )!,
      formulaKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formula_key'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      formulaText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formula_text'],
      )!,
      formulaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formula_type'],
      )!,
      inputs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inputs'],
      )!,
      outputs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outputs'],
      ),
      dependsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DisciplineFormulasTable createAlias(String alias) {
    return $DisciplineFormulasTable(attachedDatabase, alias);
  }
}

class DisciplineFormulaData extends DataClass
    implements Insertable<DisciplineFormulaData> {
  final String id;
  final String disciplineProfileId;
  final String formulaKey;
  final String? description;
  final String formulaText;
  final String formulaType;
  final String inputs;
  final String? outputs;
  final String dependsOn;
  final bool isPrimary;
  final int displayOrder;
  final String createdAt;
  const DisciplineFormulaData({
    required this.id,
    required this.disciplineProfileId,
    required this.formulaKey,
    this.description,
    required this.formulaText,
    required this.formulaType,
    required this.inputs,
    this.outputs,
    required this.dependsOn,
    required this.isPrimary,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['discipline_profile_id'] = Variable<String>(disciplineProfileId);
    map['formula_key'] = Variable<String>(formulaKey);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['formula_text'] = Variable<String>(formulaText);
    map['formula_type'] = Variable<String>(formulaType);
    map['inputs'] = Variable<String>(inputs);
    if (!nullToAbsent || outputs != null) {
      map['outputs'] = Variable<String>(outputs);
    }
    map['depends_on'] = Variable<String>(dependsOn);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DisciplineFormulasCompanion toCompanion(bool nullToAbsent) {
    return DisciplineFormulasCompanion(
      id: Value(id),
      disciplineProfileId: Value(disciplineProfileId),
      formulaKey: Value(formulaKey),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      formulaText: Value(formulaText),
      formulaType: Value(formulaType),
      inputs: Value(inputs),
      outputs: outputs == null && nullToAbsent
          ? const Value.absent()
          : Value(outputs),
      dependsOn: Value(dependsOn),
      isPrimary: Value(isPrimary),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory DisciplineFormulaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisciplineFormulaData(
      id: serializer.fromJson<String>(json['id']),
      disciplineProfileId: serializer.fromJson<String>(
        json['disciplineProfileId'],
      ),
      formulaKey: serializer.fromJson<String>(json['formulaKey']),
      description: serializer.fromJson<String?>(json['description']),
      formulaText: serializer.fromJson<String>(json['formulaText']),
      formulaType: serializer.fromJson<String>(json['formulaType']),
      inputs: serializer.fromJson<String>(json['inputs']),
      outputs: serializer.fromJson<String?>(json['outputs']),
      dependsOn: serializer.fromJson<String>(json['dependsOn']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'disciplineProfileId': serializer.toJson<String>(disciplineProfileId),
      'formulaKey': serializer.toJson<String>(formulaKey),
      'description': serializer.toJson<String?>(description),
      'formulaText': serializer.toJson<String>(formulaText),
      'formulaType': serializer.toJson<String>(formulaType),
      'inputs': serializer.toJson<String>(inputs),
      'outputs': serializer.toJson<String?>(outputs),
      'dependsOn': serializer.toJson<String>(dependsOn),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DisciplineFormulaData copyWith({
    String? id,
    String? disciplineProfileId,
    String? formulaKey,
    Value<String?> description = const Value.absent(),
    String? formulaText,
    String? formulaType,
    String? inputs,
    Value<String?> outputs = const Value.absent(),
    String? dependsOn,
    bool? isPrimary,
    int? displayOrder,
    String? createdAt,
  }) => DisciplineFormulaData(
    id: id ?? this.id,
    disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
    formulaKey: formulaKey ?? this.formulaKey,
    description: description.present ? description.value : this.description,
    formulaText: formulaText ?? this.formulaText,
    formulaType: formulaType ?? this.formulaType,
    inputs: inputs ?? this.inputs,
    outputs: outputs.present ? outputs.value : this.outputs,
    dependsOn: dependsOn ?? this.dependsOn,
    isPrimary: isPrimary ?? this.isPrimary,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  DisciplineFormulaData copyWithCompanion(DisciplineFormulasCompanion data) {
    return DisciplineFormulaData(
      id: data.id.present ? data.id.value : this.id,
      disciplineProfileId: data.disciplineProfileId.present
          ? data.disciplineProfileId.value
          : this.disciplineProfileId,
      formulaKey: data.formulaKey.present
          ? data.formulaKey.value
          : this.formulaKey,
      description: data.description.present
          ? data.description.value
          : this.description,
      formulaText: data.formulaText.present
          ? data.formulaText.value
          : this.formulaText,
      formulaType: data.formulaType.present
          ? data.formulaType.value
          : this.formulaType,
      inputs: data.inputs.present ? data.inputs.value : this.inputs,
      outputs: data.outputs.present ? data.outputs.value : this.outputs,
      dependsOn: data.dependsOn.present ? data.dependsOn.value : this.dependsOn,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineFormulaData(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('formulaKey: $formulaKey, ')
          ..write('description: $description, ')
          ..write('formulaText: $formulaText, ')
          ..write('formulaType: $formulaType, ')
          ..write('inputs: $inputs, ')
          ..write('outputs: $outputs, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    disciplineProfileId,
    formulaKey,
    description,
    formulaText,
    formulaType,
    inputs,
    outputs,
    dependsOn,
    isPrimary,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisciplineFormulaData &&
          other.id == this.id &&
          other.disciplineProfileId == this.disciplineProfileId &&
          other.formulaKey == this.formulaKey &&
          other.description == this.description &&
          other.formulaText == this.formulaText &&
          other.formulaType == this.formulaType &&
          other.inputs == this.inputs &&
          other.outputs == this.outputs &&
          other.dependsOn == this.dependsOn &&
          other.isPrimary == this.isPrimary &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class DisciplineFormulasCompanion
    extends UpdateCompanion<DisciplineFormulaData> {
  final Value<String> id;
  final Value<String> disciplineProfileId;
  final Value<String> formulaKey;
  final Value<String?> description;
  final Value<String> formulaText;
  final Value<String> formulaType;
  final Value<String> inputs;
  final Value<String?> outputs;
  final Value<String> dependsOn;
  final Value<bool> isPrimary;
  final Value<int> displayOrder;
  final Value<String> createdAt;
  final Value<int> rowid;
  const DisciplineFormulasCompanion({
    this.id = const Value.absent(),
    this.disciplineProfileId = const Value.absent(),
    this.formulaKey = const Value.absent(),
    this.description = const Value.absent(),
    this.formulaText = const Value.absent(),
    this.formulaType = const Value.absent(),
    this.inputs = const Value.absent(),
    this.outputs = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DisciplineFormulasCompanion.insert({
    required String id,
    required String disciplineProfileId,
    required String formulaKey,
    this.description = const Value.absent(),
    required String formulaText,
    required String formulaType,
    required String inputs,
    this.outputs = const Value.absent(),
    required String dependsOn,
    required bool isPrimary,
    required int displayOrder,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       disciplineProfileId = Value(disciplineProfileId),
       formulaKey = Value(formulaKey),
       formulaText = Value(formulaText),
       formulaType = Value(formulaType),
       inputs = Value(inputs),
       dependsOn = Value(dependsOn),
       isPrimary = Value(isPrimary),
       displayOrder = Value(displayOrder),
       createdAt = Value(createdAt);
  static Insertable<DisciplineFormulaData> custom({
    Expression<String>? id,
    Expression<String>? disciplineProfileId,
    Expression<String>? formulaKey,
    Expression<String>? description,
    Expression<String>? formulaText,
    Expression<String>? formulaType,
    Expression<String>? inputs,
    Expression<String>? outputs,
    Expression<String>? dependsOn,
    Expression<bool>? isPrimary,
    Expression<int>? displayOrder,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (disciplineProfileId != null)
        'discipline_profile_id': disciplineProfileId,
      if (formulaKey != null) 'formula_key': formulaKey,
      if (description != null) 'description': description,
      if (formulaText != null) 'formula_text': formulaText,
      if (formulaType != null) 'formula_type': formulaType,
      if (inputs != null) 'inputs': inputs,
      if (outputs != null) 'outputs': outputs,
      if (dependsOn != null) 'depends_on': dependsOn,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DisciplineFormulasCompanion copyWith({
    Value<String>? id,
    Value<String>? disciplineProfileId,
    Value<String>? formulaKey,
    Value<String?>? description,
    Value<String>? formulaText,
    Value<String>? formulaType,
    Value<String>? inputs,
    Value<String?>? outputs,
    Value<String>? dependsOn,
    Value<bool>? isPrimary,
    Value<int>? displayOrder,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return DisciplineFormulasCompanion(
      id: id ?? this.id,
      disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
      formulaKey: formulaKey ?? this.formulaKey,
      description: description ?? this.description,
      formulaText: formulaText ?? this.formulaText,
      formulaType: formulaType ?? this.formulaType,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      dependsOn: dependsOn ?? this.dependsOn,
      isPrimary: isPrimary ?? this.isPrimary,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (disciplineProfileId.present) {
      map['discipline_profile_id'] = Variable<String>(
        disciplineProfileId.value,
      );
    }
    if (formulaKey.present) {
      map['formula_key'] = Variable<String>(formulaKey.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (formulaText.present) {
      map['formula_text'] = Variable<String>(formulaText.value);
    }
    if (formulaType.present) {
      map['formula_type'] = Variable<String>(formulaType.value);
    }
    if (inputs.present) {
      map['inputs'] = Variable<String>(inputs.value);
    }
    if (outputs.present) {
      map['outputs'] = Variable<String>(outputs.value);
    }
    if (dependsOn.present) {
      map['depends_on'] = Variable<String>(dependsOn.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineFormulasCompanion(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('formulaKey: $formulaKey, ')
          ..write('description: $description, ')
          ..write('formulaText: $formulaText, ')
          ..write('formulaType: $formulaType, ')
          ..write('inputs: $inputs, ')
          ..write('outputs: $outputs, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DisciplineRulesTable extends DisciplineRules
    with TableInfo<$DisciplineRulesTable, DisciplineRuleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisciplineRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disciplineProfileIdMeta =
      const VerificationMeta('disciplineProfileId');
  @override
  late final GeneratedColumn<String> disciplineProfileId =
      GeneratedColumn<String>(
        'discipline_profile_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discipline_profiles (id)',
        ),
      );
  static const VerificationMeta _ruleKeyMeta = const VerificationMeta(
    'ruleKey',
  );
  @override
  late final GeneratedColumn<String> ruleKey = GeneratedColumn<String>(
    'rule_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleTypeMeta = const VerificationMeta(
    'ruleType',
  );
  @override
  late final GeneratedColumn<String> ruleType = GeneratedColumn<String>(
    'rule_type',
    aliasedName,
    false,
    check: () => ruleType.isIn(ruleTypeValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effectMeta = const VerificationMeta('effect');
  @override
  late final GeneratedColumn<String> effect = GeneratedColumn<String>(
    'effect',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appliesToMeta = const VerificationMeta(
    'appliesTo',
  );
  @override
  late final GeneratedColumn<String> appliesTo = GeneratedColumn<String>(
    'applies_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependsOnMeta = const VerificationMeta(
    'dependsOn',
  );
  @override
  late final GeneratedColumn<String> dependsOn = GeneratedColumn<String>(
    'depends_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoScoreZeroMeta = const VerificationMeta(
    'autoScoreZero',
  );
  @override
  late final GeneratedColumn<bool> autoScoreZero = GeneratedColumn<bool>(
    'auto_score_zero',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
      SqlDialect.sqlite: 'CHECK ("auto_score_zero" IN (0, 1))',
      SqlDialect.postgres: '',
    }),
  );
  static const VerificationMeta _affectsOtherFieldsMeta =
      const VerificationMeta('affectsOtherFields');
  @override
  late final GeneratedColumn<String> affectsOtherFields =
      GeneratedColumn<String>(
        'affects_other_fields',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    disciplineProfileId,
    ruleKey,
    ruleType,
    condition,
    effect,
    appliesTo,
    dependsOn,
    displayName,
    description,
    autoScoreZero,
    affectsOtherFields,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discipline_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisciplineRuleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('discipline_profile_id')) {
      context.handle(
        _disciplineProfileIdMeta,
        disciplineProfileId.isAcceptableOrUnknown(
          data['discipline_profile_id']!,
          _disciplineProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disciplineProfileIdMeta);
    }
    if (data.containsKey('rule_key')) {
      context.handle(
        _ruleKeyMeta,
        ruleKey.isAcceptableOrUnknown(data['rule_key']!, _ruleKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleKeyMeta);
    }
    if (data.containsKey('rule_type')) {
      context.handle(
        _ruleTypeMeta,
        ruleType.isAcceptableOrUnknown(data['rule_type']!, _ruleTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleTypeMeta);
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('effect')) {
      context.handle(
        _effectMeta,
        effect.isAcceptableOrUnknown(data['effect']!, _effectMeta),
      );
    }
    if (data.containsKey('applies_to')) {
      context.handle(
        _appliesToMeta,
        appliesTo.isAcceptableOrUnknown(data['applies_to']!, _appliesToMeta),
      );
    }
    if (data.containsKey('depends_on')) {
      context.handle(
        _dependsOnMeta,
        dependsOn.isAcceptableOrUnknown(data['depends_on']!, _dependsOnMeta),
      );
    } else if (isInserting) {
      context.missing(_dependsOnMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('auto_score_zero')) {
      context.handle(
        _autoScoreZeroMeta,
        autoScoreZero.isAcceptableOrUnknown(
          data['auto_score_zero']!,
          _autoScoreZeroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_autoScoreZeroMeta);
    }
    if (data.containsKey('affects_other_fields')) {
      context.handle(
        _affectsOtherFieldsMeta,
        affectsOtherFields.isAcceptableOrUnknown(
          data['affects_other_fields']!,
          _affectsOtherFieldsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_affectsOtherFieldsMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {disciplineProfileId, ruleKey},
  ];
  @override
  DisciplineRuleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisciplineRuleData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      disciplineProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discipline_profile_id'],
      )!,
      ruleKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_key'],
      )!,
      ruleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_type'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      effect: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effect'],
      ),
      appliesTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}applies_to'],
      ),
      dependsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      autoScoreZero: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_score_zero'],
      )!,
      affectsOtherFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}affects_other_fields'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DisciplineRulesTable createAlias(String alias) {
    return $DisciplineRulesTable(attachedDatabase, alias);
  }
}

class DisciplineRuleData extends DataClass
    implements Insertable<DisciplineRuleData> {
  final String id;
  final String disciplineProfileId;
  final String ruleKey;
  final String ruleType;
  final String? condition;
  final String? effect;
  final String? appliesTo;
  final String dependsOn;
  final String? displayName;
  final String? description;
  final bool autoScoreZero;
  final String affectsOtherFields;
  final int displayOrder;
  final String createdAt;
  const DisciplineRuleData({
    required this.id,
    required this.disciplineProfileId,
    required this.ruleKey,
    required this.ruleType,
    this.condition,
    this.effect,
    this.appliesTo,
    required this.dependsOn,
    this.displayName,
    this.description,
    required this.autoScoreZero,
    required this.affectsOtherFields,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['discipline_profile_id'] = Variable<String>(disciplineProfileId);
    map['rule_key'] = Variable<String>(ruleKey);
    map['rule_type'] = Variable<String>(ruleType);
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || effect != null) {
      map['effect'] = Variable<String>(effect);
    }
    if (!nullToAbsent || appliesTo != null) {
      map['applies_to'] = Variable<String>(appliesTo);
    }
    map['depends_on'] = Variable<String>(dependsOn);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['auto_score_zero'] = Variable<bool>(autoScoreZero);
    map['affects_other_fields'] = Variable<String>(affectsOtherFields);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DisciplineRulesCompanion toCompanion(bool nullToAbsent) {
    return DisciplineRulesCompanion(
      id: Value(id),
      disciplineProfileId: Value(disciplineProfileId),
      ruleKey: Value(ruleKey),
      ruleType: Value(ruleType),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      effect: effect == null && nullToAbsent
          ? const Value.absent()
          : Value(effect),
      appliesTo: appliesTo == null && nullToAbsent
          ? const Value.absent()
          : Value(appliesTo),
      dependsOn: Value(dependsOn),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      autoScoreZero: Value(autoScoreZero),
      affectsOtherFields: Value(affectsOtherFields),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory DisciplineRuleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisciplineRuleData(
      id: serializer.fromJson<String>(json['id']),
      disciplineProfileId: serializer.fromJson<String>(
        json['disciplineProfileId'],
      ),
      ruleKey: serializer.fromJson<String>(json['ruleKey']),
      ruleType: serializer.fromJson<String>(json['ruleType']),
      condition: serializer.fromJson<String?>(json['condition']),
      effect: serializer.fromJson<String?>(json['effect']),
      appliesTo: serializer.fromJson<String?>(json['appliesTo']),
      dependsOn: serializer.fromJson<String>(json['dependsOn']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      description: serializer.fromJson<String?>(json['description']),
      autoScoreZero: serializer.fromJson<bool>(json['autoScoreZero']),
      affectsOtherFields: serializer.fromJson<String>(
        json['affectsOtherFields'],
      ),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'disciplineProfileId': serializer.toJson<String>(disciplineProfileId),
      'ruleKey': serializer.toJson<String>(ruleKey),
      'ruleType': serializer.toJson<String>(ruleType),
      'condition': serializer.toJson<String?>(condition),
      'effect': serializer.toJson<String?>(effect),
      'appliesTo': serializer.toJson<String?>(appliesTo),
      'dependsOn': serializer.toJson<String>(dependsOn),
      'displayName': serializer.toJson<String?>(displayName),
      'description': serializer.toJson<String?>(description),
      'autoScoreZero': serializer.toJson<bool>(autoScoreZero),
      'affectsOtherFields': serializer.toJson<String>(affectsOtherFields),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DisciplineRuleData copyWith({
    String? id,
    String? disciplineProfileId,
    String? ruleKey,
    String? ruleType,
    Value<String?> condition = const Value.absent(),
    Value<String?> effect = const Value.absent(),
    Value<String?> appliesTo = const Value.absent(),
    String? dependsOn,
    Value<String?> displayName = const Value.absent(),
    Value<String?> description = const Value.absent(),
    bool? autoScoreZero,
    String? affectsOtherFields,
    int? displayOrder,
    String? createdAt,
  }) => DisciplineRuleData(
    id: id ?? this.id,
    disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
    ruleKey: ruleKey ?? this.ruleKey,
    ruleType: ruleType ?? this.ruleType,
    condition: condition.present ? condition.value : this.condition,
    effect: effect.present ? effect.value : this.effect,
    appliesTo: appliesTo.present ? appliesTo.value : this.appliesTo,
    dependsOn: dependsOn ?? this.dependsOn,
    displayName: displayName.present ? displayName.value : this.displayName,
    description: description.present ? description.value : this.description,
    autoScoreZero: autoScoreZero ?? this.autoScoreZero,
    affectsOtherFields: affectsOtherFields ?? this.affectsOtherFields,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  DisciplineRuleData copyWithCompanion(DisciplineRulesCompanion data) {
    return DisciplineRuleData(
      id: data.id.present ? data.id.value : this.id,
      disciplineProfileId: data.disciplineProfileId.present
          ? data.disciplineProfileId.value
          : this.disciplineProfileId,
      ruleKey: data.ruleKey.present ? data.ruleKey.value : this.ruleKey,
      ruleType: data.ruleType.present ? data.ruleType.value : this.ruleType,
      condition: data.condition.present ? data.condition.value : this.condition,
      effect: data.effect.present ? data.effect.value : this.effect,
      appliesTo: data.appliesTo.present ? data.appliesTo.value : this.appliesTo,
      dependsOn: data.dependsOn.present ? data.dependsOn.value : this.dependsOn,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      description: data.description.present
          ? data.description.value
          : this.description,
      autoScoreZero: data.autoScoreZero.present
          ? data.autoScoreZero.value
          : this.autoScoreZero,
      affectsOtherFields: data.affectsOtherFields.present
          ? data.affectsOtherFields.value
          : this.affectsOtherFields,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineRuleData(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('ruleKey: $ruleKey, ')
          ..write('ruleType: $ruleType, ')
          ..write('condition: $condition, ')
          ..write('effect: $effect, ')
          ..write('appliesTo: $appliesTo, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('displayName: $displayName, ')
          ..write('description: $description, ')
          ..write('autoScoreZero: $autoScoreZero, ')
          ..write('affectsOtherFields: $affectsOtherFields, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    disciplineProfileId,
    ruleKey,
    ruleType,
    condition,
    effect,
    appliesTo,
    dependsOn,
    displayName,
    description,
    autoScoreZero,
    affectsOtherFields,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisciplineRuleData &&
          other.id == this.id &&
          other.disciplineProfileId == this.disciplineProfileId &&
          other.ruleKey == this.ruleKey &&
          other.ruleType == this.ruleType &&
          other.condition == this.condition &&
          other.effect == this.effect &&
          other.appliesTo == this.appliesTo &&
          other.dependsOn == this.dependsOn &&
          other.displayName == this.displayName &&
          other.description == this.description &&
          other.autoScoreZero == this.autoScoreZero &&
          other.affectsOtherFields == this.affectsOtherFields &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class DisciplineRulesCompanion extends UpdateCompanion<DisciplineRuleData> {
  final Value<String> id;
  final Value<String> disciplineProfileId;
  final Value<String> ruleKey;
  final Value<String> ruleType;
  final Value<String?> condition;
  final Value<String?> effect;
  final Value<String?> appliesTo;
  final Value<String> dependsOn;
  final Value<String?> displayName;
  final Value<String?> description;
  final Value<bool> autoScoreZero;
  final Value<String> affectsOtherFields;
  final Value<int> displayOrder;
  final Value<String> createdAt;
  final Value<int> rowid;
  const DisciplineRulesCompanion({
    this.id = const Value.absent(),
    this.disciplineProfileId = const Value.absent(),
    this.ruleKey = const Value.absent(),
    this.ruleType = const Value.absent(),
    this.condition = const Value.absent(),
    this.effect = const Value.absent(),
    this.appliesTo = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.displayName = const Value.absent(),
    this.description = const Value.absent(),
    this.autoScoreZero = const Value.absent(),
    this.affectsOtherFields = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DisciplineRulesCompanion.insert({
    required String id,
    required String disciplineProfileId,
    required String ruleKey,
    required String ruleType,
    this.condition = const Value.absent(),
    this.effect = const Value.absent(),
    this.appliesTo = const Value.absent(),
    required String dependsOn,
    this.displayName = const Value.absent(),
    this.description = const Value.absent(),
    required bool autoScoreZero,
    required String affectsOtherFields,
    required int displayOrder,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       disciplineProfileId = Value(disciplineProfileId),
       ruleKey = Value(ruleKey),
       ruleType = Value(ruleType),
       dependsOn = Value(dependsOn),
       autoScoreZero = Value(autoScoreZero),
       affectsOtherFields = Value(affectsOtherFields),
       displayOrder = Value(displayOrder),
       createdAt = Value(createdAt);
  static Insertable<DisciplineRuleData> custom({
    Expression<String>? id,
    Expression<String>? disciplineProfileId,
    Expression<String>? ruleKey,
    Expression<String>? ruleType,
    Expression<String>? condition,
    Expression<String>? effect,
    Expression<String>? appliesTo,
    Expression<String>? dependsOn,
    Expression<String>? displayName,
    Expression<String>? description,
    Expression<bool>? autoScoreZero,
    Expression<String>? affectsOtherFields,
    Expression<int>? displayOrder,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (disciplineProfileId != null)
        'discipline_profile_id': disciplineProfileId,
      if (ruleKey != null) 'rule_key': ruleKey,
      if (ruleType != null) 'rule_type': ruleType,
      if (condition != null) 'condition': condition,
      if (effect != null) 'effect': effect,
      if (appliesTo != null) 'applies_to': appliesTo,
      if (dependsOn != null) 'depends_on': dependsOn,
      if (displayName != null) 'display_name': displayName,
      if (description != null) 'description': description,
      if (autoScoreZero != null) 'auto_score_zero': autoScoreZero,
      if (affectsOtherFields != null)
        'affects_other_fields': affectsOtherFields,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DisciplineRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? disciplineProfileId,
    Value<String>? ruleKey,
    Value<String>? ruleType,
    Value<String?>? condition,
    Value<String?>? effect,
    Value<String?>? appliesTo,
    Value<String>? dependsOn,
    Value<String?>? displayName,
    Value<String?>? description,
    Value<bool>? autoScoreZero,
    Value<String>? affectsOtherFields,
    Value<int>? displayOrder,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return DisciplineRulesCompanion(
      id: id ?? this.id,
      disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
      ruleKey: ruleKey ?? this.ruleKey,
      ruleType: ruleType ?? this.ruleType,
      condition: condition ?? this.condition,
      effect: effect ?? this.effect,
      appliesTo: appliesTo ?? this.appliesTo,
      dependsOn: dependsOn ?? this.dependsOn,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      autoScoreZero: autoScoreZero ?? this.autoScoreZero,
      affectsOtherFields: affectsOtherFields ?? this.affectsOtherFields,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (disciplineProfileId.present) {
      map['discipline_profile_id'] = Variable<String>(
        disciplineProfileId.value,
      );
    }
    if (ruleKey.present) {
      map['rule_key'] = Variable<String>(ruleKey.value);
    }
    if (ruleType.present) {
      map['rule_type'] = Variable<String>(ruleType.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (effect.present) {
      map['effect'] = Variable<String>(effect.value);
    }
    if (appliesTo.present) {
      map['applies_to'] = Variable<String>(appliesTo.value);
    }
    if (dependsOn.present) {
      map['depends_on'] = Variable<String>(dependsOn.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (autoScoreZero.present) {
      map['auto_score_zero'] = Variable<bool>(autoScoreZero.value);
    }
    if (affectsOtherFields.present) {
      map['affects_other_fields'] = Variable<String>(affectsOtherFields.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisciplineRulesCompanion(')
          ..write('id: $id, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('ruleKey: $ruleKey, ')
          ..write('ruleType: $ruleType, ')
          ..write('condition: $condition, ')
          ..write('effect: $effect, ')
          ..write('appliesTo: $appliesTo, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('displayName: $displayName, ')
          ..write('description: $description, ')
          ..write('autoScoreZero: $autoScoreZero, ')
          ..write('affectsOtherFields: $affectsOtherFields, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContestConfigurationPresetsTable extends ContestConfigurationPresets
    with
        TableInfo<
          $ContestConfigurationPresetsTable,
          ContestConfigurationPresetData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContestConfigurationPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disciplineProfileIdMeta =
      const VerificationMeta('disciplineProfileId');
  @override
  late final GeneratedColumn<String> disciplineProfileId =
      GeneratedColumn<String>(
        'discipline_profile_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discipline_profiles (id)',
        ),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _landingTableIdMeta = const VerificationMeta(
    'landingTableId',
  );
  @override
  late final GeneratedColumn<String> landingTableId = GeneratedColumn<String>(
    'landing_table_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES landing_tables (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerAccountId,
    disciplineProfileId,
    name,
    description,
    config,
    landingTableId,
    createdAt,
    updatedAt,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contest_configuration_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContestConfigurationPresetData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerAccountIdMeta);
    }
    if (data.containsKey('discipline_profile_id')) {
      context.handle(
        _disciplineProfileIdMeta,
        disciplineProfileId.isAcceptableOrUnknown(
          data['discipline_profile_id']!,
          _disciplineProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disciplineProfileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
      );
    } else if (isInserting) {
      context.missing(_configMeta);
    }
    if (data.containsKey('landing_table_id')) {
      context.handle(
        _landingTableIdMeta,
        landingTableId.isAcceptableOrUnknown(
          data['landing_table_id']!,
          _landingTableIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContestConfigurationPresetData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContestConfigurationPresetData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      )!,
      disciplineProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discipline_profile_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      )!,
      landingTableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}landing_table_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $ContestConfigurationPresetsTable createAlias(String alias) {
    return $ContestConfigurationPresetsTable(attachedDatabase, alias);
  }
}

class ContestConfigurationPresetData extends DataClass
    implements Insertable<ContestConfigurationPresetData> {
  final String id;
  final String ownerAccountId;
  final String disciplineProfileId;
  final String name;
  final String? description;
  final String config;
  final String? landingTableId;
  final String createdAt;
  final String updatedAt;
  final int revision;
  const ContestConfigurationPresetData({
    required this.id,
    required this.ownerAccountId,
    required this.disciplineProfileId,
    required this.name,
    this.description,
    required this.config,
    this.landingTableId,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_account_id'] = Variable<String>(ownerAccountId);
    map['discipline_profile_id'] = Variable<String>(disciplineProfileId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['config'] = Variable<String>(config);
    if (!nullToAbsent || landingTableId != null) {
      map['landing_table_id'] = Variable<String>(landingTableId);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  ContestConfigurationPresetsCompanion toCompanion(bool nullToAbsent) {
    return ContestConfigurationPresetsCompanion(
      id: Value(id),
      ownerAccountId: Value(ownerAccountId),
      disciplineProfileId: Value(disciplineProfileId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      config: Value(config),
      landingTableId: landingTableId == null && nullToAbsent
          ? const Value.absent()
          : Value(landingTableId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
    );
  }

  factory ContestConfigurationPresetData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContestConfigurationPresetData(
      id: serializer.fromJson<String>(json['id']),
      ownerAccountId: serializer.fromJson<String>(json['ownerAccountId']),
      disciplineProfileId: serializer.fromJson<String>(
        json['disciplineProfileId'],
      ),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      config: serializer.fromJson<String>(json['config']),
      landingTableId: serializer.fromJson<String?>(json['landingTableId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerAccountId': serializer.toJson<String>(ownerAccountId),
      'disciplineProfileId': serializer.toJson<String>(disciplineProfileId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'config': serializer.toJson<String>(config),
      'landingTableId': serializer.toJson<String?>(landingTableId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  ContestConfigurationPresetData copyWith({
    String? id,
    String? ownerAccountId,
    String? disciplineProfileId,
    String? name,
    Value<String?> description = const Value.absent(),
    String? config,
    Value<String?> landingTableId = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    int? revision,
  }) => ContestConfigurationPresetData(
    id: id ?? this.id,
    ownerAccountId: ownerAccountId ?? this.ownerAccountId,
    disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    config: config ?? this.config,
    landingTableId: landingTableId.present
        ? landingTableId.value
        : this.landingTableId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
  );
  ContestConfigurationPresetData copyWithCompanion(
    ContestConfigurationPresetsCompanion data,
  ) {
    return ContestConfigurationPresetData(
      id: data.id.present ? data.id.value : this.id,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      disciplineProfileId: data.disciplineProfileId.present
          ? data.disciplineProfileId.value
          : this.disciplineProfileId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      config: data.config.present ? data.config.value : this.config,
      landingTableId: data.landingTableId.present
          ? data.landingTableId.value
          : this.landingTableId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContestConfigurationPresetData(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('config: $config, ')
          ..write('landingTableId: $landingTableId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerAccountId,
    disciplineProfileId,
    name,
    description,
    config,
    landingTableId,
    createdAt,
    updatedAt,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContestConfigurationPresetData &&
          other.id == this.id &&
          other.ownerAccountId == this.ownerAccountId &&
          other.disciplineProfileId == this.disciplineProfileId &&
          other.name == this.name &&
          other.description == this.description &&
          other.config == this.config &&
          other.landingTableId == this.landingTableId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision);
}

class ContestConfigurationPresetsCompanion
    extends UpdateCompanion<ContestConfigurationPresetData> {
  final Value<String> id;
  final Value<String> ownerAccountId;
  final Value<String> disciplineProfileId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> config;
  final Value<String?> landingTableId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const ContestConfigurationPresetsCompanion({
    this.id = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.disciplineProfileId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.config = const Value.absent(),
    this.landingTableId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContestConfigurationPresetsCompanion.insert({
    required String id,
    required String ownerAccountId,
    required String disciplineProfileId,
    required String name,
    this.description = const Value.absent(),
    required String config,
    this.landingTableId = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerAccountId = Value(ownerAccountId),
       disciplineProfileId = Value(disciplineProfileId),
       name = Value(name),
       config = Value(config),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ContestConfigurationPresetData> custom({
    Expression<String>? id,
    Expression<String>? ownerAccountId,
    Expression<String>? disciplineProfileId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? config,
    Expression<String>? landingTableId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (disciplineProfileId != null)
        'discipline_profile_id': disciplineProfileId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (config != null) 'config': config,
      if (landingTableId != null) 'landing_table_id': landingTableId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContestConfigurationPresetsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerAccountId,
    Value<String>? disciplineProfileId,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? config,
    Value<String?>? landingTableId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return ContestConfigurationPresetsCompanion(
      id: id ?? this.id,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
      name: name ?? this.name,
      description: description ?? this.description,
      config: config ?? this.config,
      landingTableId: landingTableId ?? this.landingTableId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (disciplineProfileId.present) {
      map['discipline_profile_id'] = Variable<String>(
        disciplineProfileId.value,
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (landingTableId.present) {
      map['landing_table_id'] = Variable<String>(landingTableId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContestConfigurationPresetsCompanion(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('config: $config, ')
          ..write('landingTableId: $landingTableId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContestConfigurationRevisionsTable extends ContestConfigurationRevisions
    with
        TableInfo<
          $ContestConfigurationRevisionsTable,
          ContestConfigurationRevisionData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContestConfigurationRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contests (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _revisionNumberMeta = const VerificationMeta(
    'revisionNumber',
  );
  @override
  late final GeneratedColumn<int> revisionNumber = GeneratedColumn<int>(
    'revision_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disciplineProfileIdMeta =
      const VerificationMeta('disciplineProfileId');
  @override
  late final GeneratedColumn<String> disciplineProfileId =
      GeneratedColumn<String>(
        'discipline_profile_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES discipline_profiles (id)',
        ),
      );
  static const VerificationMeta _sourcePresetIdMeta = const VerificationMeta(
    'sourcePresetId',
  );
  @override
  late final GeneratedColumn<String> sourcePresetId = GeneratedColumn<String>(
    'source_preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contest_configuration_presets (id)',
    ),
  );
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _landingTableIdMeta = const VerificationMeta(
    'landingTableId',
  );
  @override
  late final GeneratedColumn<String> landingTableId = GeneratedColumn<String>(
    'landing_table_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES landing_tables (id)',
    ),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contestId,
    revisionNumber,
    disciplineProfileId,
    sourcePresetId,
    config,
    landingTableId,
    createdBy,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contest_configuration_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContestConfigurationRevisionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contestIdMeta);
    }
    if (data.containsKey('revision_number')) {
      context.handle(
        _revisionNumberMeta,
        revisionNumber.isAcceptableOrUnknown(
          data['revision_number']!,
          _revisionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_revisionNumberMeta);
    }
    if (data.containsKey('discipline_profile_id')) {
      context.handle(
        _disciplineProfileIdMeta,
        disciplineProfileId.isAcceptableOrUnknown(
          data['discipline_profile_id']!,
          _disciplineProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disciplineProfileIdMeta);
    }
    if (data.containsKey('source_preset_id')) {
      context.handle(
        _sourcePresetIdMeta,
        sourcePresetId.isAcceptableOrUnknown(
          data['source_preset_id']!,
          _sourcePresetIdMeta,
        ),
      );
    }
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
      );
    } else if (isInserting) {
      context.missing(_configMeta);
    }
    if (data.containsKey('landing_table_id')) {
      context.handle(
        _landingTableIdMeta,
        landingTableId.isAcceptableOrUnknown(
          data['landing_table_id']!,
          _landingTableIdMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {contestId, revisionNumber},
  ];
  @override
  ContestConfigurationRevisionData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContestConfigurationRevisionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      )!,
      revisionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision_number'],
      )!,
      disciplineProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discipline_profile_id'],
      )!,
      sourcePresetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_preset_id'],
      ),
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      )!,
      landingTableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}landing_table_id'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ContestConfigurationRevisionsTable createAlias(String alias) {
    return $ContestConfigurationRevisionsTable(attachedDatabase, alias);
  }
}

class ContestConfigurationRevisionData extends DataClass
    implements Insertable<ContestConfigurationRevisionData> {
  final String id;
  final String contestId;
  final int revisionNumber;
  final String disciplineProfileId;
  final String? sourcePresetId;
  final String config;
  final String? landingTableId;
  final String createdBy;
  final String? notes;
  final String createdAt;
  const ContestConfigurationRevisionData({
    required this.id,
    required this.contestId,
    required this.revisionNumber,
    required this.disciplineProfileId,
    this.sourcePresetId,
    required this.config,
    this.landingTableId,
    required this.createdBy,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contest_id'] = Variable<String>(contestId);
    map['revision_number'] = Variable<int>(revisionNumber);
    map['discipline_profile_id'] = Variable<String>(disciplineProfileId);
    if (!nullToAbsent || sourcePresetId != null) {
      map['source_preset_id'] = Variable<String>(sourcePresetId);
    }
    map['config'] = Variable<String>(config);
    if (!nullToAbsent || landingTableId != null) {
      map['landing_table_id'] = Variable<String>(landingTableId);
    }
    map['created_by'] = Variable<String>(createdBy);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ContestConfigurationRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ContestConfigurationRevisionsCompanion(
      id: Value(id),
      contestId: Value(contestId),
      revisionNumber: Value(revisionNumber),
      disciplineProfileId: Value(disciplineProfileId),
      sourcePresetId: sourcePresetId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePresetId),
      config: Value(config),
      landingTableId: landingTableId == null && nullToAbsent
          ? const Value.absent()
          : Value(landingTableId),
      createdBy: Value(createdBy),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory ContestConfigurationRevisionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContestConfigurationRevisionData(
      id: serializer.fromJson<String>(json['id']),
      contestId: serializer.fromJson<String>(json['contestId']),
      revisionNumber: serializer.fromJson<int>(json['revisionNumber']),
      disciplineProfileId: serializer.fromJson<String>(
        json['disciplineProfileId'],
      ),
      sourcePresetId: serializer.fromJson<String?>(json['sourcePresetId']),
      config: serializer.fromJson<String>(json['config']),
      landingTableId: serializer.fromJson<String?>(json['landingTableId']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contestId': serializer.toJson<String>(contestId),
      'revisionNumber': serializer.toJson<int>(revisionNumber),
      'disciplineProfileId': serializer.toJson<String>(disciplineProfileId),
      'sourcePresetId': serializer.toJson<String?>(sourcePresetId),
      'config': serializer.toJson<String>(config),
      'landingTableId': serializer.toJson<String?>(landingTableId),
      'createdBy': serializer.toJson<String>(createdBy),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ContestConfigurationRevisionData copyWith({
    String? id,
    String? contestId,
    int? revisionNumber,
    String? disciplineProfileId,
    Value<String?> sourcePresetId = const Value.absent(),
    String? config,
    Value<String?> landingTableId = const Value.absent(),
    String? createdBy,
    Value<String?> notes = const Value.absent(),
    String? createdAt,
  }) => ContestConfigurationRevisionData(
    id: id ?? this.id,
    contestId: contestId ?? this.contestId,
    revisionNumber: revisionNumber ?? this.revisionNumber,
    disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
    sourcePresetId: sourcePresetId.present
        ? sourcePresetId.value
        : this.sourcePresetId,
    config: config ?? this.config,
    landingTableId: landingTableId.present
        ? landingTableId.value
        : this.landingTableId,
    createdBy: createdBy ?? this.createdBy,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  ContestConfigurationRevisionData copyWithCompanion(
    ContestConfigurationRevisionsCompanion data,
  ) {
    return ContestConfigurationRevisionData(
      id: data.id.present ? data.id.value : this.id,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      revisionNumber: data.revisionNumber.present
          ? data.revisionNumber.value
          : this.revisionNumber,
      disciplineProfileId: data.disciplineProfileId.present
          ? data.disciplineProfileId.value
          : this.disciplineProfileId,
      sourcePresetId: data.sourcePresetId.present
          ? data.sourcePresetId.value
          : this.sourcePresetId,
      config: data.config.present ? data.config.value : this.config,
      landingTableId: data.landingTableId.present
          ? data.landingTableId.value
          : this.landingTableId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContestConfigurationRevisionData(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('revisionNumber: $revisionNumber, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('sourcePresetId: $sourcePresetId, ')
          ..write('config: $config, ')
          ..write('landingTableId: $landingTableId, ')
          ..write('createdBy: $createdBy, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contestId,
    revisionNumber,
    disciplineProfileId,
    sourcePresetId,
    config,
    landingTableId,
    createdBy,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContestConfigurationRevisionData &&
          other.id == this.id &&
          other.contestId == this.contestId &&
          other.revisionNumber == this.revisionNumber &&
          other.disciplineProfileId == this.disciplineProfileId &&
          other.sourcePresetId == this.sourcePresetId &&
          other.config == this.config &&
          other.landingTableId == this.landingTableId &&
          other.createdBy == this.createdBy &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class ContestConfigurationRevisionsCompanion
    extends UpdateCompanion<ContestConfigurationRevisionData> {
  final Value<String> id;
  final Value<String> contestId;
  final Value<int> revisionNumber;
  final Value<String> disciplineProfileId;
  final Value<String?> sourcePresetId;
  final Value<String> config;
  final Value<String?> landingTableId;
  final Value<String> createdBy;
  final Value<String?> notes;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ContestConfigurationRevisionsCompanion({
    this.id = const Value.absent(),
    this.contestId = const Value.absent(),
    this.revisionNumber = const Value.absent(),
    this.disciplineProfileId = const Value.absent(),
    this.sourcePresetId = const Value.absent(),
    this.config = const Value.absent(),
    this.landingTableId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContestConfigurationRevisionsCompanion.insert({
    required String id,
    required String contestId,
    required int revisionNumber,
    required String disciplineProfileId,
    this.sourcePresetId = const Value.absent(),
    required String config,
    this.landingTableId = const Value.absent(),
    required String createdBy,
    this.notes = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contestId = Value(contestId),
       revisionNumber = Value(revisionNumber),
       disciplineProfileId = Value(disciplineProfileId),
       config = Value(config),
       createdBy = Value(createdBy),
       createdAt = Value(createdAt);
  static Insertable<ContestConfigurationRevisionData> custom({
    Expression<String>? id,
    Expression<String>? contestId,
    Expression<int>? revisionNumber,
    Expression<String>? disciplineProfileId,
    Expression<String>? sourcePresetId,
    Expression<String>? config,
    Expression<String>? landingTableId,
    Expression<String>? createdBy,
    Expression<String>? notes,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contestId != null) 'contest_id': contestId,
      if (revisionNumber != null) 'revision_number': revisionNumber,
      if (disciplineProfileId != null)
        'discipline_profile_id': disciplineProfileId,
      if (sourcePresetId != null) 'source_preset_id': sourcePresetId,
      if (config != null) 'config': config,
      if (landingTableId != null) 'landing_table_id': landingTableId,
      if (createdBy != null) 'created_by': createdBy,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContestConfigurationRevisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? contestId,
    Value<int>? revisionNumber,
    Value<String>? disciplineProfileId,
    Value<String?>? sourcePresetId,
    Value<String>? config,
    Value<String?>? landingTableId,
    Value<String>? createdBy,
    Value<String?>? notes,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return ContestConfigurationRevisionsCompanion(
      id: id ?? this.id,
      contestId: contestId ?? this.contestId,
      revisionNumber: revisionNumber ?? this.revisionNumber,
      disciplineProfileId: disciplineProfileId ?? this.disciplineProfileId,
      sourcePresetId: sourcePresetId ?? this.sourcePresetId,
      config: config ?? this.config,
      landingTableId: landingTableId ?? this.landingTableId,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (revisionNumber.present) {
      map['revision_number'] = Variable<int>(revisionNumber.value);
    }
    if (disciplineProfileId.present) {
      map['discipline_profile_id'] = Variable<String>(
        disciplineProfileId.value,
      );
    }
    if (sourcePresetId.present) {
      map['source_preset_id'] = Variable<String>(sourcePresetId.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (landingTableId.present) {
      map['landing_table_id'] = Variable<String>(landingTableId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContestConfigurationRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('revisionNumber: $revisionNumber, ')
          ..write('disciplineProfileId: $disciplineProfileId, ')
          ..write('sourcePresetId: $sourcePresetId, ')
          ..write('config: $config, ')
          ..write('landingTableId: $landingTableId, ')
          ..write('createdBy: $createdBy, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParticipantProfilesTable extends ParticipantProfiles
    with TableInfo<$ParticipantProfilesTable, ParticipantProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParticipantProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubMeta = const VerificationMeta('club');
  @override
  late final GeneratedColumn<String> club = GeneratedColumn<String>(
    'club',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _faiNumberMeta = const VerificationMeta(
    'faiNumber',
  );
  @override
  late final GeneratedColumn<String> faiNumber = GeneratedColumn<String>(
    'fai_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nationalOrgIdMeta = const VerificationMeta(
    'nationalOrgId',
  );
  @override
  late final GeneratedColumn<String> nationalOrgId = GeneratedColumn<String>(
    'national_org_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerAccountId,
    firstName,
    lastName,
    club,
    faiNumber,
    nationalOrgId,
    city,
    state,
    country,
    email,
    createdAt,
    updatedAt,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'participant_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ParticipantProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerAccountIdMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('club')) {
      context.handle(
        _clubMeta,
        club.isAcceptableOrUnknown(data['club']!, _clubMeta),
      );
    }
    if (data.containsKey('fai_number')) {
      context.handle(
        _faiNumberMeta,
        faiNumber.isAcceptableOrUnknown(data['fai_number']!, _faiNumberMeta),
      );
    }
    if (data.containsKey('national_org_id')) {
      context.handle(
        _nationalOrgIdMeta,
        nationalOrgId.isAcceptableOrUnknown(
          data['national_org_id']!,
          _nationalOrgIdMeta,
        ),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ParticipantProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParticipantProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      club: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club'],
      ),
      faiNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fai_number'],
      ),
      nationalOrgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}national_org_id'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $ParticipantProfilesTable createAlias(String alias) {
    return $ParticipantProfilesTable(attachedDatabase, alias);
  }
}

class ParticipantProfileData extends DataClass
    implements Insertable<ParticipantProfileData> {
  final String id;
  final String ownerAccountId;
  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? state;
  final String? country;
  final String? email;
  final String createdAt;
  final String updatedAt;
  final int revision;
  const ParticipantProfileData({
    required this.id,
    required this.ownerAccountId,
    required this.firstName,
    required this.lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.city,
    this.state,
    this.country,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_account_id'] = Variable<String>(ownerAccountId);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    if (!nullToAbsent || club != null) {
      map['club'] = Variable<String>(club);
    }
    if (!nullToAbsent || faiNumber != null) {
      map['fai_number'] = Variable<String>(faiNumber);
    }
    if (!nullToAbsent || nationalOrgId != null) {
      map['national_org_id'] = Variable<String>(nationalOrgId);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  ParticipantProfilesCompanion toCompanion(bool nullToAbsent) {
    return ParticipantProfilesCompanion(
      id: Value(id),
      ownerAccountId: Value(ownerAccountId),
      firstName: Value(firstName),
      lastName: Value(lastName),
      club: club == null && nullToAbsent ? const Value.absent() : Value(club),
      faiNumber: faiNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(faiNumber),
      nationalOrgId: nationalOrgId == null && nullToAbsent
          ? const Value.absent()
          : Value(nationalOrgId),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
    );
  }

  factory ParticipantProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParticipantProfileData(
      id: serializer.fromJson<String>(json['id']),
      ownerAccountId: serializer.fromJson<String>(json['ownerAccountId']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      club: serializer.fromJson<String?>(json['club']),
      faiNumber: serializer.fromJson<String?>(json['faiNumber']),
      nationalOrgId: serializer.fromJson<String?>(json['nationalOrgId']),
      city: serializer.fromJson<String?>(json['city']),
      state: serializer.fromJson<String?>(json['state']),
      country: serializer.fromJson<String?>(json['country']),
      email: serializer.fromJson<String?>(json['email']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerAccountId': serializer.toJson<String>(ownerAccountId),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'club': serializer.toJson<String?>(club),
      'faiNumber': serializer.toJson<String?>(faiNumber),
      'nationalOrgId': serializer.toJson<String?>(nationalOrgId),
      'city': serializer.toJson<String?>(city),
      'state': serializer.toJson<String?>(state),
      'country': serializer.toJson<String?>(country),
      'email': serializer.toJson<String?>(email),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  ParticipantProfileData copyWith({
    String? id,
    String? ownerAccountId,
    String? firstName,
    String? lastName,
    Value<String?> club = const Value.absent(),
    Value<String?> faiNumber = const Value.absent(),
    Value<String?> nationalOrgId = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> state = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<String?> email = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    int? revision,
  }) => ParticipantProfileData(
    id: id ?? this.id,
    ownerAccountId: ownerAccountId ?? this.ownerAccountId,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    club: club.present ? club.value : this.club,
    faiNumber: faiNumber.present ? faiNumber.value : this.faiNumber,
    nationalOrgId: nationalOrgId.present
        ? nationalOrgId.value
        : this.nationalOrgId,
    city: city.present ? city.value : this.city,
    state: state.present ? state.value : this.state,
    country: country.present ? country.value : this.country,
    email: email.present ? email.value : this.email,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
  );
  ParticipantProfileData copyWithCompanion(ParticipantProfilesCompanion data) {
    return ParticipantProfileData(
      id: data.id.present ? data.id.value : this.id,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      club: data.club.present ? data.club.value : this.club,
      faiNumber: data.faiNumber.present ? data.faiNumber.value : this.faiNumber,
      nationalOrgId: data.nationalOrgId.present
          ? data.nationalOrgId.value
          : this.nationalOrgId,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      country: data.country.present ? data.country.value : this.country,
      email: data.email.present ? data.email.value : this.email,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParticipantProfileData(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('club: $club, ')
          ..write('faiNumber: $faiNumber, ')
          ..write('nationalOrgId: $nationalOrgId, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('country: $country, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerAccountId,
    firstName,
    lastName,
    club,
    faiNumber,
    nationalOrgId,
    city,
    state,
    country,
    email,
    createdAt,
    updatedAt,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParticipantProfileData &&
          other.id == this.id &&
          other.ownerAccountId == this.ownerAccountId &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.club == this.club &&
          other.faiNumber == this.faiNumber &&
          other.nationalOrgId == this.nationalOrgId &&
          other.city == this.city &&
          other.state == this.state &&
          other.country == this.country &&
          other.email == this.email &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision);
}

class ParticipantProfilesCompanion
    extends UpdateCompanion<ParticipantProfileData> {
  final Value<String> id;
  final Value<String> ownerAccountId;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String?> club;
  final Value<String?> faiNumber;
  final Value<String?> nationalOrgId;
  final Value<String?> city;
  final Value<String?> state;
  final Value<String?> country;
  final Value<String?> email;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const ParticipantProfilesCompanion({
    this.id = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.club = const Value.absent(),
    this.faiNumber = const Value.absent(),
    this.nationalOrgId = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.country = const Value.absent(),
    this.email = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParticipantProfilesCompanion.insert({
    required String id,
    required String ownerAccountId,
    required String firstName,
    required String lastName,
    this.club = const Value.absent(),
    this.faiNumber = const Value.absent(),
    this.nationalOrgId = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.country = const Value.absent(),
    this.email = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerAccountId = Value(ownerAccountId),
       firstName = Value(firstName),
       lastName = Value(lastName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ParticipantProfileData> custom({
    Expression<String>? id,
    Expression<String>? ownerAccountId,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? club,
    Expression<String>? faiNumber,
    Expression<String>? nationalOrgId,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? country,
    Expression<String>? email,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (club != null) 'club': club,
      if (faiNumber != null) 'fai_number': faiNumber,
      if (nationalOrgId != null) 'national_org_id': nationalOrgId,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParticipantProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerAccountId,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String?>? club,
    Value<String?>? faiNumber,
    Value<String?>? nationalOrgId,
    Value<String?>? city,
    Value<String?>? state,
    Value<String?>? country,
    Value<String?>? email,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return ParticipantProfilesCompanion(
      id: id ?? this.id,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      club: club ?? this.club,
      faiNumber: faiNumber ?? this.faiNumber,
      nationalOrgId: nationalOrgId ?? this.nationalOrgId,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (club.present) {
      map['club'] = Variable<String>(club.value);
    }
    if (faiNumber.present) {
      map['fai_number'] = Variable<String>(faiNumber.value);
    }
    if (nationalOrgId.present) {
      map['national_org_id'] = Variable<String>(nationalOrgId.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParticipantProfilesCompanion(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('club: $club, ')
          ..write('faiNumber: $faiNumber, ')
          ..write('nationalOrgId: $nationalOrgId, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('country: $country, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolesTable extends Roles with TableInfo<$RolesTable, RoleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    check: () => type.isIn(roleTypeValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<String> archivedAt = GeneratedColumn<String>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerAccountId,
    displayName,
    type,
    archivedAt,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'roles';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoleData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archived_at'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $RolesTable createAlias(String alias) {
    return $RolesTable(attachedDatabase, alias);
  }
}

class RoleData extends DataClass implements Insertable<RoleData> {
  final String id;
  final String? ownerAccountId;
  final String displayName;
  final String type;
  final String? archivedAt;
  final int revision;
  const RoleData({
    required this.id,
    this.ownerAccountId,
    required this.displayName,
    required this.type,
    this.archivedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ownerAccountId != null) {
      map['owner_account_id'] = Variable<String>(ownerAccountId);
    }
    map['display_name'] = Variable<String>(displayName);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<String>(archivedAt);
    }
    map['revision'] = Variable<int>(revision);
    return map;
  }

  RolesCompanion toCompanion(bool nullToAbsent) {
    return RolesCompanion(
      id: Value(id),
      ownerAccountId: ownerAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerAccountId),
      displayName: Value(displayName),
      type: Value(type),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      revision: Value(revision),
    );
  }

  factory RoleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoleData(
      id: serializer.fromJson<String>(json['id']),
      ownerAccountId: serializer.fromJson<String?>(json['ownerAccountId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      type: serializer.fromJson<String>(json['type']),
      archivedAt: serializer.fromJson<String?>(json['archivedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerAccountId': serializer.toJson<String?>(ownerAccountId),
      'displayName': serializer.toJson<String>(displayName),
      'type': serializer.toJson<String>(type),
      'archivedAt': serializer.toJson<String?>(archivedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  RoleData copyWith({
    String? id,
    Value<String?> ownerAccountId = const Value.absent(),
    String? displayName,
    String? type,
    Value<String?> archivedAt = const Value.absent(),
    int? revision,
  }) => RoleData(
    id: id ?? this.id,
    ownerAccountId: ownerAccountId.present
        ? ownerAccountId.value
        : this.ownerAccountId,
    displayName: displayName ?? this.displayName,
    type: type ?? this.type,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    revision: revision ?? this.revision,
  );
  RoleData copyWithCompanion(RolesCompanion data) {
    return RoleData(
      id: data.id.present ? data.id.value : this.id,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      type: data.type.present ? data.type.value : this.type,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoleData(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('displayName: $displayName, ')
          ..write('type: $type, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ownerAccountId, displayName, type, archivedAt, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoleData &&
          other.id == this.id &&
          other.ownerAccountId == this.ownerAccountId &&
          other.displayName == this.displayName &&
          other.type == this.type &&
          other.archivedAt == this.archivedAt &&
          other.revision == this.revision);
}

class RolesCompanion extends UpdateCompanion<RoleData> {
  final Value<String> id;
  final Value<String?> ownerAccountId;
  final Value<String> displayName;
  final Value<String> type;
  final Value<String?> archivedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const RolesCompanion({
    this.id = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.type = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolesCompanion.insert({
    required String id,
    this.ownerAccountId = const Value.absent(),
    required String displayName,
    required String type,
    this.archivedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       type = Value(type);
  static Insertable<RoleData> custom({
    Expression<String>? id,
    Expression<String>? ownerAccountId,
    Expression<String>? displayName,
    Expression<String>? type,
    Expression<String>? archivedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (displayName != null) 'display_name': displayName,
      if (type != null) 'type': type,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolesCompanion copyWith({
    Value<String>? id,
    Value<String?>? ownerAccountId,
    Value<String>? displayName,
    Value<String>? type,
    Value<String?>? archivedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return RolesCompanion(
      id: id ?? this.id,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      archivedAt: archivedAt ?? this.archivedAt,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<String>(archivedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RolesCompanion(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('displayName: $displayName, ')
          ..write('type: $type, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContestParticipationsTable extends ContestParticipations
    with TableInfo<$ContestParticipationsTable, ContestParticipationData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContestParticipationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contests (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _participantProfileIdMeta =
      const VerificationMeta('participantProfileId');
  @override
  late final GeneratedColumn<String> participantProfileId =
      GeneratedColumn<String>(
        'participant_profile_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES participant_profiles (id)',
        ),
      );
  static const VerificationMeta _classificationMeta = const VerificationMeta(
    'classification',
  );
  @override
  late final GeneratedColumn<String> classification = GeneratedColumn<String>(
    'classification',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES roles (id)',
    ),
  );
  static const VerificationMeta _roleNameMeta = const VerificationMeta(
    'roleName',
  );
  @override
  late final GeneratedColumn<String> roleName = GeneratedColumn<String>(
    'role_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleTypeMeta = const VerificationMeta(
    'roleType',
  );
  @override
  late final GeneratedColumn<String> roleType = GeneratedColumn<String>(
    'role_type',
    aliasedName,
    false,
    check: () => roleType.isIn(roleTypeValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantNumberMeta = const VerificationMeta(
    'participantNumber',
  );
  @override
  late final GeneratedColumn<int> participantNumber = GeneratedColumn<int>(
    'participant_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoringUuidMeta = const VerificationMeta(
    'scoringUuid',
  );
  @override
  late final GeneratedColumn<String> scoringUuid = GeneratedColumn<String>(
    'scoring_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retiredAtRoundMeta = const VerificationMeta(
    'retiredAtRound',
  );
  @override
  late final GeneratedColumn<int> retiredAtRound = GeneratedColumn<int>(
    'retired_at_round',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contestId,
    participantProfileId,
    classification,
    roleId,
    roleName,
    roleType,
    participantNumber,
    scoringUuid,
    retiredAtRound,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contest_participations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContestParticipationData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contestIdMeta);
    }
    if (data.containsKey('participant_profile_id')) {
      context.handle(
        _participantProfileIdMeta,
        participantProfileId.isAcceptableOrUnknown(
          data['participant_profile_id']!,
          _participantProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantProfileIdMeta);
    }
    if (data.containsKey('classification')) {
      context.handle(
        _classificationMeta,
        classification.isAcceptableOrUnknown(
          data['classification']!,
          _classificationMeta,
        ),
      );
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('role_name')) {
      context.handle(
        _roleNameMeta,
        roleName.isAcceptableOrUnknown(data['role_name']!, _roleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_roleNameMeta);
    }
    if (data.containsKey('role_type')) {
      context.handle(
        _roleTypeMeta,
        roleType.isAcceptableOrUnknown(data['role_type']!, _roleTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_roleTypeMeta);
    }
    if (data.containsKey('participant_number')) {
      context.handle(
        _participantNumberMeta,
        participantNumber.isAcceptableOrUnknown(
          data['participant_number']!,
          _participantNumberMeta,
        ),
      );
    }
    if (data.containsKey('scoring_uuid')) {
      context.handle(
        _scoringUuidMeta,
        scoringUuid.isAcceptableOrUnknown(
          data['scoring_uuid']!,
          _scoringUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoringUuidMeta);
    }
    if (data.containsKey('retired_at_round')) {
      context.handle(
        _retiredAtRoundMeta,
        retiredAtRound.isAcceptableOrUnknown(
          data['retired_at_round']!,
          _retiredAtRoundMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {contestId, participantNumber},
    {contestId, scoringUuid},
    {contestId, participantProfileId},
  ];
  @override
  ContestParticipationData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContestParticipationData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      )!,
      participantProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_profile_id'],
      )!,
      classification: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classification'],
      ),
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      )!,
      roleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_name'],
      )!,
      roleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_type'],
      )!,
      participantNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}participant_number'],
      ),
      scoringUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_uuid'],
      )!,
      retiredAtRound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retired_at_round'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $ContestParticipationsTable createAlias(String alias) {
    return $ContestParticipationsTable(attachedDatabase, alias);
  }
}

class ContestParticipationData extends DataClass
    implements Insertable<ContestParticipationData> {
  final String id;
  final String contestId;
  final String participantProfileId;
  final String? classification;
  final String roleId;
  final String roleName;
  final String roleType;
  final int? participantNumber;
  final String scoringUuid;
  final int? retiredAtRound;
  final int revision;
  const ContestParticipationData({
    required this.id,
    required this.contestId,
    required this.participantProfileId,
    this.classification,
    required this.roleId,
    required this.roleName,
    required this.roleType,
    this.participantNumber,
    required this.scoringUuid,
    this.retiredAtRound,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contest_id'] = Variable<String>(contestId);
    map['participant_profile_id'] = Variable<String>(participantProfileId);
    if (!nullToAbsent || classification != null) {
      map['classification'] = Variable<String>(classification);
    }
    map['role_id'] = Variable<String>(roleId);
    map['role_name'] = Variable<String>(roleName);
    map['role_type'] = Variable<String>(roleType);
    if (!nullToAbsent || participantNumber != null) {
      map['participant_number'] = Variable<int>(participantNumber);
    }
    map['scoring_uuid'] = Variable<String>(scoringUuid);
    if (!nullToAbsent || retiredAtRound != null) {
      map['retired_at_round'] = Variable<int>(retiredAtRound);
    }
    map['revision'] = Variable<int>(revision);
    return map;
  }

  ContestParticipationsCompanion toCompanion(bool nullToAbsent) {
    return ContestParticipationsCompanion(
      id: Value(id),
      contestId: Value(contestId),
      participantProfileId: Value(participantProfileId),
      classification: classification == null && nullToAbsent
          ? const Value.absent()
          : Value(classification),
      roleId: Value(roleId),
      roleName: Value(roleName),
      roleType: Value(roleType),
      participantNumber: participantNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(participantNumber),
      scoringUuid: Value(scoringUuid),
      retiredAtRound: retiredAtRound == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredAtRound),
      revision: Value(revision),
    );
  }

  factory ContestParticipationData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContestParticipationData(
      id: serializer.fromJson<String>(json['id']),
      contestId: serializer.fromJson<String>(json['contestId']),
      participantProfileId: serializer.fromJson<String>(
        json['participantProfileId'],
      ),
      classification: serializer.fromJson<String?>(json['classification']),
      roleId: serializer.fromJson<String>(json['roleId']),
      roleName: serializer.fromJson<String>(json['roleName']),
      roleType: serializer.fromJson<String>(json['roleType']),
      participantNumber: serializer.fromJson<int?>(json['participantNumber']),
      scoringUuid: serializer.fromJson<String>(json['scoringUuid']),
      retiredAtRound: serializer.fromJson<int?>(json['retiredAtRound']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contestId': serializer.toJson<String>(contestId),
      'participantProfileId': serializer.toJson<String>(participantProfileId),
      'classification': serializer.toJson<String?>(classification),
      'roleId': serializer.toJson<String>(roleId),
      'roleName': serializer.toJson<String>(roleName),
      'roleType': serializer.toJson<String>(roleType),
      'participantNumber': serializer.toJson<int?>(participantNumber),
      'scoringUuid': serializer.toJson<String>(scoringUuid),
      'retiredAtRound': serializer.toJson<int?>(retiredAtRound),
      'revision': serializer.toJson<int>(revision),
    };
  }

  ContestParticipationData copyWith({
    String? id,
    String? contestId,
    String? participantProfileId,
    Value<String?> classification = const Value.absent(),
    String? roleId,
    String? roleName,
    String? roleType,
    Value<int?> participantNumber = const Value.absent(),
    String? scoringUuid,
    Value<int?> retiredAtRound = const Value.absent(),
    int? revision,
  }) => ContestParticipationData(
    id: id ?? this.id,
    contestId: contestId ?? this.contestId,
    participantProfileId: participantProfileId ?? this.participantProfileId,
    classification: classification.present
        ? classification.value
        : this.classification,
    roleId: roleId ?? this.roleId,
    roleName: roleName ?? this.roleName,
    roleType: roleType ?? this.roleType,
    participantNumber: participantNumber.present
        ? participantNumber.value
        : this.participantNumber,
    scoringUuid: scoringUuid ?? this.scoringUuid,
    retiredAtRound: retiredAtRound.present
        ? retiredAtRound.value
        : this.retiredAtRound,
    revision: revision ?? this.revision,
  );
  ContestParticipationData copyWithCompanion(
    ContestParticipationsCompanion data,
  ) {
    return ContestParticipationData(
      id: data.id.present ? data.id.value : this.id,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      participantProfileId: data.participantProfileId.present
          ? data.participantProfileId.value
          : this.participantProfileId,
      classification: data.classification.present
          ? data.classification.value
          : this.classification,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      roleName: data.roleName.present ? data.roleName.value : this.roleName,
      roleType: data.roleType.present ? data.roleType.value : this.roleType,
      participantNumber: data.participantNumber.present
          ? data.participantNumber.value
          : this.participantNumber,
      scoringUuid: data.scoringUuid.present
          ? data.scoringUuid.value
          : this.scoringUuid,
      retiredAtRound: data.retiredAtRound.present
          ? data.retiredAtRound.value
          : this.retiredAtRound,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContestParticipationData(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('participantProfileId: $participantProfileId, ')
          ..write('classification: $classification, ')
          ..write('roleId: $roleId, ')
          ..write('roleName: $roleName, ')
          ..write('roleType: $roleType, ')
          ..write('participantNumber: $participantNumber, ')
          ..write('scoringUuid: $scoringUuid, ')
          ..write('retiredAtRound: $retiredAtRound, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contestId,
    participantProfileId,
    classification,
    roleId,
    roleName,
    roleType,
    participantNumber,
    scoringUuid,
    retiredAtRound,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContestParticipationData &&
          other.id == this.id &&
          other.contestId == this.contestId &&
          other.participantProfileId == this.participantProfileId &&
          other.classification == this.classification &&
          other.roleId == this.roleId &&
          other.roleName == this.roleName &&
          other.roleType == this.roleType &&
          other.participantNumber == this.participantNumber &&
          other.scoringUuid == this.scoringUuid &&
          other.retiredAtRound == this.retiredAtRound &&
          other.revision == this.revision);
}

class ContestParticipationsCompanion
    extends UpdateCompanion<ContestParticipationData> {
  final Value<String> id;
  final Value<String> contestId;
  final Value<String> participantProfileId;
  final Value<String?> classification;
  final Value<String> roleId;
  final Value<String> roleName;
  final Value<String> roleType;
  final Value<int?> participantNumber;
  final Value<String> scoringUuid;
  final Value<int?> retiredAtRound;
  final Value<int> revision;
  final Value<int> rowid;
  const ContestParticipationsCompanion({
    this.id = const Value.absent(),
    this.contestId = const Value.absent(),
    this.participantProfileId = const Value.absent(),
    this.classification = const Value.absent(),
    this.roleId = const Value.absent(),
    this.roleName = const Value.absent(),
    this.roleType = const Value.absent(),
    this.participantNumber = const Value.absent(),
    this.scoringUuid = const Value.absent(),
    this.retiredAtRound = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContestParticipationsCompanion.insert({
    required String id,
    required String contestId,
    required String participantProfileId,
    this.classification = const Value.absent(),
    required String roleId,
    required String roleName,
    required String roleType,
    this.participantNumber = const Value.absent(),
    required String scoringUuid,
    this.retiredAtRound = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contestId = Value(contestId),
       participantProfileId = Value(participantProfileId),
       roleId = Value(roleId),
       roleName = Value(roleName),
       roleType = Value(roleType),
       scoringUuid = Value(scoringUuid);
  static Insertable<ContestParticipationData> custom({
    Expression<String>? id,
    Expression<String>? contestId,
    Expression<String>? participantProfileId,
    Expression<String>? classification,
    Expression<String>? roleId,
    Expression<String>? roleName,
    Expression<String>? roleType,
    Expression<int>? participantNumber,
    Expression<String>? scoringUuid,
    Expression<int>? retiredAtRound,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contestId != null) 'contest_id': contestId,
      if (participantProfileId != null)
        'participant_profile_id': participantProfileId,
      if (classification != null) 'classification': classification,
      if (roleId != null) 'role_id': roleId,
      if (roleName != null) 'role_name': roleName,
      if (roleType != null) 'role_type': roleType,
      if (participantNumber != null) 'participant_number': participantNumber,
      if (scoringUuid != null) 'scoring_uuid': scoringUuid,
      if (retiredAtRound != null) 'retired_at_round': retiredAtRound,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContestParticipationsCompanion copyWith({
    Value<String>? id,
    Value<String>? contestId,
    Value<String>? participantProfileId,
    Value<String?>? classification,
    Value<String>? roleId,
    Value<String>? roleName,
    Value<String>? roleType,
    Value<int?>? participantNumber,
    Value<String>? scoringUuid,
    Value<int?>? retiredAtRound,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return ContestParticipationsCompanion(
      id: id ?? this.id,
      contestId: contestId ?? this.contestId,
      participantProfileId: participantProfileId ?? this.participantProfileId,
      classification: classification ?? this.classification,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      roleType: roleType ?? this.roleType,
      participantNumber: participantNumber ?? this.participantNumber,
      scoringUuid: scoringUuid ?? this.scoringUuid,
      retiredAtRound: retiredAtRound ?? this.retiredAtRound,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (participantProfileId.present) {
      map['participant_profile_id'] = Variable<String>(
        participantProfileId.value,
      );
    }
    if (classification.present) {
      map['classification'] = Variable<String>(classification.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (roleName.present) {
      map['role_name'] = Variable<String>(roleName.value);
    }
    if (roleType.present) {
      map['role_type'] = Variable<String>(roleType.value);
    }
    if (participantNumber.present) {
      map['participant_number'] = Variable<int>(participantNumber.value);
    }
    if (scoringUuid.present) {
      map['scoring_uuid'] = Variable<String>(scoringUuid.value);
    }
    if (retiredAtRound.present) {
      map['retired_at_round'] = Variable<int>(retiredAtRound.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContestParticipationsCompanion(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('participantProfileId: $participantProfileId, ')
          ..write('classification: $classification, ')
          ..write('roleId: $roleId, ')
          ..write('roleName: $roleName, ')
          ..write('roleType: $roleType, ')
          ..write('participantNumber: $participantNumber, ')
          ..write('scoringUuid: $scoringUuid, ')
          ..write('retiredAtRound: $retiredAtRound, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, TeamData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contests (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, contestId, name, revision];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contestIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {contestId, name},
  ];
  @override
  TeamData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class TeamData extends DataClass implements Insertable<TeamData> {
  final String id;
  final String contestId;
  final String name;
  final int revision;
  const TeamData({
    required this.id,
    required this.contestId,
    required this.name,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contest_id'] = Variable<String>(contestId);
    map['name'] = Variable<String>(name);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      contestId: Value(contestId),
      name: Value(name),
      revision: Value(revision),
    );
  }

  factory TeamData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamData(
      id: serializer.fromJson<String>(json['id']),
      contestId: serializer.fromJson<String>(json['contestId']),
      name: serializer.fromJson<String>(json['name']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contestId': serializer.toJson<String>(contestId),
      'name': serializer.toJson<String>(name),
      'revision': serializer.toJson<int>(revision),
    };
  }

  TeamData copyWith({
    String? id,
    String? contestId,
    String? name,
    int? revision,
  }) => TeamData(
    id: id ?? this.id,
    contestId: contestId ?? this.contestId,
    name: name ?? this.name,
    revision: revision ?? this.revision,
  );
  TeamData copyWithCompanion(TeamsCompanion data) {
    return TeamData(
      id: data.id.present ? data.id.value : this.id,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      name: data.name.present ? data.name.value : this.name,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamData(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('name: $name, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, contestId, name, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamData &&
          other.id == this.id &&
          other.contestId == this.contestId &&
          other.name == this.name &&
          other.revision == this.revision);
}

class TeamsCompanion extends UpdateCompanion<TeamData> {
  final Value<String> id;
  final Value<String> contestId;
  final Value<String> name;
  final Value<int> revision;
  final Value<int> rowid;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.contestId = const Value.absent(),
    this.name = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamsCompanion.insert({
    required String id,
    required String contestId,
    required String name,
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contestId = Value(contestId),
       name = Value(name);
  static Insertable<TeamData> custom({
    Expression<String>? id,
    Expression<String>? contestId,
    Expression<String>? name,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contestId != null) 'contest_id': contestId,
      if (name != null) 'name': name,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamsCompanion copyWith({
    Value<String>? id,
    Value<String>? contestId,
    Value<String>? name,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return TeamsCompanion(
      id: id ?? this.id,
      contestId: contestId ?? this.contestId,
      name: name ?? this.name,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('name: $name, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamMembershipsTable extends TeamMemberships
    with TableInfo<$TeamMembershipsTable, TeamMembershipData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamMembershipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id)',
    ),
  );
  static const VerificationMeta _contestParticipationIdMeta =
      const VerificationMeta('contestParticipationId');
  @override
  late final GeneratedColumn<String> contestParticipationId =
      GeneratedColumn<String>(
        'contest_participation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contest_participations (id)',
        ),
      );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contests (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamId,
    contestParticipationId,
    contestId,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_memberships';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamMembershipData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('contest_participation_id')) {
      context.handle(
        _contestParticipationIdMeta,
        contestParticipationId.isAcceptableOrUnknown(
          data['contest_participation_id']!,
          _contestParticipationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contestParticipationIdMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contestIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {teamId, contestParticipationId},
  ];
  @override
  TeamMembershipData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamMembershipData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      contestParticipationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_participation_id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $TeamMembershipsTable createAlias(String alias) {
    return $TeamMembershipsTable(attachedDatabase, alias);
  }
}

class TeamMembershipData extends DataClass
    implements Insertable<TeamMembershipData> {
  final String id;
  final String teamId;
  final String contestParticipationId;
  final String contestId;
  final int revision;
  const TeamMembershipData({
    required this.id,
    required this.teamId,
    required this.contestParticipationId,
    required this.contestId,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_id'] = Variable<String>(teamId);
    map['contest_participation_id'] = Variable<String>(contestParticipationId);
    map['contest_id'] = Variable<String>(contestId);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  TeamMembershipsCompanion toCompanion(bool nullToAbsent) {
    return TeamMembershipsCompanion(
      id: Value(id),
      teamId: Value(teamId),
      contestParticipationId: Value(contestParticipationId),
      contestId: Value(contestId),
      revision: Value(revision),
    );
  }

  factory TeamMembershipData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamMembershipData(
      id: serializer.fromJson<String>(json['id']),
      teamId: serializer.fromJson<String>(json['teamId']),
      contestParticipationId: serializer.fromJson<String>(
        json['contestParticipationId'],
      ),
      contestId: serializer.fromJson<String>(json['contestId']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teamId': serializer.toJson<String>(teamId),
      'contestParticipationId': serializer.toJson<String>(
        contestParticipationId,
      ),
      'contestId': serializer.toJson<String>(contestId),
      'revision': serializer.toJson<int>(revision),
    };
  }

  TeamMembershipData copyWith({
    String? id,
    String? teamId,
    String? contestParticipationId,
    String? contestId,
    int? revision,
  }) => TeamMembershipData(
    id: id ?? this.id,
    teamId: teamId ?? this.teamId,
    contestParticipationId:
        contestParticipationId ?? this.contestParticipationId,
    contestId: contestId ?? this.contestId,
    revision: revision ?? this.revision,
  );
  TeamMembershipData copyWithCompanion(TeamMembershipsCompanion data) {
    return TeamMembershipData(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      contestParticipationId: data.contestParticipationId.present
          ? data.contestParticipationId.value
          : this.contestParticipationId,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamMembershipData(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('contestParticipationId: $contestParticipationId, ')
          ..write('contestId: $contestId, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, teamId, contestParticipationId, contestId, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamMembershipData &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.contestParticipationId == this.contestParticipationId &&
          other.contestId == this.contestId &&
          other.revision == this.revision);
}

class TeamMembershipsCompanion extends UpdateCompanion<TeamMembershipData> {
  final Value<String> id;
  final Value<String> teamId;
  final Value<String> contestParticipationId;
  final Value<String> contestId;
  final Value<int> revision;
  final Value<int> rowid;
  const TeamMembershipsCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.contestParticipationId = const Value.absent(),
    this.contestId = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamMembershipsCompanion.insert({
    required String id,
    required String teamId,
    required String contestParticipationId,
    required String contestId,
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teamId = Value(teamId),
       contestParticipationId = Value(contestParticipationId),
       contestId = Value(contestId);
  static Insertable<TeamMembershipData> custom({
    Expression<String>? id,
    Expression<String>? teamId,
    Expression<String>? contestParticipationId,
    Expression<String>? contestId,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (contestParticipationId != null)
        'contest_participation_id': contestParticipationId,
      if (contestId != null) 'contest_id': contestId,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamMembershipsCompanion copyWith({
    Value<String>? id,
    Value<String>? teamId,
    Value<String>? contestParticipationId,
    Value<String>? contestId,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return TeamMembershipsCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      contestParticipationId:
          contestParticipationId ?? this.contestParticipationId,
      contestId: contestId ?? this.contestId,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (contestParticipationId.present) {
      map['contest_participation_id'] = Variable<String>(
        contestParticipationId.value,
      );
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamMembershipsCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('contestParticipationId: $contestParticipationId, ')
          ..write('contestId: $contestId, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelCatalogsTable extends ModelCatalogs
    with TableInfo<$ModelCatalogsTable, ModelCatalogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelCatalogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
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
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerAccountId,
    name,
    manufacturer,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_catalogs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModelCatalogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerAccountIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModelCatalogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelCatalogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $ModelCatalogsTable createAlias(String alias) {
    return $ModelCatalogsTable(attachedDatabase, alias);
  }
}

class ModelCatalogData extends DataClass
    implements Insertable<ModelCatalogData> {
  final String id;
  final String ownerAccountId;
  final String name;
  final String? manufacturer;
  final int revision;
  const ModelCatalogData({
    required this.id,
    required this.ownerAccountId,
    required this.name,
    this.manufacturer,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_account_id'] = Variable<String>(ownerAccountId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    map['revision'] = Variable<int>(revision);
    return map;
  }

  ModelCatalogsCompanion toCompanion(bool nullToAbsent) {
    return ModelCatalogsCompanion(
      id: Value(id),
      ownerAccountId: Value(ownerAccountId),
      name: Value(name),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      revision: Value(revision),
    );
  }

  factory ModelCatalogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelCatalogData(
      id: serializer.fromJson<String>(json['id']),
      ownerAccountId: serializer.fromJson<String>(json['ownerAccountId']),
      name: serializer.fromJson<String>(json['name']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerAccountId': serializer.toJson<String>(ownerAccountId),
      'name': serializer.toJson<String>(name),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'revision': serializer.toJson<int>(revision),
    };
  }

  ModelCatalogData copyWith({
    String? id,
    String? ownerAccountId,
    String? name,
    Value<String?> manufacturer = const Value.absent(),
    int? revision,
  }) => ModelCatalogData(
    id: id ?? this.id,
    ownerAccountId: ownerAccountId ?? this.ownerAccountId,
    name: name ?? this.name,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    revision: revision ?? this.revision,
  );
  ModelCatalogData copyWithCompanion(ModelCatalogsCompanion data) {
    return ModelCatalogData(
      id: data.id.present ? data.id.value : this.id,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      name: data.name.present ? data.name.value : this.name,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelCatalogData(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('name: $name, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ownerAccountId, name, manufacturer, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelCatalogData &&
          other.id == this.id &&
          other.ownerAccountId == this.ownerAccountId &&
          other.name == this.name &&
          other.manufacturer == this.manufacturer &&
          other.revision == this.revision);
}

class ModelCatalogsCompanion extends UpdateCompanion<ModelCatalogData> {
  final Value<String> id;
  final Value<String> ownerAccountId;
  final Value<String> name;
  final Value<String?> manufacturer;
  final Value<int> revision;
  final Value<int> rowid;
  const ModelCatalogsCompanion({
    this.id = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.name = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelCatalogsCompanion.insert({
    required String id,
    required String ownerAccountId,
    required String name,
    this.manufacturer = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerAccountId = Value(ownerAccountId),
       name = Value(name);
  static Insertable<ModelCatalogData> custom({
    Expression<String>? id,
    Expression<String>? ownerAccountId,
    Expression<String>? name,
    Expression<String>? manufacturer,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (name != null) 'name': name,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelCatalogsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerAccountId,
    Value<String>? name,
    Value<String?>? manufacturer,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return ModelCatalogsCompanion(
      id: id ?? this.id,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelCatalogsCompanion(')
          ..write('id: $id, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('name: $name, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContestModelLinksTable extends ContestModelLinks
    with TableInfo<$ContestModelLinksTable, ContestModelLinkData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContestModelLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contests (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contestParticipationIdMeta =
      const VerificationMeta('contestParticipationId');
  @override
  late final GeneratedColumn<String> contestParticipationId =
      GeneratedColumn<String>(
        'contest_participation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contest_participations (id)',
        ),
      );
  static const VerificationMeta _modelCatalogIdMeta = const VerificationMeta(
    'modelCatalogId',
  );
  @override
  late final GeneratedColumn<String> modelCatalogId = GeneratedColumn<String>(
    'model_catalog_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES model_catalogs (id)',
    ),
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestSpecificIdentifierMeta =
      const VerificationMeta('contestSpecificIdentifier');
  @override
  late final GeneratedColumn<String> contestSpecificIdentifier =
      GeneratedColumn<String>(
        'contest_specific_identifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contestId,
    contestParticipationId,
    modelCatalogId,
    modelName,
    manufacturer,
    modelId,
    contestSpecificIdentifier,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contest_model_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContestModelLinkData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contestIdMeta);
    }
    if (data.containsKey('contest_participation_id')) {
      context.handle(
        _contestParticipationIdMeta,
        contestParticipationId.isAcceptableOrUnknown(
          data['contest_participation_id']!,
          _contestParticipationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contestParticipationIdMeta);
    }
    if (data.containsKey('model_catalog_id')) {
      context.handle(
        _modelCatalogIdMeta,
        modelCatalogId.isAcceptableOrUnknown(
          data['model_catalog_id']!,
          _modelCatalogIdMeta,
        ),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    } else if (isInserting) {
      context.missing(_modelNameMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('contest_specific_identifier')) {
      context.handle(
        _contestSpecificIdentifierMeta,
        contestSpecificIdentifier.isAcceptableOrUnknown(
          data['contest_specific_identifier']!,
          _contestSpecificIdentifierMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContestModelLinkData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContestModelLinkData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      )!,
      contestParticipationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_participation_id'],
      )!,
      modelCatalogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_catalog_id'],
      ),
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      contestSpecificIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_specific_identifier'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $ContestModelLinksTable createAlias(String alias) {
    return $ContestModelLinksTable(attachedDatabase, alias);
  }
}

class ContestModelLinkData extends DataClass
    implements Insertable<ContestModelLinkData> {
  final String id;
  final String contestId;
  final String contestParticipationId;
  final String? modelCatalogId;
  final String modelName;
  final String? manufacturer;
  final String modelId;
  final String? contestSpecificIdentifier;
  final int revision;
  const ContestModelLinkData({
    required this.id,
    required this.contestId,
    required this.contestParticipationId,
    this.modelCatalogId,
    required this.modelName,
    this.manufacturer,
    required this.modelId,
    this.contestSpecificIdentifier,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contest_id'] = Variable<String>(contestId);
    map['contest_participation_id'] = Variable<String>(contestParticipationId);
    if (!nullToAbsent || modelCatalogId != null) {
      map['model_catalog_id'] = Variable<String>(modelCatalogId);
    }
    map['model_name'] = Variable<String>(modelName);
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    map['model_id'] = Variable<String>(modelId);
    if (!nullToAbsent || contestSpecificIdentifier != null) {
      map['contest_specific_identifier'] = Variable<String>(
        contestSpecificIdentifier,
      );
    }
    map['revision'] = Variable<int>(revision);
    return map;
  }

  ContestModelLinksCompanion toCompanion(bool nullToAbsent) {
    return ContestModelLinksCompanion(
      id: Value(id),
      contestId: Value(contestId),
      contestParticipationId: Value(contestParticipationId),
      modelCatalogId: modelCatalogId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelCatalogId),
      modelName: Value(modelName),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      modelId: Value(modelId),
      contestSpecificIdentifier:
          contestSpecificIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(contestSpecificIdentifier),
      revision: Value(revision),
    );
  }

  factory ContestModelLinkData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContestModelLinkData(
      id: serializer.fromJson<String>(json['id']),
      contestId: serializer.fromJson<String>(json['contestId']),
      contestParticipationId: serializer.fromJson<String>(
        json['contestParticipationId'],
      ),
      modelCatalogId: serializer.fromJson<String?>(json['modelCatalogId']),
      modelName: serializer.fromJson<String>(json['modelName']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      modelId: serializer.fromJson<String>(json['modelId']),
      contestSpecificIdentifier: serializer.fromJson<String?>(
        json['contestSpecificIdentifier'],
      ),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contestId': serializer.toJson<String>(contestId),
      'contestParticipationId': serializer.toJson<String>(
        contestParticipationId,
      ),
      'modelCatalogId': serializer.toJson<String?>(modelCatalogId),
      'modelName': serializer.toJson<String>(modelName),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'modelId': serializer.toJson<String>(modelId),
      'contestSpecificIdentifier': serializer.toJson<String?>(
        contestSpecificIdentifier,
      ),
      'revision': serializer.toJson<int>(revision),
    };
  }

  ContestModelLinkData copyWith({
    String? id,
    String? contestId,
    String? contestParticipationId,
    Value<String?> modelCatalogId = const Value.absent(),
    String? modelName,
    Value<String?> manufacturer = const Value.absent(),
    String? modelId,
    Value<String?> contestSpecificIdentifier = const Value.absent(),
    int? revision,
  }) => ContestModelLinkData(
    id: id ?? this.id,
    contestId: contestId ?? this.contestId,
    contestParticipationId:
        contestParticipationId ?? this.contestParticipationId,
    modelCatalogId: modelCatalogId.present
        ? modelCatalogId.value
        : this.modelCatalogId,
    modelName: modelName ?? this.modelName,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    modelId: modelId ?? this.modelId,
    contestSpecificIdentifier: contestSpecificIdentifier.present
        ? contestSpecificIdentifier.value
        : this.contestSpecificIdentifier,
    revision: revision ?? this.revision,
  );
  ContestModelLinkData copyWithCompanion(ContestModelLinksCompanion data) {
    return ContestModelLinkData(
      id: data.id.present ? data.id.value : this.id,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      contestParticipationId: data.contestParticipationId.present
          ? data.contestParticipationId.value
          : this.contestParticipationId,
      modelCatalogId: data.modelCatalogId.present
          ? data.modelCatalogId.value
          : this.modelCatalogId,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      contestSpecificIdentifier: data.contestSpecificIdentifier.present
          ? data.contestSpecificIdentifier.value
          : this.contestSpecificIdentifier,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContestModelLinkData(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('contestParticipationId: $contestParticipationId, ')
          ..write('modelCatalogId: $modelCatalogId, ')
          ..write('modelName: $modelName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('modelId: $modelId, ')
          ..write('contestSpecificIdentifier: $contestSpecificIdentifier, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contestId,
    contestParticipationId,
    modelCatalogId,
    modelName,
    manufacturer,
    modelId,
    contestSpecificIdentifier,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContestModelLinkData &&
          other.id == this.id &&
          other.contestId == this.contestId &&
          other.contestParticipationId == this.contestParticipationId &&
          other.modelCatalogId == this.modelCatalogId &&
          other.modelName == this.modelName &&
          other.manufacturer == this.manufacturer &&
          other.modelId == this.modelId &&
          other.contestSpecificIdentifier == this.contestSpecificIdentifier &&
          other.revision == this.revision);
}

class ContestModelLinksCompanion extends UpdateCompanion<ContestModelLinkData> {
  final Value<String> id;
  final Value<String> contestId;
  final Value<String> contestParticipationId;
  final Value<String?> modelCatalogId;
  final Value<String> modelName;
  final Value<String?> manufacturer;
  final Value<String> modelId;
  final Value<String?> contestSpecificIdentifier;
  final Value<int> revision;
  final Value<int> rowid;
  const ContestModelLinksCompanion({
    this.id = const Value.absent(),
    this.contestId = const Value.absent(),
    this.contestParticipationId = const Value.absent(),
    this.modelCatalogId = const Value.absent(),
    this.modelName = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.modelId = const Value.absent(),
    this.contestSpecificIdentifier = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContestModelLinksCompanion.insert({
    required String id,
    required String contestId,
    required String contestParticipationId,
    this.modelCatalogId = const Value.absent(),
    required String modelName,
    this.manufacturer = const Value.absent(),
    required String modelId,
    this.contestSpecificIdentifier = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contestId = Value(contestId),
       contestParticipationId = Value(contestParticipationId),
       modelName = Value(modelName),
       modelId = Value(modelId);
  static Insertable<ContestModelLinkData> custom({
    Expression<String>? id,
    Expression<String>? contestId,
    Expression<String>? contestParticipationId,
    Expression<String>? modelCatalogId,
    Expression<String>? modelName,
    Expression<String>? manufacturer,
    Expression<String>? modelId,
    Expression<String>? contestSpecificIdentifier,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contestId != null) 'contest_id': contestId,
      if (contestParticipationId != null)
        'contest_participation_id': contestParticipationId,
      if (modelCatalogId != null) 'model_catalog_id': modelCatalogId,
      if (modelName != null) 'model_name': modelName,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (modelId != null) 'model_id': modelId,
      if (contestSpecificIdentifier != null)
        'contest_specific_identifier': contestSpecificIdentifier,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContestModelLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? contestId,
    Value<String>? contestParticipationId,
    Value<String?>? modelCatalogId,
    Value<String>? modelName,
    Value<String?>? manufacturer,
    Value<String>? modelId,
    Value<String?>? contestSpecificIdentifier,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return ContestModelLinksCompanion(
      id: id ?? this.id,
      contestId: contestId ?? this.contestId,
      contestParticipationId:
          contestParticipationId ?? this.contestParticipationId,
      modelCatalogId: modelCatalogId ?? this.modelCatalogId,
      modelName: modelName ?? this.modelName,
      manufacturer: manufacturer ?? this.manufacturer,
      modelId: modelId ?? this.modelId,
      contestSpecificIdentifier:
          contestSpecificIdentifier ?? this.contestSpecificIdentifier,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (contestParticipationId.present) {
      map['contest_participation_id'] = Variable<String>(
        contestParticipationId.value,
      );
    }
    if (modelCatalogId.present) {
      map['model_catalog_id'] = Variable<String>(modelCatalogId.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (contestSpecificIdentifier.present) {
      map['contest_specific_identifier'] = Variable<String>(
        contestSpecificIdentifier.value,
      );
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContestModelLinksCompanion(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('contestParticipationId: $contestParticipationId, ')
          ..write('modelCatalogId: $modelCatalogId, ')
          ..write('modelName: $modelName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('modelId: $modelId, ')
          ..write('contestSpecificIdentifier: $contestSpecificIdentifier, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MutationRecordsTable extends MutationRecords
    with TableInfo<$MutationRecordsTable, MutationRecordData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientMutationIdMeta = const VerificationMeta(
    'clientMutationId',
  );
  @override
  late final GeneratedColumn<String> clientMutationId = GeneratedColumn<String>(
    'client_mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorityMeta = const VerificationMeta(
    'authority',
  );
  @override
  late final GeneratedColumn<String> authority = GeneratedColumn<String>(
    'authority',
    aliasedName,
    false,
    check: () => authority.isIn(authorityValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceInstallationIdMeta =
      const VerificationMeta('sourceInstallationId');
  @override
  late final GeneratedColumn<String> sourceInstallationId =
      GeneratedColumn<String>(
        'source_installation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceDeviceMeta = const VerificationMeta(
    'sourceDevice',
  );
  @override
  late final GeneratedColumn<String> sourceDevice = GeneratedColumn<String>(
    'source_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientTimeMeta = const VerificationMeta(
    'clientTime',
  );
  @override
  late final GeneratedColumn<String> clientTime = GeneratedColumn<String>(
    'client_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverAcceptanceTimeMeta =
      const VerificationMeta('serverAcceptanceTime');
  @override
  late final GeneratedColumn<String> serverAcceptanceTime =
      GeneratedColumn<String>(
        'server_acceptance_time',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverRejectionTimeMeta =
      const VerificationMeta('serverRejectionTime');
  @override
  late final GeneratedColumn<String> serverRejectionTime =
      GeneratedColumn<String>(
        'server_rejection_time',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    check: () => outcome.isIn(mutationOutcomeValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependsOnMutationIdMeta =
      const VerificationMeta('dependsOnMutationId');
  @override
  late final GeneratedColumn<String> dependsOnMutationId =
      GeneratedColumn<String>(
        'depends_on_mutation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contestId,
    ownerAccountId,
    sequence,
    entityType,
    entityId,
    baseRevision,
    clientMutationId,
    actorId,
    authority,
    sourceInstallationId,
    sourceDevice,
    clientTime,
    serverAcceptanceTime,
    serverRejectionTime,
    payload,
    outcome,
    reasonCode,
    errorMessage,
    dependsOnMutationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mutation_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MutationRecordData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('client_mutation_id')) {
      context.handle(
        _clientMutationIdMeta,
        clientMutationId.isAcceptableOrUnknown(
          data['client_mutation_id']!,
          _clientMutationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientMutationIdMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('authority')) {
      context.handle(
        _authorityMeta,
        authority.isAcceptableOrUnknown(data['authority']!, _authorityMeta),
      );
    } else if (isInserting) {
      context.missing(_authorityMeta);
    }
    if (data.containsKey('source_installation_id')) {
      context.handle(
        _sourceInstallationIdMeta,
        sourceInstallationId.isAcceptableOrUnknown(
          data['source_installation_id']!,
          _sourceInstallationIdMeta,
        ),
      );
    }
    if (data.containsKey('source_device')) {
      context.handle(
        _sourceDeviceMeta,
        sourceDevice.isAcceptableOrUnknown(
          data['source_device']!,
          _sourceDeviceMeta,
        ),
      );
    }
    if (data.containsKey('client_time')) {
      context.handle(
        _clientTimeMeta,
        clientTime.isAcceptableOrUnknown(data['client_time']!, _clientTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_clientTimeMeta);
    }
    if (data.containsKey('server_acceptance_time')) {
      context.handle(
        _serverAcceptanceTimeMeta,
        serverAcceptanceTime.isAcceptableOrUnknown(
          data['server_acceptance_time']!,
          _serverAcceptanceTimeMeta,
        ),
      );
    }
    if (data.containsKey('server_rejection_time')) {
      context.handle(
        _serverRejectionTimeMeta,
        serverRejectionTime.isAcceptableOrUnknown(
          data['server_rejection_time']!,
          _serverRejectionTimeMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('depends_on_mutation_id')) {
      context.handle(
        _dependsOnMutationIdMeta,
        dependsOnMutationId.isAcceptableOrUnknown(
          data['depends_on_mutation_id']!,
          _dependsOnMutationIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {contestId, clientMutationId},
    {ownerAccountId, clientMutationId},
    {contestId, sequence},
    {ownerAccountId, sequence},
  ];
  @override
  MutationRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutationRecordData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      ),
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      ),
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      ),
      clientMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_mutation_id'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      ),
      authority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authority'],
      )!,
      sourceInstallationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_installation_id'],
      ),
      sourceDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_device'],
      ),
      clientTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_time'],
      )!,
      serverAcceptanceTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_acceptance_time'],
      ),
      serverRejectionTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_rejection_time'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      dependsOnMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on_mutation_id'],
      ),
    );
  }

  @override
  $MutationRecordsTable createAlias(String alias) {
    return $MutationRecordsTable(attachedDatabase, alias);
  }
}

class MutationRecordData extends DataClass
    implements Insertable<MutationRecordData> {
  final String id;
  final String? contestId;
  final String? ownerAccountId;
  final int? sequence;
  final String entityType;
  final String entityId;
  final int? baseRevision;
  final String clientMutationId;
  final String? actorId;
  final String authority;
  final String? sourceInstallationId;
  final String? sourceDevice;
  final String clientTime;
  final String? serverAcceptanceTime;
  final String? serverRejectionTime;

  /// A `VersionedPayload` as JSON text.
  final String payload;
  final String outcome;
  final String? reasonCode;
  final String? errorMessage;
  final String? dependsOnMutationId;
  const MutationRecordData({
    required this.id,
    this.contestId,
    this.ownerAccountId,
    this.sequence,
    required this.entityType,
    required this.entityId,
    this.baseRevision,
    required this.clientMutationId,
    this.actorId,
    required this.authority,
    this.sourceInstallationId,
    this.sourceDevice,
    required this.clientTime,
    this.serverAcceptanceTime,
    this.serverRejectionTime,
    required this.payload,
    required this.outcome,
    this.reasonCode,
    this.errorMessage,
    this.dependsOnMutationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || contestId != null) {
      map['contest_id'] = Variable<String>(contestId);
    }
    if (!nullToAbsent || ownerAccountId != null) {
      map['owner_account_id'] = Variable<String>(ownerAccountId);
    }
    if (!nullToAbsent || sequence != null) {
      map['sequence'] = Variable<int>(sequence);
    }
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || baseRevision != null) {
      map['base_revision'] = Variable<int>(baseRevision);
    }
    map['client_mutation_id'] = Variable<String>(clientMutationId);
    if (!nullToAbsent || actorId != null) {
      map['actor_id'] = Variable<String>(actorId);
    }
    map['authority'] = Variable<String>(authority);
    if (!nullToAbsent || sourceInstallationId != null) {
      map['source_installation_id'] = Variable<String>(sourceInstallationId);
    }
    if (!nullToAbsent || sourceDevice != null) {
      map['source_device'] = Variable<String>(sourceDevice);
    }
    map['client_time'] = Variable<String>(clientTime);
    if (!nullToAbsent || serverAcceptanceTime != null) {
      map['server_acceptance_time'] = Variable<String>(serverAcceptanceTime);
    }
    if (!nullToAbsent || serverRejectionTime != null) {
      map['server_rejection_time'] = Variable<String>(serverRejectionTime);
    }
    map['payload'] = Variable<String>(payload);
    map['outcome'] = Variable<String>(outcome);
    if (!nullToAbsent || reasonCode != null) {
      map['reason_code'] = Variable<String>(reasonCode);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || dependsOnMutationId != null) {
      map['depends_on_mutation_id'] = Variable<String>(dependsOnMutationId);
    }
    return map;
  }

  MutationRecordsCompanion toCompanion(bool nullToAbsent) {
    return MutationRecordsCompanion(
      id: Value(id),
      contestId: contestId == null && nullToAbsent
          ? const Value.absent()
          : Value(contestId),
      ownerAccountId: ownerAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerAccountId),
      sequence: sequence == null && nullToAbsent
          ? const Value.absent()
          : Value(sequence),
      entityType: Value(entityType),
      entityId: Value(entityId),
      baseRevision: baseRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(baseRevision),
      clientMutationId: Value(clientMutationId),
      actorId: actorId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorId),
      authority: Value(authority),
      sourceInstallationId: sourceInstallationId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceInstallationId),
      sourceDevice: sourceDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceDevice),
      clientTime: Value(clientTime),
      serverAcceptanceTime: serverAcceptanceTime == null && nullToAbsent
          ? const Value.absent()
          : Value(serverAcceptanceTime),
      serverRejectionTime: serverRejectionTime == null && nullToAbsent
          ? const Value.absent()
          : Value(serverRejectionTime),
      payload: Value(payload),
      outcome: Value(outcome),
      reasonCode: reasonCode == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonCode),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      dependsOnMutationId: dependsOnMutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOnMutationId),
    );
  }

  factory MutationRecordData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutationRecordData(
      id: serializer.fromJson<String>(json['id']),
      contestId: serializer.fromJson<String?>(json['contestId']),
      ownerAccountId: serializer.fromJson<String?>(json['ownerAccountId']),
      sequence: serializer.fromJson<int?>(json['sequence']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      baseRevision: serializer.fromJson<int?>(json['baseRevision']),
      clientMutationId: serializer.fromJson<String>(json['clientMutationId']),
      actorId: serializer.fromJson<String?>(json['actorId']),
      authority: serializer.fromJson<String>(json['authority']),
      sourceInstallationId: serializer.fromJson<String?>(
        json['sourceInstallationId'],
      ),
      sourceDevice: serializer.fromJson<String?>(json['sourceDevice']),
      clientTime: serializer.fromJson<String>(json['clientTime']),
      serverAcceptanceTime: serializer.fromJson<String?>(
        json['serverAcceptanceTime'],
      ),
      serverRejectionTime: serializer.fromJson<String?>(
        json['serverRejectionTime'],
      ),
      payload: serializer.fromJson<String>(json['payload']),
      outcome: serializer.fromJson<String>(json['outcome']),
      reasonCode: serializer.fromJson<String?>(json['reasonCode']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      dependsOnMutationId: serializer.fromJson<String?>(
        json['dependsOnMutationId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contestId': serializer.toJson<String?>(contestId),
      'ownerAccountId': serializer.toJson<String?>(ownerAccountId),
      'sequence': serializer.toJson<int?>(sequence),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'baseRevision': serializer.toJson<int?>(baseRevision),
      'clientMutationId': serializer.toJson<String>(clientMutationId),
      'actorId': serializer.toJson<String?>(actorId),
      'authority': serializer.toJson<String>(authority),
      'sourceInstallationId': serializer.toJson<String?>(sourceInstallationId),
      'sourceDevice': serializer.toJson<String?>(sourceDevice),
      'clientTime': serializer.toJson<String>(clientTime),
      'serverAcceptanceTime': serializer.toJson<String?>(serverAcceptanceTime),
      'serverRejectionTime': serializer.toJson<String?>(serverRejectionTime),
      'payload': serializer.toJson<String>(payload),
      'outcome': serializer.toJson<String>(outcome),
      'reasonCode': serializer.toJson<String?>(reasonCode),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'dependsOnMutationId': serializer.toJson<String?>(dependsOnMutationId),
    };
  }

  MutationRecordData copyWith({
    String? id,
    Value<String?> contestId = const Value.absent(),
    Value<String?> ownerAccountId = const Value.absent(),
    Value<int?> sequence = const Value.absent(),
    String? entityType,
    String? entityId,
    Value<int?> baseRevision = const Value.absent(),
    String? clientMutationId,
    Value<String?> actorId = const Value.absent(),
    String? authority,
    Value<String?> sourceInstallationId = const Value.absent(),
    Value<String?> sourceDevice = const Value.absent(),
    String? clientTime,
    Value<String?> serverAcceptanceTime = const Value.absent(),
    Value<String?> serverRejectionTime = const Value.absent(),
    String? payload,
    String? outcome,
    Value<String?> reasonCode = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> dependsOnMutationId = const Value.absent(),
  }) => MutationRecordData(
    id: id ?? this.id,
    contestId: contestId.present ? contestId.value : this.contestId,
    ownerAccountId: ownerAccountId.present
        ? ownerAccountId.value
        : this.ownerAccountId,
    sequence: sequence.present ? sequence.value : this.sequence,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    baseRevision: baseRevision.present ? baseRevision.value : this.baseRevision,
    clientMutationId: clientMutationId ?? this.clientMutationId,
    actorId: actorId.present ? actorId.value : this.actorId,
    authority: authority ?? this.authority,
    sourceInstallationId: sourceInstallationId.present
        ? sourceInstallationId.value
        : this.sourceInstallationId,
    sourceDevice: sourceDevice.present ? sourceDevice.value : this.sourceDevice,
    clientTime: clientTime ?? this.clientTime,
    serverAcceptanceTime: serverAcceptanceTime.present
        ? serverAcceptanceTime.value
        : this.serverAcceptanceTime,
    serverRejectionTime: serverRejectionTime.present
        ? serverRejectionTime.value
        : this.serverRejectionTime,
    payload: payload ?? this.payload,
    outcome: outcome ?? this.outcome,
    reasonCode: reasonCode.present ? reasonCode.value : this.reasonCode,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    dependsOnMutationId: dependsOnMutationId.present
        ? dependsOnMutationId.value
        : this.dependsOnMutationId,
  );
  MutationRecordData copyWithCompanion(MutationRecordsCompanion data) {
    return MutationRecordData(
      id: data.id.present ? data.id.value : this.id,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      clientMutationId: data.clientMutationId.present
          ? data.clientMutationId.value
          : this.clientMutationId,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      authority: data.authority.present ? data.authority.value : this.authority,
      sourceInstallationId: data.sourceInstallationId.present
          ? data.sourceInstallationId.value
          : this.sourceInstallationId,
      sourceDevice: data.sourceDevice.present
          ? data.sourceDevice.value
          : this.sourceDevice,
      clientTime: data.clientTime.present
          ? data.clientTime.value
          : this.clientTime,
      serverAcceptanceTime: data.serverAcceptanceTime.present
          ? data.serverAcceptanceTime.value
          : this.serverAcceptanceTime,
      serverRejectionTime: data.serverRejectionTime.present
          ? data.serverRejectionTime.value
          : this.serverRejectionTime,
      payload: data.payload.present ? data.payload.value : this.payload,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      dependsOnMutationId: data.dependsOnMutationId.present
          ? data.dependsOnMutationId.value
          : this.dependsOnMutationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutationRecordData(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('sequence: $sequence, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('clientMutationId: $clientMutationId, ')
          ..write('actorId: $actorId, ')
          ..write('authority: $authority, ')
          ..write('sourceInstallationId: $sourceInstallationId, ')
          ..write('sourceDevice: $sourceDevice, ')
          ..write('clientTime: $clientTime, ')
          ..write('serverAcceptanceTime: $serverAcceptanceTime, ')
          ..write('serverRejectionTime: $serverRejectionTime, ')
          ..write('payload: $payload, ')
          ..write('outcome: $outcome, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('dependsOnMutationId: $dependsOnMutationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contestId,
    ownerAccountId,
    sequence,
    entityType,
    entityId,
    baseRevision,
    clientMutationId,
    actorId,
    authority,
    sourceInstallationId,
    sourceDevice,
    clientTime,
    serverAcceptanceTime,
    serverRejectionTime,
    payload,
    outcome,
    reasonCode,
    errorMessage,
    dependsOnMutationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutationRecordData &&
          other.id == this.id &&
          other.contestId == this.contestId &&
          other.ownerAccountId == this.ownerAccountId &&
          other.sequence == this.sequence &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.baseRevision == this.baseRevision &&
          other.clientMutationId == this.clientMutationId &&
          other.actorId == this.actorId &&
          other.authority == this.authority &&
          other.sourceInstallationId == this.sourceInstallationId &&
          other.sourceDevice == this.sourceDevice &&
          other.clientTime == this.clientTime &&
          other.serverAcceptanceTime == this.serverAcceptanceTime &&
          other.serverRejectionTime == this.serverRejectionTime &&
          other.payload == this.payload &&
          other.outcome == this.outcome &&
          other.reasonCode == this.reasonCode &&
          other.errorMessage == this.errorMessage &&
          other.dependsOnMutationId == this.dependsOnMutationId);
}

class MutationRecordsCompanion extends UpdateCompanion<MutationRecordData> {
  final Value<String> id;
  final Value<String?> contestId;
  final Value<String?> ownerAccountId;
  final Value<int?> sequence;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<int?> baseRevision;
  final Value<String> clientMutationId;
  final Value<String?> actorId;
  final Value<String> authority;
  final Value<String?> sourceInstallationId;
  final Value<String?> sourceDevice;
  final Value<String> clientTime;
  final Value<String?> serverAcceptanceTime;
  final Value<String?> serverRejectionTime;
  final Value<String> payload;
  final Value<String> outcome;
  final Value<String?> reasonCode;
  final Value<String?> errorMessage;
  final Value<String?> dependsOnMutationId;
  final Value<int> rowid;
  const MutationRecordsCompanion({
    this.id = const Value.absent(),
    this.contestId = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.clientMutationId = const Value.absent(),
    this.actorId = const Value.absent(),
    this.authority = const Value.absent(),
    this.sourceInstallationId = const Value.absent(),
    this.sourceDevice = const Value.absent(),
    this.clientTime = const Value.absent(),
    this.serverAcceptanceTime = const Value.absent(),
    this.serverRejectionTime = const Value.absent(),
    this.payload = const Value.absent(),
    this.outcome = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.dependsOnMutationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MutationRecordsCompanion.insert({
    required String id,
    this.contestId = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.sequence = const Value.absent(),
    required String entityType,
    required String entityId,
    this.baseRevision = const Value.absent(),
    required String clientMutationId,
    this.actorId = const Value.absent(),
    required String authority,
    this.sourceInstallationId = const Value.absent(),
    this.sourceDevice = const Value.absent(),
    required String clientTime,
    this.serverAcceptanceTime = const Value.absent(),
    this.serverRejectionTime = const Value.absent(),
    required String payload,
    required String outcome,
    this.reasonCode = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.dependsOnMutationId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       clientMutationId = Value(clientMutationId),
       authority = Value(authority),
       clientTime = Value(clientTime),
       payload = Value(payload),
       outcome = Value(outcome);
  static Insertable<MutationRecordData> custom({
    Expression<String>? id,
    Expression<String>? contestId,
    Expression<String>? ownerAccountId,
    Expression<int>? sequence,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? baseRevision,
    Expression<String>? clientMutationId,
    Expression<String>? actorId,
    Expression<String>? authority,
    Expression<String>? sourceInstallationId,
    Expression<String>? sourceDevice,
    Expression<String>? clientTime,
    Expression<String>? serverAcceptanceTime,
    Expression<String>? serverRejectionTime,
    Expression<String>? payload,
    Expression<String>? outcome,
    Expression<String>? reasonCode,
    Expression<String>? errorMessage,
    Expression<String>? dependsOnMutationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contestId != null) 'contest_id': contestId,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (sequence != null) 'sequence': sequence,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (clientMutationId != null) 'client_mutation_id': clientMutationId,
      if (actorId != null) 'actor_id': actorId,
      if (authority != null) 'authority': authority,
      if (sourceInstallationId != null)
        'source_installation_id': sourceInstallationId,
      if (sourceDevice != null) 'source_device': sourceDevice,
      if (clientTime != null) 'client_time': clientTime,
      if (serverAcceptanceTime != null)
        'server_acceptance_time': serverAcceptanceTime,
      if (serverRejectionTime != null)
        'server_rejection_time': serverRejectionTime,
      if (payload != null) 'payload': payload,
      if (outcome != null) 'outcome': outcome,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (dependsOnMutationId != null)
        'depends_on_mutation_id': dependsOnMutationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MutationRecordsCompanion copyWith({
    Value<String>? id,
    Value<String?>? contestId,
    Value<String?>? ownerAccountId,
    Value<int?>? sequence,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<int?>? baseRevision,
    Value<String>? clientMutationId,
    Value<String?>? actorId,
    Value<String>? authority,
    Value<String?>? sourceInstallationId,
    Value<String?>? sourceDevice,
    Value<String>? clientTime,
    Value<String?>? serverAcceptanceTime,
    Value<String?>? serverRejectionTime,
    Value<String>? payload,
    Value<String>? outcome,
    Value<String?>? reasonCode,
    Value<String?>? errorMessage,
    Value<String?>? dependsOnMutationId,
    Value<int>? rowid,
  }) {
    return MutationRecordsCompanion(
      id: id ?? this.id,
      contestId: contestId ?? this.contestId,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      sequence: sequence ?? this.sequence,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      baseRevision: baseRevision ?? this.baseRevision,
      clientMutationId: clientMutationId ?? this.clientMutationId,
      actorId: actorId ?? this.actorId,
      authority: authority ?? this.authority,
      sourceInstallationId: sourceInstallationId ?? this.sourceInstallationId,
      sourceDevice: sourceDevice ?? this.sourceDevice,
      clientTime: clientTime ?? this.clientTime,
      serverAcceptanceTime: serverAcceptanceTime ?? this.serverAcceptanceTime,
      serverRejectionTime: serverRejectionTime ?? this.serverRejectionTime,
      payload: payload ?? this.payload,
      outcome: outcome ?? this.outcome,
      reasonCode: reasonCode ?? this.reasonCode,
      errorMessage: errorMessage ?? this.errorMessage,
      dependsOnMutationId: dependsOnMutationId ?? this.dependsOnMutationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (clientMutationId.present) {
      map['client_mutation_id'] = Variable<String>(clientMutationId.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (authority.present) {
      map['authority'] = Variable<String>(authority.value);
    }
    if (sourceInstallationId.present) {
      map['source_installation_id'] = Variable<String>(
        sourceInstallationId.value,
      );
    }
    if (sourceDevice.present) {
      map['source_device'] = Variable<String>(sourceDevice.value);
    }
    if (clientTime.present) {
      map['client_time'] = Variable<String>(clientTime.value);
    }
    if (serverAcceptanceTime.present) {
      map['server_acceptance_time'] = Variable<String>(
        serverAcceptanceTime.value,
      );
    }
    if (serverRejectionTime.present) {
      map['server_rejection_time'] = Variable<String>(
        serverRejectionTime.value,
      );
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (dependsOnMutationId.present) {
      map['depends_on_mutation_id'] = Variable<String>(
        dependsOnMutationId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutationRecordsCompanion(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('sequence: $sequence, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('clientMutationId: $clientMutationId, ')
          ..write('actorId: $actorId, ')
          ..write('authority: $authority, ')
          ..write('sourceInstallationId: $sourceInstallationId, ')
          ..write('sourceDevice: $sourceDevice, ')
          ..write('clientTime: $clientTime, ')
          ..write('serverAcceptanceTime: $serverAcceptanceTime, ')
          ..write('serverRejectionTime: $serverRejectionTime, ')
          ..write('payload: $payload, ')
          ..write('outcome: $outcome, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('dependsOnMutationId: $dependsOnMutationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConflictRecordsTable extends ConflictRecords
    with TableInfo<$ConflictRecordsTable, ConflictRecordData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acceptedMutationIdMeta =
      const VerificationMeta('acceptedMutationId');
  @override
  late final GeneratedColumn<String> acceptedMutationId =
      GeneratedColumn<String>(
        'accepted_mutation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _competingMutationIdMeta =
      const VerificationMeta('competingMutationId');
  @override
  late final GeneratedColumn<String> competingMutationId =
      GeneratedColumn<String>(
        'competing_mutation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiresActionMeta = const VerificationMeta(
    'requiresAction',
  );
  @override
  late final GeneratedColumn<bool> requiresAction = GeneratedColumn<bool>(
    'requires_action',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
      SqlDialect.sqlite: 'CHECK ("requires_action" IN (0, 1))',
      SqlDialect.postgres: '',
    }),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    false,
    check: () => resolution.isIn(conflictResolutionValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolutionChoiceMeta = const VerificationMeta(
    'resolutionChoice',
  );
  @override
  late final GeneratedColumn<String> resolutionChoice = GeneratedColumn<String>(
    'resolution_choice',
    aliasedName,
    true,
    check: () => resolutionChoice.isIn(conflictResolutionChoiceValues),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<String> resolvedAt = GeneratedColumn<String>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedByMeta = const VerificationMeta(
    'resolvedBy',
  );
  @override
  late final GeneratedColumn<String> resolvedBy = GeneratedColumn<String>(
    'resolved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contestId,
    ownerAccountId,
    entityType,
    entityId,
    acceptedMutationId,
    competingMutationId,
    reasonCode,
    reason,
    requiresAction,
    resolution,
    resolutionChoice,
    createdAt,
    resolvedAt,
    resolvedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflict_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictRecordData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('accepted_mutation_id')) {
      context.handle(
        _acceptedMutationIdMeta,
        acceptedMutationId.isAcceptableOrUnknown(
          data['accepted_mutation_id']!,
          _acceptedMutationIdMeta,
        ),
      );
    }
    if (data.containsKey('competing_mutation_id')) {
      context.handle(
        _competingMutationIdMeta,
        competingMutationId.isAcceptableOrUnknown(
          data['competing_mutation_id']!,
          _competingMutationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competingMutationIdMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonCodeMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('requires_action')) {
      context.handle(
        _requiresActionMeta,
        requiresAction.isAcceptableOrUnknown(
          data['requires_action']!,
          _requiresActionMeta,
        ),
      );
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    } else if (isInserting) {
      context.missing(_resolutionMeta);
    }
    if (data.containsKey('resolution_choice')) {
      context.handle(
        _resolutionChoiceMeta,
        resolutionChoice.isAcceptableOrUnknown(
          data['resolution_choice']!,
          _resolutionChoiceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('resolved_by')) {
      context.handle(
        _resolvedByMeta,
        resolvedBy.isAcceptableOrUnknown(data['resolved_by']!, _resolvedByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConflictRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictRecordData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      ),
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      acceptedMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accepted_mutation_id'],
      ),
      competingMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competing_mutation_id'],
      )!,
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      requiresAction: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_action'],
      )!,
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      )!,
      resolutionChoice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_choice'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_at'],
      ),
      resolvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by'],
      ),
    );
  }

  @override
  $ConflictRecordsTable createAlias(String alias) {
    return $ConflictRecordsTable(attachedDatabase, alias);
  }
}

class ConflictRecordData extends DataClass
    implements Insertable<ConflictRecordData> {
  final String id;
  final String? contestId;
  final String? ownerAccountId;
  final String entityType;
  final String entityId;
  final String? acceptedMutationId;
  final String competingMutationId;
  final String reasonCode;
  final String? reason;
  final bool requiresAction;
  final String resolution;
  final String? resolutionChoice;
  final String createdAt;
  final String? resolvedAt;
  final String? resolvedBy;
  const ConflictRecordData({
    required this.id,
    this.contestId,
    this.ownerAccountId,
    required this.entityType,
    required this.entityId,
    this.acceptedMutationId,
    required this.competingMutationId,
    required this.reasonCode,
    this.reason,
    required this.requiresAction,
    required this.resolution,
    this.resolutionChoice,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || contestId != null) {
      map['contest_id'] = Variable<String>(contestId);
    }
    if (!nullToAbsent || ownerAccountId != null) {
      map['owner_account_id'] = Variable<String>(ownerAccountId);
    }
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || acceptedMutationId != null) {
      map['accepted_mutation_id'] = Variable<String>(acceptedMutationId);
    }
    map['competing_mutation_id'] = Variable<String>(competingMutationId);
    map['reason_code'] = Variable<String>(reasonCode);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['requires_action'] = Variable<bool>(requiresAction);
    map['resolution'] = Variable<String>(resolution);
    if (!nullToAbsent || resolutionChoice != null) {
      map['resolution_choice'] = Variable<String>(resolutionChoice);
    }
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<String>(resolvedAt);
    }
    if (!nullToAbsent || resolvedBy != null) {
      map['resolved_by'] = Variable<String>(resolvedBy);
    }
    return map;
  }

  ConflictRecordsCompanion toCompanion(bool nullToAbsent) {
    return ConflictRecordsCompanion(
      id: Value(id),
      contestId: contestId == null && nullToAbsent
          ? const Value.absent()
          : Value(contestId),
      ownerAccountId: ownerAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerAccountId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      acceptedMutationId: acceptedMutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedMutationId),
      competingMutationId: Value(competingMutationId),
      reasonCode: Value(reasonCode),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      requiresAction: Value(requiresAction),
      resolution: Value(resolution),
      resolutionChoice: resolutionChoice == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionChoice),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      resolvedBy: resolvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedBy),
    );
  }

  factory ConflictRecordData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictRecordData(
      id: serializer.fromJson<String>(json['id']),
      contestId: serializer.fromJson<String?>(json['contestId']),
      ownerAccountId: serializer.fromJson<String?>(json['ownerAccountId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      acceptedMutationId: serializer.fromJson<String?>(
        json['acceptedMutationId'],
      ),
      competingMutationId: serializer.fromJson<String>(
        json['competingMutationId'],
      ),
      reasonCode: serializer.fromJson<String>(json['reasonCode']),
      reason: serializer.fromJson<String?>(json['reason']),
      requiresAction: serializer.fromJson<bool>(json['requiresAction']),
      resolution: serializer.fromJson<String>(json['resolution']),
      resolutionChoice: serializer.fromJson<String?>(json['resolutionChoice']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      resolvedAt: serializer.fromJson<String?>(json['resolvedAt']),
      resolvedBy: serializer.fromJson<String?>(json['resolvedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contestId': serializer.toJson<String?>(contestId),
      'ownerAccountId': serializer.toJson<String?>(ownerAccountId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'acceptedMutationId': serializer.toJson<String?>(acceptedMutationId),
      'competingMutationId': serializer.toJson<String>(competingMutationId),
      'reasonCode': serializer.toJson<String>(reasonCode),
      'reason': serializer.toJson<String?>(reason),
      'requiresAction': serializer.toJson<bool>(requiresAction),
      'resolution': serializer.toJson<String>(resolution),
      'resolutionChoice': serializer.toJson<String?>(resolutionChoice),
      'createdAt': serializer.toJson<String>(createdAt),
      'resolvedAt': serializer.toJson<String?>(resolvedAt),
      'resolvedBy': serializer.toJson<String?>(resolvedBy),
    };
  }

  ConflictRecordData copyWith({
    String? id,
    Value<String?> contestId = const Value.absent(),
    Value<String?> ownerAccountId = const Value.absent(),
    String? entityType,
    String? entityId,
    Value<String?> acceptedMutationId = const Value.absent(),
    String? competingMutationId,
    String? reasonCode,
    Value<String?> reason = const Value.absent(),
    bool? requiresAction,
    String? resolution,
    Value<String?> resolutionChoice = const Value.absent(),
    String? createdAt,
    Value<String?> resolvedAt = const Value.absent(),
    Value<String?> resolvedBy = const Value.absent(),
  }) => ConflictRecordData(
    id: id ?? this.id,
    contestId: contestId.present ? contestId.value : this.contestId,
    ownerAccountId: ownerAccountId.present
        ? ownerAccountId.value
        : this.ownerAccountId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    acceptedMutationId: acceptedMutationId.present
        ? acceptedMutationId.value
        : this.acceptedMutationId,
    competingMutationId: competingMutationId ?? this.competingMutationId,
    reasonCode: reasonCode ?? this.reasonCode,
    reason: reason.present ? reason.value : this.reason,
    requiresAction: requiresAction ?? this.requiresAction,
    resolution: resolution ?? this.resolution,
    resolutionChoice: resolutionChoice.present
        ? resolutionChoice.value
        : this.resolutionChoice,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    resolvedBy: resolvedBy.present ? resolvedBy.value : this.resolvedBy,
  );
  ConflictRecordData copyWithCompanion(ConflictRecordsCompanion data) {
    return ConflictRecordData(
      id: data.id.present ? data.id.value : this.id,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      acceptedMutationId: data.acceptedMutationId.present
          ? data.acceptedMutationId.value
          : this.acceptedMutationId,
      competingMutationId: data.competingMutationId.present
          ? data.competingMutationId.value
          : this.competingMutationId,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      reason: data.reason.present ? data.reason.value : this.reason,
      requiresAction: data.requiresAction.present
          ? data.requiresAction.value
          : this.requiresAction,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      resolutionChoice: data.resolutionChoice.present
          ? data.resolutionChoice.value
          : this.resolutionChoice,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      resolvedBy: data.resolvedBy.present
          ? data.resolvedBy.value
          : this.resolvedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictRecordData(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('acceptedMutationId: $acceptedMutationId, ')
          ..write('competingMutationId: $competingMutationId, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reason: $reason, ')
          ..write('requiresAction: $requiresAction, ')
          ..write('resolution: $resolution, ')
          ..write('resolutionChoice: $resolutionChoice, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolvedBy: $resolvedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contestId,
    ownerAccountId,
    entityType,
    entityId,
    acceptedMutationId,
    competingMutationId,
    reasonCode,
    reason,
    requiresAction,
    resolution,
    resolutionChoice,
    createdAt,
    resolvedAt,
    resolvedBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictRecordData &&
          other.id == this.id &&
          other.contestId == this.contestId &&
          other.ownerAccountId == this.ownerAccountId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.acceptedMutationId == this.acceptedMutationId &&
          other.competingMutationId == this.competingMutationId &&
          other.reasonCode == this.reasonCode &&
          other.reason == this.reason &&
          other.requiresAction == this.requiresAction &&
          other.resolution == this.resolution &&
          other.resolutionChoice == this.resolutionChoice &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt &&
          other.resolvedBy == this.resolvedBy);
}

class ConflictRecordsCompanion extends UpdateCompanion<ConflictRecordData> {
  final Value<String> id;
  final Value<String?> contestId;
  final Value<String?> ownerAccountId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String?> acceptedMutationId;
  final Value<String> competingMutationId;
  final Value<String> reasonCode;
  final Value<String?> reason;
  final Value<bool> requiresAction;
  final Value<String> resolution;
  final Value<String?> resolutionChoice;
  final Value<String> createdAt;
  final Value<String?> resolvedAt;
  final Value<String?> resolvedBy;
  final Value<int> rowid;
  const ConflictRecordsCompanion({
    this.id = const Value.absent(),
    this.contestId = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.acceptedMutationId = const Value.absent(),
    this.competingMutationId = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.reason = const Value.absent(),
    this.requiresAction = const Value.absent(),
    this.resolution = const Value.absent(),
    this.resolutionChoice = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictRecordsCompanion.insert({
    required String id,
    this.contestId = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    required String entityType,
    required String entityId,
    this.acceptedMutationId = const Value.absent(),
    required String competingMutationId,
    required String reasonCode,
    this.reason = const Value.absent(),
    this.requiresAction = const Value.absent(),
    required String resolution,
    this.resolutionChoice = const Value.absent(),
    required String createdAt,
    this.resolvedAt = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       competingMutationId = Value(competingMutationId),
       reasonCode = Value(reasonCode),
       resolution = Value(resolution),
       createdAt = Value(createdAt);
  static Insertable<ConflictRecordData> custom({
    Expression<String>? id,
    Expression<String>? contestId,
    Expression<String>? ownerAccountId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? acceptedMutationId,
    Expression<String>? competingMutationId,
    Expression<String>? reasonCode,
    Expression<String>? reason,
    Expression<bool>? requiresAction,
    Expression<String>? resolution,
    Expression<String>? resolutionChoice,
    Expression<String>? createdAt,
    Expression<String>? resolvedAt,
    Expression<String>? resolvedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contestId != null) 'contest_id': contestId,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (acceptedMutationId != null)
        'accepted_mutation_id': acceptedMutationId,
      if (competingMutationId != null)
        'competing_mutation_id': competingMutationId,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (reason != null) 'reason': reason,
      if (requiresAction != null) 'requires_action': requiresAction,
      if (resolution != null) 'resolution': resolution,
      if (resolutionChoice != null) 'resolution_choice': resolutionChoice,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictRecordsCompanion copyWith({
    Value<String>? id,
    Value<String?>? contestId,
    Value<String?>? ownerAccountId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String?>? acceptedMutationId,
    Value<String>? competingMutationId,
    Value<String>? reasonCode,
    Value<String?>? reason,
    Value<bool>? requiresAction,
    Value<String>? resolution,
    Value<String?>? resolutionChoice,
    Value<String>? createdAt,
    Value<String?>? resolvedAt,
    Value<String?>? resolvedBy,
    Value<int>? rowid,
  }) {
    return ConflictRecordsCompanion(
      id: id ?? this.id,
      contestId: contestId ?? this.contestId,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      acceptedMutationId: acceptedMutationId ?? this.acceptedMutationId,
      competingMutationId: competingMutationId ?? this.competingMutationId,
      reasonCode: reasonCode ?? this.reasonCode,
      reason: reason ?? this.reason,
      requiresAction: requiresAction ?? this.requiresAction,
      resolution: resolution ?? this.resolution,
      resolutionChoice: resolutionChoice ?? this.resolutionChoice,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (acceptedMutationId.present) {
      map['accepted_mutation_id'] = Variable<String>(acceptedMutationId.value);
    }
    if (competingMutationId.present) {
      map['competing_mutation_id'] = Variable<String>(
        competingMutationId.value,
      );
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (requiresAction.present) {
      map['requires_action'] = Variable<bool>(requiresAction.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (resolutionChoice.present) {
      map['resolution_choice'] = Variable<String>(resolutionChoice.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<String>(resolvedAt.value);
    }
    if (resolvedBy.present) {
      map['resolved_by'] = Variable<String>(resolvedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictRecordsCompanion(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('acceptedMutationId: $acceptedMutationId, ')
          ..write('competingMutationId: $competingMutationId, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reason: $reason, ')
          ..write('requiresAction: $requiresAction, ')
          ..write('resolution: $resolution, ')
          ..write('resolutionChoice: $resolutionChoice, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TombstonesTable extends Tombstones
    with TableInfo<$TombstonesTable, TombstoneData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(tombstoneStatusValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acknowledgedAtMeta = const VerificationMeta(
    'acknowledgedAt',
  );
  @override
  late final GeneratedColumn<String> acknowledgedAt = GeneratedColumn<String>(
    'acknowledged_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeAfterMeta = const VerificationMeta(
    'purgeAfter',
  );
  @override
  late final GeneratedColumn<String> purgeAfter = GeneratedColumn<String>(
    'purge_after',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletionReasonMeta = const VerificationMeta(
    'deletionReason',
  );
  @override
  late final GeneratedColumn<String> deletionReason = GeneratedColumn<String>(
    'deletion_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contestId,
    ownerAccountId,
    entityType,
    entityId,
    status,
    deletedAt,
    acknowledgedAt,
    purgeAfter,
    deletionReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<TombstoneData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    if (data.containsKey('acknowledged_at')) {
      context.handle(
        _acknowledgedAtMeta,
        acknowledgedAt.isAcceptableOrUnknown(
          data['acknowledged_at']!,
          _acknowledgedAtMeta,
        ),
      );
    }
    if (data.containsKey('purge_after')) {
      context.handle(
        _purgeAfterMeta,
        purgeAfter.isAcceptableOrUnknown(data['purge_after']!, _purgeAfterMeta),
      );
    }
    if (data.containsKey('deletion_reason')) {
      context.handle(
        _deletionReasonMeta,
        deletionReason.isAcceptableOrUnknown(
          data['deletion_reason']!,
          _deletionReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entityType, entityId},
  ];
  @override
  TombstoneData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TombstoneData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      ),
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      )!,
      acknowledgedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acknowledged_at'],
      ),
      purgeAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purge_after'],
      ),
      deletionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deletion_reason'],
      ),
    );
  }

  @override
  $TombstonesTable createAlias(String alias) {
    return $TombstonesTable(attachedDatabase, alias);
  }
}

class TombstoneData extends DataClass implements Insertable<TombstoneData> {
  final String id;
  final String? contestId;
  final String? ownerAccountId;
  final String entityType;
  final String entityId;
  final String status;
  final String deletedAt;
  final String? acknowledgedAt;
  final String? purgeAfter;
  final String? deletionReason;
  const TombstoneData({
    required this.id,
    this.contestId,
    this.ownerAccountId,
    required this.entityType,
    required this.entityId,
    required this.status,
    required this.deletedAt,
    this.acknowledgedAt,
    this.purgeAfter,
    this.deletionReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || contestId != null) {
      map['contest_id'] = Variable<String>(contestId);
    }
    if (!nullToAbsent || ownerAccountId != null) {
      map['owner_account_id'] = Variable<String>(ownerAccountId);
    }
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['status'] = Variable<String>(status);
    map['deleted_at'] = Variable<String>(deletedAt);
    if (!nullToAbsent || acknowledgedAt != null) {
      map['acknowledged_at'] = Variable<String>(acknowledgedAt);
    }
    if (!nullToAbsent || purgeAfter != null) {
      map['purge_after'] = Variable<String>(purgeAfter);
    }
    if (!nullToAbsent || deletionReason != null) {
      map['deletion_reason'] = Variable<String>(deletionReason);
    }
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      id: Value(id),
      contestId: contestId == null && nullToAbsent
          ? const Value.absent()
          : Value(contestId),
      ownerAccountId: ownerAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerAccountId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      status: Value(status),
      deletedAt: Value(deletedAt),
      acknowledgedAt: acknowledgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedAt),
      purgeAfter: purgeAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(purgeAfter),
      deletionReason: deletionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(deletionReason),
    );
  }

  factory TombstoneData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TombstoneData(
      id: serializer.fromJson<String>(json['id']),
      contestId: serializer.fromJson<String?>(json['contestId']),
      ownerAccountId: serializer.fromJson<String?>(json['ownerAccountId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      status: serializer.fromJson<String>(json['status']),
      deletedAt: serializer.fromJson<String>(json['deletedAt']),
      acknowledgedAt: serializer.fromJson<String?>(json['acknowledgedAt']),
      purgeAfter: serializer.fromJson<String?>(json['purgeAfter']),
      deletionReason: serializer.fromJson<String?>(json['deletionReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contestId': serializer.toJson<String?>(contestId),
      'ownerAccountId': serializer.toJson<String?>(ownerAccountId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'status': serializer.toJson<String>(status),
      'deletedAt': serializer.toJson<String>(deletedAt),
      'acknowledgedAt': serializer.toJson<String?>(acknowledgedAt),
      'purgeAfter': serializer.toJson<String?>(purgeAfter),
      'deletionReason': serializer.toJson<String?>(deletionReason),
    };
  }

  TombstoneData copyWith({
    String? id,
    Value<String?> contestId = const Value.absent(),
    Value<String?> ownerAccountId = const Value.absent(),
    String? entityType,
    String? entityId,
    String? status,
    String? deletedAt,
    Value<String?> acknowledgedAt = const Value.absent(),
    Value<String?> purgeAfter = const Value.absent(),
    Value<String?> deletionReason = const Value.absent(),
  }) => TombstoneData(
    id: id ?? this.id,
    contestId: contestId.present ? contestId.value : this.contestId,
    ownerAccountId: ownerAccountId.present
        ? ownerAccountId.value
        : this.ownerAccountId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    status: status ?? this.status,
    deletedAt: deletedAt ?? this.deletedAt,
    acknowledgedAt: acknowledgedAt.present
        ? acknowledgedAt.value
        : this.acknowledgedAt,
    purgeAfter: purgeAfter.present ? purgeAfter.value : this.purgeAfter,
    deletionReason: deletionReason.present
        ? deletionReason.value
        : this.deletionReason,
  );
  TombstoneData copyWithCompanion(TombstonesCompanion data) {
    return TombstoneData(
      id: data.id.present ? data.id.value : this.id,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      status: data.status.present ? data.status.value : this.status,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      acknowledgedAt: data.acknowledgedAt.present
          ? data.acknowledgedAt.value
          : this.acknowledgedAt,
      purgeAfter: data.purgeAfter.present
          ? data.purgeAfter.value
          : this.purgeAfter,
      deletionReason: data.deletionReason.present
          ? data.deletionReason.value
          : this.deletionReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TombstoneData(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('status: $status, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('purgeAfter: $purgeAfter, ')
          ..write('deletionReason: $deletionReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contestId,
    ownerAccountId,
    entityType,
    entityId,
    status,
    deletedAt,
    acknowledgedAt,
    purgeAfter,
    deletionReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TombstoneData &&
          other.id == this.id &&
          other.contestId == this.contestId &&
          other.ownerAccountId == this.ownerAccountId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.status == this.status &&
          other.deletedAt == this.deletedAt &&
          other.acknowledgedAt == this.acknowledgedAt &&
          other.purgeAfter == this.purgeAfter &&
          other.deletionReason == this.deletionReason);
}

class TombstonesCompanion extends UpdateCompanion<TombstoneData> {
  final Value<String> id;
  final Value<String?> contestId;
  final Value<String?> ownerAccountId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> status;
  final Value<String> deletedAt;
  final Value<String?> acknowledgedAt;
  final Value<String?> purgeAfter;
  final Value<String?> deletionReason;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.id = const Value.absent(),
    this.contestId = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.status = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
    this.purgeAfter = const Value.absent(),
    this.deletionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    required String id,
    this.contestId = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    required String entityType,
    required String entityId,
    required String status,
    required String deletedAt,
    this.acknowledgedAt = const Value.absent(),
    this.purgeAfter = const Value.absent(),
    this.deletionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       status = Value(status),
       deletedAt = Value(deletedAt);
  static Insertable<TombstoneData> custom({
    Expression<String>? id,
    Expression<String>? contestId,
    Expression<String>? ownerAccountId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? status,
    Expression<String>? deletedAt,
    Expression<String>? acknowledgedAt,
    Expression<String>? purgeAfter,
    Expression<String>? deletionReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contestId != null) 'contest_id': contestId,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (status != null) 'status': status,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt,
      if (purgeAfter != null) 'purge_after': purgeAfter,
      if (deletionReason != null) 'deletion_reason': deletionReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith({
    Value<String>? id,
    Value<String?>? contestId,
    Value<String?>? ownerAccountId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? status,
    Value<String>? deletedAt,
    Value<String?>? acknowledgedAt,
    Value<String?>? purgeAfter,
    Value<String?>? deletionReason,
    Value<int>? rowid,
  }) {
    return TombstonesCompanion(
      id: id ?? this.id,
      contestId: contestId ?? this.contestId,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      purgeAfter: purgeAfter ?? this.purgeAfter,
      deletionReason: deletionReason ?? this.deletionReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (acknowledgedAt.present) {
      map['acknowledged_at'] = Variable<String>(acknowledgedAt.value);
    }
    if (purgeAfter.present) {
      map['purge_after'] = Variable<String>(purgeAfter.value);
    }
    if (deletionReason.present) {
      map['deletion_reason'] = Variable<String>(deletionReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('id: $id, ')
          ..write('contestId: $contestId, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('status: $status, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('purgeAfter: $purgeAfter, ')
          ..write('deletionReason: $deletionReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditEventsTable extends AuditEvents
    with TableInfo<$AuditEventsTable, AuditEventData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contestIdMeta = const VerificationMeta(
    'contestId',
  );
  @override
  late final GeneratedColumn<String> contestId = GeneratedColumn<String>(
    'contest_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerAccountIdMeta = const VerificationMeta(
    'ownerAccountId',
  );
  @override
  late final GeneratedColumn<String> ownerAccountId = GeneratedColumn<String>(
    'owner_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publicationIdMeta = const VerificationMeta(
    'publicationId',
  );
  @override
  late final GeneratedColumn<String> publicationId = GeneratedColumn<String>(
    'publication_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    check: () => action.isIn(auditActionValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorityMeta = const VerificationMeta(
    'authority',
  );
  @override
  late final GeneratedColumn<String> authority = GeneratedColumn<String>(
    'authority',
    aliasedName,
    false,
    check: () => authority.isIn(authorityValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installationIdMeta = const VerificationMeta(
    'installationId',
  );
  @override
  late final GeneratedColumn<String> installationId = GeneratedColumn<String>(
    'installation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
    'device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultingRevisionMeta = const VerificationMeta(
    'resultingRevision',
  );
  @override
  late final GeneratedColumn<int> resultingRevision = GeneratedColumn<int>(
    'resulting_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverTimestampMeta = const VerificationMeta(
    'serverTimestamp',
  );
  @override
  late final GeneratedColumn<String> serverTimestamp = GeneratedColumn<String>(
    'server_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientTimestampMeta = const VerificationMeta(
    'clientTimestamp',
  );
  @override
  late final GeneratedColumn<String> clientTimestamp = GeneratedColumn<String>(
    'client_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    check: () => outcome.isIn(auditOutcomeValues),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    contestId,
    ownerAccountId,
    publicationId,
    action,
    actorId,
    authority,
    installationId,
    device,
    baseRevision,
    resultingRevision,
    serverTimestamp,
    clientTimestamp,
    reason,
    outcome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditEventData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('contest_id')) {
      context.handle(
        _contestIdMeta,
        contestId.isAcceptableOrUnknown(data['contest_id']!, _contestIdMeta),
      );
    }
    if (data.containsKey('owner_account_id')) {
      context.handle(
        _ownerAccountIdMeta,
        ownerAccountId.isAcceptableOrUnknown(
          data['owner_account_id']!,
          _ownerAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('publication_id')) {
      context.handle(
        _publicationIdMeta,
        publicationId.isAcceptableOrUnknown(
          data['publication_id']!,
          _publicationIdMeta,
        ),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('authority')) {
      context.handle(
        _authorityMeta,
        authority.isAcceptableOrUnknown(data['authority']!, _authorityMeta),
      );
    } else if (isInserting) {
      context.missing(_authorityMeta);
    }
    if (data.containsKey('installation_id')) {
      context.handle(
        _installationIdMeta,
        installationId.isAcceptableOrUnknown(
          data['installation_id']!,
          _installationIdMeta,
        ),
      );
    }
    if (data.containsKey('device')) {
      context.handle(
        _deviceMeta,
        device.isAcceptableOrUnknown(data['device']!, _deviceMeta),
      );
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('resulting_revision')) {
      context.handle(
        _resultingRevisionMeta,
        resultingRevision.isAcceptableOrUnknown(
          data['resulting_revision']!,
          _resultingRevisionMeta,
        ),
      );
    }
    if (data.containsKey('server_timestamp')) {
      context.handle(
        _serverTimestampMeta,
        serverTimestamp.isAcceptableOrUnknown(
          data['server_timestamp']!,
          _serverTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverTimestampMeta);
    }
    if (data.containsKey('client_timestamp')) {
      context.handle(
        _clientTimestampMeta,
        clientTimestamp.isAcceptableOrUnknown(
          data['client_timestamp']!,
          _clientTimestampMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditEventData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditEventData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      contestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contest_id'],
      ),
      ownerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_account_id'],
      ),
      publicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_id'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      ),
      authority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authority'],
      )!,
      installationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}installation_id'],
      ),
      device: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device'],
      ),
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      ),
      resultingRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resulting_revision'],
      ),
      serverTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_timestamp'],
      )!,
      clientTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_timestamp'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
    );
  }

  @override
  $AuditEventsTable createAlias(String alias) {
    return $AuditEventsTable(attachedDatabase, alias);
  }
}

class AuditEventData extends DataClass implements Insertable<AuditEventData> {
  final String id;
  final String entityType;
  final String entityId;
  final String? contestId;
  final String? ownerAccountId;
  final String? publicationId;
  final String action;
  final String? actorId;
  final String authority;
  final String? installationId;
  final String? device;
  final int? baseRevision;
  final int? resultingRevision;
  final String serverTimestamp;
  final String? clientTimestamp;
  final String? reason;
  final String outcome;
  const AuditEventData({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.contestId,
    this.ownerAccountId,
    this.publicationId,
    required this.action,
    this.actorId,
    required this.authority,
    this.installationId,
    this.device,
    this.baseRevision,
    this.resultingRevision,
    required this.serverTimestamp,
    this.clientTimestamp,
    this.reason,
    required this.outcome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || contestId != null) {
      map['contest_id'] = Variable<String>(contestId);
    }
    if (!nullToAbsent || ownerAccountId != null) {
      map['owner_account_id'] = Variable<String>(ownerAccountId);
    }
    if (!nullToAbsent || publicationId != null) {
      map['publication_id'] = Variable<String>(publicationId);
    }
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || actorId != null) {
      map['actor_id'] = Variable<String>(actorId);
    }
    map['authority'] = Variable<String>(authority);
    if (!nullToAbsent || installationId != null) {
      map['installation_id'] = Variable<String>(installationId);
    }
    if (!nullToAbsent || device != null) {
      map['device'] = Variable<String>(device);
    }
    if (!nullToAbsent || baseRevision != null) {
      map['base_revision'] = Variable<int>(baseRevision);
    }
    if (!nullToAbsent || resultingRevision != null) {
      map['resulting_revision'] = Variable<int>(resultingRevision);
    }
    map['server_timestamp'] = Variable<String>(serverTimestamp);
    if (!nullToAbsent || clientTimestamp != null) {
      map['client_timestamp'] = Variable<String>(clientTimestamp);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['outcome'] = Variable<String>(outcome);
    return map;
  }

  AuditEventsCompanion toCompanion(bool nullToAbsent) {
    return AuditEventsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      contestId: contestId == null && nullToAbsent
          ? const Value.absent()
          : Value(contestId),
      ownerAccountId: ownerAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerAccountId),
      publicationId: publicationId == null && nullToAbsent
          ? const Value.absent()
          : Value(publicationId),
      action: Value(action),
      actorId: actorId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorId),
      authority: Value(authority),
      installationId: installationId == null && nullToAbsent
          ? const Value.absent()
          : Value(installationId),
      device: device == null && nullToAbsent
          ? const Value.absent()
          : Value(device),
      baseRevision: baseRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(baseRevision),
      resultingRevision: resultingRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(resultingRevision),
      serverTimestamp: Value(serverTimestamp),
      clientTimestamp: clientTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(clientTimestamp),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      outcome: Value(outcome),
    );
  }

  factory AuditEventData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditEventData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      contestId: serializer.fromJson<String?>(json['contestId']),
      ownerAccountId: serializer.fromJson<String?>(json['ownerAccountId']),
      publicationId: serializer.fromJson<String?>(json['publicationId']),
      action: serializer.fromJson<String>(json['action']),
      actorId: serializer.fromJson<String?>(json['actorId']),
      authority: serializer.fromJson<String>(json['authority']),
      installationId: serializer.fromJson<String?>(json['installationId']),
      device: serializer.fromJson<String?>(json['device']),
      baseRevision: serializer.fromJson<int?>(json['baseRevision']),
      resultingRevision: serializer.fromJson<int?>(json['resultingRevision']),
      serverTimestamp: serializer.fromJson<String>(json['serverTimestamp']),
      clientTimestamp: serializer.fromJson<String?>(json['clientTimestamp']),
      reason: serializer.fromJson<String?>(json['reason']),
      outcome: serializer.fromJson<String>(json['outcome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'contestId': serializer.toJson<String?>(contestId),
      'ownerAccountId': serializer.toJson<String?>(ownerAccountId),
      'publicationId': serializer.toJson<String?>(publicationId),
      'action': serializer.toJson<String>(action),
      'actorId': serializer.toJson<String?>(actorId),
      'authority': serializer.toJson<String>(authority),
      'installationId': serializer.toJson<String?>(installationId),
      'device': serializer.toJson<String?>(device),
      'baseRevision': serializer.toJson<int?>(baseRevision),
      'resultingRevision': serializer.toJson<int?>(resultingRevision),
      'serverTimestamp': serializer.toJson<String>(serverTimestamp),
      'clientTimestamp': serializer.toJson<String?>(clientTimestamp),
      'reason': serializer.toJson<String?>(reason),
      'outcome': serializer.toJson<String>(outcome),
    };
  }

  AuditEventData copyWith({
    String? id,
    String? entityType,
    String? entityId,
    Value<String?> contestId = const Value.absent(),
    Value<String?> ownerAccountId = const Value.absent(),
    Value<String?> publicationId = const Value.absent(),
    String? action,
    Value<String?> actorId = const Value.absent(),
    String? authority,
    Value<String?> installationId = const Value.absent(),
    Value<String?> device = const Value.absent(),
    Value<int?> baseRevision = const Value.absent(),
    Value<int?> resultingRevision = const Value.absent(),
    String? serverTimestamp,
    Value<String?> clientTimestamp = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    String? outcome,
  }) => AuditEventData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    contestId: contestId.present ? contestId.value : this.contestId,
    ownerAccountId: ownerAccountId.present
        ? ownerAccountId.value
        : this.ownerAccountId,
    publicationId: publicationId.present
        ? publicationId.value
        : this.publicationId,
    action: action ?? this.action,
    actorId: actorId.present ? actorId.value : this.actorId,
    authority: authority ?? this.authority,
    installationId: installationId.present
        ? installationId.value
        : this.installationId,
    device: device.present ? device.value : this.device,
    baseRevision: baseRevision.present ? baseRevision.value : this.baseRevision,
    resultingRevision: resultingRevision.present
        ? resultingRevision.value
        : this.resultingRevision,
    serverTimestamp: serverTimestamp ?? this.serverTimestamp,
    clientTimestamp: clientTimestamp.present
        ? clientTimestamp.value
        : this.clientTimestamp,
    reason: reason.present ? reason.value : this.reason,
    outcome: outcome ?? this.outcome,
  );
  AuditEventData copyWithCompanion(AuditEventsCompanion data) {
    return AuditEventData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      contestId: data.contestId.present ? data.contestId.value : this.contestId,
      ownerAccountId: data.ownerAccountId.present
          ? data.ownerAccountId.value
          : this.ownerAccountId,
      publicationId: data.publicationId.present
          ? data.publicationId.value
          : this.publicationId,
      action: data.action.present ? data.action.value : this.action,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      authority: data.authority.present ? data.authority.value : this.authority,
      installationId: data.installationId.present
          ? data.installationId.value
          : this.installationId,
      device: data.device.present ? data.device.value : this.device,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      resultingRevision: data.resultingRevision.present
          ? data.resultingRevision.value
          : this.resultingRevision,
      serverTimestamp: data.serverTimestamp.present
          ? data.serverTimestamp.value
          : this.serverTimestamp,
      clientTimestamp: data.clientTimestamp.present
          ? data.clientTimestamp.value
          : this.clientTimestamp,
      reason: data.reason.present ? data.reason.value : this.reason,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditEventData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('contestId: $contestId, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('publicationId: $publicationId, ')
          ..write('action: $action, ')
          ..write('actorId: $actorId, ')
          ..write('authority: $authority, ')
          ..write('installationId: $installationId, ')
          ..write('device: $device, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('resultingRevision: $resultingRevision, ')
          ..write('serverTimestamp: $serverTimestamp, ')
          ..write('clientTimestamp: $clientTimestamp, ')
          ..write('reason: $reason, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    contestId,
    ownerAccountId,
    publicationId,
    action,
    actorId,
    authority,
    installationId,
    device,
    baseRevision,
    resultingRevision,
    serverTimestamp,
    clientTimestamp,
    reason,
    outcome,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditEventData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.contestId == this.contestId &&
          other.ownerAccountId == this.ownerAccountId &&
          other.publicationId == this.publicationId &&
          other.action == this.action &&
          other.actorId == this.actorId &&
          other.authority == this.authority &&
          other.installationId == this.installationId &&
          other.device == this.device &&
          other.baseRevision == this.baseRevision &&
          other.resultingRevision == this.resultingRevision &&
          other.serverTimestamp == this.serverTimestamp &&
          other.clientTimestamp == this.clientTimestamp &&
          other.reason == this.reason &&
          other.outcome == this.outcome);
}

class AuditEventsCompanion extends UpdateCompanion<AuditEventData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String?> contestId;
  final Value<String?> ownerAccountId;
  final Value<String?> publicationId;
  final Value<String> action;
  final Value<String?> actorId;
  final Value<String> authority;
  final Value<String?> installationId;
  final Value<String?> device;
  final Value<int?> baseRevision;
  final Value<int?> resultingRevision;
  final Value<String> serverTimestamp;
  final Value<String?> clientTimestamp;
  final Value<String?> reason;
  final Value<String> outcome;
  final Value<int> rowid;
  const AuditEventsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.contestId = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.publicationId = const Value.absent(),
    this.action = const Value.absent(),
    this.actorId = const Value.absent(),
    this.authority = const Value.absent(),
    this.installationId = const Value.absent(),
    this.device = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.resultingRevision = const Value.absent(),
    this.serverTimestamp = const Value.absent(),
    this.clientTimestamp = const Value.absent(),
    this.reason = const Value.absent(),
    this.outcome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditEventsCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    this.contestId = const Value.absent(),
    this.ownerAccountId = const Value.absent(),
    this.publicationId = const Value.absent(),
    required String action,
    this.actorId = const Value.absent(),
    required String authority,
    this.installationId = const Value.absent(),
    this.device = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.resultingRevision = const Value.absent(),
    required String serverTimestamp,
    this.clientTimestamp = const Value.absent(),
    this.reason = const Value.absent(),
    required String outcome,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       authority = Value(authority),
       serverTimestamp = Value(serverTimestamp),
       outcome = Value(outcome);
  static Insertable<AuditEventData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? contestId,
    Expression<String>? ownerAccountId,
    Expression<String>? publicationId,
    Expression<String>? action,
    Expression<String>? actorId,
    Expression<String>? authority,
    Expression<String>? installationId,
    Expression<String>? device,
    Expression<int>? baseRevision,
    Expression<int>? resultingRevision,
    Expression<String>? serverTimestamp,
    Expression<String>? clientTimestamp,
    Expression<String>? reason,
    Expression<String>? outcome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (contestId != null) 'contest_id': contestId,
      if (ownerAccountId != null) 'owner_account_id': ownerAccountId,
      if (publicationId != null) 'publication_id': publicationId,
      if (action != null) 'action': action,
      if (actorId != null) 'actor_id': actorId,
      if (authority != null) 'authority': authority,
      if (installationId != null) 'installation_id': installationId,
      if (device != null) 'device': device,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (resultingRevision != null) 'resulting_revision': resultingRevision,
      if (serverTimestamp != null) 'server_timestamp': serverTimestamp,
      if (clientTimestamp != null) 'client_timestamp': clientTimestamp,
      if (reason != null) 'reason': reason,
      if (outcome != null) 'outcome': outcome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String?>? contestId,
    Value<String?>? ownerAccountId,
    Value<String?>? publicationId,
    Value<String>? action,
    Value<String?>? actorId,
    Value<String>? authority,
    Value<String?>? installationId,
    Value<String?>? device,
    Value<int?>? baseRevision,
    Value<int?>? resultingRevision,
    Value<String>? serverTimestamp,
    Value<String?>? clientTimestamp,
    Value<String?>? reason,
    Value<String>? outcome,
    Value<int>? rowid,
  }) {
    return AuditEventsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      contestId: contestId ?? this.contestId,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      publicationId: publicationId ?? this.publicationId,
      action: action ?? this.action,
      actorId: actorId ?? this.actorId,
      authority: authority ?? this.authority,
      installationId: installationId ?? this.installationId,
      device: device ?? this.device,
      baseRevision: baseRevision ?? this.baseRevision,
      resultingRevision: resultingRevision ?? this.resultingRevision,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      clientTimestamp: clientTimestamp ?? this.clientTimestamp,
      reason: reason ?? this.reason,
      outcome: outcome ?? this.outcome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (contestId.present) {
      map['contest_id'] = Variable<String>(contestId.value);
    }
    if (ownerAccountId.present) {
      map['owner_account_id'] = Variable<String>(ownerAccountId.value);
    }
    if (publicationId.present) {
      map['publication_id'] = Variable<String>(publicationId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (authority.present) {
      map['authority'] = Variable<String>(authority.value);
    }
    if (installationId.present) {
      map['installation_id'] = Variable<String>(installationId.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (resultingRevision.present) {
      map['resulting_revision'] = Variable<int>(resultingRevision.value);
    }
    if (serverTimestamp.present) {
      map['server_timestamp'] = Variable<String>(serverTimestamp.value);
    }
    if (clientTimestamp.present) {
      map['client_timestamp'] = Variable<String>(clientTimestamp.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditEventsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('contestId: $contestId, ')
          ..write('ownerAccountId: $ownerAccountId, ')
          ..write('publicationId: $publicationId, ')
          ..write('action: $action, ')
          ..write('actorId: $actorId, ')
          ..write('authority: $authority, ')
          ..write('installationId: $installationId, ')
          ..write('device: $device, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('resultingRevision: $resultingRevision, ')
          ..write('serverTimestamp: $serverTimestamp, ')
          ..write('clientTimestamp: $clientTimestamp, ')
          ..write('reason: $reason, ')
          ..write('outcome: $outcome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncPositionsTable extends LocalSyncPositions
    with TableInfo<$LocalSyncPositionsTable, LocalSyncPositionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    check: () => scopeKind.isIn(const ['Contest', 'Director']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedSequenceMeta =
      const VerificationMeta('lastSyncedSequence');
  @override
  late final GeneratedColumn<int> lastSyncedSequence = GeneratedColumn<int>(
    'last_synced_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<String> lastSyncedAt = GeneratedColumn<String>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    scopeKind,
    scopeId,
    lastSyncedSequence,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncPositionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
    }
    if (data.containsKey('last_synced_sequence')) {
      context.handle(
        _lastSyncedSequenceMeta,
        lastSyncedSequence.isAcceptableOrUnknown(
          data['last_synced_sequence']!,
          _lastSyncedSequenceMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scopeKind, scopeId};
  @override
  LocalSyncPositionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncPositionData(
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      lastSyncedSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_sequence'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $LocalSyncPositionsTable createAlias(String alias) {
    return $LocalSyncPositionsTable(attachedDatabase, alias);
  }
}

class LocalSyncPositionData extends DataClass
    implements Insertable<LocalSyncPositionData> {
  /// `Contest` or `Director`.
  final String scopeKind;

  /// The contest id or the director's account id.
  final String scopeId;
  final int lastSyncedSequence;
  final String? lastSyncedAt;
  const LocalSyncPositionData({
    required this.scopeKind,
    required this.scopeId,
    required this.lastSyncedSequence,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['last_synced_sequence'] = Variable<int>(lastSyncedSequence);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<String>(lastSyncedAt);
    }
    return map;
  }

  LocalSyncPositionsCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncPositionsCompanion(
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      lastSyncedSequence: Value(lastSyncedSequence),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory LocalSyncPositionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncPositionData(
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      lastSyncedSequence: serializer.fromJson<int>(json['lastSyncedSequence']),
      lastSyncedAt: serializer.fromJson<String?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'lastSyncedSequence': serializer.toJson<int>(lastSyncedSequence),
      'lastSyncedAt': serializer.toJson<String?>(lastSyncedAt),
    };
  }

  LocalSyncPositionData copyWith({
    String? scopeKind,
    String? scopeId,
    int? lastSyncedSequence,
    Value<String?> lastSyncedAt = const Value.absent(),
  }) => LocalSyncPositionData(
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    lastSyncedSequence: lastSyncedSequence ?? this.lastSyncedSequence,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  LocalSyncPositionData copyWithCompanion(LocalSyncPositionsCompanion data) {
    return LocalSyncPositionData(
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      lastSyncedSequence: data.lastSyncedSequence.present
          ? data.lastSyncedSequence.value
          : this.lastSyncedSequence,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncPositionData(')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('lastSyncedSequence: $lastSyncedSequence, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(scopeKind, scopeId, lastSyncedSequence, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncPositionData &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.lastSyncedSequence == this.lastSyncedSequence &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class LocalSyncPositionsCompanion
    extends UpdateCompanion<LocalSyncPositionData> {
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<int> lastSyncedSequence;
  final Value<String?> lastSyncedAt;
  final Value<int> rowid;
  const LocalSyncPositionsCompanion({
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.lastSyncedSequence = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncPositionsCompanion.insert({
    required String scopeKind,
    required String scopeId,
    this.lastSyncedSequence = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId);
  static Insertable<LocalSyncPositionData> custom({
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<int>? lastSyncedSequence,
    Expression<String>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (lastSyncedSequence != null)
        'last_synced_sequence': lastSyncedSequence,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncPositionsCompanion copyWith({
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<int>? lastSyncedSequence,
    Value<String?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return LocalSyncPositionsCompanion(
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      lastSyncedSequence: lastSyncedSequence ?? this.lastSyncedSequence,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (lastSyncedSequence.present) {
      map['last_synced_sequence'] = Variable<int>(lastSyncedSequence.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<String>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncPositionsCompanion(')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('lastSyncedSequence: $lastSyncedSequence, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SoarScoreDatabase extends GeneratedDatabase {
  _$SoarScoreDatabase(QueryExecutor e) : super(e);
  $SoarScoreDatabaseManager get managers => $SoarScoreDatabaseManager(this);
  late final $ContestsTable contests = $ContestsTable(this);
  late final $LandingTablesTable landingTables = $LandingTablesTable(this);
  late final $LandingResultsTable landingResults = $LandingResultsTable(this);
  late final $DisciplineProfilesTable disciplineProfiles =
      $DisciplineProfilesTable(this);
  late final $DisciplineConfigFieldsTable disciplineConfigFields =
      $DisciplineConfigFieldsTable(this);
  late final $DisciplineScoreFieldsTable disciplineScoreFields =
      $DisciplineScoreFieldsTable(this);
  late final $DisciplineValidationsTable disciplineValidations =
      $DisciplineValidationsTable(this);
  late final $DisciplineFormulasTable disciplineFormulas =
      $DisciplineFormulasTable(this);
  late final $DisciplineRulesTable disciplineRules = $DisciplineRulesTable(
    this,
  );
  late final $ContestConfigurationPresetsTable contestConfigurationPresets =
      $ContestConfigurationPresetsTable(this);
  late final $ContestConfigurationRevisionsTable contestConfigurationRevisions =
      $ContestConfigurationRevisionsTable(this);
  late final $ParticipantProfilesTable participantProfiles =
      $ParticipantProfilesTable(this);
  late final $RolesTable roles = $RolesTable(this);
  late final $ContestParticipationsTable contestParticipations =
      $ContestParticipationsTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $TeamMembershipsTable teamMemberships = $TeamMembershipsTable(
    this,
  );
  late final $ModelCatalogsTable modelCatalogs = $ModelCatalogsTable(this);
  late final $ContestModelLinksTable contestModelLinks =
      $ContestModelLinksTable(this);
  late final $MutationRecordsTable mutationRecords = $MutationRecordsTable(
    this,
  );
  late final $ConflictRecordsTable conflictRecords = $ConflictRecordsTable(
    this,
  );
  late final $TombstonesTable tombstones = $TombstonesTable(this);
  late final $AuditEventsTable auditEvents = $AuditEventsTable(this);
  late final $LocalSyncPositionsTable localSyncPositions =
      $LocalSyncPositionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contests,
    landingTables,
    landingResults,
    disciplineProfiles,
    disciplineConfigFields,
    disciplineScoreFields,
    disciplineValidations,
    disciplineFormulas,
    disciplineRules,
    contestConfigurationPresets,
    contestConfigurationRevisions,
    participantProfiles,
    roles,
    contestParticipations,
    teams,
    teamMemberships,
    modelCatalogs,
    contestModelLinks,
    mutationRecords,
    conflictRecords,
    tombstones,
    auditEvents,
    localSyncPositions,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contests',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('contest_configuration_revisions', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contests',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contest_participations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contests',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('teams', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contests',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('team_memberships', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contests',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contest_model_links', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ContestsTableCreateCompanionBuilder = ContestsCompanion Function({
  required String id,
  required String name,
  required String startDateTime,
  required String endDateTime,
  required String timezone,
  Value<String?> host,
  Value<String?> city,
  Value<String?> state,
  Value<String?> country,
  Value<String?> ownerAccountId,
  required String lifecycleState,
  required String scoringAccess,
  required String adminLock,
  Value<int?> resultsHiddenThroughRound,
  Value<String?> resultsHiddenAt,
  Value<bool> localArchive,
  required String createdAt,
  required String updatedAt,
  Value<int> revision,
  Value<int> rowid,
});
typedef $$ContestsTableUpdateCompanionBuilder = ContestsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> startDateTime,
  Value<String> endDateTime,
  Value<String> timezone,
  Value<String?> host,
  Value<String?> city,
  Value<String?> state,
  Value<String?> country,
  Value<String?> ownerAccountId,
  Value<String> lifecycleState,
  Value<String> scoringAccess,
  Value<String> adminLock,
  Value<int?> resultsHiddenThroughRound,
  Value<String?> resultsHiddenAt,
  Value<bool> localArchive,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> revision,
  Value<int> rowid,
});

final class $$ContestsTableReferences
    extends BaseReferences<_$SoarScoreDatabase, $ContestsTable, ContestData> {
  $$ContestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $ContestConfigurationRevisionsTable,
    List<ContestConfigurationRevisionData>
  >
  _contestConfigurationRevisionsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestConfigurationRevisions,
        aliasName: 'contests__id__contest_configuration_revisions__contest_id',
      );

  $$ContestConfigurationRevisionsTableProcessedTableManager
  get contestConfigurationRevisionsRefs {
    final manager = $$ContestConfigurationRevisionsTableTableManager(
      $_db,
      $_db.contestConfigurationRevisions,
    ).filter((f) => f.contestId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contestConfigurationRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContestParticipationsTable,
    List<ContestParticipationData>
  >
  _contestParticipationsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestParticipations,
        aliasName: 'contests__id__contest_participations__contest_id',
      );

  $$ContestParticipationsTableProcessedTableManager
  get contestParticipationsRefs {
    final manager = $$ContestParticipationsTableTableManager(
      $_db,
      $_db.contestParticipations,
    ).filter((f) => f.contestId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contestParticipationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TeamsTable, List<TeamData>> _teamsRefsTable(
    _$SoarScoreDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.teams,
    aliasName: 'contests__id__teams__contest_id',
  );

  $$TeamsTableProcessedTableManager get teamsRefs {
    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.contestId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_teamsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TeamMembershipsTable, List<TeamMembershipData>>
  _teamMembershipsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.teamMemberships,
        aliasName: 'contests__id__team_memberships__contest_id',
      );

  $$TeamMembershipsTableProcessedTableManager get teamMembershipsRefs {
    final manager = $$TeamMembershipsTableTableManager(
      $_db,
      $_db.teamMemberships,
    ).filter((f) => f.contestId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _teamMembershipsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContestModelLinksTable,
    List<ContestModelLinkData>
  >
  _contestModelLinksRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestModelLinks,
        aliasName: 'contests__id__contest_model_links__contest_id',
      );

  $$ContestModelLinksTableProcessedTableManager get contestModelLinksRefs {
    final manager = $$ContestModelLinksTableTableManager(
      $_db,
      $_db.contestModelLinks,
    ).filter((f) => f.contestId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contestModelLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get startDateTime => $composableBuilder(
    column: $table.startDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDateTime => $composableBuilder(
    column: $table.endDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifecycleState => $composableBuilder(
    column: $table.lifecycleState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoringAccess => $composableBuilder(
    column: $table.scoringAccess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adminLock => $composableBuilder(
    column: $table.adminLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resultsHiddenThroughRound => $composableBuilder(
    column: $table.resultsHiddenThroughRound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultsHiddenAt => $composableBuilder(
    column: $table.resultsHiddenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localArchive => $composableBuilder(
    column: $table.localArchive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contestConfigurationRevisionsRefs(
    Expression<bool> Function(
      $$ContestConfigurationRevisionsTableFilterComposer f,
    )
    f,
  ) {
    final $$ContestConfigurationRevisionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationRevisions,
          getReferencedColumn: (t) => t.contestId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationRevisionsTableFilterComposer(
                $db: $db,
                $table: $db.contestConfigurationRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> contestParticipationsRefs(
    Expression<bool> Function($$ContestParticipationsTableFilterComposer f) f,
  ) {
    final $$ContestParticipationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.contestId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableFilterComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> teamsRefs(
    Expression<bool> Function($$TeamsTableFilterComposer f) f,
  ) {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.contestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> teamMembershipsRefs(
    Expression<bool> Function($$TeamMembershipsTableFilterComposer f) f,
  ) {
    final $$TeamMembershipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMemberships,
      getReferencedColumn: (t) => t.contestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembershipsTableFilterComposer(
            $db: $db,
            $table: $db.teamMemberships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contestModelLinksRefs(
    Expression<bool> Function($$ContestModelLinksTableFilterComposer f) f,
  ) {
    final $$ContestModelLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contestModelLinks,
      getReferencedColumn: (t) => t.contestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestModelLinksTableFilterComposer(
            $db: $db,
            $table: $db.contestModelLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get startDateTime => $composableBuilder(
    column: $table.startDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDateTime => $composableBuilder(
    column: $table.endDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycleState => $composableBuilder(
    column: $table.lifecycleState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringAccess => $composableBuilder(
    column: $table.scoringAccess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adminLock => $composableBuilder(
    column: $table.adminLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resultsHiddenThroughRound => $composableBuilder(
    column: $table.resultsHiddenThroughRound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultsHiddenAt => $composableBuilder(
    column: $table.resultsHiddenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localArchive => $composableBuilder(
    column: $table.localArchive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
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

  GeneratedColumn<String> get startDateTime => $composableBuilder(
    column: $table.startDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endDateTime => $composableBuilder(
    column: $table.endDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lifecycleState => $composableBuilder(
    column: $table.lifecycleState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scoringAccess => $composableBuilder(
    column: $table.scoringAccess,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adminLock =>
      $composableBuilder(column: $table.adminLock, builder: (column) => column);

  GeneratedColumn<int> get resultsHiddenThroughRound => $composableBuilder(
    column: $table.resultsHiddenThroughRound,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultsHiddenAt => $composableBuilder(
    column: $table.resultsHiddenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get localArchive => $composableBuilder(
    column: $table.localArchive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  Expression<T> contestConfigurationRevisionsRefs<T extends Object>(
    Expression<T> Function(
      $$ContestConfigurationRevisionsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ContestConfigurationRevisionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationRevisions,
          getReferencedColumn: (t) => t.contestId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationRevisionsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestConfigurationRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> contestParticipationsRefs<T extends Object>(
    Expression<T> Function($$ContestParticipationsTableAnnotationComposer a) f,
  ) {
    final $$ContestParticipationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.contestId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> teamsRefs<T extends Object>(
    Expression<T> Function($$TeamsTableAnnotationComposer a) f,
  ) {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.contestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> teamMembershipsRefs<T extends Object>(
    Expression<T> Function($$TeamMembershipsTableAnnotationComposer a) f,
  ) {
    final $$TeamMembershipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMemberships,
      getReferencedColumn: (t) => t.contestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembershipsTableAnnotationComposer(
            $db: $db,
            $table: $db.teamMemberships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> contestModelLinksRefs<T extends Object>(
    Expression<T> Function($$ContestModelLinksTableAnnotationComposer a) f,
  ) {
    final $$ContestModelLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestModelLinks,
          getReferencedColumn: (t) => t.contestId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestModelLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.contestModelLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
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
          (ContestData, $$ContestsTableReferences),
          ContestData,
          PrefetchHooks Function({
            bool contestConfigurationRevisionsRefs,
            bool contestParticipationsRefs,
            bool teamsRefs,
            bool teamMembershipsRefs,
            bool contestModelLinksRefs,
          })
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
                Value<String> startDateTime = const Value.absent(),
                Value<String> endDateTime = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String?> host = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<String> lifecycleState = const Value.absent(),
                Value<String> scoringAccess = const Value.absent(),
                Value<String> adminLock = const Value.absent(),
                Value<int?> resultsHiddenThroughRound = const Value.absent(),
                Value<String?> resultsHiddenAt = const Value.absent(),
                Value<bool> localArchive = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestsCompanion(
                id: id,
                name: name,
                startDateTime: startDateTime,
                endDateTime: endDateTime,
                timezone: timezone,
                host: host,
                city: city,
                state: state,
                country: country,
                ownerAccountId: ownerAccountId,
                lifecycleState: lifecycleState,
                scoringAccess: scoringAccess,
                adminLock: adminLock,
                resultsHiddenThroughRound: resultsHiddenThroughRound,
                resultsHiddenAt: resultsHiddenAt,
                localArchive: localArchive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String startDateTime,
                required String endDateTime,
                required String timezone,
                Value<String?> host = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                required String lifecycleState,
                required String scoringAccess,
                required String adminLock,
                Value<int?> resultsHiddenThroughRound = const Value.absent(),
                Value<String?> resultsHiddenAt = const Value.absent(),
                Value<bool> localArchive = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestsCompanion.insert(
                id: id,
                name: name,
                startDateTime: startDateTime,
                endDateTime: endDateTime,
                timezone: timezone,
                host: host,
                city: city,
                state: state,
                country: country,
                ownerAccountId: ownerAccountId,
                lifecycleState: lifecycleState,
                scoringAccess: scoringAccess,
                adminLock: adminLock,
                resultsHiddenThroughRound: resultsHiddenThroughRound,
                resultsHiddenAt: resultsHiddenAt,
                localArchive: localArchive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContestsTable, ContestData>(table),
                  $$ContestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                contestConfigurationRevisionsRefs = false,
                contestParticipationsRefs = false,
                teamsRefs = false,
                teamMembershipsRefs = false,
                contestModelLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (contestConfigurationRevisionsRefs)
                      db.contestConfigurationRevisions,
                    if (contestParticipationsRefs) db.contestParticipations,
                    if (teamsRefs) db.teams,
                    if (teamMembershipsRefs) db.teamMemberships,
                    if (contestModelLinksRefs) db.contestModelLinks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (contestConfigurationRevisionsRefs)
                        await $_getPrefetchedData<
                          ContestData,
                          $ContestsTable,
                          ContestConfigurationRevisionData
                        >(
                          currentTable: table,
                          referencedTable: $$ContestsTableReferences
                              ._contestConfigurationRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContestsTableReferences(
                                db,
                                table,
                                p0,
                              ).contestConfigurationRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contestId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contestParticipationsRefs)
                        await $_getPrefetchedData<
                          ContestData,
                          $ContestsTable,
                          ContestParticipationData
                        >(
                          currentTable: table,
                          referencedTable: $$ContestsTableReferences
                              ._contestParticipationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContestsTableReferences(
                                db,
                                table,
                                p0,
                              ).contestParticipationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contestId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (teamsRefs)
                        await $_getPrefetchedData<
                          ContestData,
                          $ContestsTable,
                          TeamData
                        >(
                          currentTable: table,
                          referencedTable: $$ContestsTableReferences
                              ._teamsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContestsTableReferences(
                                db,
                                table,
                                p0,
                              ).teamsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contestId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (teamMembershipsRefs)
                        await $_getPrefetchedData<
                          ContestData,
                          $ContestsTable,
                          TeamMembershipData
                        >(
                          currentTable: table,
                          referencedTable: $$ContestsTableReferences
                              ._teamMembershipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContestsTableReferences(
                                db,
                                table,
                                p0,
                              ).teamMembershipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contestId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contestModelLinksRefs)
                        await $_getPrefetchedData<
                          ContestData,
                          $ContestsTable,
                          ContestModelLinkData
                        >(
                          currentTable: table,
                          referencedTable: $$ContestsTableReferences
                              ._contestModelLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContestsTableReferences(
                                db,
                                table,
                                p0,
                              ).contestModelLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contestId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (ContestData, $$ContestsTableReferences),
      ContestData,
      PrefetchHooks Function({
        bool contestConfigurationRevisionsRefs,
        bool contestParticipationsRefs,
        bool teamsRefs,
        bool teamMembershipsRefs,
        bool contestModelLinksRefs,
      })
    >;
typedef $$LandingTablesTableCreateCompanionBuilder =
    LandingTablesCompanion Function({
      required String id,
      Value<String?> ownerAccountId,
      required String name,
      required String inputUnit,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$LandingTablesTableUpdateCompanionBuilder =
    LandingTablesCompanion Function({
      Value<String> id,
      Value<String?> ownerAccountId,
      Value<String> name,
      Value<String> inputUnit,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$LandingTablesTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $LandingTablesTable,
          LandingTableData
        > {
  $$LandingTablesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LandingResultsTable, List<LandingResultData>>
  _landingResultsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.landingResults,
        aliasName: 'landing_tables__id__landing_results__landing_table_id',
      );

  $$LandingResultsTableProcessedTableManager get landingResultsRefs {
    final manager = $$LandingResultsTableTableManager(
      $_db,
      $_db.landingResults,
    ).filter((f) => f.landingTableId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_landingResultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DisciplineProfilesTable,
    List<DisciplineProfileData>
  >
  _disciplineProfilesRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.disciplineProfiles,
        aliasName:
            'landing_tables__id__discipline_profiles__default_landing_table_id',
      );

  $$DisciplineProfilesTableProcessedTableManager get disciplineProfilesRefs {
    final manager =
        $$DisciplineProfilesTableTableManager(
          $_db,
          $_db.disciplineProfiles,
        ).filter(
          (f) =>
              f.defaultLandingTableId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _disciplineProfilesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContestConfigurationPresetsTable,
    List<ContestConfigurationPresetData>
  >
  _contestConfigurationPresetsRefsTable(
    _$SoarScoreDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.contestConfigurationPresets,
    aliasName:
        'landing_tables__id__contest_configuration_presets__landing_table_id',
  );

  $$ContestConfigurationPresetsTableProcessedTableManager
  get contestConfigurationPresetsRefs {
    final manager = $$ContestConfigurationPresetsTableTableManager(
      $_db,
      $_db.contestConfigurationPresets,
    ).filter((f) => f.landingTableId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contestConfigurationPresetsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContestConfigurationRevisionsTable,
    List<ContestConfigurationRevisionData>
  >
  _contestConfigurationRevisionsRefsTable(
    _$SoarScoreDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.contestConfigurationRevisions,
    aliasName:
        'landing_tables__id__contest_configuration_revisions__landing_table_id',
  );

  $$ContestConfigurationRevisionsTableProcessedTableManager
  get contestConfigurationRevisionsRefs {
    final manager = $$ContestConfigurationRevisionsTableTableManager(
      $_db,
      $_db.contestConfigurationRevisions,
    ).filter((f) => f.landingTableId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contestConfigurationRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LandingTablesTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $LandingTablesTable> {
  $$LandingTablesTableFilterComposer({
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

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputUnit => $composableBuilder(
    column: $table.inputUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> landingResultsRefs(
    Expression<bool> Function($$LandingResultsTableFilterComposer f) f,
  ) {
    final $$LandingResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.landingResults,
      getReferencedColumn: (t) => t.landingTableId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingResultsTableFilterComposer(
            $db: $db,
            $table: $db.landingResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> disciplineProfilesRefs(
    Expression<bool> Function($$DisciplineProfilesTableFilterComposer f) f,
  ) {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.defaultLandingTableId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contestConfigurationPresetsRefs(
    Expression<bool> Function(
      $$ContestConfigurationPresetsTableFilterComposer f,
    )
    f,
  ) {
    final $$ContestConfigurationPresetsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationPresets,
          getReferencedColumn: (t) => t.landingTableId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationPresetsTableFilterComposer(
                $db: $db,
                $table: $db.contestConfigurationPresets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> contestConfigurationRevisionsRefs(
    Expression<bool> Function(
      $$ContestConfigurationRevisionsTableFilterComposer f,
    )
    f,
  ) {
    final $$ContestConfigurationRevisionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationRevisions,
          getReferencedColumn: (t) => t.landingTableId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationRevisionsTableFilterComposer(
                $db: $db,
                $table: $db.contestConfigurationRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LandingTablesTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $LandingTablesTable> {
  $$LandingTablesTableOrderingComposer({
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

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputUnit => $composableBuilder(
    column: $table.inputUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LandingTablesTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $LandingTablesTable> {
  $$LandingTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get inputUnit =>
      $composableBuilder(column: $table.inputUnit, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> landingResultsRefs<T extends Object>(
    Expression<T> Function($$LandingResultsTableAnnotationComposer a) f,
  ) {
    final $$LandingResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.landingResults,
      getReferencedColumn: (t) => t.landingTableId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.landingResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> disciplineProfilesRefs<T extends Object>(
    Expression<T> Function($$DisciplineProfilesTableAnnotationComposer a) f,
  ) {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.defaultLandingTableId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> contestConfigurationPresetsRefs<T extends Object>(
    Expression<T> Function(
      $$ContestConfigurationPresetsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ContestConfigurationPresetsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationPresets,
          getReferencedColumn: (t) => t.landingTableId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationPresetsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestConfigurationPresets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> contestConfigurationRevisionsRefs<T extends Object>(
    Expression<T> Function(
      $$ContestConfigurationRevisionsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ContestConfigurationRevisionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationRevisions,
          getReferencedColumn: (t) => t.landingTableId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationRevisionsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestConfigurationRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LandingTablesTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $LandingTablesTable,
          LandingTableData,
          $$LandingTablesTableFilterComposer,
          $$LandingTablesTableOrderingComposer,
          $$LandingTablesTableAnnotationComposer,
          $$LandingTablesTableCreateCompanionBuilder,
          $$LandingTablesTableUpdateCompanionBuilder,
          (LandingTableData, $$LandingTablesTableReferences),
          LandingTableData,
          PrefetchHooks Function({
            bool landingResultsRefs,
            bool disciplineProfilesRefs,
            bool contestConfigurationPresetsRefs,
            bool contestConfigurationRevisionsRefs,
          })
        > {
  $$LandingTablesTableTableManager(
    _$SoarScoreDatabase db,
    $LandingTablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LandingTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LandingTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LandingTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> inputUnit = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LandingTablesCompanion(
                id: id,
                ownerAccountId: ownerAccountId,
                name: name,
                inputUnit: inputUnit,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ownerAccountId = const Value.absent(),
                required String name,
                required String inputUnit,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LandingTablesCompanion.insert(
                id: id,
                ownerAccountId: ownerAccountId,
                name: name,
                inputUnit: inputUnit,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LandingTablesTable, LandingTableData>(table),
                  $$LandingTablesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                landingResultsRefs = false,
                disciplineProfilesRefs = false,
                contestConfigurationPresetsRefs = false,
                contestConfigurationRevisionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (landingResultsRefs) db.landingResults,
                    if (disciplineProfilesRefs) db.disciplineProfiles,
                    if (contestConfigurationPresetsRefs)
                      db.contestConfigurationPresets,
                    if (contestConfigurationRevisionsRefs)
                      db.contestConfigurationRevisions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (landingResultsRefs)
                        await $_getPrefetchedData<
                          LandingTableData,
                          $LandingTablesTable,
                          LandingResultData
                        >(
                          currentTable: table,
                          referencedTable: $$LandingTablesTableReferences
                              ._landingResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LandingTablesTableReferences(
                                db,
                                table,
                                p0,
                              ).landingResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.landingTableId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (disciplineProfilesRefs)
                        await $_getPrefetchedData<
                          LandingTableData,
                          $LandingTablesTable,
                          DisciplineProfileData
                        >(
                          currentTable: table,
                          referencedTable: $$LandingTablesTableReferences
                              ._disciplineProfilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LandingTablesTableReferences(
                                db,
                                table,
                                p0,
                              ).disciplineProfilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.defaultLandingTableId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contestConfigurationPresetsRefs)
                        await $_getPrefetchedData<
                          LandingTableData,
                          $LandingTablesTable,
                          ContestConfigurationPresetData
                        >(
                          currentTable: table,
                          referencedTable: $$LandingTablesTableReferences
                              ._contestConfigurationPresetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LandingTablesTableReferences(
                                db,
                                table,
                                p0,
                              ).contestConfigurationPresetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.landingTableId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contestConfigurationRevisionsRefs)
                        await $_getPrefetchedData<
                          LandingTableData,
                          $LandingTablesTable,
                          ContestConfigurationRevisionData
                        >(
                          currentTable: table,
                          referencedTable: $$LandingTablesTableReferences
                              ._contestConfigurationRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LandingTablesTableReferences(
                                db,
                                table,
                                p0,
                              ).contestConfigurationRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.landingTableId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LandingTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $LandingTablesTable,
      LandingTableData,
      $$LandingTablesTableFilterComposer,
      $$LandingTablesTableOrderingComposer,
      $$LandingTablesTableAnnotationComposer,
      $$LandingTablesTableCreateCompanionBuilder,
      $$LandingTablesTableUpdateCompanionBuilder,
      (LandingTableData, $$LandingTablesTableReferences),
      LandingTableData,
      PrefetchHooks Function({
        bool landingResultsRefs,
        bool disciplineProfilesRefs,
        bool contestConfigurationPresetsRefs,
        bool contestConfigurationRevisionsRefs,
      })
    >;
typedef $$LandingResultsTableCreateCompanionBuilder =
    LandingResultsCompanion Function({
      required String id,
      required String landingTableId,
      required String entryKey,
      required String displayValue,
      required int pointValue,
      required int ordinalPosition,
      Value<int> rowid,
    });
typedef $$LandingResultsTableUpdateCompanionBuilder =
    LandingResultsCompanion Function({
      Value<String> id,
      Value<String> landingTableId,
      Value<String> entryKey,
      Value<String> displayValue,
      Value<int> pointValue,
      Value<int> ordinalPosition,
      Value<int> rowid,
    });

final class $$LandingResultsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $LandingResultsTable,
          LandingResultData
        > {
  $$LandingResultsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LandingTablesTable _landingTableIdTable(_$SoarScoreDatabase db) => db
      .landingTables
      .createAlias('landing_results__landing_table_id__landing_tables__id');

  $$LandingTablesTableProcessedTableManager get landingTableId {
    final $_column = $_itemColumn<String>('landing_table_id')!;

    final manager = $$LandingTablesTableTableManager(
      $_db,
      $_db.landingTables,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_landingTableIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LandingResultsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $LandingResultsTable> {
  $$LandingResultsTableFilterComposer({
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

  ColumnFilters<String> get entryKey => $composableBuilder(
    column: $table.entryKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointValue => $composableBuilder(
    column: $table.pointValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinalPosition => $composableBuilder(
    column: $table.ordinalPosition,
    builder: (column) => ColumnFilters(column),
  );

  $$LandingTablesTableFilterComposer get landingTableId {
    final $$LandingTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableFilterComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LandingResultsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $LandingResultsTable> {
  $$LandingResultsTableOrderingComposer({
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

  ColumnOrderings<String> get entryKey => $composableBuilder(
    column: $table.entryKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointValue => $composableBuilder(
    column: $table.pointValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinalPosition => $composableBuilder(
    column: $table.ordinalPosition,
    builder: (column) => ColumnOrderings(column),
  );

  $$LandingTablesTableOrderingComposer get landingTableId {
    final $$LandingTablesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableOrderingComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LandingResultsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $LandingResultsTable> {
  $$LandingResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryKey =>
      $composableBuilder(column: $table.entryKey, builder: (column) => column);

  GeneratedColumn<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pointValue => $composableBuilder(
    column: $table.pointValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordinalPosition => $composableBuilder(
    column: $table.ordinalPosition,
    builder: (column) => column,
  );

  $$LandingTablesTableAnnotationComposer get landingTableId {
    final $$LandingTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LandingResultsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $LandingResultsTable,
          LandingResultData,
          $$LandingResultsTableFilterComposer,
          $$LandingResultsTableOrderingComposer,
          $$LandingResultsTableAnnotationComposer,
          $$LandingResultsTableCreateCompanionBuilder,
          $$LandingResultsTableUpdateCompanionBuilder,
          (LandingResultData, $$LandingResultsTableReferences),
          LandingResultData,
          PrefetchHooks Function({bool landingTableId})
        > {
  $$LandingResultsTableTableManager(
    _$SoarScoreDatabase db,
    $LandingResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LandingResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LandingResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LandingResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> landingTableId = const Value.absent(),
                Value<String> entryKey = const Value.absent(),
                Value<String> displayValue = const Value.absent(),
                Value<int> pointValue = const Value.absent(),
                Value<int> ordinalPosition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LandingResultsCompanion(
                id: id,
                landingTableId: landingTableId,
                entryKey: entryKey,
                displayValue: displayValue,
                pointValue: pointValue,
                ordinalPosition: ordinalPosition,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String landingTableId,
                required String entryKey,
                required String displayValue,
                required int pointValue,
                required int ordinalPosition,
                Value<int> rowid = const Value.absent(),
              }) => LandingResultsCompanion.insert(
                id: id,
                landingTableId: landingTableId,
                entryKey: entryKey,
                displayValue: displayValue,
                pointValue: pointValue,
                ordinalPosition: ordinalPosition,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LandingResultsTable, LandingResultData>(table),
                  $$LandingResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({landingTableId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (landingTableId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.landingTableId,
                        referencedTable: $$LandingResultsTableReferences
                            ._landingTableIdTable(db),
                        referencedColumn: $$LandingResultsTableReferences
                            ._landingTableIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LandingResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $LandingResultsTable,
      LandingResultData,
      $$LandingResultsTableFilterComposer,
      $$LandingResultsTableOrderingComposer,
      $$LandingResultsTableAnnotationComposer,
      $$LandingResultsTableCreateCompanionBuilder,
      $$LandingResultsTableUpdateCompanionBuilder,
      (LandingResultData, $$LandingResultsTableReferences),
      LandingResultData,
      PrefetchHooks Function({bool landingTableId})
    >;
typedef $$DisciplineProfilesTableCreateCompanionBuilder =
    DisciplineProfilesCompanion Function({
      required String id,
      required String type,
      required int version,
      required String name,
      Value<String?> description,
      required String category,
      Value<String?> defaultLandingTableId,
      Value<String?> defaultOptions,
      required String status,
      Value<String?> supersededBy,
      required String createdBy,
      required String createdAt,
      Value<String?> updatedBy,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$DisciplineProfilesTableUpdateCompanionBuilder =
    DisciplineProfilesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<int> version,
      Value<String> name,
      Value<String?> description,
      Value<String> category,
      Value<String?> defaultLandingTableId,
      Value<String?> defaultOptions,
      Value<String> status,
      Value<String?> supersededBy,
      Value<String> createdBy,
      Value<String> createdAt,
      Value<String?> updatedBy,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

final class $$DisciplineProfilesTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $DisciplineProfilesTable,
          DisciplineProfileData
        > {
  $$DisciplineProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LandingTablesTable _defaultLandingTableIdTable(
    _$SoarScoreDatabase db,
  ) => db.landingTables.createAlias(
    'discipline_profiles__default_landing_table_id__landing_tables__id',
  );

  $$LandingTablesTableProcessedTableManager? get defaultLandingTableId {
    final $_column = $_itemColumn<String>('default_landing_table_id');
    if ($_column == null) return null;
    final manager = $$LandingTablesTableTableManager(
      $_db,
      $_db.landingTables,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _defaultLandingTableIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DisciplineProfilesTable _supersededByTable(_$SoarScoreDatabase db) =>
      db.disciplineProfiles.createAlias(
        'discipline_profiles__superseded_by__discipline_profiles__id',
      );

  $$DisciplineProfilesTableProcessedTableManager? get supersededBy {
    final $_column = $_itemColumn<String>('superseded_by');
    if ($_column == null) return null;
    final manager = $$DisciplineProfilesTableTableManager(
      $_db,
      $_db.disciplineProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supersededByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $DisciplineConfigFieldsTable,
    List<DisciplineConfigFieldData>
  >
  _disciplineConfigFieldsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.disciplineConfigFields,
        aliasName: 'discipline_profiles__id__discipline_config_fields__discipline_profile_id',
      );

  $$DisciplineConfigFieldsTableProcessedTableManager
  get disciplineConfigFieldsRefs {
    final manager =
        $$DisciplineConfigFieldsTableTableManager(
          $_db,
          $_db.disciplineConfigFields,
        ).filter(
          (f) =>
              f.disciplineProfileId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _disciplineConfigFieldsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DisciplineScoreFieldsTable,
    List<DisciplineScoreFieldData>
  >
  _disciplineScoreFieldsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.disciplineScoreFields,
        aliasName: 'discipline_profiles__id__discipline_score_fields__discipline_profile_id',
      );

  $$DisciplineScoreFieldsTableProcessedTableManager
  get disciplineScoreFieldsRefs {
    final manager =
        $$DisciplineScoreFieldsTableTableManager(
          $_db,
          $_db.disciplineScoreFields,
        ).filter(
          (f) =>
              f.disciplineProfileId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _disciplineScoreFieldsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DisciplineValidationsTable,
    List<DisciplineValidationData>
  >
  _disciplineValidationsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.disciplineValidations,
        aliasName: 'discipline_profiles__id__discipline_validations__discipline_profile_id',
      );

  $$DisciplineValidationsTableProcessedTableManager
  get disciplineValidationsRefs {
    final manager =
        $$DisciplineValidationsTableTableManager(
          $_db,
          $_db.disciplineValidations,
        ).filter(
          (f) =>
              f.disciplineProfileId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _disciplineValidationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DisciplineFormulasTable,
    List<DisciplineFormulaData>
  >
  _disciplineFormulasRefsTable(
    _$SoarScoreDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.disciplineFormulas,
    aliasName:
        'discipline_profiles__id__discipline_formulas__discipline_profile_id',
  );

  $$DisciplineFormulasTableProcessedTableManager get disciplineFormulasRefs {
    final manager =
        $$DisciplineFormulasTableTableManager(
          $_db,
          $_db.disciplineFormulas,
        ).filter(
          (f) =>
              f.disciplineProfileId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _disciplineFormulasRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DisciplineRulesTable, List<DisciplineRuleData>>
  _disciplineRulesRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.disciplineRules,
        aliasName:
            'discipline_profiles__id__discipline_rules__discipline_profile_id',
      );

  $$DisciplineRulesTableProcessedTableManager get disciplineRulesRefs {
    final manager =
        $$DisciplineRulesTableTableManager($_db, $_db.disciplineRules).filter(
          (f) =>
              f.disciplineProfileId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _disciplineRulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContestConfigurationPresetsTable,
    List<ContestConfigurationPresetData>
  >
  _contestConfigurationPresetsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestConfigurationPresets,
        aliasName: 'discipline_profiles__id__contest_configuration_presets__discipline_profile_id',
      );

  $$ContestConfigurationPresetsTableProcessedTableManager
  get contestConfigurationPresetsRefs {
    final manager =
        $$ContestConfigurationPresetsTableTableManager(
          $_db,
          $_db.contestConfigurationPresets,
        ).filter(
          (f) =>
              f.disciplineProfileId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _contestConfigurationPresetsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContestConfigurationRevisionsTable,
    List<ContestConfigurationRevisionData>
  >
  _contestConfigurationRevisionsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestConfigurationRevisions,
        aliasName: 'discipline_profiles__id__contest_configuration_revisions__discipline_profile_id',
      );

  $$ContestConfigurationRevisionsTableProcessedTableManager
  get contestConfigurationRevisionsRefs {
    final manager =
        $$ContestConfigurationRevisionsTableTableManager(
          $_db,
          $_db.contestConfigurationRevisions,
        ).filter(
          (f) =>
              f.disciplineProfileId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _contestConfigurationRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DisciplineProfilesTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineProfilesTable> {
  $$DisciplineProfilesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultOptions => $composableBuilder(
    column: $table.defaultOptions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LandingTablesTableFilterComposer get defaultLandingTableId {
    final $$LandingTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultLandingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableFilterComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DisciplineProfilesTableFilterComposer get supersededBy {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supersededBy,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> disciplineConfigFieldsRefs(
    Expression<bool> Function($$DisciplineConfigFieldsTableFilterComposer f) f,
  ) {
    final $$DisciplineConfigFieldsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.disciplineConfigFields,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineConfigFieldsTableFilterComposer(
                $db: $db,
                $table: $db.disciplineConfigFields,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> disciplineScoreFieldsRefs(
    Expression<bool> Function($$DisciplineScoreFieldsTableFilterComposer f) f,
  ) {
    final $$DisciplineScoreFieldsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.disciplineScoreFields,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineScoreFieldsTableFilterComposer(
                $db: $db,
                $table: $db.disciplineScoreFields,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> disciplineValidationsRefs(
    Expression<bool> Function($$DisciplineValidationsTableFilterComposer f) f,
  ) {
    final $$DisciplineValidationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.disciplineValidations,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineValidationsTableFilterComposer(
                $db: $db,
                $table: $db.disciplineValidations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> disciplineFormulasRefs(
    Expression<bool> Function($$DisciplineFormulasTableFilterComposer f) f,
  ) {
    final $$DisciplineFormulasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.disciplineFormulas,
      getReferencedColumn: (t) => t.disciplineProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineFormulasTableFilterComposer(
            $db: $db,
            $table: $db.disciplineFormulas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> disciplineRulesRefs(
    Expression<bool> Function($$DisciplineRulesTableFilterComposer f) f,
  ) {
    final $$DisciplineRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.disciplineRules,
      getReferencedColumn: (t) => t.disciplineProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineRulesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contestConfigurationPresetsRefs(
    Expression<bool> Function(
      $$ContestConfigurationPresetsTableFilterComposer f,
    )
    f,
  ) {
    final $$ContestConfigurationPresetsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationPresets,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationPresetsTableFilterComposer(
                $db: $db,
                $table: $db.contestConfigurationPresets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> contestConfigurationRevisionsRefs(
    Expression<bool> Function(
      $$ContestConfigurationRevisionsTableFilterComposer f,
    )
    f,
  ) {
    final $$ContestConfigurationRevisionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationRevisions,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationRevisionsTableFilterComposer(
                $db: $db,
                $table: $db.contestConfigurationRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DisciplineProfilesTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineProfilesTable> {
  $$DisciplineProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultOptions => $composableBuilder(
    column: $table.defaultOptions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LandingTablesTableOrderingComposer get defaultLandingTableId {
    final $$LandingTablesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultLandingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableOrderingComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DisciplineProfilesTableOrderingComposer get supersededBy {
    final $$DisciplineProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supersededBy,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineProfilesTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineProfilesTable> {
  $$DisciplineProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get defaultOptions => $composableBuilder(
    column: $table.defaultOptions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LandingTablesTableAnnotationComposer get defaultLandingTableId {
    final $$LandingTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultLandingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DisciplineProfilesTableAnnotationComposer get supersededBy {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.supersededBy,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> disciplineConfigFieldsRefs<T extends Object>(
    Expression<T> Function($$DisciplineConfigFieldsTableAnnotationComposer a) f,
  ) {
    final $$DisciplineConfigFieldsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.disciplineConfigFields,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineConfigFieldsTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineConfigFields,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> disciplineScoreFieldsRefs<T extends Object>(
    Expression<T> Function($$DisciplineScoreFieldsTableAnnotationComposer a) f,
  ) {
    final $$DisciplineScoreFieldsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.disciplineScoreFields,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineScoreFieldsTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineScoreFields,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> disciplineValidationsRefs<T extends Object>(
    Expression<T> Function($$DisciplineValidationsTableAnnotationComposer a) f,
  ) {
    final $$DisciplineValidationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.disciplineValidations,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineValidationsTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineValidations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> disciplineFormulasRefs<T extends Object>(
    Expression<T> Function($$DisciplineFormulasTableAnnotationComposer a) f,
  ) {
    final $$DisciplineFormulasTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.disciplineFormulas,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineFormulasTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineFormulas,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> disciplineRulesRefs<T extends Object>(
    Expression<T> Function($$DisciplineRulesTableAnnotationComposer a) f,
  ) {
    final $$DisciplineRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.disciplineRules,
      getReferencedColumn: (t) => t.disciplineProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.disciplineRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> contestConfigurationPresetsRefs<T extends Object>(
    Expression<T> Function(
      $$ContestConfigurationPresetsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ContestConfigurationPresetsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationPresets,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationPresetsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestConfigurationPresets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> contestConfigurationRevisionsRefs<T extends Object>(
    Expression<T> Function(
      $$ContestConfigurationRevisionsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ContestConfigurationRevisionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationRevisions,
          getReferencedColumn: (t) => t.disciplineProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationRevisionsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestConfigurationRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DisciplineProfilesTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $DisciplineProfilesTable,
          DisciplineProfileData,
          $$DisciplineProfilesTableFilterComposer,
          $$DisciplineProfilesTableOrderingComposer,
          $$DisciplineProfilesTableAnnotationComposer,
          $$DisciplineProfilesTableCreateCompanionBuilder,
          $$DisciplineProfilesTableUpdateCompanionBuilder,
          (DisciplineProfileData, $$DisciplineProfilesTableReferences),
          DisciplineProfileData,
          PrefetchHooks Function({
            bool defaultLandingTableId,
            bool supersededBy,
            bool disciplineConfigFieldsRefs,
            bool disciplineScoreFieldsRefs,
            bool disciplineValidationsRefs,
            bool disciplineFormulasRefs,
            bool disciplineRulesRefs,
            bool contestConfigurationPresetsRefs,
            bool contestConfigurationRevisionsRefs,
          })
        > {
  $$DisciplineProfilesTableTableManager(
    _$SoarScoreDatabase db,
    $DisciplineProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisciplineProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DisciplineProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DisciplineProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> defaultLandingTableId = const Value.absent(),
                Value<String?> defaultOptions = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> supersededBy = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisciplineProfilesCompanion(
                id: id,
                type: type,
                version: version,
                name: name,
                description: description,
                category: category,
                defaultLandingTableId: defaultLandingTableId,
                defaultOptions: defaultOptions,
                status: status,
                supersededBy: supersededBy,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedBy: updatedBy,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required int version,
                required String name,
                Value<String?> description = const Value.absent(),
                required String category,
                Value<String?> defaultLandingTableId = const Value.absent(),
                Value<String?> defaultOptions = const Value.absent(),
                required String status,
                Value<String?> supersededBy = const Value.absent(),
                required String createdBy,
                required String createdAt,
                Value<String?> updatedBy = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisciplineProfilesCompanion.insert(
                id: id,
                type: type,
                version: version,
                name: name,
                description: description,
                category: category,
                defaultLandingTableId: defaultLandingTableId,
                defaultOptions: defaultOptions,
                status: status,
                supersededBy: supersededBy,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedBy: updatedBy,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DisciplineProfilesTable, DisciplineProfileData>(
                    table,
                  ),
                  $$DisciplineProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                defaultLandingTableId = false,
                supersededBy = false,
                disciplineConfigFieldsRefs = false,
                disciplineScoreFieldsRefs = false,
                disciplineValidationsRefs = false,
                disciplineFormulasRefs = false,
                disciplineRulesRefs = false,
                contestConfigurationPresetsRefs = false,
                contestConfigurationRevisionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (disciplineConfigFieldsRefs) db.disciplineConfigFields,
                    if (disciplineScoreFieldsRefs) db.disciplineScoreFields,
                    if (disciplineValidationsRefs) db.disciplineValidations,
                    if (disciplineFormulasRefs) db.disciplineFormulas,
                    if (disciplineRulesRefs) db.disciplineRules,
                    if (contestConfigurationPresetsRefs)
                      db.contestConfigurationPresets,
                    if (contestConfigurationRevisionsRefs)
                      db.contestConfigurationRevisions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (defaultLandingTableId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.defaultLandingTableId,
                            referencedTable: $$DisciplineProfilesTableReferences
                                ._defaultLandingTableIdTable(db),
                            referencedColumn:
                                $$DisciplineProfilesTableReferences
                                    ._defaultLandingTableIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (supersededBy) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.supersededBy,
                            referencedTable: $$DisciplineProfilesTableReferences
                                ._supersededByTable(db),
                            referencedColumn:
                                $$DisciplineProfilesTableReferences
                                    ._supersededByTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (disciplineConfigFieldsRefs)
                        await $_getPrefetchedData<
                          DisciplineProfileData,
                          $DisciplineProfilesTable,
                          DisciplineConfigFieldData
                        >(
                          currentTable: table,
                          referencedTable: $$DisciplineProfilesTableReferences
                              ._disciplineConfigFieldsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisciplineProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).disciplineConfigFieldsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.disciplineProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (disciplineScoreFieldsRefs)
                        await $_getPrefetchedData<
                          DisciplineProfileData,
                          $DisciplineProfilesTable,
                          DisciplineScoreFieldData
                        >(
                          currentTable: table,
                          referencedTable: $$DisciplineProfilesTableReferences
                              ._disciplineScoreFieldsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisciplineProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).disciplineScoreFieldsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.disciplineProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (disciplineValidationsRefs)
                        await $_getPrefetchedData<
                          DisciplineProfileData,
                          $DisciplineProfilesTable,
                          DisciplineValidationData
                        >(
                          currentTable: table,
                          referencedTable: $$DisciplineProfilesTableReferences
                              ._disciplineValidationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisciplineProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).disciplineValidationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.disciplineProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (disciplineFormulasRefs)
                        await $_getPrefetchedData<
                          DisciplineProfileData,
                          $DisciplineProfilesTable,
                          DisciplineFormulaData
                        >(
                          currentTable: table,
                          referencedTable: $$DisciplineProfilesTableReferences
                              ._disciplineFormulasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisciplineProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).disciplineFormulasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.disciplineProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (disciplineRulesRefs)
                        await $_getPrefetchedData<
                          DisciplineProfileData,
                          $DisciplineProfilesTable,
                          DisciplineRuleData
                        >(
                          currentTable: table,
                          referencedTable: $$DisciplineProfilesTableReferences
                              ._disciplineRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisciplineProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).disciplineRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.disciplineProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contestConfigurationPresetsRefs)
                        await $_getPrefetchedData<
                          DisciplineProfileData,
                          $DisciplineProfilesTable,
                          ContestConfigurationPresetData
                        >(
                          currentTable: table,
                          referencedTable: $$DisciplineProfilesTableReferences
                              ._contestConfigurationPresetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisciplineProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).contestConfigurationPresetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.disciplineProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contestConfigurationRevisionsRefs)
                        await $_getPrefetchedData<
                          DisciplineProfileData,
                          $DisciplineProfilesTable,
                          ContestConfigurationRevisionData
                        >(
                          currentTable: table,
                          referencedTable: $$DisciplineProfilesTableReferences
                              ._contestConfigurationRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisciplineProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).contestConfigurationRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.disciplineProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DisciplineProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $DisciplineProfilesTable,
      DisciplineProfileData,
      $$DisciplineProfilesTableFilterComposer,
      $$DisciplineProfilesTableOrderingComposer,
      $$DisciplineProfilesTableAnnotationComposer,
      $$DisciplineProfilesTableCreateCompanionBuilder,
      $$DisciplineProfilesTableUpdateCompanionBuilder,
      (DisciplineProfileData, $$DisciplineProfilesTableReferences),
      DisciplineProfileData,
      PrefetchHooks Function({
        bool defaultLandingTableId,
        bool supersededBy,
        bool disciplineConfigFieldsRefs,
        bool disciplineScoreFieldsRefs,
        bool disciplineValidationsRefs,
        bool disciplineFormulasRefs,
        bool disciplineRulesRefs,
        bool contestConfigurationPresetsRefs,
        bool contestConfigurationRevisionsRefs,
      })
    >;
typedef $$DisciplineConfigFieldsTableCreateCompanionBuilder =
    DisciplineConfigFieldsCompanion Function({
      required String id,
      required String disciplineProfileId,
      required String fieldKey,
      required String fieldType,
      required String name,
      Value<String?> description,
      Value<String?> unit,
      required bool required,
      Value<String?> defaultValue,
      Value<String?> options,
      Value<String?> validation,
      required int displayOrder,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$DisciplineConfigFieldsTableUpdateCompanionBuilder =
    DisciplineConfigFieldsCompanion Function({
      Value<String> id,
      Value<String> disciplineProfileId,
      Value<String> fieldKey,
      Value<String> fieldType,
      Value<String> name,
      Value<String?> description,
      Value<String?> unit,
      Value<bool> required,
      Value<String?> defaultValue,
      Value<String?> options,
      Value<String?> validation,
      Value<int> displayOrder,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$DisciplineConfigFieldsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $DisciplineConfigFieldsTable,
          DisciplineConfigFieldData
        > {
  $$DisciplineConfigFieldsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DisciplineProfilesTable _disciplineProfileIdTable(
    _$SoarScoreDatabase db,
  ) => db.disciplineProfiles.createAlias(
    'discipline_config_fields__discipline_profile_id__discipline_profiles__id',
  );

  $$DisciplineProfilesTableProcessedTableManager get disciplineProfileId {
    final $_column = $_itemColumn<String>('discipline_profile_id')!;

    final manager = $$DisciplineProfilesTableTableManager(
      $_db,
      $_db.disciplineProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_disciplineProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DisciplineConfigFieldsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineConfigFieldsTable> {
  $$DisciplineConfigFieldsTableFilterComposer({
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

  ColumnFilters<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validation => $composableBuilder(
    column: $table.validation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DisciplineProfilesTableFilterComposer get disciplineProfileId {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineConfigFieldsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineConfigFieldsTable> {
  $$DisciplineConfigFieldsTableOrderingComposer({
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

  ColumnOrderings<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validation => $composableBuilder(
    column: $table.validation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DisciplineProfilesTableOrderingComposer get disciplineProfileId {
    final $$DisciplineProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineConfigFieldsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineConfigFieldsTable> {
  $$DisciplineConfigFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<String> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);

  GeneratedColumn<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<String> get validation => $composableBuilder(
    column: $table.validation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DisciplineProfilesTableAnnotationComposer get disciplineProfileId {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.disciplineProfileId,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DisciplineConfigFieldsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $DisciplineConfigFieldsTable,
          DisciplineConfigFieldData,
          $$DisciplineConfigFieldsTableFilterComposer,
          $$DisciplineConfigFieldsTableOrderingComposer,
          $$DisciplineConfigFieldsTableAnnotationComposer,
          $$DisciplineConfigFieldsTableCreateCompanionBuilder,
          $$DisciplineConfigFieldsTableUpdateCompanionBuilder,
          (DisciplineConfigFieldData, $$DisciplineConfigFieldsTableReferences),
          DisciplineConfigFieldData,
          PrefetchHooks Function({bool disciplineProfileId})
        > {
  $$DisciplineConfigFieldsTableTableManager(
    _$SoarScoreDatabase db,
    $DisciplineConfigFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisciplineConfigFieldsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DisciplineConfigFieldsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DisciplineConfigFieldsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> disciplineProfileId = const Value.absent(),
                Value<String> fieldKey = const Value.absent(),
                Value<String> fieldType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<String?> defaultValue = const Value.absent(),
                Value<String?> options = const Value.absent(),
                Value<String?> validation = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisciplineConfigFieldsCompanion(
                id: id,
                disciplineProfileId: disciplineProfileId,
                fieldKey: fieldKey,
                fieldType: fieldType,
                name: name,
                description: description,
                unit: unit,
                required: required,
                defaultValue: defaultValue,
                options: options,
                validation: validation,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String disciplineProfileId,
                required String fieldKey,
                required String fieldType,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required bool required,
                Value<String?> defaultValue = const Value.absent(),
                Value<String?> options = const Value.absent(),
                Value<String?> validation = const Value.absent(),
                required int displayOrder,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DisciplineConfigFieldsCompanion.insert(
                id: id,
                disciplineProfileId: disciplineProfileId,
                fieldKey: fieldKey,
                fieldType: fieldType,
                name: name,
                description: description,
                unit: unit,
                required: required,
                defaultValue: defaultValue,
                options: options,
                validation: validation,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $DisciplineConfigFieldsTable,
                    DisciplineConfigFieldData
                  >(table),
                  $$DisciplineConfigFieldsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({disciplineProfileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (disciplineProfileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.disciplineProfileId,
                        referencedTable: $$DisciplineConfigFieldsTableReferences
                            ._disciplineProfileIdTable(db),
                        referencedColumn:
                            $$DisciplineConfigFieldsTableReferences
                                ._disciplineProfileIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DisciplineConfigFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $DisciplineConfigFieldsTable,
      DisciplineConfigFieldData,
      $$DisciplineConfigFieldsTableFilterComposer,
      $$DisciplineConfigFieldsTableOrderingComposer,
      $$DisciplineConfigFieldsTableAnnotationComposer,
      $$DisciplineConfigFieldsTableCreateCompanionBuilder,
      $$DisciplineConfigFieldsTableUpdateCompanionBuilder,
      (DisciplineConfigFieldData, $$DisciplineConfigFieldsTableReferences),
      DisciplineConfigFieldData,
      PrefetchHooks Function({bool disciplineProfileId})
    >;
typedef $$DisciplineScoreFieldsTableCreateCompanionBuilder =
    DisciplineScoreFieldsCompanion Function({
      required String id,
      required String disciplineProfileId,
      required String fieldKey,
      required String fieldType,
      required String name,
      Value<String?> description,
      required String fieldKind,
      Value<String?> unit,
      Value<int?> precision,
      required bool required,
      Value<String?> defaultValue,
      Value<String?> options,
      Value<String?> validation,
      required int displayOrder,
      required bool isZeroReason,
      Value<String?> zeroReasonCode,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$DisciplineScoreFieldsTableUpdateCompanionBuilder =
    DisciplineScoreFieldsCompanion Function({
      Value<String> id,
      Value<String> disciplineProfileId,
      Value<String> fieldKey,
      Value<String> fieldType,
      Value<String> name,
      Value<String?> description,
      Value<String> fieldKind,
      Value<String?> unit,
      Value<int?> precision,
      Value<bool> required,
      Value<String?> defaultValue,
      Value<String?> options,
      Value<String?> validation,
      Value<int> displayOrder,
      Value<bool> isZeroReason,
      Value<String?> zeroReasonCode,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$DisciplineScoreFieldsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $DisciplineScoreFieldsTable,
          DisciplineScoreFieldData
        > {
  $$DisciplineScoreFieldsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DisciplineProfilesTable _disciplineProfileIdTable(
    _$SoarScoreDatabase db,
  ) => db.disciplineProfiles.createAlias(
    'discipline_score_fields__discipline_profile_id__discipline_profiles__id',
  );

  $$DisciplineProfilesTableProcessedTableManager get disciplineProfileId {
    final $_column = $_itemColumn<String>('discipline_profile_id')!;

    final manager = $$DisciplineProfilesTableTableManager(
      $_db,
      $_db.disciplineProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_disciplineProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DisciplineScoreFieldsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineScoreFieldsTable> {
  $$DisciplineScoreFieldsTableFilterComposer({
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

  ColumnFilters<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldKind => $composableBuilder(
    column: $table.fieldKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precision => $composableBuilder(
    column: $table.precision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validation => $composableBuilder(
    column: $table.validation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isZeroReason => $composableBuilder(
    column: $table.isZeroReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zeroReasonCode => $composableBuilder(
    column: $table.zeroReasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DisciplineProfilesTableFilterComposer get disciplineProfileId {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineScoreFieldsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineScoreFieldsTable> {
  $$DisciplineScoreFieldsTableOrderingComposer({
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

  ColumnOrderings<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldKind => $composableBuilder(
    column: $table.fieldKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precision => $composableBuilder(
    column: $table.precision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validation => $composableBuilder(
    column: $table.validation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isZeroReason => $composableBuilder(
    column: $table.isZeroReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zeroReasonCode => $composableBuilder(
    column: $table.zeroReasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DisciplineProfilesTableOrderingComposer get disciplineProfileId {
    final $$DisciplineProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineScoreFieldsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineScoreFieldsTable> {
  $$DisciplineScoreFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<String> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldKind =>
      $composableBuilder(column: $table.fieldKind, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get precision =>
      $composableBuilder(column: $table.precision, builder: (column) => column);

  GeneratedColumn<bool> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);

  GeneratedColumn<String> get defaultValue => $composableBuilder(
    column: $table.defaultValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<String> get validation => $composableBuilder(
    column: $table.validation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isZeroReason => $composableBuilder(
    column: $table.isZeroReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zeroReasonCode => $composableBuilder(
    column: $table.zeroReasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DisciplineProfilesTableAnnotationComposer get disciplineProfileId {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.disciplineProfileId,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DisciplineScoreFieldsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $DisciplineScoreFieldsTable,
          DisciplineScoreFieldData,
          $$DisciplineScoreFieldsTableFilterComposer,
          $$DisciplineScoreFieldsTableOrderingComposer,
          $$DisciplineScoreFieldsTableAnnotationComposer,
          $$DisciplineScoreFieldsTableCreateCompanionBuilder,
          $$DisciplineScoreFieldsTableUpdateCompanionBuilder,
          (DisciplineScoreFieldData, $$DisciplineScoreFieldsTableReferences),
          DisciplineScoreFieldData,
          PrefetchHooks Function({bool disciplineProfileId})
        > {
  $$DisciplineScoreFieldsTableTableManager(
    _$SoarScoreDatabase db,
    $DisciplineScoreFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisciplineScoreFieldsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DisciplineScoreFieldsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DisciplineScoreFieldsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> disciplineProfileId = const Value.absent(),
                Value<String> fieldKey = const Value.absent(),
                Value<String> fieldType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> fieldKind = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> precision = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<String?> defaultValue = const Value.absent(),
                Value<String?> options = const Value.absent(),
                Value<String?> validation = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<bool> isZeroReason = const Value.absent(),
                Value<String?> zeroReasonCode = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisciplineScoreFieldsCompanion(
                id: id,
                disciplineProfileId: disciplineProfileId,
                fieldKey: fieldKey,
                fieldType: fieldType,
                name: name,
                description: description,
                fieldKind: fieldKind,
                unit: unit,
                precision: precision,
                required: required,
                defaultValue: defaultValue,
                options: options,
                validation: validation,
                displayOrder: displayOrder,
                isZeroReason: isZeroReason,
                zeroReasonCode: zeroReasonCode,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String disciplineProfileId,
                required String fieldKey,
                required String fieldType,
                required String name,
                Value<String?> description = const Value.absent(),
                required String fieldKind,
                Value<String?> unit = const Value.absent(),
                Value<int?> precision = const Value.absent(),
                required bool required,
                Value<String?> defaultValue = const Value.absent(),
                Value<String?> options = const Value.absent(),
                Value<String?> validation = const Value.absent(),
                required int displayOrder,
                required bool isZeroReason,
                Value<String?> zeroReasonCode = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DisciplineScoreFieldsCompanion.insert(
                id: id,
                disciplineProfileId: disciplineProfileId,
                fieldKey: fieldKey,
                fieldType: fieldType,
                name: name,
                description: description,
                fieldKind: fieldKind,
                unit: unit,
                precision: precision,
                required: required,
                defaultValue: defaultValue,
                options: options,
                validation: validation,
                displayOrder: displayOrder,
                isZeroReason: isZeroReason,
                zeroReasonCode: zeroReasonCode,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $DisciplineScoreFieldsTable,
                    DisciplineScoreFieldData
                  >(table),
                  $$DisciplineScoreFieldsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({disciplineProfileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (disciplineProfileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.disciplineProfileId,
                        referencedTable: $$DisciplineScoreFieldsTableReferences
                            ._disciplineProfileIdTable(db),
                        referencedColumn: $$DisciplineScoreFieldsTableReferences
                            ._disciplineProfileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DisciplineScoreFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $DisciplineScoreFieldsTable,
      DisciplineScoreFieldData,
      $$DisciplineScoreFieldsTableFilterComposer,
      $$DisciplineScoreFieldsTableOrderingComposer,
      $$DisciplineScoreFieldsTableAnnotationComposer,
      $$DisciplineScoreFieldsTableCreateCompanionBuilder,
      $$DisciplineScoreFieldsTableUpdateCompanionBuilder,
      (DisciplineScoreFieldData, $$DisciplineScoreFieldsTableReferences),
      DisciplineScoreFieldData,
      PrefetchHooks Function({bool disciplineProfileId})
    >;
typedef $$DisciplineValidationsTableCreateCompanionBuilder =
    DisciplineValidationsCompanion Function({
      required String id,
      required String disciplineProfileId,
      required String fieldKeys,
      required String constraintType,
      Value<String?> description,
      Value<String?> appliesTo,
      Value<String?> message,
      required int displayOrder,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$DisciplineValidationsTableUpdateCompanionBuilder =
    DisciplineValidationsCompanion Function({
      Value<String> id,
      Value<String> disciplineProfileId,
      Value<String> fieldKeys,
      Value<String> constraintType,
      Value<String?> description,
      Value<String?> appliesTo,
      Value<String?> message,
      Value<int> displayOrder,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$DisciplineValidationsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $DisciplineValidationsTable,
          DisciplineValidationData
        > {
  $$DisciplineValidationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DisciplineProfilesTable _disciplineProfileIdTable(
    _$SoarScoreDatabase db,
  ) => db.disciplineProfiles.createAlias(
    'discipline_validations__discipline_profile_id__discipline_profiles__id',
  );

  $$DisciplineProfilesTableProcessedTableManager get disciplineProfileId {
    final $_column = $_itemColumn<String>('discipline_profile_id')!;

    final manager = $$DisciplineProfilesTableTableManager(
      $_db,
      $_db.disciplineProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_disciplineProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DisciplineValidationsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineValidationsTable> {
  $$DisciplineValidationsTableFilterComposer({
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

  ColumnFilters<String> get fieldKeys => $composableBuilder(
    column: $table.fieldKeys,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get constraintType => $composableBuilder(
    column: $table.constraintType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appliesTo => $composableBuilder(
    column: $table.appliesTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DisciplineProfilesTableFilterComposer get disciplineProfileId {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineValidationsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineValidationsTable> {
  $$DisciplineValidationsTableOrderingComposer({
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

  ColumnOrderings<String> get fieldKeys => $composableBuilder(
    column: $table.fieldKeys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get constraintType => $composableBuilder(
    column: $table.constraintType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appliesTo => $composableBuilder(
    column: $table.appliesTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DisciplineProfilesTableOrderingComposer get disciplineProfileId {
    final $$DisciplineProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineValidationsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineValidationsTable> {
  $$DisciplineValidationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldKeys =>
      $composableBuilder(column: $table.fieldKeys, builder: (column) => column);

  GeneratedColumn<String> get constraintType => $composableBuilder(
    column: $table.constraintType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appliesTo =>
      $composableBuilder(column: $table.appliesTo, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DisciplineProfilesTableAnnotationComposer get disciplineProfileId {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.disciplineProfileId,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DisciplineValidationsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $DisciplineValidationsTable,
          DisciplineValidationData,
          $$DisciplineValidationsTableFilterComposer,
          $$DisciplineValidationsTableOrderingComposer,
          $$DisciplineValidationsTableAnnotationComposer,
          $$DisciplineValidationsTableCreateCompanionBuilder,
          $$DisciplineValidationsTableUpdateCompanionBuilder,
          (DisciplineValidationData, $$DisciplineValidationsTableReferences),
          DisciplineValidationData,
          PrefetchHooks Function({bool disciplineProfileId})
        > {
  $$DisciplineValidationsTableTableManager(
    _$SoarScoreDatabase db,
    $DisciplineValidationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisciplineValidationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DisciplineValidationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DisciplineValidationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> disciplineProfileId = const Value.absent(),
                Value<String> fieldKeys = const Value.absent(),
                Value<String> constraintType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> appliesTo = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisciplineValidationsCompanion(
                id: id,
                disciplineProfileId: disciplineProfileId,
                fieldKeys: fieldKeys,
                constraintType: constraintType,
                description: description,
                appliesTo: appliesTo,
                message: message,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String disciplineProfileId,
                required String fieldKeys,
                required String constraintType,
                Value<String?> description = const Value.absent(),
                Value<String?> appliesTo = const Value.absent(),
                Value<String?> message = const Value.absent(),
                required int displayOrder,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DisciplineValidationsCompanion.insert(
                id: id,
                disciplineProfileId: disciplineProfileId,
                fieldKeys: fieldKeys,
                constraintType: constraintType,
                description: description,
                appliesTo: appliesTo,
                message: message,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $DisciplineValidationsTable,
                    DisciplineValidationData
                  >(table),
                  $$DisciplineValidationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({disciplineProfileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (disciplineProfileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.disciplineProfileId,
                        referencedTable: $$DisciplineValidationsTableReferences
                            ._disciplineProfileIdTable(db),
                        referencedColumn: $$DisciplineValidationsTableReferences
                            ._disciplineProfileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DisciplineValidationsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $DisciplineValidationsTable,
      DisciplineValidationData,
      $$DisciplineValidationsTableFilterComposer,
      $$DisciplineValidationsTableOrderingComposer,
      $$DisciplineValidationsTableAnnotationComposer,
      $$DisciplineValidationsTableCreateCompanionBuilder,
      $$DisciplineValidationsTableUpdateCompanionBuilder,
      (DisciplineValidationData, $$DisciplineValidationsTableReferences),
      DisciplineValidationData,
      PrefetchHooks Function({bool disciplineProfileId})
    >;
typedef $$DisciplineFormulasTableCreateCompanionBuilder =
    DisciplineFormulasCompanion Function({
      required String id,
      required String disciplineProfileId,
      required String formulaKey,
      Value<String?> description,
      required String formulaText,
      required String formulaType,
      required String inputs,
      Value<String?> outputs,
      required String dependsOn,
      required bool isPrimary,
      required int displayOrder,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$DisciplineFormulasTableUpdateCompanionBuilder =
    DisciplineFormulasCompanion Function({
      Value<String> id,
      Value<String> disciplineProfileId,
      Value<String> formulaKey,
      Value<String?> description,
      Value<String> formulaText,
      Value<String> formulaType,
      Value<String> inputs,
      Value<String?> outputs,
      Value<String> dependsOn,
      Value<bool> isPrimary,
      Value<int> displayOrder,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$DisciplineFormulasTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $DisciplineFormulasTable,
          DisciplineFormulaData
        > {
  $$DisciplineFormulasTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DisciplineProfilesTable _disciplineProfileIdTable(
    _$SoarScoreDatabase db,
  ) => db.disciplineProfiles.createAlias(
    'discipline_formulas__discipline_profile_id__discipline_profiles__id',
  );

  $$DisciplineProfilesTableProcessedTableManager get disciplineProfileId {
    final $_column = $_itemColumn<String>('discipline_profile_id')!;

    final manager = $$DisciplineProfilesTableTableManager(
      $_db,
      $_db.disciplineProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_disciplineProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DisciplineFormulasTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineFormulasTable> {
  $$DisciplineFormulasTableFilterComposer({
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

  ColumnFilters<String> get formulaKey => $composableBuilder(
    column: $table.formulaKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formulaText => $composableBuilder(
    column: $table.formulaText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formulaType => $composableBuilder(
    column: $table.formulaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputs => $composableBuilder(
    column: $table.inputs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputs => $composableBuilder(
    column: $table.outputs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DisciplineProfilesTableFilterComposer get disciplineProfileId {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineFormulasTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineFormulasTable> {
  $$DisciplineFormulasTableOrderingComposer({
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

  ColumnOrderings<String> get formulaKey => $composableBuilder(
    column: $table.formulaKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formulaText => $composableBuilder(
    column: $table.formulaText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formulaType => $composableBuilder(
    column: $table.formulaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputs => $composableBuilder(
    column: $table.inputs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputs => $composableBuilder(
    column: $table.outputs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DisciplineProfilesTableOrderingComposer get disciplineProfileId {
    final $$DisciplineProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineFormulasTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineFormulasTable> {
  $$DisciplineFormulasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get formulaKey => $composableBuilder(
    column: $table.formulaKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get formulaText => $composableBuilder(
    column: $table.formulaText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get formulaType => $composableBuilder(
    column: $table.formulaType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputs =>
      $composableBuilder(column: $table.inputs, builder: (column) => column);

  GeneratedColumn<String> get outputs =>
      $composableBuilder(column: $table.outputs, builder: (column) => column);

  GeneratedColumn<String> get dependsOn =>
      $composableBuilder(column: $table.dependsOn, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DisciplineProfilesTableAnnotationComposer get disciplineProfileId {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.disciplineProfileId,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DisciplineFormulasTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $DisciplineFormulasTable,
          DisciplineFormulaData,
          $$DisciplineFormulasTableFilterComposer,
          $$DisciplineFormulasTableOrderingComposer,
          $$DisciplineFormulasTableAnnotationComposer,
          $$DisciplineFormulasTableCreateCompanionBuilder,
          $$DisciplineFormulasTableUpdateCompanionBuilder,
          (DisciplineFormulaData, $$DisciplineFormulasTableReferences),
          DisciplineFormulaData,
          PrefetchHooks Function({bool disciplineProfileId})
        > {
  $$DisciplineFormulasTableTableManager(
    _$SoarScoreDatabase db,
    $DisciplineFormulasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisciplineFormulasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DisciplineFormulasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DisciplineFormulasTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> disciplineProfileId = const Value.absent(),
                Value<String> formulaKey = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> formulaText = const Value.absent(),
                Value<String> formulaType = const Value.absent(),
                Value<String> inputs = const Value.absent(),
                Value<String?> outputs = const Value.absent(),
                Value<String> dependsOn = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisciplineFormulasCompanion(
                id: id,
                disciplineProfileId: disciplineProfileId,
                formulaKey: formulaKey,
                description: description,
                formulaText: formulaText,
                formulaType: formulaType,
                inputs: inputs,
                outputs: outputs,
                dependsOn: dependsOn,
                isPrimary: isPrimary,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String disciplineProfileId,
                required String formulaKey,
                Value<String?> description = const Value.absent(),
                required String formulaText,
                required String formulaType,
                required String inputs,
                Value<String?> outputs = const Value.absent(),
                required String dependsOn,
                required bool isPrimary,
                required int displayOrder,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DisciplineFormulasCompanion.insert(
                id: id,
                disciplineProfileId: disciplineProfileId,
                formulaKey: formulaKey,
                description: description,
                formulaText: formulaText,
                formulaType: formulaType,
                inputs: inputs,
                outputs: outputs,
                dependsOn: dependsOn,
                isPrimary: isPrimary,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DisciplineFormulasTable, DisciplineFormulaData>(
                    table,
                  ),
                  $$DisciplineFormulasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({disciplineProfileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (disciplineProfileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.disciplineProfileId,
                        referencedTable: $$DisciplineFormulasTableReferences
                            ._disciplineProfileIdTable(db),
                        referencedColumn: $$DisciplineFormulasTableReferences
                            ._disciplineProfileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DisciplineFormulasTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $DisciplineFormulasTable,
      DisciplineFormulaData,
      $$DisciplineFormulasTableFilterComposer,
      $$DisciplineFormulasTableOrderingComposer,
      $$DisciplineFormulasTableAnnotationComposer,
      $$DisciplineFormulasTableCreateCompanionBuilder,
      $$DisciplineFormulasTableUpdateCompanionBuilder,
      (DisciplineFormulaData, $$DisciplineFormulasTableReferences),
      DisciplineFormulaData,
      PrefetchHooks Function({bool disciplineProfileId})
    >;
typedef $$DisciplineRulesTableCreateCompanionBuilder =
    DisciplineRulesCompanion Function({
      required String id,
      required String disciplineProfileId,
      required String ruleKey,
      required String ruleType,
      Value<String?> condition,
      Value<String?> effect,
      Value<String?> appliesTo,
      required String dependsOn,
      Value<String?> displayName,
      Value<String?> description,
      required bool autoScoreZero,
      required String affectsOtherFields,
      required int displayOrder,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$DisciplineRulesTableUpdateCompanionBuilder =
    DisciplineRulesCompanion Function({
      Value<String> id,
      Value<String> disciplineProfileId,
      Value<String> ruleKey,
      Value<String> ruleType,
      Value<String?> condition,
      Value<String?> effect,
      Value<String?> appliesTo,
      Value<String> dependsOn,
      Value<String?> displayName,
      Value<String?> description,
      Value<bool> autoScoreZero,
      Value<String> affectsOtherFields,
      Value<int> displayOrder,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$DisciplineRulesTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $DisciplineRulesTable,
          DisciplineRuleData
        > {
  $$DisciplineRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DisciplineProfilesTable _disciplineProfileIdTable(
    _$SoarScoreDatabase db,
  ) => db.disciplineProfiles.createAlias(
    'discipline_rules__discipline_profile_id__discipline_profiles__id',
  );

  $$DisciplineProfilesTableProcessedTableManager get disciplineProfileId {
    final $_column = $_itemColumn<String>('discipline_profile_id')!;

    final manager = $$DisciplineProfilesTableTableManager(
      $_db,
      $_db.disciplineProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_disciplineProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DisciplineRulesTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineRulesTable> {
  $$DisciplineRulesTableFilterComposer({
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

  ColumnFilters<String> get ruleKey => $composableBuilder(
    column: $table.ruleKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleType => $composableBuilder(
    column: $table.ruleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effect => $composableBuilder(
    column: $table.effect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appliesTo => $composableBuilder(
    column: $table.appliesTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoScoreZero => $composableBuilder(
    column: $table.autoScoreZero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get affectsOtherFields => $composableBuilder(
    column: $table.affectsOtherFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DisciplineProfilesTableFilterComposer get disciplineProfileId {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineRulesTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineRulesTable> {
  $$DisciplineRulesTableOrderingComposer({
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

  ColumnOrderings<String> get ruleKey => $composableBuilder(
    column: $table.ruleKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleType => $composableBuilder(
    column: $table.ruleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effect => $composableBuilder(
    column: $table.effect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appliesTo => $composableBuilder(
    column: $table.appliesTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoScoreZero => $composableBuilder(
    column: $table.autoScoreZero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get affectsOtherFields => $composableBuilder(
    column: $table.affectsOtherFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DisciplineProfilesTableOrderingComposer get disciplineProfileId {
    final $$DisciplineProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DisciplineRulesTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $DisciplineRulesTable> {
  $$DisciplineRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ruleKey =>
      $composableBuilder(column: $table.ruleKey, builder: (column) => column);

  GeneratedColumn<String> get ruleType =>
      $composableBuilder(column: $table.ruleType, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get effect =>
      $composableBuilder(column: $table.effect, builder: (column) => column);

  GeneratedColumn<String> get appliesTo =>
      $composableBuilder(column: $table.appliesTo, builder: (column) => column);

  GeneratedColumn<String> get dependsOn =>
      $composableBuilder(column: $table.dependsOn, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoScoreZero => $composableBuilder(
    column: $table.autoScoreZero,
    builder: (column) => column,
  );

  GeneratedColumn<String> get affectsOtherFields => $composableBuilder(
    column: $table.affectsOtherFields,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DisciplineProfilesTableAnnotationComposer get disciplineProfileId {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.disciplineProfileId,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DisciplineRulesTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $DisciplineRulesTable,
          DisciplineRuleData,
          $$DisciplineRulesTableFilterComposer,
          $$DisciplineRulesTableOrderingComposer,
          $$DisciplineRulesTableAnnotationComposer,
          $$DisciplineRulesTableCreateCompanionBuilder,
          $$DisciplineRulesTableUpdateCompanionBuilder,
          (DisciplineRuleData, $$DisciplineRulesTableReferences),
          DisciplineRuleData,
          PrefetchHooks Function({bool disciplineProfileId})
        > {
  $$DisciplineRulesTableTableManager(
    _$SoarScoreDatabase db,
    $DisciplineRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisciplineRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DisciplineRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DisciplineRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> disciplineProfileId = const Value.absent(),
                Value<String> ruleKey = const Value.absent(),
                Value<String> ruleType = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> effect = const Value.absent(),
                Value<String?> appliesTo = const Value.absent(),
                Value<String> dependsOn = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> autoScoreZero = const Value.absent(),
                Value<String> affectsOtherFields = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisciplineRulesCompanion(
                id: id,
                disciplineProfileId: disciplineProfileId,
                ruleKey: ruleKey,
                ruleType: ruleType,
                condition: condition,
                effect: effect,
                appliesTo: appliesTo,
                dependsOn: dependsOn,
                displayName: displayName,
                description: description,
                autoScoreZero: autoScoreZero,
                affectsOtherFields: affectsOtherFields,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String disciplineProfileId,
                required String ruleKey,
                required String ruleType,
                Value<String?> condition = const Value.absent(),
                Value<String?> effect = const Value.absent(),
                Value<String?> appliesTo = const Value.absent(),
                required String dependsOn,
                Value<String?> displayName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required bool autoScoreZero,
                required String affectsOtherFields,
                required int displayOrder,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DisciplineRulesCompanion.insert(
                id: id,
                disciplineProfileId: disciplineProfileId,
                ruleKey: ruleKey,
                ruleType: ruleType,
                condition: condition,
                effect: effect,
                appliesTo: appliesTo,
                dependsOn: dependsOn,
                displayName: displayName,
                description: description,
                autoScoreZero: autoScoreZero,
                affectsOtherFields: affectsOtherFields,
                displayOrder: displayOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DisciplineRulesTable, DisciplineRuleData>(table),
                  $$DisciplineRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({disciplineProfileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (disciplineProfileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.disciplineProfileId,
                        referencedTable: $$DisciplineRulesTableReferences
                            ._disciplineProfileIdTable(db),
                        referencedColumn: $$DisciplineRulesTableReferences
                            ._disciplineProfileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DisciplineRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $DisciplineRulesTable,
      DisciplineRuleData,
      $$DisciplineRulesTableFilterComposer,
      $$DisciplineRulesTableOrderingComposer,
      $$DisciplineRulesTableAnnotationComposer,
      $$DisciplineRulesTableCreateCompanionBuilder,
      $$DisciplineRulesTableUpdateCompanionBuilder,
      (DisciplineRuleData, $$DisciplineRulesTableReferences),
      DisciplineRuleData,
      PrefetchHooks Function({bool disciplineProfileId})
    >;
typedef $$ContestConfigurationPresetsTableCreateCompanionBuilder =
    ContestConfigurationPresetsCompanion Function({
      required String id,
      required String ownerAccountId,
      required String disciplineProfileId,
      required String name,
      Value<String?> description,
      required String config,
      Value<String?> landingTableId,
      required String createdAt,
      required String updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$ContestConfigurationPresetsTableUpdateCompanionBuilder =
    ContestConfigurationPresetsCompanion Function({
      Value<String> id,
      Value<String> ownerAccountId,
      Value<String> disciplineProfileId,
      Value<String> name,
      Value<String?> description,
      Value<String> config,
      Value<String?> landingTableId,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });

final class $$ContestConfigurationPresetsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $ContestConfigurationPresetsTable,
          ContestConfigurationPresetData
        > {
  $$ContestConfigurationPresetsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DisciplineProfilesTable _disciplineProfileIdTable(
    _$SoarScoreDatabase db,
  ) => db.disciplineProfiles.createAlias(
    'contest_configuration_presets__discipline_profile_id__discipline_profiles__id',
  );

  $$DisciplineProfilesTableProcessedTableManager get disciplineProfileId {
    final $_column = $_itemColumn<String>('discipline_profile_id')!;

    final manager = $$DisciplineProfilesTableTableManager(
      $_db,
      $_db.disciplineProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_disciplineProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LandingTablesTable _landingTableIdTable(_$SoarScoreDatabase db) =>
      db.landingTables.createAlias(
        'contest_configuration_presets__landing_table_id__landing_tables__id',
      );

  $$LandingTablesTableProcessedTableManager? get landingTableId {
    final $_column = $_itemColumn<String>('landing_table_id');
    if ($_column == null) return null;
    final manager = $$LandingTablesTableTableManager(
      $_db,
      $_db.landingTables,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_landingTableIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ContestConfigurationRevisionsTable,
    List<ContestConfigurationRevisionData>
  >
  _contestConfigurationRevisionsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestConfigurationRevisions,
        aliasName: 'contest_configuration_presets__id__contest_configuration_revisions__source_preset_id',
      );

  $$ContestConfigurationRevisionsTableProcessedTableManager
  get contestConfigurationRevisionsRefs {
    final manager = $$ContestConfigurationRevisionsTableTableManager(
      $_db,
      $_db.contestConfigurationRevisions,
    ).filter((f) => f.sourcePresetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contestConfigurationRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContestConfigurationPresetsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $ContestConfigurationPresetsTable> {
  $$ContestConfigurationPresetsTableFilterComposer({
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

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $$DisciplineProfilesTableFilterComposer get disciplineProfileId {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LandingTablesTableFilterComposer get landingTableId {
    final $$LandingTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableFilterComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> contestConfigurationRevisionsRefs(
    Expression<bool> Function(
      $$ContestConfigurationRevisionsTableFilterComposer f,
    )
    f,
  ) {
    final $$ContestConfigurationRevisionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationRevisions,
          getReferencedColumn: (t) => t.sourcePresetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationRevisionsTableFilterComposer(
                $db: $db,
                $table: $db.contestConfigurationRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContestConfigurationPresetsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $ContestConfigurationPresetsTable> {
  $$ContestConfigurationPresetsTableOrderingComposer({
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

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $$DisciplineProfilesTableOrderingComposer get disciplineProfileId {
    final $$DisciplineProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LandingTablesTableOrderingComposer get landingTableId {
    final $$LandingTablesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableOrderingComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContestConfigurationPresetsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $ContestConfigurationPresetsTable> {
  $$ContestConfigurationPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $$DisciplineProfilesTableAnnotationComposer get disciplineProfileId {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.disciplineProfileId,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$LandingTablesTableAnnotationComposer get landingTableId {
    final $$LandingTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> contestConfigurationRevisionsRefs<T extends Object>(
    Expression<T> Function(
      $$ContestConfigurationRevisionsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$ContestConfigurationRevisionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestConfigurationRevisions,
          getReferencedColumn: (t) => t.sourcePresetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationRevisionsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestConfigurationRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContestConfigurationPresetsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $ContestConfigurationPresetsTable,
          ContestConfigurationPresetData,
          $$ContestConfigurationPresetsTableFilterComposer,
          $$ContestConfigurationPresetsTableOrderingComposer,
          $$ContestConfigurationPresetsTableAnnotationComposer,
          $$ContestConfigurationPresetsTableCreateCompanionBuilder,
          $$ContestConfigurationPresetsTableUpdateCompanionBuilder,
          (
            ContestConfigurationPresetData,
            $$ContestConfigurationPresetsTableReferences,
          ),
          ContestConfigurationPresetData,
          PrefetchHooks Function({
            bool disciplineProfileId,
            bool landingTableId,
            bool contestConfigurationRevisionsRefs,
          })
        > {
  $$ContestConfigurationPresetsTableTableManager(
    _$SoarScoreDatabase db,
    $ContestConfigurationPresetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContestConfigurationPresetsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ContestConfigurationPresetsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContestConfigurationPresetsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerAccountId = const Value.absent(),
                Value<String> disciplineProfileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> config = const Value.absent(),
                Value<String?> landingTableId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestConfigurationPresetsCompanion(
                id: id,
                ownerAccountId: ownerAccountId,
                disciplineProfileId: disciplineProfileId,
                name: name,
                description: description,
                config: config,
                landingTableId: landingTableId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerAccountId,
                required String disciplineProfileId,
                required String name,
                Value<String?> description = const Value.absent(),
                required String config,
                Value<String?> landingTableId = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestConfigurationPresetsCompanion.insert(
                id: id,
                ownerAccountId: ownerAccountId,
                disciplineProfileId: disciplineProfileId,
                name: name,
                description: description,
                config: config,
                landingTableId: landingTableId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ContestConfigurationPresetsTable,
                    ContestConfigurationPresetData
                  >(table),
                  $$ContestConfigurationPresetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                disciplineProfileId = false,
                landingTableId = false,
                contestConfigurationRevisionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (contestConfigurationRevisionsRefs)
                      db.contestConfigurationRevisions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (disciplineProfileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.disciplineProfileId,
                            referencedTable:
                                $$ContestConfigurationPresetsTableReferences
                                    ._disciplineProfileIdTable(db),
                            referencedColumn:
                                $$ContestConfigurationPresetsTableReferences
                                    ._disciplineProfileIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (landingTableId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.landingTableId,
                            referencedTable:
                                $$ContestConfigurationPresetsTableReferences
                                    ._landingTableIdTable(db),
                            referencedColumn:
                                $$ContestConfigurationPresetsTableReferences
                                    ._landingTableIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (contestConfigurationRevisionsRefs)
                        await $_getPrefetchedData<
                          ContestConfigurationPresetData,
                          $ContestConfigurationPresetsTable,
                          ContestConfigurationRevisionData
                        >(
                          currentTable: table,
                          referencedTable:
                              $$ContestConfigurationPresetsTableReferences
                                  ._contestConfigurationRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContestConfigurationPresetsTableReferences(
                                db,
                                table,
                                p0,
                              ).contestConfigurationRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourcePresetId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ContestConfigurationPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $ContestConfigurationPresetsTable,
      ContestConfigurationPresetData,
      $$ContestConfigurationPresetsTableFilterComposer,
      $$ContestConfigurationPresetsTableOrderingComposer,
      $$ContestConfigurationPresetsTableAnnotationComposer,
      $$ContestConfigurationPresetsTableCreateCompanionBuilder,
      $$ContestConfigurationPresetsTableUpdateCompanionBuilder,
      (
        ContestConfigurationPresetData,
        $$ContestConfigurationPresetsTableReferences,
      ),
      ContestConfigurationPresetData,
      PrefetchHooks Function({
        bool disciplineProfileId,
        bool landingTableId,
        bool contestConfigurationRevisionsRefs,
      })
    >;
typedef $$ContestConfigurationRevisionsTableCreateCompanionBuilder =
    ContestConfigurationRevisionsCompanion Function({
      required String id,
      required String contestId,
      required int revisionNumber,
      required String disciplineProfileId,
      Value<String?> sourcePresetId,
      required String config,
      Value<String?> landingTableId,
      required String createdBy,
      Value<String?> notes,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$ContestConfigurationRevisionsTableUpdateCompanionBuilder =
    ContestConfigurationRevisionsCompanion Function({
      Value<String> id,
      Value<String> contestId,
      Value<int> revisionNumber,
      Value<String> disciplineProfileId,
      Value<String?> sourcePresetId,
      Value<String> config,
      Value<String?> landingTableId,
      Value<String> createdBy,
      Value<String?> notes,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$ContestConfigurationRevisionsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $ContestConfigurationRevisionsTable,
          ContestConfigurationRevisionData
        > {
  $$ContestConfigurationRevisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContestsTable _contestIdTable(_$SoarScoreDatabase db) => db.contests
      .createAlias('contest_configuration_revisions__contest_id__contests__id');

  $$ContestsTableProcessedTableManager get contestId {
    final $_column = $_itemColumn<String>('contest_id')!;

    final manager = $$ContestsTableTableManager(
      $_db,
      $_db.contests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DisciplineProfilesTable _disciplineProfileIdTable(
    _$SoarScoreDatabase db,
  ) => db.disciplineProfiles.createAlias(
    'contest_configuration_revisions__discipline_profile_id__discipline_profiles__id',
  );

  $$DisciplineProfilesTableProcessedTableManager get disciplineProfileId {
    final $_column = $_itemColumn<String>('discipline_profile_id')!;

    final manager = $$DisciplineProfilesTableTableManager(
      $_db,
      $_db.disciplineProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_disciplineProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContestConfigurationPresetsTable _sourcePresetIdTable(
    _$SoarScoreDatabase db,
  ) => db.contestConfigurationPresets.createAlias(
    'contest_configuration_revisions__source_preset_id__contest_configuration_presets__id',
  );

  $$ContestConfigurationPresetsTableProcessedTableManager? get sourcePresetId {
    final $_column = $_itemColumn<String>('source_preset_id');
    if ($_column == null) return null;
    final manager = $$ContestConfigurationPresetsTableTableManager(
      $_db,
      $_db.contestConfigurationPresets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourcePresetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LandingTablesTable _landingTableIdTable(_$SoarScoreDatabase db) =>
      db.landingTables.createAlias(
        'contest_configuration_revisions__landing_table_id__landing_tables__id',
      );

  $$LandingTablesTableProcessedTableManager? get landingTableId {
    final $_column = $_itemColumn<String>('landing_table_id');
    if ($_column == null) return null;
    final manager = $$LandingTablesTableTableManager(
      $_db,
      $_db.landingTables,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_landingTableIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContestConfigurationRevisionsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $ContestConfigurationRevisionsTable> {
  $$ContestConfigurationRevisionsTableFilterComposer({
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

  ColumnFilters<int> get revisionNumber => $composableBuilder(
    column: $table.revisionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ContestsTableFilterComposer get contestId {
    final $$ContestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableFilterComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DisciplineProfilesTableFilterComposer get disciplineProfileId {
    final $$DisciplineProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableFilterComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContestConfigurationPresetsTableFilterComposer get sourcePresetId {
    final $$ContestConfigurationPresetsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourcePresetId,
          referencedTable: $db.contestConfigurationPresets,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationPresetsTableFilterComposer(
                $db: $db,
                $table: $db.contestConfigurationPresets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$LandingTablesTableFilterComposer get landingTableId {
    final $$LandingTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableFilterComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContestConfigurationRevisionsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $ContestConfigurationRevisionsTable> {
  $$ContestConfigurationRevisionsTableOrderingComposer({
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

  ColumnOrderings<int> get revisionNumber => $composableBuilder(
    column: $table.revisionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContestsTableOrderingComposer get contestId {
    final $$ContestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableOrderingComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DisciplineProfilesTableOrderingComposer get disciplineProfileId {
    final $$DisciplineProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.disciplineProfileId,
      referencedTable: $db.disciplineProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisciplineProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.disciplineProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContestConfigurationPresetsTableOrderingComposer get sourcePresetId {
    final $$ContestConfigurationPresetsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourcePresetId,
          referencedTable: $db.contestConfigurationPresets,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationPresetsTableOrderingComposer(
                $db: $db,
                $table: $db.contestConfigurationPresets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$LandingTablesTableOrderingComposer get landingTableId {
    final $$LandingTablesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableOrderingComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContestConfigurationRevisionsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $ContestConfigurationRevisionsTable> {
  $$ContestConfigurationRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get revisionNumber => $composableBuilder(
    column: $table.revisionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ContestsTableAnnotationComposer get contestId {
    final $$ContestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableAnnotationComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DisciplineProfilesTableAnnotationComposer get disciplineProfileId {
    final $$DisciplineProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.disciplineProfileId,
          referencedTable: $db.disciplineProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DisciplineProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.disciplineProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ContestConfigurationPresetsTableAnnotationComposer get sourcePresetId {
    final $$ContestConfigurationPresetsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourcePresetId,
          referencedTable: $db.contestConfigurationPresets,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestConfigurationPresetsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestConfigurationPresets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$LandingTablesTableAnnotationComposer get landingTableId {
    final $$LandingTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.landingTableId,
      referencedTable: $db.landingTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LandingTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.landingTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContestConfigurationRevisionsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $ContestConfigurationRevisionsTable,
          ContestConfigurationRevisionData,
          $$ContestConfigurationRevisionsTableFilterComposer,
          $$ContestConfigurationRevisionsTableOrderingComposer,
          $$ContestConfigurationRevisionsTableAnnotationComposer,
          $$ContestConfigurationRevisionsTableCreateCompanionBuilder,
          $$ContestConfigurationRevisionsTableUpdateCompanionBuilder,
          (
            ContestConfigurationRevisionData,
            $$ContestConfigurationRevisionsTableReferences,
          ),
          ContestConfigurationRevisionData,
          PrefetchHooks Function({
            bool contestId,
            bool disciplineProfileId,
            bool sourcePresetId,
            bool landingTableId,
          })
        > {
  $$ContestConfigurationRevisionsTableTableManager(
    _$SoarScoreDatabase db,
    $ContestConfigurationRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContestConfigurationRevisionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ContestConfigurationRevisionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContestConfigurationRevisionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contestId = const Value.absent(),
                Value<int> revisionNumber = const Value.absent(),
                Value<String> disciplineProfileId = const Value.absent(),
                Value<String?> sourcePresetId = const Value.absent(),
                Value<String> config = const Value.absent(),
                Value<String?> landingTableId = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestConfigurationRevisionsCompanion(
                id: id,
                contestId: contestId,
                revisionNumber: revisionNumber,
                disciplineProfileId: disciplineProfileId,
                sourcePresetId: sourcePresetId,
                config: config,
                landingTableId: landingTableId,
                createdBy: createdBy,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contestId,
                required int revisionNumber,
                required String disciplineProfileId,
                Value<String?> sourcePresetId = const Value.absent(),
                required String config,
                Value<String?> landingTableId = const Value.absent(),
                required String createdBy,
                Value<String?> notes = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ContestConfigurationRevisionsCompanion.insert(
                id: id,
                contestId: contestId,
                revisionNumber: revisionNumber,
                disciplineProfileId: disciplineProfileId,
                sourcePresetId: sourcePresetId,
                config: config,
                landingTableId: landingTableId,
                createdBy: createdBy,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ContestConfigurationRevisionsTable,
                    ContestConfigurationRevisionData
                  >(table),
                  $$ContestConfigurationRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                contestId = false,
                disciplineProfileId = false,
                sourcePresetId = false,
                landingTableId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (contestId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contestId,
                            referencedTable:
                                $$ContestConfigurationRevisionsTableReferences
                                    ._contestIdTable(db),
                            referencedColumn:
                                $$ContestConfigurationRevisionsTableReferences
                                    ._contestIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (disciplineProfileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.disciplineProfileId,
                            referencedTable:
                                $$ContestConfigurationRevisionsTableReferences
                                    ._disciplineProfileIdTable(db),
                            referencedColumn:
                                $$ContestConfigurationRevisionsTableReferences
                                    ._disciplineProfileIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (sourcePresetId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourcePresetId,
                            referencedTable:
                                $$ContestConfigurationRevisionsTableReferences
                                    ._sourcePresetIdTable(db),
                            referencedColumn:
                                $$ContestConfigurationRevisionsTableReferences
                                    ._sourcePresetIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (landingTableId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.landingTableId,
                            referencedTable:
                                $$ContestConfigurationRevisionsTableReferences
                                    ._landingTableIdTable(db),
                            referencedColumn:
                                $$ContestConfigurationRevisionsTableReferences
                                    ._landingTableIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ContestConfigurationRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $ContestConfigurationRevisionsTable,
      ContestConfigurationRevisionData,
      $$ContestConfigurationRevisionsTableFilterComposer,
      $$ContestConfigurationRevisionsTableOrderingComposer,
      $$ContestConfigurationRevisionsTableAnnotationComposer,
      $$ContestConfigurationRevisionsTableCreateCompanionBuilder,
      $$ContestConfigurationRevisionsTableUpdateCompanionBuilder,
      (
        ContestConfigurationRevisionData,
        $$ContestConfigurationRevisionsTableReferences,
      ),
      ContestConfigurationRevisionData,
      PrefetchHooks Function({
        bool contestId,
        bool disciplineProfileId,
        bool sourcePresetId,
        bool landingTableId,
      })
    >;
typedef $$ParticipantProfilesTableCreateCompanionBuilder =
    ParticipantProfilesCompanion Function({
      required String id,
      required String ownerAccountId,
      required String firstName,
      required String lastName,
      Value<String?> club,
      Value<String?> faiNumber,
      Value<String?> nationalOrgId,
      Value<String?> city,
      Value<String?> state,
      Value<String?> country,
      Value<String?> email,
      required String createdAt,
      required String updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$ParticipantProfilesTableUpdateCompanionBuilder =
    ParticipantProfilesCompanion Function({
      Value<String> id,
      Value<String> ownerAccountId,
      Value<String> firstName,
      Value<String> lastName,
      Value<String?> club,
      Value<String?> faiNumber,
      Value<String?> nationalOrgId,
      Value<String?> city,
      Value<String?> state,
      Value<String?> country,
      Value<String?> email,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });

final class $$ParticipantProfilesTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $ParticipantProfilesTable,
          ParticipantProfileData
        > {
  $$ParticipantProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ContestParticipationsTable,
    List<ContestParticipationData>
  >
  _contestParticipationsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestParticipations,
        aliasName: 'participant_profiles__id__contest_participations__participant_profile_id',
      );

  $$ContestParticipationsTableProcessedTableManager
  get contestParticipationsRefs {
    final manager =
        $$ContestParticipationsTableTableManager(
          $_db,
          $_db.contestParticipations,
        ).filter(
          (f) =>
              f.participantProfileId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _contestParticipationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ParticipantProfilesTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $ParticipantProfilesTable> {
  $$ParticipantProfilesTableFilterComposer({
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

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get club => $composableBuilder(
    column: $table.club,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faiNumber => $composableBuilder(
    column: $table.faiNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nationalOrgId => $composableBuilder(
    column: $table.nationalOrgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contestParticipationsRefs(
    Expression<bool> Function($$ContestParticipationsTableFilterComposer f) f,
  ) {
    final $$ContestParticipationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.participantProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableFilterComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ParticipantProfilesTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $ParticipantProfilesTable> {
  $$ParticipantProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get club => $composableBuilder(
    column: $table.club,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faiNumber => $composableBuilder(
    column: $table.faiNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nationalOrgId => $composableBuilder(
    column: $table.nationalOrgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParticipantProfilesTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $ParticipantProfilesTable> {
  $$ParticipantProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get club =>
      $composableBuilder(column: $table.club, builder: (column) => column);

  GeneratedColumn<String> get faiNumber =>
      $composableBuilder(column: $table.faiNumber, builder: (column) => column);

  GeneratedColumn<String> get nationalOrgId => $composableBuilder(
    column: $table.nationalOrgId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  Expression<T> contestParticipationsRefs<T extends Object>(
    Expression<T> Function($$ContestParticipationsTableAnnotationComposer a) f,
  ) {
    final $$ContestParticipationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.participantProfileId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ParticipantProfilesTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $ParticipantProfilesTable,
          ParticipantProfileData,
          $$ParticipantProfilesTableFilterComposer,
          $$ParticipantProfilesTableOrderingComposer,
          $$ParticipantProfilesTableAnnotationComposer,
          $$ParticipantProfilesTableCreateCompanionBuilder,
          $$ParticipantProfilesTableUpdateCompanionBuilder,
          (ParticipantProfileData, $$ParticipantProfilesTableReferences),
          ParticipantProfileData,
          PrefetchHooks Function({bool contestParticipationsRefs})
        > {
  $$ParticipantProfilesTableTableManager(
    _$SoarScoreDatabase db,
    $ParticipantProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParticipantProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParticipantProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ParticipantProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerAccountId = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String?> club = const Value.absent(),
                Value<String?> faiNumber = const Value.absent(),
                Value<String?> nationalOrgId = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParticipantProfilesCompanion(
                id: id,
                ownerAccountId: ownerAccountId,
                firstName: firstName,
                lastName: lastName,
                club: club,
                faiNumber: faiNumber,
                nationalOrgId: nationalOrgId,
                city: city,
                state: state,
                country: country,
                email: email,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerAccountId,
                required String firstName,
                required String lastName,
                Value<String?> club = const Value.absent(),
                Value<String?> faiNumber = const Value.absent(),
                Value<String?> nationalOrgId = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> email = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParticipantProfilesCompanion.insert(
                id: id,
                ownerAccountId: ownerAccountId,
                firstName: firstName,
                lastName: lastName,
                club: club,
                faiNumber: faiNumber,
                nationalOrgId: nationalOrgId,
                city: city,
                state: state,
                country: country,
                email: email,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ParticipantProfilesTable,
                    ParticipantProfileData
                  >(table),
                  $$ParticipantProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contestParticipationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (contestParticipationsRefs) db.contestParticipations,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (contestParticipationsRefs)
                    await $_getPrefetchedData<
                      ParticipantProfileData,
                      $ParticipantProfilesTable,
                      ContestParticipationData
                    >(
                      currentTable: table,
                      referencedTable: $$ParticipantProfilesTableReferences
                          ._contestParticipationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ParticipantProfilesTableReferences(
                            db,
                            table,
                            p0,
                          ).contestParticipationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.participantProfileId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ParticipantProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $ParticipantProfilesTable,
      ParticipantProfileData,
      $$ParticipantProfilesTableFilterComposer,
      $$ParticipantProfilesTableOrderingComposer,
      $$ParticipantProfilesTableAnnotationComposer,
      $$ParticipantProfilesTableCreateCompanionBuilder,
      $$ParticipantProfilesTableUpdateCompanionBuilder,
      (ParticipantProfileData, $$ParticipantProfilesTableReferences),
      ParticipantProfileData,
      PrefetchHooks Function({bool contestParticipationsRefs})
    >;
typedef $$RolesTableCreateCompanionBuilder = RolesCompanion Function({
  required String id,
  Value<String?> ownerAccountId,
  required String displayName,
  required String type,
  Value<String?> archivedAt,
  Value<int> revision,
  Value<int> rowid,
});
typedef $$RolesTableUpdateCompanionBuilder = RolesCompanion Function({
  Value<String> id,
  Value<String?> ownerAccountId,
  Value<String> displayName,
  Value<String> type,
  Value<String?> archivedAt,
  Value<int> revision,
  Value<int> rowid,
});

final class $$RolesTableReferences
    extends BaseReferences<_$SoarScoreDatabase, $RolesTable, RoleData> {
  $$RolesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $ContestParticipationsTable,
    List<ContestParticipationData>
  >
  _contestParticipationsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestParticipations,
        aliasName: 'roles__id__contest_participations__role_id',
      );

  $$ContestParticipationsTableProcessedTableManager
  get contestParticipationsRefs {
    final manager = $$ContestParticipationsTableTableManager(
      $_db,
      $_db.contestParticipations,
    ).filter((f) => f.roleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contestParticipationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RolesTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $RolesTable> {
  $$RolesTableFilterComposer({
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

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contestParticipationsRefs(
    Expression<bool> Function($$ContestParticipationsTableFilterComposer f) f,
  ) {
    final $$ContestParticipationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.roleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableFilterComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RolesTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $RolesTable> {
  $$RolesTableOrderingComposer({
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

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RolesTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $RolesTable> {
  $$RolesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  Expression<T> contestParticipationsRefs<T extends Object>(
    Expression<T> Function($$ContestParticipationsTableAnnotationComposer a) f,
  ) {
    final $$ContestParticipationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.roleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RolesTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $RolesTable,
          RoleData,
          $$RolesTableFilterComposer,
          $$RolesTableOrderingComposer,
          $$RolesTableAnnotationComposer,
          $$RolesTableCreateCompanionBuilder,
          $$RolesTableUpdateCompanionBuilder,
          (RoleData, $$RolesTableReferences),
          RoleData,
          PrefetchHooks Function({bool contestParticipationsRefs})
        > {
  $$RolesTableTableManager(_$SoarScoreDatabase db, $RolesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> archivedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolesCompanion(
                id: id,
                ownerAccountId: ownerAccountId,
                displayName: displayName,
                type: type,
                archivedAt: archivedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ownerAccountId = const Value.absent(),
                required String displayName,
                required String type,
                Value<String?> archivedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolesCompanion.insert(
                id: id,
                ownerAccountId: ownerAccountId,
                displayName: displayName,
                type: type,
                archivedAt: archivedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RolesTable, RoleData>(table),
                  $$RolesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contestParticipationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (contestParticipationsRefs) db.contestParticipations,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (contestParticipationsRefs)
                    await $_getPrefetchedData<
                      RoleData,
                      $RolesTable,
                      ContestParticipationData
                    >(
                      currentTable: table,
                      referencedTable: $$RolesTableReferences
                          ._contestParticipationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RolesTableReferences(
                        db,
                        table,
                        p0,
                      ).contestParticipationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.roleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RolesTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $RolesTable,
      RoleData,
      $$RolesTableFilterComposer,
      $$RolesTableOrderingComposer,
      $$RolesTableAnnotationComposer,
      $$RolesTableCreateCompanionBuilder,
      $$RolesTableUpdateCompanionBuilder,
      (RoleData, $$RolesTableReferences),
      RoleData,
      PrefetchHooks Function({bool contestParticipationsRefs})
    >;
typedef $$ContestParticipationsTableCreateCompanionBuilder =
    ContestParticipationsCompanion Function({
      required String id,
      required String contestId,
      required String participantProfileId,
      Value<String?> classification,
      required String roleId,
      required String roleName,
      required String roleType,
      Value<int?> participantNumber,
      required String scoringUuid,
      Value<int?> retiredAtRound,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$ContestParticipationsTableUpdateCompanionBuilder =
    ContestParticipationsCompanion Function({
      Value<String> id,
      Value<String> contestId,
      Value<String> participantProfileId,
      Value<String?> classification,
      Value<String> roleId,
      Value<String> roleName,
      Value<String> roleType,
      Value<int?> participantNumber,
      Value<String> scoringUuid,
      Value<int?> retiredAtRound,
      Value<int> revision,
      Value<int> rowid,
    });

final class $$ContestParticipationsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $ContestParticipationsTable,
          ContestParticipationData
        > {
  $$ContestParticipationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContestsTable _contestIdTable(_$SoarScoreDatabase db) => db.contests
      .createAlias('contest_participations__contest_id__contests__id');

  $$ContestsTableProcessedTableManager get contestId {
    final $_column = $_itemColumn<String>('contest_id')!;

    final manager = $$ContestsTableTableManager(
      $_db,
      $_db.contests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ParticipantProfilesTable _participantProfileIdTable(
    _$SoarScoreDatabase db,
  ) => db.participantProfiles.createAlias(
    'contest_participations__participant_profile_id__participant_profiles__id',
  );

  $$ParticipantProfilesTableProcessedTableManager get participantProfileId {
    final $_column = $_itemColumn<String>('participant_profile_id')!;

    final manager = $$ParticipantProfilesTableTableManager(
      $_db,
      $_db.participantProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _participantProfileIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RolesTable _roleIdTable(_$SoarScoreDatabase db) =>
      db.roles.createAlias('contest_participations__role_id__roles__id');

  $$RolesTableProcessedTableManager get roleId {
    final $_column = $_itemColumn<String>('role_id')!;

    final manager = $$RolesTableTableManager(
      $_db,
      $_db.roles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TeamMembershipsTable, List<TeamMembershipData>>
  _teamMembershipsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.teamMemberships,
        aliasName: 'contest_participations__id__team_memberships__contest_participation_id',
      );

  $$TeamMembershipsTableProcessedTableManager get teamMembershipsRefs {
    final manager =
        $$TeamMembershipsTableTableManager($_db, $_db.teamMemberships).filter(
          (f) => f.contestParticipationId.id.sqlEquals(
            $_itemColumn<String>('id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _teamMembershipsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContestModelLinksTable,
    List<ContestModelLinkData>
  >
  _contestModelLinksRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestModelLinks,
        aliasName: 'contest_participations__id__contest_model_links__contest_participation_id',
      );

  $$ContestModelLinksTableProcessedTableManager get contestModelLinksRefs {
    final manager =
        $$ContestModelLinksTableTableManager(
          $_db,
          $_db.contestModelLinks,
        ).filter(
          (f) => f.contestParticipationId.id.sqlEquals(
            $_itemColumn<String>('id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _contestModelLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContestParticipationsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $ContestParticipationsTable> {
  $$ContestParticipationsTableFilterComposer({
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

  ColumnFilters<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleType => $composableBuilder(
    column: $table.roleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get participantNumber => $composableBuilder(
    column: $table.participantNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoringUuid => $composableBuilder(
    column: $table.scoringUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retiredAtRound => $composableBuilder(
    column: $table.retiredAtRound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $$ContestsTableFilterComposer get contestId {
    final $$ContestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableFilterComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ParticipantProfilesTableFilterComposer get participantProfileId {
    final $$ParticipantProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantProfileId,
      referencedTable: $db.participantProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParticipantProfilesTableFilterComposer(
            $db: $db,
            $table: $db.participantProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RolesTableFilterComposer get roleId {
    final $$RolesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableFilterComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> teamMembershipsRefs(
    Expression<bool> Function($$TeamMembershipsTableFilterComposer f) f,
  ) {
    final $$TeamMembershipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMemberships,
      getReferencedColumn: (t) => t.contestParticipationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembershipsTableFilterComposer(
            $db: $db,
            $table: $db.teamMemberships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contestModelLinksRefs(
    Expression<bool> Function($$ContestModelLinksTableFilterComposer f) f,
  ) {
    final $$ContestModelLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contestModelLinks,
      getReferencedColumn: (t) => t.contestParticipationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestModelLinksTableFilterComposer(
            $db: $db,
            $table: $db.contestModelLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContestParticipationsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $ContestParticipationsTable> {
  $$ContestParticipationsTableOrderingComposer({
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

  ColumnOrderings<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleType => $composableBuilder(
    column: $table.roleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get participantNumber => $composableBuilder(
    column: $table.participantNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringUuid => $composableBuilder(
    column: $table.scoringUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retiredAtRound => $composableBuilder(
    column: $table.retiredAtRound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContestsTableOrderingComposer get contestId {
    final $$ContestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableOrderingComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ParticipantProfilesTableOrderingComposer get participantProfileId {
    final $$ParticipantProfilesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.participantProfileId,
          referencedTable: $db.participantProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ParticipantProfilesTableOrderingComposer(
                $db: $db,
                $table: $db.participantProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$RolesTableOrderingComposer get roleId {
    final $$RolesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableOrderingComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContestParticipationsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $ContestParticipationsTable> {
  $$ContestParticipationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roleName =>
      $composableBuilder(column: $table.roleName, builder: (column) => column);

  GeneratedColumn<String> get roleType =>
      $composableBuilder(column: $table.roleType, builder: (column) => column);

  GeneratedColumn<int> get participantNumber => $composableBuilder(
    column: $table.participantNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scoringUuid => $composableBuilder(
    column: $table.scoringUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retiredAtRound => $composableBuilder(
    column: $table.retiredAtRound,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $$ContestsTableAnnotationComposer get contestId {
    final $$ContestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableAnnotationComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ParticipantProfilesTableAnnotationComposer get participantProfileId {
    final $$ParticipantProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.participantProfileId,
          referencedTable: $db.participantProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ParticipantProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.participantProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$RolesTableAnnotationComposer get roleId {
    final $$RolesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roleId,
      referencedTable: $db.roles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RolesTableAnnotationComposer(
            $db: $db,
            $table: $db.roles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> teamMembershipsRefs<T extends Object>(
    Expression<T> Function($$TeamMembershipsTableAnnotationComposer a) f,
  ) {
    final $$TeamMembershipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMemberships,
      getReferencedColumn: (t) => t.contestParticipationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembershipsTableAnnotationComposer(
            $db: $db,
            $table: $db.teamMemberships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> contestModelLinksRefs<T extends Object>(
    Expression<T> Function($$ContestModelLinksTableAnnotationComposer a) f,
  ) {
    final $$ContestModelLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestModelLinks,
          getReferencedColumn: (t) => t.contestParticipationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestModelLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.contestModelLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContestParticipationsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $ContestParticipationsTable,
          ContestParticipationData,
          $$ContestParticipationsTableFilterComposer,
          $$ContestParticipationsTableOrderingComposer,
          $$ContestParticipationsTableAnnotationComposer,
          $$ContestParticipationsTableCreateCompanionBuilder,
          $$ContestParticipationsTableUpdateCompanionBuilder,
          (ContestParticipationData, $$ContestParticipationsTableReferences),
          ContestParticipationData,
          PrefetchHooks Function({
            bool contestId,
            bool participantProfileId,
            bool roleId,
            bool teamMembershipsRefs,
            bool contestModelLinksRefs,
          })
        > {
  $$ContestParticipationsTableTableManager(
    _$SoarScoreDatabase db,
    $ContestParticipationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContestParticipationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ContestParticipationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContestParticipationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contestId = const Value.absent(),
                Value<String> participantProfileId = const Value.absent(),
                Value<String?> classification = const Value.absent(),
                Value<String> roleId = const Value.absent(),
                Value<String> roleName = const Value.absent(),
                Value<String> roleType = const Value.absent(),
                Value<int?> participantNumber = const Value.absent(),
                Value<String> scoringUuid = const Value.absent(),
                Value<int?> retiredAtRound = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestParticipationsCompanion(
                id: id,
                contestId: contestId,
                participantProfileId: participantProfileId,
                classification: classification,
                roleId: roleId,
                roleName: roleName,
                roleType: roleType,
                participantNumber: participantNumber,
                scoringUuid: scoringUuid,
                retiredAtRound: retiredAtRound,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contestId,
                required String participantProfileId,
                Value<String?> classification = const Value.absent(),
                required String roleId,
                required String roleName,
                required String roleType,
                Value<int?> participantNumber = const Value.absent(),
                required String scoringUuid,
                Value<int?> retiredAtRound = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestParticipationsCompanion.insert(
                id: id,
                contestId: contestId,
                participantProfileId: participantProfileId,
                classification: classification,
                roleId: roleId,
                roleName: roleName,
                roleType: roleType,
                participantNumber: participantNumber,
                scoringUuid: scoringUuid,
                retiredAtRound: retiredAtRound,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ContestParticipationsTable,
                    ContestParticipationData
                  >(table),
                  $$ContestParticipationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                contestId = false,
                participantProfileId = false,
                roleId = false,
                teamMembershipsRefs = false,
                contestModelLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (teamMembershipsRefs) db.teamMemberships,
                    if (contestModelLinksRefs) db.contestModelLinks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (contestId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contestId,
                            referencedTable:
                                $$ContestParticipationsTableReferences
                                    ._contestIdTable(db),
                            referencedColumn:
                                $$ContestParticipationsTableReferences
                                    ._contestIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (participantProfileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.participantProfileId,
                            referencedTable:
                                $$ContestParticipationsTableReferences
                                    ._participantProfileIdTable(db),
                            referencedColumn:
                                $$ContestParticipationsTableReferences
                                    ._participantProfileIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (roleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.roleId,
                            referencedTable:
                                $$ContestParticipationsTableReferences
                                    ._roleIdTable(db),
                            referencedColumn:
                                $$ContestParticipationsTableReferences
                                    ._roleIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (teamMembershipsRefs)
                        await $_getPrefetchedData<
                          ContestParticipationData,
                          $ContestParticipationsTable,
                          TeamMembershipData
                        >(
                          currentTable: table,
                          referencedTable:
                              $$ContestParticipationsTableReferences
                                  ._teamMembershipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContestParticipationsTableReferences(
                                db,
                                table,
                                p0,
                              ).teamMembershipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contestParticipationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contestModelLinksRefs)
                        await $_getPrefetchedData<
                          ContestParticipationData,
                          $ContestParticipationsTable,
                          ContestModelLinkData
                        >(
                          currentTable: table,
                          referencedTable:
                              $$ContestParticipationsTableReferences
                                  ._contestModelLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContestParticipationsTableReferences(
                                db,
                                table,
                                p0,
                              ).contestModelLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contestParticipationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ContestParticipationsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $ContestParticipationsTable,
      ContestParticipationData,
      $$ContestParticipationsTableFilterComposer,
      $$ContestParticipationsTableOrderingComposer,
      $$ContestParticipationsTableAnnotationComposer,
      $$ContestParticipationsTableCreateCompanionBuilder,
      $$ContestParticipationsTableUpdateCompanionBuilder,
      (ContestParticipationData, $$ContestParticipationsTableReferences),
      ContestParticipationData,
      PrefetchHooks Function({
        bool contestId,
        bool participantProfileId,
        bool roleId,
        bool teamMembershipsRefs,
        bool contestModelLinksRefs,
      })
    >;
typedef $$TeamsTableCreateCompanionBuilder = TeamsCompanion Function({
  required String id,
  required String contestId,
  required String name,
  Value<int> revision,
  Value<int> rowid,
});
typedef $$TeamsTableUpdateCompanionBuilder = TeamsCompanion Function({
  Value<String> id,
  Value<String> contestId,
  Value<String> name,
  Value<int> revision,
  Value<int> rowid,
});

final class $$TeamsTableReferences
    extends BaseReferences<_$SoarScoreDatabase, $TeamsTable, TeamData> {
  $$TeamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ContestsTable _contestIdTable(_$SoarScoreDatabase db) =>
      db.contests.createAlias('teams__contest_id__contests__id');

  $$ContestsTableProcessedTableManager get contestId {
    final $_column = $_itemColumn<String>('contest_id')!;

    final manager = $$ContestsTableTableManager(
      $_db,
      $_db.contests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TeamMembershipsTable, List<TeamMembershipData>>
  _teamMembershipsRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.teamMemberships,
        aliasName: 'teams__id__team_memberships__team_id',
      );

  $$TeamMembershipsTableProcessedTableManager get teamMembershipsRefs {
    final manager = $$TeamMembershipsTableTableManager(
      $_db,
      $_db.teamMemberships,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _teamMembershipsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeamsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $TeamsTable> {
  $$TeamsTableFilterComposer({
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

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $$ContestsTableFilterComposer get contestId {
    final $$ContestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableFilterComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> teamMembershipsRefs(
    Expression<bool> Function($$TeamMembershipsTableFilterComposer f) f,
  ) {
    final $$TeamMembershipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMemberships,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembershipsTableFilterComposer(
            $db: $db,
            $table: $db.teamMemberships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $TeamsTable> {
  $$TeamsTableOrderingComposer({
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

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContestsTableOrderingComposer get contestId {
    final $$ContestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableOrderingComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $TeamsTable> {
  $$TeamsTableAnnotationComposer({
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

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $$ContestsTableAnnotationComposer get contestId {
    final $$ContestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableAnnotationComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> teamMembershipsRefs<T extends Object>(
    Expression<T> Function($$TeamMembershipsTableAnnotationComposer a) f,
  ) {
    final $$TeamMembershipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMemberships,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembershipsTableAnnotationComposer(
            $db: $db,
            $table: $db.teamMemberships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $TeamsTable,
          TeamData,
          $$TeamsTableFilterComposer,
          $$TeamsTableOrderingComposer,
          $$TeamsTableAnnotationComposer,
          $$TeamsTableCreateCompanionBuilder,
          $$TeamsTableUpdateCompanionBuilder,
          (TeamData, $$TeamsTableReferences),
          TeamData,
          PrefetchHooks Function({bool contestId, bool teamMembershipsRefs})
        > {
  $$TeamsTableTableManager(_$SoarScoreDatabase db, $TeamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contestId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamsCompanion(
                id: id,
                contestId: contestId,
                name: name,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contestId,
                required String name,
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamsCompanion.insert(
                id: id,
                contestId: contestId,
                name: name,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeamsTable, TeamData>(table),
                  $$TeamsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({contestId = false, teamMembershipsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (teamMembershipsRefs) db.teamMemberships,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (contestId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contestId,
                            referencedTable: $$TeamsTableReferences
                                ._contestIdTable(db),
                            referencedColumn: $$TeamsTableReferences
                                ._contestIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (teamMembershipsRefs)
                        await $_getPrefetchedData<
                          TeamData,
                          $TeamsTable,
                          TeamMembershipData
                        >(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._teamMembershipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(
                                db,
                                table,
                                p0,
                              ).teamMembershipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $TeamsTable,
      TeamData,
      $$TeamsTableFilterComposer,
      $$TeamsTableOrderingComposer,
      $$TeamsTableAnnotationComposer,
      $$TeamsTableCreateCompanionBuilder,
      $$TeamsTableUpdateCompanionBuilder,
      (TeamData, $$TeamsTableReferences),
      TeamData,
      PrefetchHooks Function({bool contestId, bool teamMembershipsRefs})
    >;
typedef $$TeamMembershipsTableCreateCompanionBuilder =
    TeamMembershipsCompanion Function({
      required String id,
      required String teamId,
      required String contestParticipationId,
      required String contestId,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$TeamMembershipsTableUpdateCompanionBuilder =
    TeamMembershipsCompanion Function({
      Value<String> id,
      Value<String> teamId,
      Value<String> contestParticipationId,
      Value<String> contestId,
      Value<int> revision,
      Value<int> rowid,
    });

final class $$TeamMembershipsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $TeamMembershipsTable,
          TeamMembershipData
        > {
  $$TeamMembershipsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TeamsTable _teamIdTable(_$SoarScoreDatabase db) =>
      db.teams.createAlias('team_memberships__team_id__teams__id');

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<String>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContestParticipationsTable _contestParticipationIdTable(
    _$SoarScoreDatabase db,
  ) => db.contestParticipations.createAlias(
    'team_memberships__contest_participation_id__contest_participations__id',
  );

  $$ContestParticipationsTableProcessedTableManager get contestParticipationId {
    final $_column = $_itemColumn<String>('contest_participation_id')!;

    final manager = $$ContestParticipationsTableTableManager(
      $_db,
      $_db.contestParticipations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _contestParticipationIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContestsTable _contestIdTable(_$SoarScoreDatabase db) =>
      db.contests.createAlias('team_memberships__contest_id__contests__id');

  $$ContestsTableProcessedTableManager get contestId {
    final $_column = $_itemColumn<String>('contest_id')!;

    final manager = $$ContestsTableTableManager(
      $_db,
      $_db.contests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TeamMembershipsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $TeamMembershipsTable> {
  $$TeamMembershipsTableFilterComposer({
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

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContestParticipationsTableFilterComposer get contestParticipationId {
    final $$ContestParticipationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contestParticipationId,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableFilterComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ContestsTableFilterComposer get contestId {
    final $$ContestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableFilterComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembershipsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $TeamMembershipsTable> {
  $$TeamMembershipsTableOrderingComposer({
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

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContestParticipationsTableOrderingComposer get contestParticipationId {
    final $$ContestParticipationsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contestParticipationId,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableOrderingComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ContestsTableOrderingComposer get contestId {
    final $$ContestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableOrderingComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembershipsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $TeamMembershipsTable> {
  $$TeamMembershipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContestParticipationsTableAnnotationComposer get contestParticipationId {
    final $$ContestParticipationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contestParticipationId,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ContestsTableAnnotationComposer get contestId {
    final $$ContestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableAnnotationComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembershipsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $TeamMembershipsTable,
          TeamMembershipData,
          $$TeamMembershipsTableFilterComposer,
          $$TeamMembershipsTableOrderingComposer,
          $$TeamMembershipsTableAnnotationComposer,
          $$TeamMembershipsTableCreateCompanionBuilder,
          $$TeamMembershipsTableUpdateCompanionBuilder,
          (TeamMembershipData, $$TeamMembershipsTableReferences),
          TeamMembershipData,
          PrefetchHooks Function({
            bool teamId,
            bool contestParticipationId,
            bool contestId,
          })
        > {
  $$TeamMembershipsTableTableManager(
    _$SoarScoreDatabase db,
    $TeamMembershipsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamMembershipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamMembershipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamMembershipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> contestParticipationId = const Value.absent(),
                Value<String> contestId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamMembershipsCompanion(
                id: id,
                teamId: teamId,
                contestParticipationId: contestParticipationId,
                contestId: contestId,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teamId,
                required String contestParticipationId,
                required String contestId,
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamMembershipsCompanion.insert(
                id: id,
                teamId: teamId,
                contestParticipationId: contestParticipationId,
                contestId: contestId,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeamMembershipsTable, TeamMembershipData>(table),
                  $$TeamMembershipsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                teamId = false,
                contestParticipationId = false,
                contestId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (teamId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.teamId,
                            referencedTable: $$TeamMembershipsTableReferences
                                ._teamIdTable(db),
                            referencedColumn: $$TeamMembershipsTableReferences
                                ._teamIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (contestParticipationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contestParticipationId,
                            referencedTable: $$TeamMembershipsTableReferences
                                ._contestParticipationIdTable(db),
                            referencedColumn: $$TeamMembershipsTableReferences
                                ._contestParticipationIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (contestId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contestId,
                            referencedTable: $$TeamMembershipsTableReferences
                                ._contestIdTable(db),
                            referencedColumn: $$TeamMembershipsTableReferences
                                ._contestIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TeamMembershipsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $TeamMembershipsTable,
      TeamMembershipData,
      $$TeamMembershipsTableFilterComposer,
      $$TeamMembershipsTableOrderingComposer,
      $$TeamMembershipsTableAnnotationComposer,
      $$TeamMembershipsTableCreateCompanionBuilder,
      $$TeamMembershipsTableUpdateCompanionBuilder,
      (TeamMembershipData, $$TeamMembershipsTableReferences),
      TeamMembershipData,
      PrefetchHooks Function({
        bool teamId,
        bool contestParticipationId,
        bool contestId,
      })
    >;
typedef $$ModelCatalogsTableCreateCompanionBuilder =
    ModelCatalogsCompanion Function({
      required String id,
      required String ownerAccountId,
      required String name,
      Value<String?> manufacturer,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$ModelCatalogsTableUpdateCompanionBuilder =
    ModelCatalogsCompanion Function({
      Value<String> id,
      Value<String> ownerAccountId,
      Value<String> name,
      Value<String?> manufacturer,
      Value<int> revision,
      Value<int> rowid,
    });

final class $$ModelCatalogsTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $ModelCatalogsTable,
          ModelCatalogData
        > {
  $$ModelCatalogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ContestModelLinksTable,
    List<ContestModelLinkData>
  >
  _contestModelLinksRefsTable(_$SoarScoreDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.contestModelLinks,
        aliasName: 'model_catalogs__id__contest_model_links__model_catalog_id',
      );

  $$ContestModelLinksTableProcessedTableManager get contestModelLinksRefs {
    final manager = $$ContestModelLinksTableTableManager(
      $_db,
      $_db.contestModelLinks,
    ).filter((f) => f.modelCatalogId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _contestModelLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ModelCatalogsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $ModelCatalogsTable> {
  $$ModelCatalogsTableFilterComposer({
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

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contestModelLinksRefs(
    Expression<bool> Function($$ContestModelLinksTableFilterComposer f) f,
  ) {
    final $$ContestModelLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contestModelLinks,
      getReferencedColumn: (t) => t.modelCatalogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestModelLinksTableFilterComposer(
            $db: $db,
            $table: $db.contestModelLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ModelCatalogsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $ModelCatalogsTable> {
  $$ModelCatalogsTableOrderingComposer({
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

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModelCatalogsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $ModelCatalogsTable> {
  $$ModelCatalogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  Expression<T> contestModelLinksRefs<T extends Object>(
    Expression<T> Function($$ContestModelLinksTableAnnotationComposer a) f,
  ) {
    final $$ContestModelLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contestModelLinks,
          getReferencedColumn: (t) => t.modelCatalogId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestModelLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.contestModelLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ModelCatalogsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $ModelCatalogsTable,
          ModelCatalogData,
          $$ModelCatalogsTableFilterComposer,
          $$ModelCatalogsTableOrderingComposer,
          $$ModelCatalogsTableAnnotationComposer,
          $$ModelCatalogsTableCreateCompanionBuilder,
          $$ModelCatalogsTableUpdateCompanionBuilder,
          (ModelCatalogData, $$ModelCatalogsTableReferences),
          ModelCatalogData,
          PrefetchHooks Function({bool contestModelLinksRefs})
        > {
  $$ModelCatalogsTableTableManager(
    _$SoarScoreDatabase db,
    $ModelCatalogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelCatalogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelCatalogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelCatalogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerAccountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelCatalogsCompanion(
                id: id,
                ownerAccountId: ownerAccountId,
                name: name,
                manufacturer: manufacturer,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerAccountId,
                required String name,
                Value<String?> manufacturer = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelCatalogsCompanion.insert(
                id: id,
                ownerAccountId: ownerAccountId,
                name: name,
                manufacturer: manufacturer,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ModelCatalogsTable, ModelCatalogData>(table),
                  $$ModelCatalogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contestModelLinksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (contestModelLinksRefs) db.contestModelLinks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (contestModelLinksRefs)
                    await $_getPrefetchedData<
                      ModelCatalogData,
                      $ModelCatalogsTable,
                      ContestModelLinkData
                    >(
                      currentTable: table,
                      referencedTable: $$ModelCatalogsTableReferences
                          ._contestModelLinksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ModelCatalogsTableReferences(
                            db,
                            table,
                            p0,
                          ).contestModelLinksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.modelCatalogId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ModelCatalogsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $ModelCatalogsTable,
      ModelCatalogData,
      $$ModelCatalogsTableFilterComposer,
      $$ModelCatalogsTableOrderingComposer,
      $$ModelCatalogsTableAnnotationComposer,
      $$ModelCatalogsTableCreateCompanionBuilder,
      $$ModelCatalogsTableUpdateCompanionBuilder,
      (ModelCatalogData, $$ModelCatalogsTableReferences),
      ModelCatalogData,
      PrefetchHooks Function({bool contestModelLinksRefs})
    >;
typedef $$ContestModelLinksTableCreateCompanionBuilder =
    ContestModelLinksCompanion Function({
      required String id,
      required String contestId,
      required String contestParticipationId,
      Value<String?> modelCatalogId,
      required String modelName,
      Value<String?> manufacturer,
      required String modelId,
      Value<String?> contestSpecificIdentifier,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$ContestModelLinksTableUpdateCompanionBuilder =
    ContestModelLinksCompanion Function({
      Value<String> id,
      Value<String> contestId,
      Value<String> contestParticipationId,
      Value<String?> modelCatalogId,
      Value<String> modelName,
      Value<String?> manufacturer,
      Value<String> modelId,
      Value<String?> contestSpecificIdentifier,
      Value<int> revision,
      Value<int> rowid,
    });

final class $$ContestModelLinksTableReferences
    extends
        BaseReferences<
          _$SoarScoreDatabase,
          $ContestModelLinksTable,
          ContestModelLinkData
        > {
  $$ContestModelLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContestsTable _contestIdTable(_$SoarScoreDatabase db) =>
      db.contests.createAlias('contest_model_links__contest_id__contests__id');

  $$ContestsTableProcessedTableManager get contestId {
    final $_column = $_itemColumn<String>('contest_id')!;

    final manager = $$ContestsTableTableManager(
      $_db,
      $_db.contests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContestParticipationsTable _contestParticipationIdTable(
    _$SoarScoreDatabase db,
  ) => db.contestParticipations.createAlias(
    'contest_model_links__contest_participation_id__contest_participations__id',
  );

  $$ContestParticipationsTableProcessedTableManager get contestParticipationId {
    final $_column = $_itemColumn<String>('contest_participation_id')!;

    final manager = $$ContestParticipationsTableTableManager(
      $_db,
      $_db.contestParticipations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _contestParticipationIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ModelCatalogsTable _modelCatalogIdTable(_$SoarScoreDatabase db) => db
      .modelCatalogs
      .createAlias('contest_model_links__model_catalog_id__model_catalogs__id');

  $$ModelCatalogsTableProcessedTableManager? get modelCatalogId {
    final $_column = $_itemColumn<String>('model_catalog_id');
    if ($_column == null) return null;
    final manager = $$ModelCatalogsTableTableManager(
      $_db,
      $_db.modelCatalogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modelCatalogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContestModelLinksTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $ContestModelLinksTable> {
  $$ContestModelLinksTableFilterComposer({
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

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contestSpecificIdentifier => $composableBuilder(
    column: $table.contestSpecificIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $$ContestsTableFilterComposer get contestId {
    final $$ContestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableFilterComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContestParticipationsTableFilterComposer get contestParticipationId {
    final $$ContestParticipationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contestParticipationId,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableFilterComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ModelCatalogsTableFilterComposer get modelCatalogId {
    final $$ModelCatalogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelCatalogId,
      referencedTable: $db.modelCatalogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModelCatalogsTableFilterComposer(
            $db: $db,
            $table: $db.modelCatalogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContestModelLinksTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $ContestModelLinksTable> {
  $$ContestModelLinksTableOrderingComposer({
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

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contestSpecificIdentifier => $composableBuilder(
    column: $table.contestSpecificIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContestsTableOrderingComposer get contestId {
    final $$ContestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableOrderingComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContestParticipationsTableOrderingComposer get contestParticipationId {
    final $$ContestParticipationsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contestParticipationId,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableOrderingComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ModelCatalogsTableOrderingComposer get modelCatalogId {
    final $$ModelCatalogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelCatalogId,
      referencedTable: $db.modelCatalogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModelCatalogsTableOrderingComposer(
            $db: $db,
            $table: $db.modelCatalogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContestModelLinksTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $ContestModelLinksTable> {
  $$ContestModelLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get contestSpecificIdentifier => $composableBuilder(
    column: $table.contestSpecificIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $$ContestsTableAnnotationComposer get contestId {
    final $$ContestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contestId,
      referencedTable: $db.contests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContestsTableAnnotationComposer(
            $db: $db,
            $table: $db.contests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContestParticipationsTableAnnotationComposer get contestParticipationId {
    final $$ContestParticipationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contestParticipationId,
          referencedTable: $db.contestParticipations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContestParticipationsTableAnnotationComposer(
                $db: $db,
                $table: $db.contestParticipations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ModelCatalogsTableAnnotationComposer get modelCatalogId {
    final $$ModelCatalogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelCatalogId,
      referencedTable: $db.modelCatalogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModelCatalogsTableAnnotationComposer(
            $db: $db,
            $table: $db.modelCatalogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContestModelLinksTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $ContestModelLinksTable,
          ContestModelLinkData,
          $$ContestModelLinksTableFilterComposer,
          $$ContestModelLinksTableOrderingComposer,
          $$ContestModelLinksTableAnnotationComposer,
          $$ContestModelLinksTableCreateCompanionBuilder,
          $$ContestModelLinksTableUpdateCompanionBuilder,
          (ContestModelLinkData, $$ContestModelLinksTableReferences),
          ContestModelLinkData,
          PrefetchHooks Function({
            bool contestId,
            bool contestParticipationId,
            bool modelCatalogId,
          })
        > {
  $$ContestModelLinksTableTableManager(
    _$SoarScoreDatabase db,
    $ContestModelLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContestModelLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContestModelLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContestModelLinksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contestId = const Value.absent(),
                Value<String> contestParticipationId = const Value.absent(),
                Value<String?> modelCatalogId = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String?> contestSpecificIdentifier = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestModelLinksCompanion(
                id: id,
                contestId: contestId,
                contestParticipationId: contestParticipationId,
                modelCatalogId: modelCatalogId,
                modelName: modelName,
                manufacturer: manufacturer,
                modelId: modelId,
                contestSpecificIdentifier: contestSpecificIdentifier,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contestId,
                required String contestParticipationId,
                Value<String?> modelCatalogId = const Value.absent(),
                required String modelName,
                Value<String?> manufacturer = const Value.absent(),
                required String modelId,
                Value<String?> contestSpecificIdentifier = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContestModelLinksCompanion.insert(
                id: id,
                contestId: contestId,
                contestParticipationId: contestParticipationId,
                modelCatalogId: modelCatalogId,
                modelName: modelName,
                manufacturer: manufacturer,
                modelId: modelId,
                contestSpecificIdentifier: contestSpecificIdentifier,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContestModelLinksTable, ContestModelLinkData>(
                    table,
                  ),
                  $$ContestModelLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                contestId = false,
                contestParticipationId = false,
                modelCatalogId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (contestId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contestId,
                            referencedTable: $$ContestModelLinksTableReferences
                                ._contestIdTable(db),
                            referencedColumn: $$ContestModelLinksTableReferences
                                ._contestIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (contestParticipationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contestParticipationId,
                            referencedTable: $$ContestModelLinksTableReferences
                                ._contestParticipationIdTable(db),
                            referencedColumn: $$ContestModelLinksTableReferences
                                ._contestParticipationIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (modelCatalogId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.modelCatalogId,
                            referencedTable: $$ContestModelLinksTableReferences
                                ._modelCatalogIdTable(db),
                            referencedColumn: $$ContestModelLinksTableReferences
                                ._modelCatalogIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ContestModelLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $ContestModelLinksTable,
      ContestModelLinkData,
      $$ContestModelLinksTableFilterComposer,
      $$ContestModelLinksTableOrderingComposer,
      $$ContestModelLinksTableAnnotationComposer,
      $$ContestModelLinksTableCreateCompanionBuilder,
      $$ContestModelLinksTableUpdateCompanionBuilder,
      (ContestModelLinkData, $$ContestModelLinksTableReferences),
      ContestModelLinkData,
      PrefetchHooks Function({
        bool contestId,
        bool contestParticipationId,
        bool modelCatalogId,
      })
    >;
typedef $$MutationRecordsTableCreateCompanionBuilder =
    MutationRecordsCompanion Function({
      required String id,
      Value<String?> contestId,
      Value<String?> ownerAccountId,
      Value<int?> sequence,
      required String entityType,
      required String entityId,
      Value<int?> baseRevision,
      required String clientMutationId,
      Value<String?> actorId,
      required String authority,
      Value<String?> sourceInstallationId,
      Value<String?> sourceDevice,
      required String clientTime,
      Value<String?> serverAcceptanceTime,
      Value<String?> serverRejectionTime,
      required String payload,
      required String outcome,
      Value<String?> reasonCode,
      Value<String?> errorMessage,
      Value<String?> dependsOnMutationId,
      Value<int> rowid,
    });
typedef $$MutationRecordsTableUpdateCompanionBuilder =
    MutationRecordsCompanion Function({
      Value<String> id,
      Value<String?> contestId,
      Value<String?> ownerAccountId,
      Value<int?> sequence,
      Value<String> entityType,
      Value<String> entityId,
      Value<int?> baseRevision,
      Value<String> clientMutationId,
      Value<String?> actorId,
      Value<String> authority,
      Value<String?> sourceInstallationId,
      Value<String?> sourceDevice,
      Value<String> clientTime,
      Value<String?> serverAcceptanceTime,
      Value<String?> serverRejectionTime,
      Value<String> payload,
      Value<String> outcome,
      Value<String?> reasonCode,
      Value<String?> errorMessage,
      Value<String?> dependsOnMutationId,
      Value<int> rowid,
    });

class $$MutationRecordsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $MutationRecordsTable> {
  $$MutationRecordsTableFilterComposer({
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

  ColumnFilters<String> get contestId => $composableBuilder(
    column: $table.contestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authority => $composableBuilder(
    column: $table.authority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceInstallationId => $composableBuilder(
    column: $table.sourceInstallationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDevice => $composableBuilder(
    column: $table.sourceDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientTime => $composableBuilder(
    column: $table.clientTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverAcceptanceTime => $composableBuilder(
    column: $table.serverAcceptanceTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverRejectionTime => $composableBuilder(
    column: $table.serverRejectionTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOnMutationId => $composableBuilder(
    column: $table.dependsOnMutationId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MutationRecordsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $MutationRecordsTable> {
  $$MutationRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get contestId => $composableBuilder(
    column: $table.contestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authority => $composableBuilder(
    column: $table.authority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceInstallationId => $composableBuilder(
    column: $table.sourceInstallationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDevice => $composableBuilder(
    column: $table.sourceDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientTime => $composableBuilder(
    column: $table.clientTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverAcceptanceTime => $composableBuilder(
    column: $table.serverAcceptanceTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverRejectionTime => $composableBuilder(
    column: $table.serverRejectionTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOnMutationId => $composableBuilder(
    column: $table.dependsOnMutationId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MutationRecordsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $MutationRecordsTable> {
  $$MutationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contestId =>
      $composableBuilder(column: $table.contestId, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get authority =>
      $composableBuilder(column: $table.authority, builder: (column) => column);

  GeneratedColumn<String> get sourceInstallationId => $composableBuilder(
    column: $table.sourceInstallationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceDevice => $composableBuilder(
    column: $table.sourceDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientTime => $composableBuilder(
    column: $table.clientTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverAcceptanceTime => $composableBuilder(
    column: $table.serverAcceptanceTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverRejectionTime => $composableBuilder(
    column: $table.serverRejectionTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependsOnMutationId => $composableBuilder(
    column: $table.dependsOnMutationId,
    builder: (column) => column,
  );
}

class $$MutationRecordsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $MutationRecordsTable,
          MutationRecordData,
          $$MutationRecordsTableFilterComposer,
          $$MutationRecordsTableOrderingComposer,
          $$MutationRecordsTableAnnotationComposer,
          $$MutationRecordsTableCreateCompanionBuilder,
          $$MutationRecordsTableUpdateCompanionBuilder,
          (
            MutationRecordData,
            BaseReferences<
              _$SoarScoreDatabase,
              $MutationRecordsTable,
              MutationRecordData
            >,
          ),
          MutationRecordData,
          PrefetchHooks Function()
        > {
  $$MutationRecordsTableTableManager(
    _$SoarScoreDatabase db,
    $MutationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutationRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutationRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutationRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> contestId = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<int?> sequence = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<int?> baseRevision = const Value.absent(),
                Value<String> clientMutationId = const Value.absent(),
                Value<String?> actorId = const Value.absent(),
                Value<String> authority = const Value.absent(),
                Value<String?> sourceInstallationId = const Value.absent(),
                Value<String?> sourceDevice = const Value.absent(),
                Value<String> clientTime = const Value.absent(),
                Value<String?> serverAcceptanceTime = const Value.absent(),
                Value<String?> serverRejectionTime = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String?> reasonCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> dependsOnMutationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MutationRecordsCompanion(
                id: id,
                contestId: contestId,
                ownerAccountId: ownerAccountId,
                sequence: sequence,
                entityType: entityType,
                entityId: entityId,
                baseRevision: baseRevision,
                clientMutationId: clientMutationId,
                actorId: actorId,
                authority: authority,
                sourceInstallationId: sourceInstallationId,
                sourceDevice: sourceDevice,
                clientTime: clientTime,
                serverAcceptanceTime: serverAcceptanceTime,
                serverRejectionTime: serverRejectionTime,
                payload: payload,
                outcome: outcome,
                reasonCode: reasonCode,
                errorMessage: errorMessage,
                dependsOnMutationId: dependsOnMutationId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> contestId = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<int?> sequence = const Value.absent(),
                required String entityType,
                required String entityId,
                Value<int?> baseRevision = const Value.absent(),
                required String clientMutationId,
                Value<String?> actorId = const Value.absent(),
                required String authority,
                Value<String?> sourceInstallationId = const Value.absent(),
                Value<String?> sourceDevice = const Value.absent(),
                required String clientTime,
                Value<String?> serverAcceptanceTime = const Value.absent(),
                Value<String?> serverRejectionTime = const Value.absent(),
                required String payload,
                required String outcome,
                Value<String?> reasonCode = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> dependsOnMutationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MutationRecordsCompanion.insert(
                id: id,
                contestId: contestId,
                ownerAccountId: ownerAccountId,
                sequence: sequence,
                entityType: entityType,
                entityId: entityId,
                baseRevision: baseRevision,
                clientMutationId: clientMutationId,
                actorId: actorId,
                authority: authority,
                sourceInstallationId: sourceInstallationId,
                sourceDevice: sourceDevice,
                clientTime: clientTime,
                serverAcceptanceTime: serverAcceptanceTime,
                serverRejectionTime: serverRejectionTime,
                payload: payload,
                outcome: outcome,
                reasonCode: reasonCode,
                errorMessage: errorMessage,
                dependsOnMutationId: dependsOnMutationId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MutationRecordsTable, MutationRecordData>(table),
                  BaseReferences<
                    _$SoarScoreDatabase,
                    $MutationRecordsTable,
                    MutationRecordData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MutationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $MutationRecordsTable,
      MutationRecordData,
      $$MutationRecordsTableFilterComposer,
      $$MutationRecordsTableOrderingComposer,
      $$MutationRecordsTableAnnotationComposer,
      $$MutationRecordsTableCreateCompanionBuilder,
      $$MutationRecordsTableUpdateCompanionBuilder,
      (
        MutationRecordData,
        BaseReferences<
          _$SoarScoreDatabase,
          $MutationRecordsTable,
          MutationRecordData
        >,
      ),
      MutationRecordData,
      PrefetchHooks Function()
    >;
typedef $$ConflictRecordsTableCreateCompanionBuilder =
    ConflictRecordsCompanion Function({
      required String id,
      Value<String?> contestId,
      Value<String?> ownerAccountId,
      required String entityType,
      required String entityId,
      Value<String?> acceptedMutationId,
      required String competingMutationId,
      required String reasonCode,
      Value<String?> reason,
      Value<bool> requiresAction,
      required String resolution,
      Value<String?> resolutionChoice,
      required String createdAt,
      Value<String?> resolvedAt,
      Value<String?> resolvedBy,
      Value<int> rowid,
    });
typedef $$ConflictRecordsTableUpdateCompanionBuilder =
    ConflictRecordsCompanion Function({
      Value<String> id,
      Value<String?> contestId,
      Value<String?> ownerAccountId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String?> acceptedMutationId,
      Value<String> competingMutationId,
      Value<String> reasonCode,
      Value<String?> reason,
      Value<bool> requiresAction,
      Value<String> resolution,
      Value<String?> resolutionChoice,
      Value<String> createdAt,
      Value<String?> resolvedAt,
      Value<String?> resolvedBy,
      Value<int> rowid,
    });

class $$ConflictRecordsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $ConflictRecordsTable> {
  $$ConflictRecordsTableFilterComposer({
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

  ColumnFilters<String> get contestId => $composableBuilder(
    column: $table.contestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acceptedMutationId => $composableBuilder(
    column: $table.acceptedMutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get competingMutationId => $composableBuilder(
    column: $table.competingMutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresAction => $composableBuilder(
    column: $table.requiresAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionChoice => $composableBuilder(
    column: $table.resolutionChoice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvedBy => $composableBuilder(
    column: $table.resolvedBy,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConflictRecordsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $ConflictRecordsTable> {
  $$ConflictRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get contestId => $composableBuilder(
    column: $table.contestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acceptedMutationId => $composableBuilder(
    column: $table.acceptedMutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get competingMutationId => $composableBuilder(
    column: $table.competingMutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresAction => $composableBuilder(
    column: $table.requiresAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionChoice => $composableBuilder(
    column: $table.resolutionChoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedBy => $composableBuilder(
    column: $table.resolvedBy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConflictRecordsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $ConflictRecordsTable> {
  $$ConflictRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contestId =>
      $composableBuilder(column: $table.contestId, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get acceptedMutationId => $composableBuilder(
    column: $table.acceptedMutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get competingMutationId => $composableBuilder(
    column: $table.competingMutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get requiresAction => $composableBuilder(
    column: $table.requiresAction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionChoice => $composableBuilder(
    column: $table.resolutionChoice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolvedBy => $composableBuilder(
    column: $table.resolvedBy,
    builder: (column) => column,
  );
}

class $$ConflictRecordsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $ConflictRecordsTable,
          ConflictRecordData,
          $$ConflictRecordsTableFilterComposer,
          $$ConflictRecordsTableOrderingComposer,
          $$ConflictRecordsTableAnnotationComposer,
          $$ConflictRecordsTableCreateCompanionBuilder,
          $$ConflictRecordsTableUpdateCompanionBuilder,
          (
            ConflictRecordData,
            BaseReferences<
              _$SoarScoreDatabase,
              $ConflictRecordsTable,
              ConflictRecordData
            >,
          ),
          ConflictRecordData,
          PrefetchHooks Function()
        > {
  $$ConflictRecordsTableTableManager(
    _$SoarScoreDatabase db,
    $ConflictRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> contestId = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String?> acceptedMutationId = const Value.absent(),
                Value<String> competingMutationId = const Value.absent(),
                Value<String> reasonCode = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<bool> requiresAction = const Value.absent(),
                Value<String> resolution = const Value.absent(),
                Value<String?> resolutionChoice = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> resolvedAt = const Value.absent(),
                Value<String?> resolvedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictRecordsCompanion(
                id: id,
                contestId: contestId,
                ownerAccountId: ownerAccountId,
                entityType: entityType,
                entityId: entityId,
                acceptedMutationId: acceptedMutationId,
                competingMutationId: competingMutationId,
                reasonCode: reasonCode,
                reason: reason,
                requiresAction: requiresAction,
                resolution: resolution,
                resolutionChoice: resolutionChoice,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                resolvedBy: resolvedBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> contestId = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                required String entityType,
                required String entityId,
                Value<String?> acceptedMutationId = const Value.absent(),
                required String competingMutationId,
                required String reasonCode,
                Value<String?> reason = const Value.absent(),
                Value<bool> requiresAction = const Value.absent(),
                required String resolution,
                Value<String?> resolutionChoice = const Value.absent(),
                required String createdAt,
                Value<String?> resolvedAt = const Value.absent(),
                Value<String?> resolvedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictRecordsCompanion.insert(
                id: id,
                contestId: contestId,
                ownerAccountId: ownerAccountId,
                entityType: entityType,
                entityId: entityId,
                acceptedMutationId: acceptedMutationId,
                competingMutationId: competingMutationId,
                reasonCode: reasonCode,
                reason: reason,
                requiresAction: requiresAction,
                resolution: resolution,
                resolutionChoice: resolutionChoice,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                resolvedBy: resolvedBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConflictRecordsTable, ConflictRecordData>(table),
                  BaseReferences<
                    _$SoarScoreDatabase,
                    $ConflictRecordsTable,
                    ConflictRecordData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConflictRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $ConflictRecordsTable,
      ConflictRecordData,
      $$ConflictRecordsTableFilterComposer,
      $$ConflictRecordsTableOrderingComposer,
      $$ConflictRecordsTableAnnotationComposer,
      $$ConflictRecordsTableCreateCompanionBuilder,
      $$ConflictRecordsTableUpdateCompanionBuilder,
      (
        ConflictRecordData,
        BaseReferences<
          _$SoarScoreDatabase,
          $ConflictRecordsTable,
          ConflictRecordData
        >,
      ),
      ConflictRecordData,
      PrefetchHooks Function()
    >;
typedef $$TombstonesTableCreateCompanionBuilder = TombstonesCompanion Function({
  required String id,
  Value<String?> contestId,
  Value<String?> ownerAccountId,
  required String entityType,
  required String entityId,
  required String status,
  required String deletedAt,
  Value<String?> acknowledgedAt,
  Value<String?> purgeAfter,
  Value<String?> deletionReason,
  Value<int> rowid,
});
typedef $$TombstonesTableUpdateCompanionBuilder = TombstonesCompanion Function({
  Value<String> id,
  Value<String?> contestId,
  Value<String?> ownerAccountId,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> status,
  Value<String> deletedAt,
  Value<String?> acknowledgedAt,
  Value<String?> purgeAfter,
  Value<String?> deletionReason,
  Value<int> rowid,
});

class $$TombstonesTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $TombstonesTable> {
  $$TombstonesTableFilterComposer({
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

  ColumnFilters<String> get contestId => $composableBuilder(
    column: $table.contestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purgeAfter => $composableBuilder(
    column: $table.purgeAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletionReason => $composableBuilder(
    column: $table.deletionReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TombstonesTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $TombstonesTable> {
  $$TombstonesTableOrderingComposer({
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

  ColumnOrderings<String> get contestId => $composableBuilder(
    column: $table.contestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purgeAfter => $composableBuilder(
    column: $table.purgeAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletionReason => $composableBuilder(
    column: $table.deletionReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TombstonesTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $TombstonesTable> {
  $$TombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contestId =>
      $composableBuilder(column: $table.contestId, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purgeAfter => $composableBuilder(
    column: $table.purgeAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletionReason => $composableBuilder(
    column: $table.deletionReason,
    builder: (column) => column,
  );
}

class $$TombstonesTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $TombstonesTable,
          TombstoneData,
          $$TombstonesTableFilterComposer,
          $$TombstonesTableOrderingComposer,
          $$TombstonesTableAnnotationComposer,
          $$TombstonesTableCreateCompanionBuilder,
          $$TombstonesTableUpdateCompanionBuilder,
          (
            TombstoneData,
            BaseReferences<
              _$SoarScoreDatabase,
              $TombstonesTable,
              TombstoneData
            >,
          ),
          TombstoneData,
          PrefetchHooks Function()
        > {
  $$TombstonesTableTableManager(_$SoarScoreDatabase db, $TombstonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> contestId = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> deletedAt = const Value.absent(),
                Value<String?> acknowledgedAt = const Value.absent(),
                Value<String?> purgeAfter = const Value.absent(),
                Value<String?> deletionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion(
                id: id,
                contestId: contestId,
                ownerAccountId: ownerAccountId,
                entityType: entityType,
                entityId: entityId,
                status: status,
                deletedAt: deletedAt,
                acknowledgedAt: acknowledgedAt,
                purgeAfter: purgeAfter,
                deletionReason: deletionReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> contestId = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                required String entityType,
                required String entityId,
                required String status,
                required String deletedAt,
                Value<String?> acknowledgedAt = const Value.absent(),
                Value<String?> purgeAfter = const Value.absent(),
                Value<String?> deletionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion.insert(
                id: id,
                contestId: contestId,
                ownerAccountId: ownerAccountId,
                entityType: entityType,
                entityId: entityId,
                status: status,
                deletedAt: deletedAt,
                acknowledgedAt: acknowledgedAt,
                purgeAfter: purgeAfter,
                deletionReason: deletionReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TombstonesTable, TombstoneData>(table),
                  BaseReferences<
                    _$SoarScoreDatabase,
                    $TombstonesTable,
                    TombstoneData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $TombstonesTable,
      TombstoneData,
      $$TombstonesTableFilterComposer,
      $$TombstonesTableOrderingComposer,
      $$TombstonesTableAnnotationComposer,
      $$TombstonesTableCreateCompanionBuilder,
      $$TombstonesTableUpdateCompanionBuilder,
      (
        TombstoneData,
        BaseReferences<_$SoarScoreDatabase, $TombstonesTable, TombstoneData>,
      ),
      TombstoneData,
      PrefetchHooks Function()
    >;
typedef $$AuditEventsTableCreateCompanionBuilder =
    AuditEventsCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      Value<String?> contestId,
      Value<String?> ownerAccountId,
      Value<String?> publicationId,
      required String action,
      Value<String?> actorId,
      required String authority,
      Value<String?> installationId,
      Value<String?> device,
      Value<int?> baseRevision,
      Value<int?> resultingRevision,
      required String serverTimestamp,
      Value<String?> clientTimestamp,
      Value<String?> reason,
      required String outcome,
      Value<int> rowid,
    });
typedef $$AuditEventsTableUpdateCompanionBuilder =
    AuditEventsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String?> contestId,
      Value<String?> ownerAccountId,
      Value<String?> publicationId,
      Value<String> action,
      Value<String?> actorId,
      Value<String> authority,
      Value<String?> installationId,
      Value<String?> device,
      Value<int?> baseRevision,
      Value<int?> resultingRevision,
      Value<String> serverTimestamp,
      Value<String?> clientTimestamp,
      Value<String?> reason,
      Value<String> outcome,
      Value<int> rowid,
    });

class $$AuditEventsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $AuditEventsTable> {
  $$AuditEventsTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contestId => $composableBuilder(
    column: $table.contestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicationId => $composableBuilder(
    column: $table.publicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authority => $composableBuilder(
    column: $table.authority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get device => $composableBuilder(
    column: $table.device,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resultingRevision => $composableBuilder(
    column: $table.resultingRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverTimestamp => $composableBuilder(
    column: $table.serverTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientTimestamp => $composableBuilder(
    column: $table.clientTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditEventsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $AuditEventsTable> {
  $$AuditEventsTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contestId => $composableBuilder(
    column: $table.contestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicationId => $composableBuilder(
    column: $table.publicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authority => $composableBuilder(
    column: $table.authority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get device => $composableBuilder(
    column: $table.device,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resultingRevision => $composableBuilder(
    column: $table.resultingRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverTimestamp => $composableBuilder(
    column: $table.serverTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientTimestamp => $composableBuilder(
    column: $table.clientTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditEventsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $AuditEventsTable> {
  $$AuditEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get contestId =>
      $composableBuilder(column: $table.contestId, builder: (column) => column);

  GeneratedColumn<String> get ownerAccountId => $composableBuilder(
    column: $table.ownerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicationId => $composableBuilder(
    column: $table.publicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get authority =>
      $composableBuilder(column: $table.authority, builder: (column) => column);

  GeneratedColumn<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resultingRevision => $composableBuilder(
    column: $table.resultingRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverTimestamp => $composableBuilder(
    column: $table.serverTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientTimestamp => $composableBuilder(
    column: $table.clientTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);
}

class $$AuditEventsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $AuditEventsTable,
          AuditEventData,
          $$AuditEventsTableFilterComposer,
          $$AuditEventsTableOrderingComposer,
          $$AuditEventsTableAnnotationComposer,
          $$AuditEventsTableCreateCompanionBuilder,
          $$AuditEventsTableUpdateCompanionBuilder,
          (
            AuditEventData,
            BaseReferences<
              _$SoarScoreDatabase,
              $AuditEventsTable,
              AuditEventData
            >,
          ),
          AuditEventData,
          PrefetchHooks Function()
        > {
  $$AuditEventsTableTableManager(
    _$SoarScoreDatabase db,
    $AuditEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String?> contestId = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<String?> publicationId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> actorId = const Value.absent(),
                Value<String> authority = const Value.absent(),
                Value<String?> installationId = const Value.absent(),
                Value<String?> device = const Value.absent(),
                Value<int?> baseRevision = const Value.absent(),
                Value<int?> resultingRevision = const Value.absent(),
                Value<String> serverTimestamp = const Value.absent(),
                Value<String?> clientTimestamp = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEventsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                contestId: contestId,
                ownerAccountId: ownerAccountId,
                publicationId: publicationId,
                action: action,
                actorId: actorId,
                authority: authority,
                installationId: installationId,
                device: device,
                baseRevision: baseRevision,
                resultingRevision: resultingRevision,
                serverTimestamp: serverTimestamp,
                clientTimestamp: clientTimestamp,
                reason: reason,
                outcome: outcome,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                Value<String?> contestId = const Value.absent(),
                Value<String?> ownerAccountId = const Value.absent(),
                Value<String?> publicationId = const Value.absent(),
                required String action,
                Value<String?> actorId = const Value.absent(),
                required String authority,
                Value<String?> installationId = const Value.absent(),
                Value<String?> device = const Value.absent(),
                Value<int?> baseRevision = const Value.absent(),
                Value<int?> resultingRevision = const Value.absent(),
                required String serverTimestamp,
                Value<String?> clientTimestamp = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                required String outcome,
                Value<int> rowid = const Value.absent(),
              }) => AuditEventsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                contestId: contestId,
                ownerAccountId: ownerAccountId,
                publicationId: publicationId,
                action: action,
                actorId: actorId,
                authority: authority,
                installationId: installationId,
                device: device,
                baseRevision: baseRevision,
                resultingRevision: resultingRevision,
                serverTimestamp: serverTimestamp,
                clientTimestamp: clientTimestamp,
                reason: reason,
                outcome: outcome,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditEventsTable, AuditEventData>(table),
                  BaseReferences<
                    _$SoarScoreDatabase,
                    $AuditEventsTable,
                    AuditEventData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $AuditEventsTable,
      AuditEventData,
      $$AuditEventsTableFilterComposer,
      $$AuditEventsTableOrderingComposer,
      $$AuditEventsTableAnnotationComposer,
      $$AuditEventsTableCreateCompanionBuilder,
      $$AuditEventsTableUpdateCompanionBuilder,
      (
        AuditEventData,
        BaseReferences<_$SoarScoreDatabase, $AuditEventsTable, AuditEventData>,
      ),
      AuditEventData,
      PrefetchHooks Function()
    >;
typedef $$LocalSyncPositionsTableCreateCompanionBuilder =
    LocalSyncPositionsCompanion Function({
      required String scopeKind,
      required String scopeId,
      Value<int> lastSyncedSequence,
      Value<String?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$LocalSyncPositionsTableUpdateCompanionBuilder =
    LocalSyncPositionsCompanion Function({
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<int> lastSyncedSequence,
      Value<String?> lastSyncedAt,
      Value<int> rowid,
    });

class $$LocalSyncPositionsTableFilterComposer
    extends Composer<_$SoarScoreDatabase, $LocalSyncPositionsTable> {
  $$LocalSyncPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedSequence => $composableBuilder(
    column: $table.lastSyncedSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncPositionsTableOrderingComposer
    extends Composer<_$SoarScoreDatabase, $LocalSyncPositionsTable> {
  $$LocalSyncPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedSequence => $composableBuilder(
    column: $table.lastSyncedSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncPositionsTableAnnotationComposer
    extends Composer<_$SoarScoreDatabase, $LocalSyncPositionsTable> {
  $$LocalSyncPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedSequence => $composableBuilder(
    column: $table.lastSyncedSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$LocalSyncPositionsTableTableManager
    extends
        RootTableManager<
          _$SoarScoreDatabase,
          $LocalSyncPositionsTable,
          LocalSyncPositionData,
          $$LocalSyncPositionsTableFilterComposer,
          $$LocalSyncPositionsTableOrderingComposer,
          $$LocalSyncPositionsTableAnnotationComposer,
          $$LocalSyncPositionsTableCreateCompanionBuilder,
          $$LocalSyncPositionsTableUpdateCompanionBuilder,
          (
            LocalSyncPositionData,
            BaseReferences<
              _$SoarScoreDatabase,
              $LocalSyncPositionsTable,
              LocalSyncPositionData
            >,
          ),
          LocalSyncPositionData,
          PrefetchHooks Function()
        > {
  $$LocalSyncPositionsTableTableManager(
    _$SoarScoreDatabase db,
    $LocalSyncPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncPositionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<int> lastSyncedSequence = const Value.absent(),
                Value<String?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncPositionsCompanion(
                scopeKind: scopeKind,
                scopeId: scopeId,
                lastSyncedSequence: lastSyncedSequence,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scopeKind,
                required String scopeId,
                Value<int> lastSyncedSequence = const Value.absent(),
                Value<String?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncPositionsCompanion.insert(
                scopeKind: scopeKind,
                scopeId: scopeId,
                lastSyncedSequence: lastSyncedSequence,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSyncPositionsTable, LocalSyncPositionData>(
                    table,
                  ),
                  BaseReferences<
                    _$SoarScoreDatabase,
                    $LocalSyncPositionsTable,
                    LocalSyncPositionData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SoarScoreDatabase,
      $LocalSyncPositionsTable,
      LocalSyncPositionData,
      $$LocalSyncPositionsTableFilterComposer,
      $$LocalSyncPositionsTableOrderingComposer,
      $$LocalSyncPositionsTableAnnotationComposer,
      $$LocalSyncPositionsTableCreateCompanionBuilder,
      $$LocalSyncPositionsTableUpdateCompanionBuilder,
      (
        LocalSyncPositionData,
        BaseReferences<
          _$SoarScoreDatabase,
          $LocalSyncPositionsTable,
          LocalSyncPositionData
        >,
      ),
      LocalSyncPositionData,
      PrefetchHooks Function()
    >;

class $SoarScoreDatabaseManager {
  final _$SoarScoreDatabase _db;
  $SoarScoreDatabaseManager(this._db);
  $$ContestsTableTableManager get contests =>
      $$ContestsTableTableManager(_db, _db.contests);
  $$LandingTablesTableTableManager get landingTables =>
      $$LandingTablesTableTableManager(_db, _db.landingTables);
  $$LandingResultsTableTableManager get landingResults =>
      $$LandingResultsTableTableManager(_db, _db.landingResults);
  $$DisciplineProfilesTableTableManager get disciplineProfiles =>
      $$DisciplineProfilesTableTableManager(_db, _db.disciplineProfiles);
  $$DisciplineConfigFieldsTableTableManager get disciplineConfigFields =>
      $$DisciplineConfigFieldsTableTableManager(
        _db,
        _db.disciplineConfigFields,
      );
  $$DisciplineScoreFieldsTableTableManager get disciplineScoreFields =>
      $$DisciplineScoreFieldsTableTableManager(_db, _db.disciplineScoreFields);
  $$DisciplineValidationsTableTableManager get disciplineValidations =>
      $$DisciplineValidationsTableTableManager(_db, _db.disciplineValidations);
  $$DisciplineFormulasTableTableManager get disciplineFormulas =>
      $$DisciplineFormulasTableTableManager(_db, _db.disciplineFormulas);
  $$DisciplineRulesTableTableManager get disciplineRules =>
      $$DisciplineRulesTableTableManager(_db, _db.disciplineRules);
  $$ContestConfigurationPresetsTableTableManager
  get contestConfigurationPresets =>
      $$ContestConfigurationPresetsTableTableManager(
        _db,
        _db.contestConfigurationPresets,
      );
  $$ContestConfigurationRevisionsTableTableManager
  get contestConfigurationRevisions =>
      $$ContestConfigurationRevisionsTableTableManager(
        _db,
        _db.contestConfigurationRevisions,
      );
  $$ParticipantProfilesTableTableManager get participantProfiles =>
      $$ParticipantProfilesTableTableManager(_db, _db.participantProfiles);
  $$RolesTableTableManager get roles =>
      $$RolesTableTableManager(_db, _db.roles);
  $$ContestParticipationsTableTableManager get contestParticipations =>
      $$ContestParticipationsTableTableManager(_db, _db.contestParticipations);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$TeamMembershipsTableTableManager get teamMemberships =>
      $$TeamMembershipsTableTableManager(_db, _db.teamMemberships);
  $$ModelCatalogsTableTableManager get modelCatalogs =>
      $$ModelCatalogsTableTableManager(_db, _db.modelCatalogs);
  $$ContestModelLinksTableTableManager get contestModelLinks =>
      $$ContestModelLinksTableTableManager(_db, _db.contestModelLinks);
  $$MutationRecordsTableTableManager get mutationRecords =>
      $$MutationRecordsTableTableManager(_db, _db.mutationRecords);
  $$ConflictRecordsTableTableManager get conflictRecords =>
      $$ConflictRecordsTableTableManager(_db, _db.conflictRecords);
  $$TombstonesTableTableManager get tombstones =>
      $$TombstonesTableTableManager(_db, _db.tombstones);
  $$AuditEventsTableTableManager get auditEvents =>
      $$AuditEventsTableTableManager(_db, _db.auditEvents);
  $$LocalSyncPositionsTableTableManager get localSyncPositions =>
      $$LocalSyncPositionsTableTableManager(_db, _db.localSyncPositions);
}
