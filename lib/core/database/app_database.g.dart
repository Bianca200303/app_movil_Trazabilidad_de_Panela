// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProducersTable extends Producers
    with TableInfo<$ProducersTable, Producer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProducersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _dniMeta = const VerificationMeta('dni');
  @override
  late final GeneratedColumn<String> dni = GeneratedColumn<String>(
    'dni',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coopModuleIdMeta = const VerificationMeta(
    'coopModuleId',
  );
  @override
  late final GeneratedColumn<String> coopModuleId = GeneratedColumn<String>(
    'coop_module_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cooperativeIdMeta = const VerificationMeta(
    'cooperativeId',
  );
  @override
  late final GeneratedColumn<String> cooperativeId = GeneratedColumn<String>(
    'cooperative_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isMemberMeta = const VerificationMeta(
    'isMember',
  );
  @override
  late final GeneratedColumn<bool> isMember = GeneratedColumn<bool>(
    'is_member',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_member" IN (0, 1))',
    ),
  );
  static const VerificationMeta _appagropCodeMeta = const VerificationMeta(
    'appagropCode',
  );
  @override
  late final GeneratedColumn<String> appagropCode = GeneratedColumn<String>(
    'appagrop_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firstName,
    lastName,
    dni,
    coopModuleId,
    cooperativeId,
    isMember,
    appagropCode,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'producers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Producer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('dni')) {
      context.handle(
        _dniMeta,
        dni.isAcceptableOrUnknown(data['dni']!, _dniMeta),
      );
    } else if (isInserting) {
      context.missing(_dniMeta);
    }
    if (data.containsKey('coop_module_id')) {
      context.handle(
        _coopModuleIdMeta,
        coopModuleId.isAcceptableOrUnknown(
          data['coop_module_id']!,
          _coopModuleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coopModuleIdMeta);
    }
    if (data.containsKey('cooperative_id')) {
      context.handle(
        _cooperativeIdMeta,
        cooperativeId.isAcceptableOrUnknown(
          data['cooperative_id']!,
          _cooperativeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cooperativeIdMeta);
    }
    if (data.containsKey('is_member')) {
      context.handle(
        _isMemberMeta,
        isMember.isAcceptableOrUnknown(data['is_member']!, _isMemberMeta),
      );
    } else if (isInserting) {
      context.missing(_isMemberMeta);
    }
    if (data.containsKey('appagrop_code')) {
      context.handle(
        _appagropCodeMeta,
        appagropCode.isAcceptableOrUnknown(
          data['appagrop_code']!,
          _appagropCodeMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Producer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Producer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      dni: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dni'],
      )!,
      coopModuleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coop_module_id'],
      )!,
      cooperativeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cooperative_id'],
      )!,
      isMember: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_member'],
      )!,
      appagropCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appagrop_code'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $ProducersTable createAlias(String alias) {
    return $ProducersTable(attachedDatabase, alias);
  }
}

class Producer extends DataClass implements Insertable<Producer> {
  /// Local auto-increment ID
  final int id;
  final String firstName;
  final String lastName;
  final String dni;
  final String coopModuleId;
  final String cooperativeId;
  final bool isMember;
  final String? appagropCode;

  /// Sync status: 0=pending, 1=synced, 2=modified
  final int syncStatus;

  /// Remote UUID from Supabase (null if not synced yet)
  final String? remoteId;

  /// Created at timestamp (local)
  final DateTime createdAt;

