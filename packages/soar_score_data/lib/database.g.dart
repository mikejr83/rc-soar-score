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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("requires_action" IN (0, 1))',
    ),
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
    mutationRecords,
    conflictRecords,
    tombstones,
    auditEvents,
    localSyncPositions,
  ];
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
