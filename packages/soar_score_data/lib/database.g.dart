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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_archive" IN (0, 1))',
    ),
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