  /// Last synced at timestamp (null if never synced)
  final DateTime? syncedAt;
  const Producer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.coopModuleId,
    required this.cooperativeId,
    required this.isMember,
    this.appagropCode,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['dni'] = Variable<String>(dni);
    map['coop_module_id'] = Variable<String>(coopModuleId);
    map['cooperative_id'] = Variable<String>(cooperativeId);
    map['is_member'] = Variable<bool>(isMember);
    if (!nullToAbsent || appagropCode != null) {
      map['appagrop_code'] = Variable<String>(appagropCode);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  ProducersCompanion toCompanion(bool nullToAbsent) {
    return ProducersCompanion(
      id: Value(id),
      firstName: Value(firstName),
      lastName: Value(lastName),
      dni: Value(dni),
      coopModuleId: Value(coopModuleId),
      cooperativeId: Value(cooperativeId),
      isMember: Value(isMember),
      appagropCode: appagropCode == null && nullToAbsent
          ? const Value.absent()
          : Value(appagropCode),
      syncStatus: Value(syncStatus),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory Producer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Producer(
      id: serializer.fromJson<int>(json['id']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      dni: serializer.fromJson<String>(json['dni']),
      coopModuleId: serializer.fromJson<String>(json['coopModuleId']),
      cooperativeId: serializer.fromJson<String>(json['cooperativeId']),
      isMember: serializer.fromJson<bool>(json['isMember']),
      appagropCode: serializer.fromJson<String?>(json['appagropCode']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'dni': serializer.toJson<String>(dni),
      'coopModuleId': serializer.toJson<String>(coopModuleId),
      'cooperativeId': serializer.toJson<String>(cooperativeId),
      'isMember': serializer.toJson<bool>(isMember),
      'appagropCode': serializer.toJson<String?>(appagropCode),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  Producer copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? dni,
    String? coopModuleId,
    String? cooperativeId,
    bool? isMember,
    Value<String?> appagropCode = const Value.absent(),
    int? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => Producer(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    dni: dni ?? this.dni,
    coopModuleId: coopModuleId ?? this.coopModuleId,
    cooperativeId: cooperativeId ?? this.cooperativeId,
    isMember: isMember ?? this.isMember,
    appagropCode: appagropCode.present ? appagropCode.value : this.appagropCode,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  Producer copyWithCompanion(ProducersCompanion data) {
    return Producer(
      id: data.id.present ? data.id.value : this.id,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      dni: data.dni.present ? data.dni.value : this.dni,
      coopModuleId: data.coopModuleId.present
          ? data.coopModuleId.value
          : this.coopModuleId,
      cooperativeId: data.cooperativeId.present
          ? data.cooperativeId.value
          : this.cooperativeId,
      isMember: data.isMember.present ? data.isMember.value : this.isMember,
      appagropCode: data.appagropCode.present
          ? data.appagropCode.value
          : this.appagropCode,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Producer(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('dni: $dni, ')
          ..write('coopModuleId: $coopModuleId, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('isMember: $isMember, ')
          ..write('appagropCode: $appagropCode, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firstName,
    lastName,
    dni,
    coopModuleId,
    cooperativeId,
    isMember,
    appagropCode,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Producer &&
          other.id == this.id &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.dni == this.dni &&
          other.coopModuleId == this.coopModuleId &&
          other.cooperativeId == this.cooperativeId &&
          other.isMember == this.isMember &&
          other.appagropCode == this.appagropCode &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class ProducersCompanion extends UpdateCompanion<Producer> {
  final Value<int> id;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> dni;
  final Value<String> coopModuleId;
  final Value<String> cooperativeId;
  final Value<bool> isMember;
  final Value<String?> appagropCode;
  final Value<int> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const ProducersCompanion({
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.dni = const Value.absent(),
    this.coopModuleId = const Value.absent(),
    this.cooperativeId = const Value.absent(),
    this.isMember = const Value.absent(),
    this.appagropCode = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  ProducersCompanion.insert({
    this.id = const Value.absent(),
    required String firstName,
    required String lastName,
    required String dni,
    required String coopModuleId,
    required String cooperativeId,
    required bool isMember,
    this.appagropCode = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : firstName = Value(firstName),
       lastName = Value(lastName),
       dni = Value(dni),
       coopModuleId = Value(coopModuleId),
       cooperativeId = Value(cooperativeId),
       isMember = Value(isMember);
  static Insertable<Producer> custom({
    Expression<int>? id,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? dni,
    Expression<String>? coopModuleId,
    Expression<String>? cooperativeId,
    Expression<bool>? isMember,
    Expression<String>? appagropCode,
    Expression<int>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (dni != null) 'dni': dni,
      if (coopModuleId != null) 'coop_module_id': coopModuleId,
      if (cooperativeId != null) 'cooperative_id': cooperativeId,
      if (isMember != null) 'is_member': isMember,
      if (appagropCode != null) 'appagrop_code': appagropCode,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  ProducersCompanion copyWith({
    Value<int>? id,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String>? dni,
    Value<String>? coopModuleId,
    Value<String>? cooperativeId,
    Value<bool>? isMember,
    Value<String?>? appagropCode,
    Value<int>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return ProducersCompanion(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dni: dni ?? this.dni,
      coopModuleId: coopModuleId ?? this.coopModuleId,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      isMember: isMember ?? this.isMember,
      appagropCode: appagropCode ?? this.appagropCode,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (dni.present) {
      map['dni'] = Variable<String>(dni.value);
    }
    if (coopModuleId.present) {
      map['coop_module_id'] = Variable<String>(coopModuleId.value);
    }
    if (cooperativeId.present) {
      map['cooperative_id'] = Variable<String>(cooperativeId.value);
    }
    if (isMember.present) {
      map['is_member'] = Variable<bool>(isMember.value);
    }
    if (appagropCode.present) {
      map['appagrop_code'] = Variable<String>(appagropCode.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProducersCompanion(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('dni: $dni, ')
          ..write('coopModuleId: $coopModuleId, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('isMember: $isMember, ')
          ..write('appagropCode: $appagropCode, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $PlotsTable extends Plots with TableInfo<$PlotsTable, Plot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _producerLocalIdMeta = const VerificationMeta(
    'producerLocalId',
  );
  @override
  late final GeneratedColumn<int> producerLocalId = GeneratedColumn<int>(
    'producer_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteProducerIdMeta = const VerificationMeta(
    'remoteProducerId',
  );
  @override
  late final GeneratedColumn<String> remoteProducerId = GeneratedColumn<String>(
    'remote_producer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    code,
    producerLocalId,
    syncStatus,
    remoteId,
    remoteProducerId,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plots';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('producer_local_id')) {
      context.handle(
        _producerLocalIdMeta,
        producerLocalId.isAcceptableOrUnknown(
          data['producer_local_id']!,
          _producerLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_producerLocalIdMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('remote_producer_id')) {
      context.handle(
        _remoteProducerIdMeta,
        remoteProducerId.isAcceptableOrUnknown(
          data['remote_producer_id']!,
          _remoteProducerIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      producerLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}producer_local_id'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      remoteProducerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_producer_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $PlotsTable createAlias(String alias) {
    return $PlotsTable(attachedDatabase, alias);
  }
}

class Plot extends DataClass implements Insertable<Plot> {
  /// Local auto-increment ID
  final int id;
  final String name;
  final String code;

  /// Foreign key to local producers table
  final int producerLocalId;

  /// Sync status: 0=pending, 1=synced, 2=modified
  final int syncStatus;

  /// Remote UUID from Supabase (null if not synced yet)
  final String? remoteId;

  /// Remote producer UUID from Supabase
  final String? remoteProducerId;

  /// Created at timestamp (local)
  final DateTime createdAt;

  /// Last synced at timestamp (null if never synced)
  final DateTime? syncedAt;
  const Plot({
    required this.id,
    required this.name,
    required this.code,
    required this.producerLocalId,
    required this.syncStatus,
    this.remoteId,
    this.remoteProducerId,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['producer_local_id'] = Variable<int>(producerLocalId);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || remoteProducerId != null) {
      map['remote_producer_id'] = Variable<String>(remoteProducerId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  PlotsCompanion toCompanion(bool nullToAbsent) {
    return PlotsCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
      producerLocalId: Value(producerLocalId),
      syncStatus: Value(syncStatus),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      remoteProducerId: remoteProducerId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteProducerId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory Plot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plot(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      producerLocalId: serializer.fromJson<int>(json['producerLocalId']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      remoteProducerId: serializer.fromJson<String?>(json['remoteProducerId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'producerLocalId': serializer.toJson<int>(producerLocalId),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'remoteProducerId': serializer.toJson<String?>(remoteProducerId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  Plot copyWith({
    int? id,
    String? name,
    String? code,
    int? producerLocalId,
    int? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    Value<String?> remoteProducerId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => Plot(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    producerLocalId: producerLocalId ?? this.producerLocalId,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    remoteProducerId: remoteProducerId.present
        ? remoteProducerId.value
        : this.remoteProducerId,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  Plot copyWithCompanion(PlotsCompanion data) {
    return Plot(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      producerLocalId: data.producerLocalId.present
          ? data.producerLocalId.value
          : this.producerLocalId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      remoteProducerId: data.remoteProducerId.present
          ? data.remoteProducerId.value
          : this.remoteProducerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plot(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('producerLocalId: $producerLocalId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteProducerId: $remoteProducerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    code,
    producerLocalId,
    syncStatus,
    remoteId,
    remoteProducerId,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plot &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code &&
          other.producerLocalId == this.producerLocalId &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.remoteProducerId == this.remoteProducerId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class PlotsCompanion extends UpdateCompanion<Plot> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> code;
  final Value<int> producerLocalId;
  final Value<int> syncStatus;
  final Value<String?> remoteId;
  final Value<String?> remoteProducerId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const PlotsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.producerLocalId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteProducerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  PlotsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String code,
    required int producerLocalId,
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteProducerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : name = Value(name),
       code = Value(code),
       producerLocalId = Value(producerLocalId);
  static Insertable<Plot> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<int>? producerLocalId,
    Expression<int>? syncStatus,
    Expression<String>? remoteId,
    Expression<String>? remoteProducerId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (producerLocalId != null) 'producer_local_id': producerLocalId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (remoteProducerId != null) 'remote_producer_id': remoteProducerId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  PlotsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? code,
    Value<int>? producerLocalId,
    Value<int>? syncStatus,
    Value<String?>? remoteId,
    Value<String?>? remoteProducerId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return PlotsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      producerLocalId: producerLocalId ?? this.producerLocalId,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      remoteProducerId: remoteProducerId ?? this.remoteProducerId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (producerLocalId.present) {
      map['producer_local_id'] = Variable<int>(producerLocalId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (remoteProducerId.present) {
      map['remote_producer_id'] = Variable<String>(remoteProducerId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlotsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('producerLocalId: $producerLocalId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteProducerId: $remoteProducerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $CoopModulesTable extends CoopModules
    with TableInfo<$CoopModulesTable, CoopModuleLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoopModulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coop_modules';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoopModuleLocal> instance, {
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
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
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
  CoopModuleLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoopModuleLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CoopModulesTable createAlias(String alias) {
    return $CoopModulesTable(attachedDatabase, alias);
  }
}

class CoopModuleLocal extends DataClass implements Insertable<CoopModuleLocal> {
  /// Module ID (UUID from Supabase)
  final String id;

  /// Module name
  final String name;

  /// Whether the module is active
  final bool isActive;

  /// When this record was created locally
  final DateTime createdAt;

  /// When this record was last updated
  final DateTime updatedAt;
  const CoopModuleLocal({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CoopModulesCompanion toCompanion(bool nullToAbsent) {
    return CoopModulesCompanion(
      id: Value(id),
      name: Value(name),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CoopModuleLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoopModuleLocal(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CoopModuleLocal copyWith({
    String? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CoopModuleLocal(
    id: id ?? this.id,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CoopModuleLocal copyWithCompanion(CoopModulesCompanion data) {
    return CoopModuleLocal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoopModuleLocal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoopModuleLocal &&
          other.id == this.id &&
          other.name == this.name &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CoopModulesCompanion extends UpdateCompanion<CoopModuleLocal> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CoopModulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoopModulesCompanion.insert({
    required String id,
    required String name,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<CoopModuleLocal> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoopModulesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CoopModulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoopModulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductionBatchesTable extends ProductionBatches
    with TableInfo<$ProductionBatchesTable, ProductionBatchLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductionBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _batchCodeMeta = const VerificationMeta(
    'batchCode',
  );
  @override
  late final GeneratedColumn<String> batchCode = GeneratedColumn<String>(
    'batch_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _harvestDateMeta = const VerificationMeta(
    'harvestDate',
  );
  @override
  late final GeneratedColumn<DateTime> harvestDate = GeneratedColumn<DateTime>(
    'harvest_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processDateMeta = const VerificationMeta(
    'processDate',
  );
  @override
  late final GeneratedColumn<DateTime> processDate = GeneratedColumn<DateTime>(
    'process_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caneKgMeta = const VerificationMeta('caneKg');
  @override
  late final GeneratedColumn<double> caneKg = GeneratedColumn<double>(
    'cane_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _juiceLitersMeta = const VerificationMeta(
    'juiceLiters',
  );
  @override
  late final GeneratedColumn<double> juiceLiters = GeneratedColumn<double>(
    'juice_liters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _panelaKgMeta = const VerificationMeta(
    'panelaKg',
  );
  @override
  late final GeneratedColumn<double> panelaKg = GeneratedColumn<double>(
    'panela_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confitilloKgMeta = const VerificationMeta(
    'confitilloKg',
  );
  @override
  late final GeneratedColumn<double> confitilloKg = GeneratedColumn<double>(
    'confitillo_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _porcentajeExtraccionMeta =
      const VerificationMeta('porcentajeExtraccion');
  @override
  late final GeneratedColumn<double> porcentajeExtraccion =
      GeneratedColumn<double>(
        'porcentaje_extraccion',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cachazaPercentageMeta = const VerificationMeta(
    'cachazaPercentage',
  );
  @override
  late final GeneratedColumn<double> cachazaPercentage =
      GeneratedColumn<double>(
        'cachaza_percentage',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _efficiencyPercentageMeta =
      const VerificationMeta('efficiencyPercentage');
  @override
  late final GeneratedColumn<double> efficiencyPercentage =
      GeneratedColumn<double>(
        'efficiency_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _caneDensityMeta = const VerificationMeta(
    'caneDensity',
  );
  @override
  late final GeneratedColumn<double> caneDensity = GeneratedColumn<double>(
    'cane_density',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.05),
  );
  static const VerificationMeta _producerLocalIdMeta = const VerificationMeta(
    'producerLocalId',
  );
  @override
  late final GeneratedColumn<int> producerLocalId = GeneratedColumn<int>(
    'producer_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotLocalIdMeta = const VerificationMeta(
    'plotLocalId',
  );
  @override
  late final GeneratedColumn<int> plotLocalId = GeneratedColumn<int>(
    'plot_local_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cooperativeIdMeta = const VerificationMeta(
    'cooperativeId',
  );
  @override
  late final GeneratedColumn<String> cooperativeId = GeneratedColumn<String>(
    'cooperative_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationTextMeta = const VerificationMeta(
    'locationText',
  );
  @override
  late final GeneratedColumn<String> locationText = GeneratedColumn<String>(
    'location_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observationsMeta = const VerificationMeta(
    'observations',
  );
  @override
  late final GeneratedColumn<String> observations = GeneratedColumn<String>(
    'observations',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    batchCode,
    harvestDate,
    processDate,
    caneKg,
    juiceLiters,
    panelaKg,
    confitilloKg,
    porcentajeExtraccion,
    cachazaPercentage,
    efficiencyPercentage,
    caneDensity,
    producerLocalId,
    plotLocalId,
    cooperativeId,
    latitude,
    longitude,
    locationText,
    observations,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'production_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductionBatchLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('batch_code')) {
      context.handle(
        _batchCodeMeta,
        batchCode.isAcceptableOrUnknown(data['batch_code']!, _batchCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_batchCodeMeta);
    }
    if (data.containsKey('harvest_date')) {
      context.handle(
        _harvestDateMeta,
        harvestDate.isAcceptableOrUnknown(
          data['harvest_date']!,
          _harvestDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_harvestDateMeta);
    }
    if (data.containsKey('process_date')) {
      context.handle(
        _processDateMeta,
        processDate.isAcceptableOrUnknown(
          data['process_date']!,
          _processDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processDateMeta);
    }
    if (data.containsKey('cane_kg')) {
      context.handle(
        _caneKgMeta,
        caneKg.isAcceptableOrUnknown(data['cane_kg']!, _caneKgMeta),
      );
    } else if (isInserting) {
      context.missing(_caneKgMeta);
    }
    if (data.containsKey('juice_liters')) {
      context.handle(
        _juiceLitersMeta,
        juiceLiters.isAcceptableOrUnknown(
          data['juice_liters']!,
          _juiceLitersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_juiceLitersMeta);
    }
    if (data.containsKey('panela_kg')) {
      context.handle(
        _panelaKgMeta,
        panelaKg.isAcceptableOrUnknown(data['panela_kg']!, _panelaKgMeta),
      );
    } else if (isInserting) {
      context.missing(_panelaKgMeta);
    }
    if (data.containsKey('confitillo_kg')) {
      context.handle(
        _confitilloKgMeta,
        confitilloKg.isAcceptableOrUnknown(
          data['confitillo_kg']!,
          _confitilloKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confitilloKgMeta);
    }
    if (data.containsKey('porcentaje_extraccion')) {
      context.handle(
        _porcentajeExtraccionMeta,
        porcentajeExtraccion.isAcceptableOrUnknown(
          data['porcentaje_extraccion']!,
          _porcentajeExtraccionMeta,
        ),
      );
    }
    if (data.containsKey('cachaza_percentage')) {
      context.handle(
        _cachazaPercentageMeta,
        cachazaPercentage.isAcceptableOrUnknown(
          data['cachaza_percentage']!,
          _cachazaPercentageMeta,
        ),
      );
    }
    if (data.containsKey('efficiency_percentage')) {
      context.handle(
        _efficiencyPercentageMeta,
        efficiencyPercentage.isAcceptableOrUnknown(
          data['efficiency_percentage']!,
          _efficiencyPercentageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_efficiencyPercentageMeta);
    }
    if (data.containsKey('cane_density')) {
      context.handle(
        _caneDensityMeta,
        caneDensity.isAcceptableOrUnknown(
          data['cane_density']!,
          _caneDensityMeta,
        ),
      );
    }
    if (data.containsKey('producer_local_id')) {
      context.handle(
        _producerLocalIdMeta,
        producerLocalId.isAcceptableOrUnknown(
          data['producer_local_id']!,
          _producerLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_producerLocalIdMeta);
    }
    if (data.containsKey('plot_local_id')) {
      context.handle(
        _plotLocalIdMeta,
        plotLocalId.isAcceptableOrUnknown(
          data['plot_local_id']!,
          _plotLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('cooperative_id')) {
      context.handle(
        _cooperativeIdMeta,
        cooperativeId.isAcceptableOrUnknown(
          data['cooperative_id']!,
          _cooperativeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cooperativeIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('location_text')) {
      context.handle(
        _locationTextMeta,
        locationText.isAcceptableOrUnknown(
          data['location_text']!,
          _locationTextMeta,
        ),
      );
    }
    if (data.containsKey('observations')) {
      context.handle(
        _observationsMeta,
        observations.isAcceptableOrUnknown(
          data['observations']!,
          _observationsMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductionBatchLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductionBatchLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      batchCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_code'],
      )!,
      harvestDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}harvest_date'],
      )!,
      processDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}process_date'],
      )!,
      caneKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cane_kg'],
      )!,
      juiceLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}juice_liters'],
      )!,
      panelaKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}panela_kg'],
      )!,
      confitilloKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confitillo_kg'],
      )!,
      porcentajeExtraccion: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}porcentaje_extraccion'],
      ),
      cachazaPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cachaza_percentage'],
      ),
      efficiencyPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}efficiency_percentage'],
      )!,
      caneDensity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cane_density'],
      )!,
      producerLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}producer_local_id'],
      )!,
      plotLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plot_local_id'],
      ),
      cooperativeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cooperative_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      locationText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_text'],
      ),
      observations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observations'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $ProductionBatchesTable createAlias(String alias) {
    return $ProductionBatchesTable(attachedDatabase, alias);
  }
}

class ProductionBatchLocal extends DataClass
    implements Insertable<ProductionBatchLocal> {
  /// Local auto-increment ID
  final int id;
  final String batchCode;
  final DateTime harvestDate;
  final DateTime processDate;
  final double caneKg;
  final double juiceLiters;
  final double panelaKg;
  final double confitilloKg;
  final double? porcentajeExtraccion;
  final double? cachazaPercentage;
  final double efficiencyPercentage;
  final double caneDensity;
  final int producerLocalId;
  final int? plotLocalId;
  final String cooperativeId;
  final double? latitude;
  final double? longitude;
  final String? locationText;
  final String? observations;

  /// Sync status: 0=pending, 1=synced, 2=modified
  final int syncStatus;

  /// Remote UUID from Supabase (null if not synced yet)
  final String? remoteId;

  /// Created at timestamp (local)
  final DateTime createdAt;

  /// Last synced at timestamp (null if never synced)
  final DateTime? syncedAt;
  const ProductionBatchLocal({
    required this.id,
    required this.batchCode,
    required this.harvestDate,
    required this.processDate,
    required this.caneKg,
    required this.juiceLiters,
    required this.panelaKg,
    required this.confitilloKg,
    this.porcentajeExtraccion,
    this.cachazaPercentage,
    required this.efficiencyPercentage,
    required this.caneDensity,
    required this.producerLocalId,
    this.plotLocalId,
    required this.cooperativeId,
    this.latitude,
    this.longitude,
    this.locationText,
    this.observations,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['batch_code'] = Variable<String>(batchCode);
    map['harvest_date'] = Variable<DateTime>(harvestDate);
    map['process_date'] = Variable<DateTime>(processDate);
    map['cane_kg'] = Variable<double>(caneKg);
    map['juice_liters'] = Variable<double>(juiceLiters);
    map['panela_kg'] = Variable<double>(panelaKg);
    map['confitillo_kg'] = Variable<double>(confitilloKg);
    if (!nullToAbsent || porcentajeExtraccion != null) {
      map['porcentaje_extraccion'] = Variable<double>(porcentajeExtraccion);
    }
    if (!nullToAbsent || cachazaPercentage != null) {
      map['cachaza_percentage'] = Variable<double>(cachazaPercentage);
    }
    map['efficiency_percentage'] = Variable<double>(efficiencyPercentage);
    map['cane_density'] = Variable<double>(caneDensity);
    map['producer_local_id'] = Variable<int>(producerLocalId);
    if (!nullToAbsent || plotLocalId != null) {
      map['plot_local_id'] = Variable<int>(plotLocalId);
    }
    map['cooperative_id'] = Variable<String>(cooperativeId);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || locationText != null) {
      map['location_text'] = Variable<String>(locationText);
    }
    if (!nullToAbsent || observations != null) {
      map['observations'] = Variable<String>(observations);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  ProductionBatchesCompanion toCompanion(bool nullToAbsent) {
    return ProductionBatchesCompanion(
      id: Value(id),
      batchCode: Value(batchCode),
      harvestDate: Value(harvestDate),
      processDate: Value(processDate),
      caneKg: Value(caneKg),
      juiceLiters: Value(juiceLiters),
      panelaKg: Value(panelaKg),
      confitilloKg: Value(confitilloKg),
      porcentajeExtraccion: porcentajeExtraccion == null && nullToAbsent
          ? const Value.absent()
          : Value(porcentajeExtraccion),
      cachazaPercentage: cachazaPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(cachazaPercentage),
      efficiencyPercentage: Value(efficiencyPercentage),
      caneDensity: Value(caneDensity),
      producerLocalId: Value(producerLocalId),
      plotLocalId: plotLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(plotLocalId),
      cooperativeId: Value(cooperativeId),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      locationText: locationText == null && nullToAbsent
          ? const Value.absent()
          : Value(locationText),
      observations: observations == null && nullToAbsent
          ? const Value.absent()
          : Value(observations),
      syncStatus: Value(syncStatus),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory ProductionBatchLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductionBatchLocal(
      id: serializer.fromJson<int>(json['id']),
      batchCode: serializer.fromJson<String>(json['batchCode']),
      harvestDate: serializer.fromJson<DateTime>(json['harvestDate']),
      processDate: serializer.fromJson<DateTime>(json['processDate']),
      caneKg: serializer.fromJson<double>(json['caneKg']),
      juiceLiters: serializer.fromJson<double>(json['juiceLiters']),
      panelaKg: serializer.fromJson<double>(json['panelaKg']),
      confitilloKg: serializer.fromJson<double>(json['confitilloKg']),
      porcentajeExtraccion: serializer.fromJson<double?>(
        json['porcentajeExtraccion'],
      ),
      cachazaPercentage: serializer.fromJson<double?>(
        json['cachazaPercentage'],
      ),
      efficiencyPercentage: serializer.fromJson<double>(
        json['efficiencyPercentage'],
      ),
      caneDensity: serializer.fromJson<double>(json['caneDensity']),
      producerLocalId: serializer.fromJson<int>(json['producerLocalId']),
      plotLocalId: serializer.fromJson<int?>(json['plotLocalId']),
      cooperativeId: serializer.fromJson<String>(json['cooperativeId']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      locationText: serializer.fromJson<String?>(json['locationText']),
      observations: serializer.fromJson<String?>(json['observations']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'batchCode': serializer.toJson<String>(batchCode),
      'harvestDate': serializer.toJson<DateTime>(harvestDate),
      'processDate': serializer.toJson<DateTime>(processDate),
      'caneKg': serializer.toJson<double>(caneKg),
      'juiceLiters': serializer.toJson<double>(juiceLiters),
      'panelaKg': serializer.toJson<double>(panelaKg),
      'confitilloKg': serializer.toJson<double>(confitilloKg),
      'porcentajeExtraccion': serializer.toJson<double?>(porcentajeExtraccion),
      'cachazaPercentage': serializer.toJson<double?>(cachazaPercentage),
      'efficiencyPercentage': serializer.toJson<double>(efficiencyPercentage),
      'caneDensity': serializer.toJson<double>(caneDensity),
      'producerLocalId': serializer.toJson<int>(producerLocalId),
      'plotLocalId': serializer.toJson<int?>(plotLocalId),
      'cooperativeId': serializer.toJson<String>(cooperativeId),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'locationText': serializer.toJson<String?>(locationText),
      'observations': serializer.toJson<String?>(observations),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  ProductionBatchLocal copyWith({
    int? id,
    String? batchCode,
    DateTime? harvestDate,
    DateTime? processDate,
    double? caneKg,
    double? juiceLiters,
    double? panelaKg,
    double? confitilloKg,
    Value<double?> porcentajeExtraccion = const Value.absent(),
    Value<double?> cachazaPercentage = const Value.absent(),
    double? efficiencyPercentage,
    double? caneDensity,
    int? producerLocalId,
    Value<int?> plotLocalId = const Value.absent(),
    String? cooperativeId,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> locationText = const Value.absent(),
    Value<String?> observations = const Value.absent(),
    int? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => ProductionBatchLocal(
    id: id ?? this.id,
    batchCode: batchCode ?? this.batchCode,
    harvestDate: harvestDate ?? this.harvestDate,
    processDate: processDate ?? this.processDate,
    caneKg: caneKg ?? this.caneKg,
    juiceLiters: juiceLiters ?? this.juiceLiters,
    panelaKg: panelaKg ?? this.panelaKg,
    confitilloKg: confitilloKg ?? this.confitilloKg,
    porcentajeExtraccion: porcentajeExtraccion.present
        ? porcentajeExtraccion.value
        : this.porcentajeExtraccion,
    cachazaPercentage: cachazaPercentage.present
        ? cachazaPercentage.value
        : this.cachazaPercentage,
    efficiencyPercentage: efficiencyPercentage ?? this.efficiencyPercentage,
    caneDensity: caneDensity ?? this.caneDensity,
    producerLocalId: producerLocalId ?? this.producerLocalId,
    plotLocalId: plotLocalId.present ? plotLocalId.value : this.plotLocalId,
    cooperativeId: cooperativeId ?? this.cooperativeId,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    locationText: locationText.present ? locationText.value : this.locationText,
    observations: observations.present ? observations.value : this.observations,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  ProductionBatchLocal copyWithCompanion(ProductionBatchesCompanion data) {
    return ProductionBatchLocal(
      id: data.id.present ? data.id.value : this.id,
      batchCode: data.batchCode.present ? data.batchCode.value : this.batchCode,
      harvestDate: data.harvestDate.present
          ? data.harvestDate.value
          : this.harvestDate,
      processDate: data.processDate.present
          ? data.processDate.value
          : this.processDate,
      caneKg: data.caneKg.present ? data.caneKg.value : this.caneKg,
      juiceLiters: data.juiceLiters.present
          ? data.juiceLiters.value
          : this.juiceLiters,
      panelaKg: data.panelaKg.present ? data.panelaKg.value : this.panelaKg,
      confitilloKg: data.confitilloKg.present
          ? data.confitilloKg.value
          : this.confitilloKg,
      porcentajeExtraccion: data.porcentajeExtraccion.present
          ? data.porcentajeExtraccion.value
          : this.porcentajeExtraccion,
      cachazaPercentage: data.cachazaPercentage.present
          ? data.cachazaPercentage.value
          : this.cachazaPercentage,
      efficiencyPercentage: data.efficiencyPercentage.present
          ? data.efficiencyPercentage.value
          : this.efficiencyPercentage,
      caneDensity: data.caneDensity.present
          ? data.caneDensity.value
          : this.caneDensity,
      producerLocalId: data.producerLocalId.present
          ? data.producerLocalId.value
          : this.producerLocalId,
      plotLocalId: data.plotLocalId.present
          ? data.plotLocalId.value
          : this.plotLocalId,
      cooperativeId: data.cooperativeId.present
          ? data.cooperativeId.value
          : this.cooperativeId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      locationText: data.locationText.present
          ? data.locationText.value
          : this.locationText,
      observations: data.observations.present
          ? data.observations.value
          : this.observations,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatchLocal(')
          ..write('id: $id, ')
          ..write('batchCode: $batchCode, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('processDate: $processDate, ')
          ..write('caneKg: $caneKg, ')
          ..write('juiceLiters: $juiceLiters, ')
          ..write('panelaKg: $panelaKg, ')
          ..write('confitilloKg: $confitilloKg, ')
          ..write('porcentajeExtraccion: $porcentajeExtraccion, ')
          ..write('cachazaPercentage: $cachazaPercentage, ')
          ..write('efficiencyPercentage: $efficiencyPercentage, ')
          ..write('caneDensity: $caneDensity, ')
          ..write('producerLocalId: $producerLocalId, ')
          ..write('plotLocalId: $plotLocalId, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('locationText: $locationText, ')
          ..write('observations: $observations, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    batchCode,
    harvestDate,
    processDate,
    caneKg,
    juiceLiters,
    panelaKg,
    confitilloKg,
    porcentajeExtraccion,
    cachazaPercentage,
    efficiencyPercentage,
    caneDensity,
    producerLocalId,
    plotLocalId,
    cooperativeId,
    latitude,
    longitude,
    locationText,
    observations,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductionBatchLocal &&
          other.id == this.id &&
          other.batchCode == this.batchCode &&
          other.harvestDate == this.harvestDate &&
          other.processDate == this.processDate &&
          other.caneKg == this.caneKg &&
          other.juiceLiters == this.juiceLiters &&
          other.panelaKg == this.panelaKg &&
          other.confitilloKg == this.confitilloKg &&
          other.porcentajeExtraccion == this.porcentajeExtraccion &&
          other.cachazaPercentage == this.cachazaPercentage &&
          other.efficiencyPercentage == this.efficiencyPercentage &&
          other.caneDensity == this.caneDensity &&
          other.producerLocalId == this.producerLocalId &&
          other.plotLocalId == this.plotLocalId &&
          other.cooperativeId == this.cooperativeId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.locationText == this.locationText &&
          other.observations == this.observations &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class ProductionBatchesCompanion extends UpdateCompanion<ProductionBatchLocal> {
  final Value<int> id;
  final Value<String> batchCode;
  final Value<DateTime> harvestDate;
  final Value<DateTime> processDate;
  final Value<double> caneKg;
  final Value<double> juiceLiters;
  final Value<double> panelaKg;
  final Value<double> confitilloKg;
  final Value<double?> porcentajeExtraccion;
  final Value<double?> cachazaPercentage;
  final Value<double> efficiencyPercentage;
  final Value<double> caneDensity;
  final Value<int> producerLocalId;
  final Value<int?> plotLocalId;
  final Value<String> cooperativeId;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> locationText;
  final Value<String?> observations;
  final Value<int> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const ProductionBatchesCompanion({
    this.id = const Value.absent(),
    this.batchCode = const Value.absent(),
    this.harvestDate = const Value.absent(),
    this.processDate = const Value.absent(),
    this.caneKg = const Value.absent(),
    this.juiceLiters = const Value.absent(),
    this.panelaKg = const Value.absent(),
    this.confitilloKg = const Value.absent(),
    this.porcentajeExtraccion = const Value.absent(),
    this.cachazaPercentage = const Value.absent(),
    this.efficiencyPercentage = const Value.absent(),
    this.caneDensity = const Value.absent(),
    this.producerLocalId = const Value.absent(),
    this.plotLocalId = const Value.absent(),
    this.cooperativeId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.locationText = const Value.absent(),
    this.observations = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  ProductionBatchesCompanion.insert({
    this.id = const Value.absent(),
    required String batchCode,
    required DateTime harvestDate,
    required DateTime processDate,
    required double caneKg,
    required double juiceLiters,
    required double panelaKg,
    required double confitilloKg,
    this.porcentajeExtraccion = const Value.absent(),
    this.cachazaPercentage = const Value.absent(),
    required double efficiencyPercentage,
    this.caneDensity = const Value.absent(),
    required int producerLocalId,
    this.plotLocalId = const Value.absent(),
    required String cooperativeId,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.locationText = const Value.absent(),
    this.observations = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : batchCode = Value(batchCode),
       harvestDate = Value(harvestDate),
       processDate = Value(processDate),
       caneKg = Value(caneKg),
       juiceLiters = Value(juiceLiters),
       panelaKg = Value(panelaKg),
       confitilloKg = Value(confitilloKg),
       efficiencyPercentage = Value(efficiencyPercentage),
       producerLocalId = Value(producerLocalId),
       cooperativeId = Value(cooperativeId);
  static Insertable<ProductionBatchLocal> custom({
    Expression<int>? id,
    Expression<String>? batchCode,
    Expression<DateTime>? harvestDate,
    Expression<DateTime>? processDate,
    Expression<double>? caneKg,
    Expression<double>? juiceLiters,
    Expression<double>? panelaKg,
    Expression<double>? confitilloKg,
    Expression<double>? porcentajeExtraccion,
    Expression<double>? cachazaPercentage,
    Expression<double>? efficiencyPercentage,
    Expression<double>? caneDensity,
    Expression<int>? producerLocalId,
    Expression<int>? plotLocalId,
    Expression<String>? cooperativeId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? locationText,
    Expression<String>? observations,
    Expression<int>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (batchCode != null) 'batch_code': batchCode,
      if (harvestDate != null) 'harvest_date': harvestDate,
      if (processDate != null) 'process_date': processDate,
      if (caneKg != null) 'cane_kg': caneKg,
      if (juiceLiters != null) 'juice_liters': juiceLiters,
      if (panelaKg != null) 'panela_kg': panelaKg,
      if (confitilloKg != null) 'confitillo_kg': confitilloKg,
      if (porcentajeExtraccion != null)
        'porcentaje_extraccion': porcentajeExtraccion,
      if (cachazaPercentage != null) 'cachaza_percentage': cachazaPercentage,
      if (efficiencyPercentage != null)
        'efficiency_percentage': efficiencyPercentage,
      if (caneDensity != null) 'cane_density': caneDensity,
      if (producerLocalId != null) 'producer_local_id': producerLocalId,
      if (plotLocalId != null) 'plot_local_id': plotLocalId,
      if (cooperativeId != null) 'cooperative_id': cooperativeId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationText != null) 'location_text': locationText,
      if (observations != null) 'observations': observations,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  ProductionBatchesCompanion copyWith({
    Value<int>? id,
    Value<String>? batchCode,
    Value<DateTime>? harvestDate,
    Value<DateTime>? processDate,
    Value<double>? caneKg,
    Value<double>? juiceLiters,
    Value<double>? panelaKg,
    Value<double>? confitilloKg,
    Value<double?>? porcentajeExtraccion,
    Value<double?>? cachazaPercentage,
    Value<double>? efficiencyPercentage,
    Value<double>? caneDensity,
    Value<int>? producerLocalId,
    Value<int?>? plotLocalId,
    Value<String>? cooperativeId,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? locationText,
    Value<String?>? observations,
    Value<int>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return ProductionBatchesCompanion(
      id: id ?? this.id,
      batchCode: batchCode ?? this.batchCode,
      harvestDate: harvestDate ?? this.harvestDate,
      processDate: processDate ?? this.processDate,
      caneKg: caneKg ?? this.caneKg,
      juiceLiters: juiceLiters ?? this.juiceLiters,
      panelaKg: panelaKg ?? this.panelaKg,
      confitilloKg: confitilloKg ?? this.confitilloKg,
      porcentajeExtraccion: porcentajeExtraccion ?? this.porcentajeExtraccion,
      cachazaPercentage: cachazaPercentage ?? this.cachazaPercentage,
      efficiencyPercentage: efficiencyPercentage ?? this.efficiencyPercentage,
      caneDensity: caneDensity ?? this.caneDensity,
      producerLocalId: producerLocalId ?? this.producerLocalId,
      plotLocalId: plotLocalId ?? this.plotLocalId,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationText: locationText ?? this.locationText,
      observations: observations ?? this.observations,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (batchCode.present) {
      map['batch_code'] = Variable<String>(batchCode.value);
    }
    if (harvestDate.present) {
      map['harvest_date'] = Variable<DateTime>(harvestDate.value);
    }
    if (processDate.present) {
      map['process_date'] = Variable<DateTime>(processDate.value);
    }
    if (caneKg.present) {
      map['cane_kg'] = Variable<double>(caneKg.value);
    }
    if (juiceLiters.present) {
      map['juice_liters'] = Variable<double>(juiceLiters.value);
    }
    if (panelaKg.present) {
      map['panela_kg'] = Variable<double>(panelaKg.value);
    }
    if (confitilloKg.present) {
      map['confitillo_kg'] = Variable<double>(confitilloKg.value);
    }
    if (porcentajeExtraccion.present) {
      map['porcentaje_extraccion'] = Variable<double>(
        porcentajeExtraccion.value,
      );
    }
    if (cachazaPercentage.present) {
      map['cachaza_percentage'] = Variable<double>(cachazaPercentage.value);
    }
    if (efficiencyPercentage.present) {
      map['efficiency_percentage'] = Variable<double>(
        efficiencyPercentage.value,
      );
    }
    if (caneDensity.present) {
      map['cane_density'] = Variable<double>(caneDensity.value);
    }
    if (producerLocalId.present) {
      map['producer_local_id'] = Variable<int>(producerLocalId.value);
    }
    if (plotLocalId.present) {
      map['plot_local_id'] = Variable<int>(plotLocalId.value);
    }
    if (cooperativeId.present) {
      map['cooperative_id'] = Variable<String>(cooperativeId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (locationText.present) {
      map['location_text'] = Variable<String>(locationText.value);
    }
    if (observations.present) {
      map['observations'] = Variable<String>(observations.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatchesCompanion(')
          ..write('id: $id, ')
          ..write('batchCode: $batchCode, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('processDate: $processDate, ')
          ..write('caneKg: $caneKg, ')
          ..write('juiceLiters: $juiceLiters, ')
          ..write('panelaKg: $panelaKg, ')
          ..write('confitilloKg: $confitilloKg, ')
          ..write('porcentajeExtraccion: $porcentajeExtraccion, ')
          ..write('cachazaPercentage: $cachazaPercentage, ')
          ..write('efficiencyPercentage: $efficiencyPercentage, ')
          ..write('caneDensity: $caneDensity, ')
          ..write('producerLocalId: $producerLocalId, ')
          ..write('plotLocalId: $plotLocalId, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('locationText: $locationText, ')
          ..write('observations: $observations, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $BatchTemperaturesTable extends BatchTemperatures
    with TableInfo<$BatchTemperaturesTable, BatchTemperatureLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchTemperaturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productionBatchLocalIdMeta =
      const VerificationMeta('productionBatchLocalId');
  @override
  late final GeneratedColumn<int> productionBatchLocalId = GeneratedColumn<int>(
    'production_batch_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceNumberMeta = const VerificationMeta(
    'sequenceNumber',
  );
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
    'sequence_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cooperativeIdMeta = const VerificationMeta(
    'cooperativeId',
  );
  @override
  late final GeneratedColumn<String> cooperativeId = GeneratedColumn<String>(
    'cooperative_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productionBatchLocalId,
    temperature,
    sequenceNumber,
    cooperativeId,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batch_temperatures';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchTemperatureLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('production_batch_local_id')) {
      context.handle(
        _productionBatchLocalIdMeta,
        productionBatchLocalId.isAcceptableOrUnknown(
          data['production_batch_local_id']!,
          _productionBatchLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productionBatchLocalIdMeta);
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_temperatureMeta);
    }
    if (data.containsKey('sequence_number')) {
      context.handle(
        _sequenceNumberMeta,
        sequenceNumber.isAcceptableOrUnknown(
          data['sequence_number']!,
          _sequenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumberMeta);
    }
    if (data.containsKey('cooperative_id')) {
      context.handle(
        _cooperativeIdMeta,
        cooperativeId.isAcceptableOrUnknown(
          data['cooperative_id']!,
          _cooperativeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cooperativeIdMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BatchTemperatureLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchTemperatureLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productionBatchLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}production_batch_local_id'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      sequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_number'],
      )!,
      cooperativeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cooperative_id'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $BatchTemperaturesTable createAlias(String alias) {
    return $BatchTemperaturesTable(attachedDatabase, alias);
  }
}

class BatchTemperatureLocal extends DataClass
    implements Insertable<BatchTemperatureLocal> {
  /// Local auto-increment ID
  final int id;
  final int productionBatchLocalId;
  final double temperature;
  final int sequenceNumber;
  final String cooperativeId;
  final int syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const BatchTemperatureLocal({
    required this.id,
    required this.productionBatchLocalId,
    required this.temperature,
    required this.sequenceNumber,
    required this.cooperativeId,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['production_batch_local_id'] = Variable<int>(productionBatchLocalId);
    map['temperature'] = Variable<double>(temperature);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    map['cooperative_id'] = Variable<String>(cooperativeId);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  BatchTemperaturesCompanion toCompanion(bool nullToAbsent) {
    return BatchTemperaturesCompanion(
      id: Value(id),
      productionBatchLocalId: Value(productionBatchLocalId),
      temperature: Value(temperature),
      sequenceNumber: Value(sequenceNumber),
      cooperativeId: Value(cooperativeId),
      syncStatus: Value(syncStatus),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory BatchTemperatureLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchTemperatureLocal(
      id: serializer.fromJson<int>(json['id']),
      productionBatchLocalId: serializer.fromJson<int>(
        json['productionBatchLocalId'],
      ),
      temperature: serializer.fromJson<double>(json['temperature']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      cooperativeId: serializer.fromJson<String>(json['cooperativeId']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productionBatchLocalId': serializer.toJson<int>(productionBatchLocalId),
      'temperature': serializer.toJson<double>(temperature),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'cooperativeId': serializer.toJson<String>(cooperativeId),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  BatchTemperatureLocal copyWith({
    int? id,
    int? productionBatchLocalId,
    double? temperature,
    int? sequenceNumber,
    String? cooperativeId,
    int? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => BatchTemperatureLocal(
    id: id ?? this.id,
    productionBatchLocalId:
        productionBatchLocalId ?? this.productionBatchLocalId,
    temperature: temperature ?? this.temperature,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    cooperativeId: cooperativeId ?? this.cooperativeId,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  BatchTemperatureLocal copyWithCompanion(BatchTemperaturesCompanion data) {
    return BatchTemperatureLocal(
      id: data.id.present ? data.id.value : this.id,
      productionBatchLocalId: data.productionBatchLocalId.present
          ? data.productionBatchLocalId.value
          : this.productionBatchLocalId,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      cooperativeId: data.cooperativeId.present
          ? data.cooperativeId.value
          : this.cooperativeId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchTemperatureLocal(')
          ..write('id: $id, ')
          ..write('productionBatchLocalId: $productionBatchLocalId, ')
          ..write('temperature: $temperature, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productionBatchLocalId,
    temperature,
    sequenceNumber,
    cooperativeId,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchTemperatureLocal &&
          other.id == this.id &&
          other.productionBatchLocalId == this.productionBatchLocalId &&
          other.temperature == this.temperature &&
          other.sequenceNumber == this.sequenceNumber &&
          other.cooperativeId == this.cooperativeId &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class BatchTemperaturesCompanion
    extends UpdateCompanion<BatchTemperatureLocal> {
  final Value<int> id;
  final Value<int> productionBatchLocalId;
  final Value<double> temperature;
  final Value<int> sequenceNumber;
  final Value<String> cooperativeId;
  final Value<int> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const BatchTemperaturesCompanion({
    this.id = const Value.absent(),
    this.productionBatchLocalId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.cooperativeId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  BatchTemperaturesCompanion.insert({
    this.id = const Value.absent(),
    required int productionBatchLocalId,
    required double temperature,
    required int sequenceNumber,
    required String cooperativeId,
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : productionBatchLocalId = Value(productionBatchLocalId),
       temperature = Value(temperature),
       sequenceNumber = Value(sequenceNumber),
       cooperativeId = Value(cooperativeId);
  static Insertable<BatchTemperatureLocal> custom({
    Expression<int>? id,
    Expression<int>? productionBatchLocalId,
    Expression<double>? temperature,
    Expression<int>? sequenceNumber,
    Expression<String>? cooperativeId,
    Expression<int>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productionBatchLocalId != null)
        'production_batch_local_id': productionBatchLocalId,
      if (temperature != null) 'temperature': temperature,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (cooperativeId != null) 'cooperative_id': cooperativeId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  BatchTemperaturesCompanion copyWith({
    Value<int>? id,
    Value<int>? productionBatchLocalId,
    Value<double>? temperature,
    Value<int>? sequenceNumber,
    Value<String>? cooperativeId,
    Value<int>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return BatchTemperaturesCompanion(
      id: id ?? this.id,
      productionBatchLocalId:
          productionBatchLocalId ?? this.productionBatchLocalId,
      temperature: temperature ?? this.temperature,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productionBatchLocalId.present) {
      map['production_batch_local_id'] = Variable<int>(
        productionBatchLocalId.value,
      );
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (cooperativeId.present) {
      map['cooperative_id'] = Variable<String>(cooperativeId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchTemperaturesCompanion(')
          ..write('id: $id, ')
          ..write('productionBatchLocalId: $productionBatchLocalId, ')
          ..write('temperature: $temperature, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $BatchPhControlsTable extends BatchPhControls
    with TableInfo<$BatchPhControlsTable, BatchPhControlLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchPhControlsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productionBatchLocalIdMeta =
      const VerificationMeta('productionBatchLocalId');
  @override
  late final GeneratedColumn<int> productionBatchLocalId = GeneratedColumn<int>(
    'production_batch_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordDateMeta = const VerificationMeta(
    'recordDate',
  );
  @override
  late final GeneratedColumn<DateTime> recordDate = GeneratedColumn<DateTime>(
    'record_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regulatorTypeMeta = const VerificationMeta(
    'regulatorType',
  );
  @override
  late final GeneratedColumn<String> regulatorType = GeneratedColumn<String>(
    'regulator_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phInitialMeta = const VerificationMeta(
    'phInitial',
  );
  @override
  late final GeneratedColumn<double> phInitial = GeneratedColumn<double>(
    'ph_initial',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phFinalMeta = const VerificationMeta(
    'phFinal',
  );
  @override
  late final GeneratedColumn<double> phFinal = GeneratedColumn<double>(
    'ph_final',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regulatorQuantityValueMeta =
      const VerificationMeta('regulatorQuantityValue');
  @override
  late final GeneratedColumn<double> regulatorQuantityValue =
      GeneratedColumn<double>(
        'regulator_quantity_value',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _regulatorQuantityUnitMeta =
      const VerificationMeta('regulatorQuantityUnit');
  @override
  late final GeneratedColumn<String> regulatorQuantityUnit =
      GeneratedColumn<String>(
        'regulator_quantity_unit',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _brixMeta = const VerificationMeta('brix');
  @override
  late final GeneratedColumn<double> brix = GeneratedColumn<double>(
    'brix',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctiveActionMeta = const VerificationMeta(
    'correctiveAction',
  );
  @override
  late final GeneratedColumn<String> correctiveAction = GeneratedColumn<String>(
    'corrective_action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cooperativeIdMeta = const VerificationMeta(
    'cooperativeId',
  );
  @override
  late final GeneratedColumn<String> cooperativeId = GeneratedColumn<String>(
    'cooperative_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productionBatchLocalId,
    recordDate,
    regulatorType,
    phInitial,
    phFinal,
    regulatorQuantityValue,
    regulatorQuantityUnit,
    brix,
    correctiveAction,
    cooperativeId,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batch_ph_controls';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchPhControlLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('production_batch_local_id')) {
      context.handle(
        _productionBatchLocalIdMeta,
        productionBatchLocalId.isAcceptableOrUnknown(
          data['production_batch_local_id']!,
          _productionBatchLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productionBatchLocalIdMeta);
    }
    if (data.containsKey('record_date')) {
      context.handle(
        _recordDateMeta,
        recordDate.isAcceptableOrUnknown(data['record_date']!, _recordDateMeta),
      );
    } else if (isInserting) {
      context.missing(_recordDateMeta);
    }
    if (data.containsKey('regulator_type')) {
      context.handle(
        _regulatorTypeMeta,
        regulatorType.isAcceptableOrUnknown(
          data['regulator_type']!,
          _regulatorTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regulatorTypeMeta);
    }
    if (data.containsKey('ph_initial')) {
      context.handle(
        _phInitialMeta,
        phInitial.isAcceptableOrUnknown(data['ph_initial']!, _phInitialMeta),
      );
    } else if (isInserting) {
      context.missing(_phInitialMeta);
    }
    if (data.containsKey('ph_final')) {
      context.handle(
        _phFinalMeta,
        phFinal.isAcceptableOrUnknown(data['ph_final']!, _phFinalMeta),
      );
    } else if (isInserting) {
      context.missing(_phFinalMeta);
    }
    if (data.containsKey('regulator_quantity_value')) {
      context.handle(
        _regulatorQuantityValueMeta,
        regulatorQuantityValue.isAcceptableOrUnknown(
          data['regulator_quantity_value']!,
          _regulatorQuantityValueMeta,
        ),
      );
    }
    if (data.containsKey('regulator_quantity_unit')) {
      context.handle(
        _regulatorQuantityUnitMeta,
        regulatorQuantityUnit.isAcceptableOrUnknown(
          data['regulator_quantity_unit']!,
          _regulatorQuantityUnitMeta,
        ),
      );
    }
    if (data.containsKey('brix')) {
      context.handle(
        _brixMeta,
        brix.isAcceptableOrUnknown(data['brix']!, _brixMeta),
      );
    }
    if (data.containsKey('corrective_action')) {
      context.handle(
        _correctiveActionMeta,
        correctiveAction.isAcceptableOrUnknown(
          data['corrective_action']!,
          _correctiveActionMeta,
        ),
      );
    }
    if (data.containsKey('cooperative_id')) {
      context.handle(
        _cooperativeIdMeta,
        cooperativeId.isAcceptableOrUnknown(
          data['cooperative_id']!,
          _cooperativeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cooperativeIdMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BatchPhControlLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchPhControlLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productionBatchLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}production_batch_local_id'],
      )!,
      recordDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}record_date'],
      )!,
      regulatorType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regulator_type'],
      )!,
      phInitial: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ph_initial'],
      )!,
      phFinal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ph_final'],
      )!,
      regulatorQuantityValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}regulator_quantity_value'],
      ),
      regulatorQuantityUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regulator_quantity_unit'],
      ),
      brix: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}brix'],
      ),
      correctiveAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrective_action'],
      ),
      cooperativeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cooperative_id'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $BatchPhControlsTable createAlias(String alias) {
    return $BatchPhControlsTable(attachedDatabase, alias);
  }
}

class BatchPhControlLocal extends DataClass
    implements Insertable<BatchPhControlLocal> {
  /// Local auto-increment ID
  final int id;
  final int productionBatchLocalId;
  final DateTime recordDate;
  final String regulatorType;
  final double phInitial;
  final double phFinal;
  final double? regulatorQuantityValue;
  final String? regulatorQuantityUnit;
  final double? brix;
  final String? correctiveAction;
  final String cooperativeId;
  final int syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const BatchPhControlLocal({
    required this.id,
    required this.productionBatchLocalId,
    required this.recordDate,
    required this.regulatorType,
    required this.phInitial,
    required this.phFinal,
    this.regulatorQuantityValue,
    this.regulatorQuantityUnit,
    this.brix,
    this.correctiveAction,
    required this.cooperativeId,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['production_batch_local_id'] = Variable<int>(productionBatchLocalId);
    map['record_date'] = Variable<DateTime>(recordDate);
    map['regulator_type'] = Variable<String>(regulatorType);
    map['ph_initial'] = Variable<double>(phInitial);
    map['ph_final'] = Variable<double>(phFinal);
    if (!nullToAbsent || regulatorQuantityValue != null) {
      map['regulator_quantity_value'] = Variable<double>(
        regulatorQuantityValue,
      );
    }
    if (!nullToAbsent || regulatorQuantityUnit != null) {
      map['regulator_quantity_unit'] = Variable<String>(regulatorQuantityUnit);
    }
    if (!nullToAbsent || brix != null) {
      map['brix'] = Variable<double>(brix);
    }
    if (!nullToAbsent || correctiveAction != null) {
      map['corrective_action'] = Variable<String>(correctiveAction);
    }
    map['cooperative_id'] = Variable<String>(cooperativeId);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  BatchPhControlsCompanion toCompanion(bool nullToAbsent) {
    return BatchPhControlsCompanion(
      id: Value(id),
      productionBatchLocalId: Value(productionBatchLocalId),
      recordDate: Value(recordDate),
      regulatorType: Value(regulatorType),
      phInitial: Value(phInitial),
      phFinal: Value(phFinal),
      regulatorQuantityValue: regulatorQuantityValue == null && nullToAbsent
          ? const Value.absent()
          : Value(regulatorQuantityValue),
      regulatorQuantityUnit: regulatorQuantityUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(regulatorQuantityUnit),
      brix: brix == null && nullToAbsent ? const Value.absent() : Value(brix),
      correctiveAction: correctiveAction == null && nullToAbsent
          ? const Value.absent()
          : Value(correctiveAction),
      cooperativeId: Value(cooperativeId),
      syncStatus: Value(syncStatus),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory BatchPhControlLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchPhControlLocal(
      id: serializer.fromJson<int>(json['id']),
      productionBatchLocalId: serializer.fromJson<int>(
        json['productionBatchLocalId'],
      ),
      recordDate: serializer.fromJson<DateTime>(json['recordDate']),
      regulatorType: serializer.fromJson<String>(json['regulatorType']),
      phInitial: serializer.fromJson<double>(json['phInitial']),
      phFinal: serializer.fromJson<double>(json['phFinal']),
      regulatorQuantityValue: serializer.fromJson<double?>(
        json['regulatorQuantityValue'],
      ),
      regulatorQuantityUnit: serializer.fromJson<String?>(
        json['regulatorQuantityUnit'],
      ),
      brix: serializer.fromJson<double?>(json['brix']),
      correctiveAction: serializer.fromJson<String?>(json['correctiveAction']),
      cooperativeId: serializer.fromJson<String>(json['cooperativeId']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productionBatchLocalId': serializer.toJson<int>(productionBatchLocalId),
      'recordDate': serializer.toJson<DateTime>(recordDate),
      'regulatorType': serializer.toJson<String>(regulatorType),
      'phInitial': serializer.toJson<double>(phInitial),
      'phFinal': serializer.toJson<double>(phFinal),
      'regulatorQuantityValue': serializer.toJson<double?>(
        regulatorQuantityValue,
      ),
      'regulatorQuantityUnit': serializer.toJson<String?>(
        regulatorQuantityUnit,
      ),
      'brix': serializer.toJson<double?>(brix),
      'correctiveAction': serializer.toJson<String?>(correctiveAction),
      'cooperativeId': serializer.toJson<String>(cooperativeId),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  BatchPhControlLocal copyWith({
    int? id,
    int? productionBatchLocalId,
    DateTime? recordDate,
    String? regulatorType,
    double? phInitial,
    double? phFinal,
    Value<double?> regulatorQuantityValue = const Value.absent(),
    Value<String?> regulatorQuantityUnit = const Value.absent(),
    Value<double?> brix = const Value.absent(),
    Value<String?> correctiveAction = const Value.absent(),
    String? cooperativeId,
    int? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => BatchPhControlLocal(
    id: id ?? this.id,
    productionBatchLocalId:
        productionBatchLocalId ?? this.productionBatchLocalId,
    recordDate: recordDate ?? this.recordDate,
    regulatorType: regulatorType ?? this.regulatorType,
    phInitial: phInitial ?? this.phInitial,
    phFinal: phFinal ?? this.phFinal,
    regulatorQuantityValue: regulatorQuantityValue.present
        ? regulatorQuantityValue.value
        : this.regulatorQuantityValue,
    regulatorQuantityUnit: regulatorQuantityUnit.present
        ? regulatorQuantityUnit.value
        : this.regulatorQuantityUnit,
    brix: brix.present ? brix.value : this.brix,
    correctiveAction: correctiveAction.present
        ? correctiveAction.value
        : this.correctiveAction,
    cooperativeId: cooperativeId ?? this.cooperativeId,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  BatchPhControlLocal copyWithCompanion(BatchPhControlsCompanion data) {
    return BatchPhControlLocal(
      id: data.id.present ? data.id.value : this.id,
      productionBatchLocalId: data.productionBatchLocalId.present
          ? data.productionBatchLocalId.value
          : this.productionBatchLocalId,
      recordDate: data.recordDate.present
          ? data.recordDate.value
          : this.recordDate,
      regulatorType: data.regulatorType.present
          ? data.regulatorType.value
          : this.regulatorType,
      phInitial: data.phInitial.present ? data.phInitial.value : this.phInitial,
      phFinal: data.phFinal.present ? data.phFinal.value : this.phFinal,
      regulatorQuantityValue: data.regulatorQuantityValue.present
          ? data.regulatorQuantityValue.value
          : this.regulatorQuantityValue,
      regulatorQuantityUnit: data.regulatorQuantityUnit.present
          ? data.regulatorQuantityUnit.value
          : this.regulatorQuantityUnit,
      brix: data.brix.present ? data.brix.value : this.brix,
      correctiveAction: data.correctiveAction.present
          ? data.correctiveAction.value
          : this.correctiveAction,
      cooperativeId: data.cooperativeId.present
          ? data.cooperativeId.value
          : this.cooperativeId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchPhControlLocal(')
          ..write('id: $id, ')
          ..write('productionBatchLocalId: $productionBatchLocalId, ')
          ..write('recordDate: $recordDate, ')
          ..write('regulatorType: $regulatorType, ')
          ..write('phInitial: $phInitial, ')
          ..write('phFinal: $phFinal, ')
          ..write('regulatorQuantityValue: $regulatorQuantityValue, ')
          ..write('regulatorQuantityUnit: $regulatorQuantityUnit, ')
          ..write('brix: $brix, ')
          ..write('correctiveAction: $correctiveAction, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productionBatchLocalId,
    recordDate,
    regulatorType,
    phInitial,
    phFinal,
    regulatorQuantityValue,
    regulatorQuantityUnit,
    brix,
    correctiveAction,
    cooperativeId,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchPhControlLocal &&
          other.id == this.id &&
          other.productionBatchLocalId == this.productionBatchLocalId &&
          other.recordDate == this.recordDate &&
          other.regulatorType == this.regulatorType &&
          other.phInitial == this.phInitial &&
          other.phFinal == this.phFinal &&
          other.regulatorQuantityValue == this.regulatorQuantityValue &&
          other.regulatorQuantityUnit == this.regulatorQuantityUnit &&
          other.brix == this.brix &&
          other.correctiveAction == this.correctiveAction &&
          other.cooperativeId == this.cooperativeId &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class BatchPhControlsCompanion extends UpdateCompanion<BatchPhControlLocal> {
  final Value<int> id;
  final Value<int> productionBatchLocalId;
  final Value<DateTime> recordDate;
  final Value<String> regulatorType;
  final Value<double> phInitial;
  final Value<double> phFinal;
  final Value<double?> regulatorQuantityValue;
  final Value<String?> regulatorQuantityUnit;
  final Value<double?> brix;
  final Value<String?> correctiveAction;
  final Value<String> cooperativeId;
  final Value<int> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const BatchPhControlsCompanion({
    this.id = const Value.absent(),
    this.productionBatchLocalId = const Value.absent(),
    this.recordDate = const Value.absent(),
    this.regulatorType = const Value.absent(),
    this.phInitial = const Value.absent(),
    this.phFinal = const Value.absent(),
    this.regulatorQuantityValue = const Value.absent(),
    this.regulatorQuantityUnit = const Value.absent(),
    this.brix = const Value.absent(),
    this.correctiveAction = const Value.absent(),
    this.cooperativeId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  BatchPhControlsCompanion.insert({
    this.id = const Value.absent(),
    required int productionBatchLocalId,
    required DateTime recordDate,
    required String regulatorType,
    required double phInitial,
    required double phFinal,
    this.regulatorQuantityValue = const Value.absent(),
    this.regulatorQuantityUnit = const Value.absent(),
    this.brix = const Value.absent(),
    this.correctiveAction = const Value.absent(),
    required String cooperativeId,
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : productionBatchLocalId = Value(productionBatchLocalId),
       recordDate = Value(recordDate),
       regulatorType = Value(regulatorType),
       phInitial = Value(phInitial),
       phFinal = Value(phFinal),
       cooperativeId = Value(cooperativeId);
  static Insertable<BatchPhControlLocal> custom({
    Expression<int>? id,
    Expression<int>? productionBatchLocalId,
    Expression<DateTime>? recordDate,
    Expression<String>? regulatorType,
    Expression<double>? phInitial,
    Expression<double>? phFinal,
    Expression<double>? regulatorQuantityValue,
    Expression<String>? regulatorQuantityUnit,
    Expression<double>? brix,
    Expression<String>? correctiveAction,
    Expression<String>? cooperativeId,
    Expression<int>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productionBatchLocalId != null)
        'production_batch_local_id': productionBatchLocalId,
      if (recordDate != null) 'record_date': recordDate,
      if (regulatorType != null) 'regulator_type': regulatorType,
      if (phInitial != null) 'ph_initial': phInitial,
      if (phFinal != null) 'ph_final': phFinal,
      if (regulatorQuantityValue != null)
        'regulator_quantity_value': regulatorQuantityValue,
      if (regulatorQuantityUnit != null)
        'regulator_quantity_unit': regulatorQuantityUnit,
      if (brix != null) 'brix': brix,
      if (correctiveAction != null) 'corrective_action': correctiveAction,
      if (cooperativeId != null) 'cooperative_id': cooperativeId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  BatchPhControlsCompanion copyWith({
    Value<int>? id,
    Value<int>? productionBatchLocalId,
    Value<DateTime>? recordDate,
    Value<String>? regulatorType,
    Value<double>? phInitial,
    Value<double>? phFinal,
    Value<double?>? regulatorQuantityValue,
    Value<String?>? regulatorQuantityUnit,
    Value<double?>? brix,
    Value<String?>? correctiveAction,
    Value<String>? cooperativeId,
    Value<int>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return BatchPhControlsCompanion(
      id: id ?? this.id,
      productionBatchLocalId:
          productionBatchLocalId ?? this.productionBatchLocalId,
      recordDate: recordDate ?? this.recordDate,
      regulatorType: regulatorType ?? this.regulatorType,
      phInitial: phInitial ?? this.phInitial,
      phFinal: phFinal ?? this.phFinal,
      regulatorQuantityValue:
          regulatorQuantityValue ?? this.regulatorQuantityValue,
      regulatorQuantityUnit:
          regulatorQuantityUnit ?? this.regulatorQuantityUnit,
      brix: brix ?? this.brix,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productionBatchLocalId.present) {
      map['production_batch_local_id'] = Variable<int>(
        productionBatchLocalId.value,
      );
    }
    if (recordDate.present) {
      map['record_date'] = Variable<DateTime>(recordDate.value);
    }
    if (regulatorType.present) {
      map['regulator_type'] = Variable<String>(regulatorType.value);
    }
    if (phInitial.present) {
      map['ph_initial'] = Variable<double>(phInitial.value);
    }
    if (phFinal.present) {
      map['ph_final'] = Variable<double>(phFinal.value);
    }
    if (regulatorQuantityValue.present) {
      map['regulator_quantity_value'] = Variable<double>(
        regulatorQuantityValue.value,
      );
    }
    if (regulatorQuantityUnit.present) {
      map['regulator_quantity_unit'] = Variable<String>(
        regulatorQuantityUnit.value,
      );
    }
    if (brix.present) {
      map['brix'] = Variable<double>(brix.value);
    }
    if (correctiveAction.present) {
      map['corrective_action'] = Variable<String>(correctiveAction.value);
    }
    if (cooperativeId.present) {
      map['cooperative_id'] = Variable<String>(cooperativeId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchPhControlsCompanion(')
          ..write('id: $id, ')
          ..write('productionBatchLocalId: $productionBatchLocalId, ')
          ..write('recordDate: $recordDate, ')
          ..write('regulatorType: $regulatorType, ')
          ..write('phInitial: $phInitial, ')
          ..write('phFinal: $phFinal, ')
          ..write('regulatorQuantityValue: $regulatorQuantityValue, ')
          ..write('regulatorQuantityUnit: $regulatorQuantityUnit, ')
          ..write('brix: $brix, ')
          ..write('correctiveAction: $correctiveAction, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $ProductionBatchCertsTable extends ProductionBatchCerts
    with TableInfo<$ProductionBatchCertsTable, ProductionBatchCertLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductionBatchCertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productionBatchLocalIdMeta =
      const VerificationMeta('productionBatchLocalId');
  @override
  late final GeneratedColumn<int> productionBatchLocalId = GeneratedColumn<int>(
    'production_batch_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchCertIdMeta = const VerificationMeta(
    'batchCertId',
  );
  @override
  late final GeneratedColumn<String> batchCertId = GeneratedColumn<String>(
    'batch_cert_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cooperativeIdMeta = const VerificationMeta(
    'cooperativeId',
  );
  @override
  late final GeneratedColumn<String> cooperativeId = GeneratedColumn<String>(
    'cooperative_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productionBatchLocalId,
    batchCertId,
    cooperativeId,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'production_batch_certs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductionBatchCertLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('production_batch_local_id')) {
      context.handle(
        _productionBatchLocalIdMeta,
        productionBatchLocalId.isAcceptableOrUnknown(
          data['production_batch_local_id']!,
          _productionBatchLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productionBatchLocalIdMeta);
    }
    if (data.containsKey('batch_cert_id')) {
      context.handle(
        _batchCertIdMeta,
        batchCertId.isAcceptableOrUnknown(
          data['batch_cert_id']!,
          _batchCertIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_batchCertIdMeta);
    }
    if (data.containsKey('cooperative_id')) {
      context.handle(
        _cooperativeIdMeta,
        cooperativeId.isAcceptableOrUnknown(
          data['cooperative_id']!,
          _cooperativeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cooperativeIdMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductionBatchCertLocal map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductionBatchCertLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productionBatchLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}production_batch_local_id'],
      )!,
      batchCertId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_cert_id'],
      )!,
      cooperativeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cooperative_id'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $ProductionBatchCertsTable createAlias(String alias) {
    return $ProductionBatchCertsTable(attachedDatabase, alias);
  }
}

class ProductionBatchCertLocal extends DataClass
    implements Insertable<ProductionBatchCertLocal> {
  /// Local auto-increment ID
  final int id;
  final int productionBatchLocalId;
  final String batchCertId;
  final String cooperativeId;
  final int syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const ProductionBatchCertLocal({
    required this.id,
    required this.productionBatchLocalId,
    required this.batchCertId,
    required this.cooperativeId,
    required this.syncStatus,
    this.remoteId,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['production_batch_local_id'] = Variable<int>(productionBatchLocalId);
    map['batch_cert_id'] = Variable<String>(batchCertId);
    map['cooperative_id'] = Variable<String>(cooperativeId);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  ProductionBatchCertsCompanion toCompanion(bool nullToAbsent) {
    return ProductionBatchCertsCompanion(
      id: Value(id),
      productionBatchLocalId: Value(productionBatchLocalId),
      batchCertId: Value(batchCertId),
      cooperativeId: Value(cooperativeId),
      syncStatus: Value(syncStatus),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory ProductionBatchCertLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductionBatchCertLocal(
      id: serializer.fromJson<int>(json['id']),
      productionBatchLocalId: serializer.fromJson<int>(
        json['productionBatchLocalId'],
      ),
      batchCertId: serializer.fromJson<String>(json['batchCertId']),
      cooperativeId: serializer.fromJson<String>(json['cooperativeId']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productionBatchLocalId': serializer.toJson<int>(productionBatchLocalId),
      'batchCertId': serializer.toJson<String>(batchCertId),
      'cooperativeId': serializer.toJson<String>(cooperativeId),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  ProductionBatchCertLocal copyWith({
    int? id,
    int? productionBatchLocalId,
    String? batchCertId,
    String? cooperativeId,
    int? syncStatus,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => ProductionBatchCertLocal(
    id: id ?? this.id,
    productionBatchLocalId:
        productionBatchLocalId ?? this.productionBatchLocalId,
    batchCertId: batchCertId ?? this.batchCertId,
    cooperativeId: cooperativeId ?? this.cooperativeId,
    syncStatus: syncStatus ?? this.syncStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  ProductionBatchCertLocal copyWithCompanion(
    ProductionBatchCertsCompanion data,
  ) {
    return ProductionBatchCertLocal(
      id: data.id.present ? data.id.value : this.id,
      productionBatchLocalId: data.productionBatchLocalId.present
          ? data.productionBatchLocalId.value
          : this.productionBatchLocalId,
      batchCertId: data.batchCertId.present
          ? data.batchCertId.value
          : this.batchCertId,
      cooperativeId: data.cooperativeId.present
          ? data.cooperativeId.value
          : this.cooperativeId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatchCertLocal(')
          ..write('id: $id, ')
          ..write('productionBatchLocalId: $productionBatchLocalId, ')
          ..write('batchCertId: $batchCertId, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productionBatchLocalId,
    batchCertId,
    cooperativeId,
    syncStatus,
    remoteId,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductionBatchCertLocal &&
          other.id == this.id &&
          other.productionBatchLocalId == this.productionBatchLocalId &&
          other.batchCertId == this.batchCertId &&
          other.cooperativeId == this.cooperativeId &&
          other.syncStatus == this.syncStatus &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class ProductionBatchCertsCompanion
    extends UpdateCompanion<ProductionBatchCertLocal> {
  final Value<int> id;
  final Value<int> productionBatchLocalId;
  final Value<String> batchCertId;
  final Value<String> cooperativeId;
  final Value<int> syncStatus;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const ProductionBatchCertsCompanion({
    this.id = const Value.absent(),
    this.productionBatchLocalId = const Value.absent(),
    this.batchCertId = const Value.absent(),
    this.cooperativeId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  ProductionBatchCertsCompanion.insert({
    this.id = const Value.absent(),
    required int productionBatchLocalId,
    required String batchCertId,
    required String cooperativeId,
    this.syncStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  }) : productionBatchLocalId = Value(productionBatchLocalId),
       batchCertId = Value(batchCertId),
       cooperativeId = Value(cooperativeId);
  static Insertable<ProductionBatchCertLocal> custom({
    Expression<int>? id,
    Expression<int>? productionBatchLocalId,
    Expression<String>? batchCertId,
    Expression<String>? cooperativeId,
    Expression<int>? syncStatus,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productionBatchLocalId != null)
        'production_batch_local_id': productionBatchLocalId,
      if (batchCertId != null) 'batch_cert_id': batchCertId,
      if (cooperativeId != null) 'cooperative_id': cooperativeId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  ProductionBatchCertsCompanion copyWith({
    Value<int>? id,
    Value<int>? productionBatchLocalId,
    Value<String>? batchCertId,
    Value<String>? cooperativeId,
    Value<int>? syncStatus,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return ProductionBatchCertsCompanion(
      id: id ?? this.id,
      productionBatchLocalId:
          productionBatchLocalId ?? this.productionBatchLocalId,
      batchCertId: batchCertId ?? this.batchCertId,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      syncStatus: syncStatus ?? this.syncStatus,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productionBatchLocalId.present) {
      map['production_batch_local_id'] = Variable<int>(
        productionBatchLocalId.value,
      );
    }
    if (batchCertId.present) {
      map['batch_cert_id'] = Variable<String>(batchCertId.value);
    }
    if (cooperativeId.present) {
      map['cooperative_id'] = Variable<String>(cooperativeId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductionBatchCertsCompanion(')
          ..write('id: $id, ')
          ..write('productionBatchLocalId: $productionBatchLocalId, ')
          ..write('batchCertId: $batchCertId, ')
          ..write('cooperativeId: $cooperativeId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $BatchCertsTable extends BatchCerts
    with TableInfo<$BatchCertsTable, BatchCertLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchCertsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _exclusionGroupIdMeta = const VerificationMeta(
    'exclusionGroupId',
  );
  @override
  late final GeneratedColumn<String> exclusionGroupId = GeneratedColumn<String>(
    'exclusion_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    exclusionGroupId,
    isDefault,
    isActive,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batch_certs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchCertLocal> instance, {
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
    if (data.containsKey('exclusion_group_id')) {
      context.handle(
        _exclusionGroupIdMeta,
        exclusionGroupId.isAcceptableOrUnknown(
          data['exclusion_group_id']!,
          _exclusionGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    } else if (isInserting) {
      context.missing(_isDefaultMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BatchCertLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchCertLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      exclusionGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exclusion_group_id'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $BatchCertsTable createAlias(String alias) {
    return $BatchCertsTable(attachedDatabase, alias);
  }
}

class BatchCertLocal extends DataClass implements Insertable<BatchCertLocal> {
  final String id;
  final String name;
  final String? exclusionGroupId;
  final bool isDefault;
  final bool isActive;
  final DateTime cachedAt;
  const BatchCertLocal({
    required this.id,
    required this.name,
    this.exclusionGroupId,
    required this.isDefault,
    required this.isActive,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || exclusionGroupId != null) {
      map['exclusion_group_id'] = Variable<String>(exclusionGroupId);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  BatchCertsCompanion toCompanion(bool nullToAbsent) {
    return BatchCertsCompanion(
      id: Value(id),
      name: Value(name),
      exclusionGroupId: exclusionGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(exclusionGroupId),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory BatchCertLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchCertLocal(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      exclusionGroupId: serializer.fromJson<String?>(json['exclusionGroupId']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'exclusionGroupId': serializer.toJson<String?>(exclusionGroupId),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  BatchCertLocal copyWith({
    String? id,
    String? name,
    Value<String?> exclusionGroupId = const Value.absent(),
    bool? isDefault,
    bool? isActive,
    DateTime? cachedAt,
  }) => BatchCertLocal(
    id: id ?? this.id,
    name: name ?? this.name,
    exclusionGroupId: exclusionGroupId.present
        ? exclusionGroupId.value
        : this.exclusionGroupId,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  BatchCertLocal copyWithCompanion(BatchCertsCompanion data) {
    return BatchCertLocal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      exclusionGroupId: data.exclusionGroupId.present
          ? data.exclusionGroupId.value
          : this.exclusionGroupId,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchCertLocal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('exclusionGroupId: $exclusionGroupId, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, exclusionGroupId, isDefault, isActive, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchCertLocal &&
          other.id == this.id &&
          other.name == this.name &&
          other.exclusionGroupId == this.exclusionGroupId &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class BatchCertsCompanion extends UpdateCompanion<BatchCertLocal> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> exclusionGroupId;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const BatchCertsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.exclusionGroupId = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchCertsCompanion.insert({
    required String id,
    required String name,
    this.exclusionGroupId = const Value.absent(),
    required bool isDefault,
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       isDefault = Value(isDefault);
  static Insertable<BatchCertLocal> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? exclusionGroupId,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (exclusionGroupId != null) 'exclusion_group_id': exclusionGroupId,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchCertsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? exclusionGroupId,
    Value<bool>? isDefault,
    Value<bool>? isActive,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return BatchCertsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      exclusionGroupId: exclusionGroupId ?? this.exclusionGroupId,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
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
    if (exclusionGroupId.present) {
      map['exclusion_group_id'] = Variable<String>(exclusionGroupId.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchCertsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('exclusionGroupId: $exclusionGroupId, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProducersTable producers = $ProducersTable(this);
  late final $PlotsTable plots = $PlotsTable(this);
  late final $CoopModulesTable coopModules = $CoopModulesTable(this);
  late final $ProductionBatchesTable productionBatches =
      $ProductionBatchesTable(this);
  late final $BatchTemperaturesTable batchTemperatures =
      $BatchTemperaturesTable(this);
  late final $BatchPhControlsTable batchPhControls = $BatchPhControlsTable(
    this,
  );
  late final $ProductionBatchCertsTable productionBatchCerts =
      $ProductionBatchCertsTable(this);
  late final $BatchCertsTable batchCerts = $BatchCertsTable(this);
  late final ProducersDao producersDao = ProducersDao(this as AppDatabase);
  late final PlotsDao plotsDao = PlotsDao(this as AppDatabase);
  late final CoopModulesDao coopModulesDao = CoopModulesDao(
    this as AppDatabase,
  );
  late final ProductionBatchesDao productionBatchesDao = ProductionBatchesDao(
    this as AppDatabase,
  );
  late final BatchTemperaturesDao batchTemperaturesDao = BatchTemperaturesDao(
    this as AppDatabase,
  );
  late final BatchPhControlsDao batchPhControlsDao = BatchPhControlsDao(
    this as AppDatabase,
  );
  late final ProductionBatchCertsDao productionBatchCertsDao =
      ProductionBatchCertsDao(this as AppDatabase);
  late final BatchCertsDao batchCertsDao = BatchCertsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    producers,
    plots,
    coopModules,
    productionBatches,
    batchTemperatures,
    batchPhControls,
    productionBatchCerts,
    batchCerts,
  ];
}

typedef $$ProducersTableCreateCompanionBuilder =
    ProducersCompanion Function({
      Value<int> id,
      required String firstName,
      required String lastName,
      required String dni,
      required String coopModuleId,
      required String cooperativeId,
      required bool isMember,
      Value<String?> appagropCode,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$ProducersTableUpdateCompanionBuilder =
    ProducersCompanion Function({
      Value<int> id,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> dni,
      Value<String> coopModuleId,
      Value<String> cooperativeId,
      Value<bool> isMember,
      Value<String?> appagropCode,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$ProducersTableFilterComposer
    extends Composer<_$AppDatabase, $ProducersTable> {
  $$ProducersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
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

  ColumnFilters<String> get dni => $composableBuilder(
    column: $table.dni,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coopModuleId => $composableBuilder(
    column: $table.coopModuleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMember => $composableBuilder(
    column: $table.isMember,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appagropCode => $composableBuilder(
    column: $table.appagropCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProducersTableOrderingComposer
    extends Composer<_$AppDatabase, $ProducersTable> {
  $$ProducersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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

  ColumnOrderings<String> get dni => $composableBuilder(
    column: $table.dni,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coopModuleId => $composableBuilder(
    column: $table.coopModuleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMember => $composableBuilder(
    column: $table.isMember,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appagropCode => $composableBuilder(
    column: $table.appagropCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProducersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProducersTable> {
  $$ProducersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get dni =>
      $composableBuilder(column: $table.dni, builder: (column) => column);

  GeneratedColumn<String> get coopModuleId => $composableBuilder(
    column: $table.coopModuleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMember =>
      $composableBuilder(column: $table.isMember, builder: (column) => column);

  GeneratedColumn<String> get appagropCode => $composableBuilder(
    column: $table.appagropCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ProducersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProducersTable,
          Producer,
          $$ProducersTableFilterComposer,
          $$ProducersTableOrderingComposer,
          $$ProducersTableAnnotationComposer,
          $$ProducersTableCreateCompanionBuilder,
          $$ProducersTableUpdateCompanionBuilder,
          (Producer, BaseReferences<_$AppDatabase, $ProducersTable, Producer>),
          Producer,
          PrefetchHooks Function()
        > {
  $$ProducersTableTableManager(_$AppDatabase db, $ProducersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProducersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProducersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProducersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> dni = const Value.absent(),
                Value<String> coopModuleId = const Value.absent(),
                Value<String> cooperativeId = const Value.absent(),
                Value<bool> isMember = const Value.absent(),
                Value<String?> appagropCode = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => ProducersCompanion(
                id: id,
                firstName: firstName,
                lastName: lastName,
                dni: dni,
                coopModuleId: coopModuleId,
                cooperativeId: cooperativeId,
                isMember: isMember,
                appagropCode: appagropCode,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String firstName,
                required String lastName,
                required String dni,
                required String coopModuleId,
                required String cooperativeId,
                required bool isMember,
                Value<String?> appagropCode = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => ProducersCompanion.insert(
                id: id,
                firstName: firstName,
                lastName: lastName,
                dni: dni,
                coopModuleId: coopModuleId,
                cooperativeId: cooperativeId,
                isMember: isMember,
                appagropCode: appagropCode,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProducersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProducersTable,
      Producer,
      $$ProducersTableFilterComposer,
      $$ProducersTableOrderingComposer,
      $$ProducersTableAnnotationComposer,
      $$ProducersTableCreateCompanionBuilder,
      $$ProducersTableUpdateCompanionBuilder,
      (Producer, BaseReferences<_$AppDatabase, $ProducersTable, Producer>),
      Producer,
      PrefetchHooks Function()
    >;
typedef $$PlotsTableCreateCompanionBuilder =
    PlotsCompanion Function({
      Value<int> id,
      required String name,
      required String code,
      required int producerLocalId,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<String?> remoteProducerId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$PlotsTableUpdateCompanionBuilder =
    PlotsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> code,
      Value<int> producerLocalId,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<String?> remoteProducerId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$PlotsTableFilterComposer extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get producerLocalId => $composableBuilder(
    column: $table.producerLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteProducerId => $composableBuilder(
    column: $table.remoteProducerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get producerLocalId => $composableBuilder(
    column: $table.producerLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteProducerId => $composableBuilder(
    column: $table.remoteProducerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<int> get producerLocalId => $composableBuilder(
    column: $table.producerLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get remoteProducerId => $composableBuilder(
    column: $table.remoteProducerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$PlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlotsTable,
          Plot,
          $$PlotsTableFilterComposer,
          $$PlotsTableOrderingComposer,
          $$PlotsTableAnnotationComposer,
          $$PlotsTableCreateCompanionBuilder,
          $$PlotsTableUpdateCompanionBuilder,
          (Plot, BaseReferences<_$AppDatabase, $PlotsTable, Plot>),
          Plot,
          PrefetchHooks Function()
        > {
  $$PlotsTableTableManager(_$AppDatabase db, $PlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<int> producerLocalId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> remoteProducerId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => PlotsCompanion(
                id: id,
                name: name,
                code: code,
                producerLocalId: producerLocalId,
                syncStatus: syncStatus,
                remoteId: remoteId,
                remoteProducerId: remoteProducerId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String code,
                required int producerLocalId,
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> remoteProducerId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => PlotsCompanion.insert(
                id: id,
                name: name,
                code: code,
                producerLocalId: producerLocalId,
                syncStatus: syncStatus,
                remoteId: remoteId,
                remoteProducerId: remoteProducerId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlotsTable,
      Plot,
      $$PlotsTableFilterComposer,
      $$PlotsTableOrderingComposer,
      $$PlotsTableAnnotationComposer,
      $$PlotsTableCreateCompanionBuilder,
      $$PlotsTableUpdateCompanionBuilder,
      (Plot, BaseReferences<_$AppDatabase, $PlotsTable, Plot>),
      Plot,
      PrefetchHooks Function()
    >;
typedef $$CoopModulesTableCreateCompanionBuilder =
    CoopModulesCompanion Function({
      required String id,
      required String name,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CoopModulesTableUpdateCompanionBuilder =
    CoopModulesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CoopModulesTableFilterComposer
    extends Composer<_$AppDatabase, $CoopModulesTable> {
  $$CoopModulesTableFilterComposer({
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

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoopModulesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoopModulesTable> {
  $$CoopModulesTableOrderingComposer({
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

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoopModulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoopModulesTable> {
  $$CoopModulesTableAnnotationComposer({
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

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CoopModulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoopModulesTable,
          CoopModuleLocal,
          $$CoopModulesTableFilterComposer,
          $$CoopModulesTableOrderingComposer,
          $$CoopModulesTableAnnotationComposer,
          $$CoopModulesTableCreateCompanionBuilder,
          $$CoopModulesTableUpdateCompanionBuilder,
          (
            CoopModuleLocal,
            BaseReferences<_$AppDatabase, $CoopModulesTable, CoopModuleLocal>,
          ),
          CoopModuleLocal,
          PrefetchHooks Function()
        > {
  $$CoopModulesTableTableManager(_$AppDatabase db, $CoopModulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoopModulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoopModulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoopModulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoopModulesCompanion(
                id: id,
                name: name,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoopModulesCompanion.insert(
                id: id,
                name: name,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoopModulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoopModulesTable,
      CoopModuleLocal,
      $$CoopModulesTableFilterComposer,
      $$CoopModulesTableOrderingComposer,
      $$CoopModulesTableAnnotationComposer,
      $$CoopModulesTableCreateCompanionBuilder,
      $$CoopModulesTableUpdateCompanionBuilder,
      (
        CoopModuleLocal,
        BaseReferences<_$AppDatabase, $CoopModulesTable, CoopModuleLocal>,
      ),
      CoopModuleLocal,
      PrefetchHooks Function()
    >;
typedef $$ProductionBatchesTableCreateCompanionBuilder =
    ProductionBatchesCompanion Function({
      Value<int> id,
      required String batchCode,
      required DateTime harvestDate,
      required DateTime processDate,
      required double caneKg,
      required double juiceLiters,
      required double panelaKg,
      required double confitilloKg,
      Value<double?> porcentajeExtraccion,
      Value<double?> cachazaPercentage,
      required double efficiencyPercentage,
      Value<double> caneDensity,
      required int producerLocalId,
      Value<int?> plotLocalId,
      required String cooperativeId,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> locationText,
      Value<String?> observations,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$ProductionBatchesTableUpdateCompanionBuilder =
    ProductionBatchesCompanion Function({
      Value<int> id,
      Value<String> batchCode,
      Value<DateTime> harvestDate,
      Value<DateTime> processDate,
      Value<double> caneKg,
      Value<double> juiceLiters,
      Value<double> panelaKg,
      Value<double> confitilloKg,
      Value<double?> porcentajeExtraccion,
      Value<double?> cachazaPercentage,
      Value<double> efficiencyPercentage,
      Value<double> caneDensity,
      Value<int> producerLocalId,
      Value<int?> plotLocalId,
      Value<String> cooperativeId,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> locationText,
      Value<String?> observations,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$ProductionBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTable> {
  $$ProductionBatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchCode => $composableBuilder(
    column: $table.batchCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get harvestDate => $composableBuilder(
    column: $table.harvestDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processDate => $composableBuilder(
    column: $table.processDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caneKg => $composableBuilder(
    column: $table.caneKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get juiceLiters => $composableBuilder(
    column: $table.juiceLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get panelaKg => $composableBuilder(
    column: $table.panelaKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confitilloKg => $composableBuilder(
    column: $table.confitilloKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get porcentajeExtraccion => $composableBuilder(
    column: $table.porcentajeExtraccion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cachazaPercentage => $composableBuilder(
    column: $table.cachazaPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get efficiencyPercentage => $composableBuilder(
    column: $table.efficiencyPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caneDensity => $composableBuilder(
    column: $table.caneDensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get producerLocalId => $composableBuilder(
    column: $table.producerLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plotLocalId => $composableBuilder(
    column: $table.plotLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductionBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTable> {
  $$ProductionBatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchCode => $composableBuilder(
    column: $table.batchCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get harvestDate => $composableBuilder(
    column: $table.harvestDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processDate => $composableBuilder(
    column: $table.processDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caneKg => $composableBuilder(
    column: $table.caneKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get juiceLiters => $composableBuilder(
    column: $table.juiceLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get panelaKg => $composableBuilder(
    column: $table.panelaKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confitilloKg => $composableBuilder(
    column: $table.confitilloKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get porcentajeExtraccion => $composableBuilder(
    column: $table.porcentajeExtraccion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cachazaPercentage => $composableBuilder(
    column: $table.cachazaPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get efficiencyPercentage => $composableBuilder(
    column: $table.efficiencyPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caneDensity => $composableBuilder(
    column: $table.caneDensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get producerLocalId => $composableBuilder(
    column: $table.producerLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plotLocalId => $composableBuilder(
    column: $table.plotLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductionBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductionBatchesTable> {
  $$ProductionBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get batchCode =>
      $composableBuilder(column: $table.batchCode, builder: (column) => column);

  GeneratedColumn<DateTime> get harvestDate => $composableBuilder(
    column: $table.harvestDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get processDate => $composableBuilder(
    column: $table.processDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get caneKg =>
      $composableBuilder(column: $table.caneKg, builder: (column) => column);

  GeneratedColumn<double> get juiceLiters => $composableBuilder(
    column: $table.juiceLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get panelaKg =>
      $composableBuilder(column: $table.panelaKg, builder: (column) => column);

  GeneratedColumn<double> get confitilloKg => $composableBuilder(
    column: $table.confitilloKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get porcentajeExtraccion => $composableBuilder(
    column: $table.porcentajeExtraccion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cachazaPercentage => $composableBuilder(
    column: $table.cachazaPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get efficiencyPercentage => $composableBuilder(
    column: $table.efficiencyPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get caneDensity => $composableBuilder(
    column: $table.caneDensity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get producerLocalId => $composableBuilder(
    column: $table.producerLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plotLocalId => $composableBuilder(
    column: $table.plotLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ProductionBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductionBatchesTable,
          ProductionBatchLocal,
          $$ProductionBatchesTableFilterComposer,
          $$ProductionBatchesTableOrderingComposer,
          $$ProductionBatchesTableAnnotationComposer,
          $$ProductionBatchesTableCreateCompanionBuilder,
          $$ProductionBatchesTableUpdateCompanionBuilder,
          (
            ProductionBatchLocal,
            BaseReferences<
              _$AppDatabase,
              $ProductionBatchesTable,
              ProductionBatchLocal
            >,
          ),
          ProductionBatchLocal,
          PrefetchHooks Function()
        > {
  $$ProductionBatchesTableTableManager(
    _$AppDatabase db,
    $ProductionBatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductionBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductionBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductionBatchesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> batchCode = const Value.absent(),
                Value<DateTime> harvestDate = const Value.absent(),
                Value<DateTime> processDate = const Value.absent(),
                Value<double> caneKg = const Value.absent(),
                Value<double> juiceLiters = const Value.absent(),
                Value<double> panelaKg = const Value.absent(),
                Value<double> confitilloKg = const Value.absent(),
                Value<double?> porcentajeExtraccion = const Value.absent(),
                Value<double?> cachazaPercentage = const Value.absent(),
                Value<double> efficiencyPercentage = const Value.absent(),
                Value<double> caneDensity = const Value.absent(),
                Value<int> producerLocalId = const Value.absent(),
                Value<int?> plotLocalId = const Value.absent(),
                Value<String> cooperativeId = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> locationText = const Value.absent(),
                Value<String?> observations = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => ProductionBatchesCompanion(
                id: id,
                batchCode: batchCode,
                harvestDate: harvestDate,
                processDate: processDate,
                caneKg: caneKg,
                juiceLiters: juiceLiters,
                panelaKg: panelaKg,
                confitilloKg: confitilloKg,
                porcentajeExtraccion: porcentajeExtraccion,
                cachazaPercentage: cachazaPercentage,
                efficiencyPercentage: efficiencyPercentage,
                caneDensity: caneDensity,
                producerLocalId: producerLocalId,
                plotLocalId: plotLocalId,
                cooperativeId: cooperativeId,
                latitude: latitude,
                longitude: longitude,
                locationText: locationText,
                observations: observations,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String batchCode,
                required DateTime harvestDate,
                required DateTime processDate,
                required double caneKg,
                required double juiceLiters,
                required double panelaKg,
                required double confitilloKg,
                Value<double?> porcentajeExtraccion = const Value.absent(),
                Value<double?> cachazaPercentage = const Value.absent(),
                required double efficiencyPercentage,
                Value<double> caneDensity = const Value.absent(),
                required int producerLocalId,
                Value<int?> plotLocalId = const Value.absent(),
                required String cooperativeId,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> locationText = const Value.absent(),
                Value<String?> observations = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => ProductionBatchesCompanion.insert(
                id: id,
                batchCode: batchCode,
                harvestDate: harvestDate,
                processDate: processDate,
                caneKg: caneKg,
                juiceLiters: juiceLiters,
                panelaKg: panelaKg,
                confitilloKg: confitilloKg,
                porcentajeExtraccion: porcentajeExtraccion,
                cachazaPercentage: cachazaPercentage,
                efficiencyPercentage: efficiencyPercentage,
                caneDensity: caneDensity,
                producerLocalId: producerLocalId,
                plotLocalId: plotLocalId,
                cooperativeId: cooperativeId,
                latitude: latitude,
                longitude: longitude,
                locationText: locationText,
                observations: observations,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductionBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductionBatchesTable,
      ProductionBatchLocal,
      $$ProductionBatchesTableFilterComposer,
      $$ProductionBatchesTableOrderingComposer,
      $$ProductionBatchesTableAnnotationComposer,
      $$ProductionBatchesTableCreateCompanionBuilder,
      $$ProductionBatchesTableUpdateCompanionBuilder,
      (
        ProductionBatchLocal,
        BaseReferences<
          _$AppDatabase,
          $ProductionBatchesTable,
          ProductionBatchLocal
        >,
      ),
      ProductionBatchLocal,
      PrefetchHooks Function()
    >;
typedef $$BatchTemperaturesTableCreateCompanionBuilder =
    BatchTemperaturesCompanion Function({
      Value<int> id,
      required int productionBatchLocalId,
      required double temperature,
      required int sequenceNumber,
      required String cooperativeId,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$BatchTemperaturesTableUpdateCompanionBuilder =
    BatchTemperaturesCompanion Function({
      Value<int> id,
      Value<int> productionBatchLocalId,
      Value<double> temperature,
      Value<int> sequenceNumber,
      Value<String> cooperativeId,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$BatchTemperaturesTableFilterComposer
    extends Composer<_$AppDatabase, $BatchTemperaturesTable> {
  $$BatchTemperaturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BatchTemperaturesTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchTemperaturesTable> {
  $$BatchTemperaturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchTemperaturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchTemperaturesTable> {
  $$BatchTemperaturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$BatchTemperaturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchTemperaturesTable,
          BatchTemperatureLocal,
          $$BatchTemperaturesTableFilterComposer,
          $$BatchTemperaturesTableOrderingComposer,
          $$BatchTemperaturesTableAnnotationComposer,
          $$BatchTemperaturesTableCreateCompanionBuilder,
          $$BatchTemperaturesTableUpdateCompanionBuilder,
          (
            BatchTemperatureLocal,
            BaseReferences<
              _$AppDatabase,
              $BatchTemperaturesTable,
              BatchTemperatureLocal
            >,
          ),
          BatchTemperatureLocal,
          PrefetchHooks Function()
        > {
  $$BatchTemperaturesTableTableManager(
    _$AppDatabase db,
    $BatchTemperaturesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchTemperaturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchTemperaturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchTemperaturesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productionBatchLocalId = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<int> sequenceNumber = const Value.absent(),
                Value<String> cooperativeId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => BatchTemperaturesCompanion(
                id: id,
                productionBatchLocalId: productionBatchLocalId,
                temperature: temperature,
                sequenceNumber: sequenceNumber,
                cooperativeId: cooperativeId,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productionBatchLocalId,
                required double temperature,
                required int sequenceNumber,
                required String cooperativeId,
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => BatchTemperaturesCompanion.insert(
                id: id,
                productionBatchLocalId: productionBatchLocalId,
                temperature: temperature,
                sequenceNumber: sequenceNumber,
                cooperativeId: cooperativeId,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatchTemperaturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchTemperaturesTable,
      BatchTemperatureLocal,
      $$BatchTemperaturesTableFilterComposer,
      $$BatchTemperaturesTableOrderingComposer,
      $$BatchTemperaturesTableAnnotationComposer,
      $$BatchTemperaturesTableCreateCompanionBuilder,
      $$BatchTemperaturesTableUpdateCompanionBuilder,
      (
        BatchTemperatureLocal,
        BaseReferences<
          _$AppDatabase,
          $BatchTemperaturesTable,
          BatchTemperatureLocal
        >,
      ),
      BatchTemperatureLocal,
      PrefetchHooks Function()
    >;
typedef $$BatchPhControlsTableCreateCompanionBuilder =
    BatchPhControlsCompanion Function({
      Value<int> id,
      required int productionBatchLocalId,
      required DateTime recordDate,
      required String regulatorType,
      required double phInitial,
      required double phFinal,
      Value<double?> regulatorQuantityValue,
      Value<String?> regulatorQuantityUnit,
      Value<double?> brix,
      Value<String?> correctiveAction,
      required String cooperativeId,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$BatchPhControlsTableUpdateCompanionBuilder =
    BatchPhControlsCompanion Function({
      Value<int> id,
      Value<int> productionBatchLocalId,
      Value<DateTime> recordDate,
      Value<String> regulatorType,
      Value<double> phInitial,
      Value<double> phFinal,
      Value<double?> regulatorQuantityValue,
      Value<String?> regulatorQuantityUnit,
      Value<double?> brix,
      Value<String?> correctiveAction,
      Value<String> cooperativeId,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$BatchPhControlsTableFilterComposer
    extends Composer<_$AppDatabase, $BatchPhControlsTable> {
  $$BatchPhControlsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regulatorType => $composableBuilder(
    column: $table.regulatorType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get phInitial => $composableBuilder(
    column: $table.phInitial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get phFinal => $composableBuilder(
    column: $table.phFinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get regulatorQuantityValue => $composableBuilder(
    column: $table.regulatorQuantityValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regulatorQuantityUnit => $composableBuilder(
    column: $table.regulatorQuantityUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get brix => $composableBuilder(
    column: $table.brix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctiveAction => $composableBuilder(
    column: $table.correctiveAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BatchPhControlsTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchPhControlsTable> {
  $$BatchPhControlsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regulatorType => $composableBuilder(
    column: $table.regulatorType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get phInitial => $composableBuilder(
    column: $table.phInitial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get phFinal => $composableBuilder(
    column: $table.phFinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get regulatorQuantityValue => $composableBuilder(
    column: $table.regulatorQuantityValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regulatorQuantityUnit => $composableBuilder(
    column: $table.regulatorQuantityUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get brix => $composableBuilder(
    column: $table.brix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctiveAction => $composableBuilder(
    column: $table.correctiveAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchPhControlsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchPhControlsTable> {
  $$BatchPhControlsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regulatorType => $composableBuilder(
    column: $table.regulatorType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get phInitial =>
      $composableBuilder(column: $table.phInitial, builder: (column) => column);

  GeneratedColumn<double> get phFinal =>
      $composableBuilder(column: $table.phFinal, builder: (column) => column);

  GeneratedColumn<double> get regulatorQuantityValue => $composableBuilder(
    column: $table.regulatorQuantityValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regulatorQuantityUnit => $composableBuilder(
    column: $table.regulatorQuantityUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get brix =>
      $composableBuilder(column: $table.brix, builder: (column) => column);

  GeneratedColumn<String> get correctiveAction => $composableBuilder(
    column: $table.correctiveAction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$BatchPhControlsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchPhControlsTable,
          BatchPhControlLocal,
          $$BatchPhControlsTableFilterComposer,
          $$BatchPhControlsTableOrderingComposer,
          $$BatchPhControlsTableAnnotationComposer,
          $$BatchPhControlsTableCreateCompanionBuilder,
          $$BatchPhControlsTableUpdateCompanionBuilder,
          (
            BatchPhControlLocal,
            BaseReferences<
              _$AppDatabase,
              $BatchPhControlsTable,
              BatchPhControlLocal
            >,
          ),
          BatchPhControlLocal,
          PrefetchHooks Function()
        > {
  $$BatchPhControlsTableTableManager(
    _$AppDatabase db,
    $BatchPhControlsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchPhControlsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchPhControlsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchPhControlsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productionBatchLocalId = const Value.absent(),
                Value<DateTime> recordDate = const Value.absent(),
                Value<String> regulatorType = const Value.absent(),
                Value<double> phInitial = const Value.absent(),
                Value<double> phFinal = const Value.absent(),
                Value<double?> regulatorQuantityValue = const Value.absent(),
                Value<String?> regulatorQuantityUnit = const Value.absent(),
                Value<double?> brix = const Value.absent(),
                Value<String?> correctiveAction = const Value.absent(),
                Value<String> cooperativeId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => BatchPhControlsCompanion(
                id: id,
                productionBatchLocalId: productionBatchLocalId,
                recordDate: recordDate,
                regulatorType: regulatorType,
                phInitial: phInitial,
                phFinal: phFinal,
                regulatorQuantityValue: regulatorQuantityValue,
                regulatorQuantityUnit: regulatorQuantityUnit,
                brix: brix,
                correctiveAction: correctiveAction,
                cooperativeId: cooperativeId,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productionBatchLocalId,
                required DateTime recordDate,
                required String regulatorType,
                required double phInitial,
                required double phFinal,
                Value<double?> regulatorQuantityValue = const Value.absent(),
                Value<String?> regulatorQuantityUnit = const Value.absent(),
                Value<double?> brix = const Value.absent(),
                Value<String?> correctiveAction = const Value.absent(),
                required String cooperativeId,
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => BatchPhControlsCompanion.insert(
                id: id,
                productionBatchLocalId: productionBatchLocalId,
                recordDate: recordDate,
                regulatorType: regulatorType,
                phInitial: phInitial,
                phFinal: phFinal,
                regulatorQuantityValue: regulatorQuantityValue,
                regulatorQuantityUnit: regulatorQuantityUnit,
                brix: brix,
                correctiveAction: correctiveAction,
                cooperativeId: cooperativeId,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatchPhControlsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchPhControlsTable,
      BatchPhControlLocal,
      $$BatchPhControlsTableFilterComposer,
      $$BatchPhControlsTableOrderingComposer,
      $$BatchPhControlsTableAnnotationComposer,
      $$BatchPhControlsTableCreateCompanionBuilder,
      $$BatchPhControlsTableUpdateCompanionBuilder,
      (
        BatchPhControlLocal,
        BaseReferences<
          _$AppDatabase,
          $BatchPhControlsTable,
          BatchPhControlLocal
        >,
      ),
      BatchPhControlLocal,
      PrefetchHooks Function()
    >;
typedef $$ProductionBatchCertsTableCreateCompanionBuilder =
    ProductionBatchCertsCompanion Function({
      Value<int> id,
      required int productionBatchLocalId,
      required String batchCertId,
      required String cooperativeId,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$ProductionBatchCertsTableUpdateCompanionBuilder =
    ProductionBatchCertsCompanion Function({
      Value<int> id,
      Value<int> productionBatchLocalId,
      Value<String> batchCertId,
      Value<String> cooperativeId,
      Value<int> syncStatus,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$ProductionBatchCertsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductionBatchCertsTable> {
  $$ProductionBatchCertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchCertId => $composableBuilder(
    column: $table.batchCertId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductionBatchCertsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductionBatchCertsTable> {
  $$ProductionBatchCertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchCertId => $composableBuilder(
    column: $table.batchCertId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductionBatchCertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductionBatchCertsTable> {
  $$ProductionBatchCertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get productionBatchLocalId => $composableBuilder(
    column: $table.productionBatchLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get batchCertId => $composableBuilder(
    column: $table.batchCertId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cooperativeId => $composableBuilder(
    column: $table.cooperativeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ProductionBatchCertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductionBatchCertsTable,
          ProductionBatchCertLocal,
          $$ProductionBatchCertsTableFilterComposer,
          $$ProductionBatchCertsTableOrderingComposer,
          $$ProductionBatchCertsTableAnnotationComposer,
          $$ProductionBatchCertsTableCreateCompanionBuilder,
          $$ProductionBatchCertsTableUpdateCompanionBuilder,
          (
            ProductionBatchCertLocal,
            BaseReferences<
              _$AppDatabase,
              $ProductionBatchCertsTable,
              ProductionBatchCertLocal
            >,
          ),
          ProductionBatchCertLocal,
          PrefetchHooks Function()
        > {
  $$ProductionBatchCertsTableTableManager(
    _$AppDatabase db,
    $ProductionBatchCertsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductionBatchCertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductionBatchCertsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductionBatchCertsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productionBatchLocalId = const Value.absent(),
                Value<String> batchCertId = const Value.absent(),
                Value<String> cooperativeId = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => ProductionBatchCertsCompanion(
                id: id,
                productionBatchLocalId: productionBatchLocalId,
                batchCertId: batchCertId,
                cooperativeId: cooperativeId,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productionBatchLocalId,
                required String batchCertId,
                required String cooperativeId,
                Value<int> syncStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => ProductionBatchCertsCompanion.insert(
                id: id,
                productionBatchLocalId: productionBatchLocalId,
                batchCertId: batchCertId,
                cooperativeId: cooperativeId,
                syncStatus: syncStatus,
                remoteId: remoteId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductionBatchCertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductionBatchCertsTable,
      ProductionBatchCertLocal,
      $$ProductionBatchCertsTableFilterComposer,
      $$ProductionBatchCertsTableOrderingComposer,
      $$ProductionBatchCertsTableAnnotationComposer,
      $$ProductionBatchCertsTableCreateCompanionBuilder,
      $$ProductionBatchCertsTableUpdateCompanionBuilder,
      (
        ProductionBatchCertLocal,
        BaseReferences<
          _$AppDatabase,
          $ProductionBatchCertsTable,
          ProductionBatchCertLocal
        >,
      ),
      ProductionBatchCertLocal,
      PrefetchHooks Function()
    >;
typedef $$BatchCertsTableCreateCompanionBuilder =
    BatchCertsCompanion Function({
      required String id,
      required String name,
      Value<String?> exclusionGroupId,
      required bool isDefault,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$BatchCertsTableUpdateCompanionBuilder =
    BatchCertsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> exclusionGroupId,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$BatchCertsTableFilterComposer
    extends Composer<_$AppDatabase, $BatchCertsTable> {
  $$BatchCertsTableFilterComposer({
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

  ColumnFilters<String> get exclusionGroupId => $composableBuilder(
    column: $table.exclusionGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BatchCertsTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchCertsTable> {
  $$BatchCertsTableOrderingComposer({
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

  ColumnOrderings<String> get exclusionGroupId => $composableBuilder(
    column: $table.exclusionGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchCertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchCertsTable> {
  $$BatchCertsTableAnnotationComposer({
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

  GeneratedColumn<String> get exclusionGroupId => $composableBuilder(
    column: $table.exclusionGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$BatchCertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchCertsTable,
          BatchCertLocal,
          $$BatchCertsTableFilterComposer,
          $$BatchCertsTableOrderingComposer,
          $$BatchCertsTableAnnotationComposer,
          $$BatchCertsTableCreateCompanionBuilder,
          $$BatchCertsTableUpdateCompanionBuilder,
          (
            BatchCertLocal,
            BaseReferences<_$AppDatabase, $BatchCertsTable, BatchCertLocal>,
          ),
          BatchCertLocal,
          PrefetchHooks Function()
        > {
  $$BatchCertsTableTableManager(_$AppDatabase db, $BatchCertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchCertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchCertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchCertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> exclusionGroupId = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchCertsCompanion(
                id: id,
                name: name,
                exclusionGroupId: exclusionGroupId,
                isDefault: isDefault,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> exclusionGroupId = const Value.absent(),
                required bool isDefault,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchCertsCompanion.insert(
                id: id,
                name: name,
                exclusionGroupId: exclusionGroupId,
                isDefault: isDefault,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatchCertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchCertsTable,
      BatchCertLocal,
      $$BatchCertsTableFilterComposer,
      $$BatchCertsTableOrderingComposer,
      $$BatchCertsTableAnnotationComposer,
      $$BatchCertsTableCreateCompanionBuilder,
      $$BatchCertsTableUpdateCompanionBuilder,
      (
        BatchCertLocal,
        BaseReferences<_$AppDatabase, $BatchCertsTable, BatchCertLocal>,
      ),
      BatchCertLocal,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProducersTableTableManager get producers =>
      $$ProducersTableTableManager(_db, _db.producers);
  $$PlotsTableTableManager get plots =>
      $$PlotsTableTableManager(_db, _db.plots);
  $$CoopModulesTableTableManager get coopModules =>
      $$CoopModulesTableTableManager(_db, _db.coopModules);
  $$ProductionBatchesTableTableManager get productionBatches =>
      $$ProductionBatchesTableTableManager(_db, _db.productionBatches);
  $$BatchTemperaturesTableTableManager get batchTemperatures =>
      $$BatchTemperaturesTableTableManager(_db, _db.batchTemperatures);
  $$BatchPhControlsTableTableManager get batchPhControls =>
      $$BatchPhControlsTableTableManager(_db, _db.batchPhControls);
  $$ProductionBatchCertsTableTableManager get productionBatchCerts =>
      $$ProductionBatchCertsTableTableManager(_db, _db.productionBatchCerts);
  $$BatchCertsTableTableManager get batchCerts =>
      $$BatchCertsTableTableManager(_db, _db.batchCerts);
}
