// dart format width=80
import 'dart:typed_data' as i2;
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Sessions extends Table with TableInfo<Sessions, SessionsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Sessions(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> outcomeJson = GeneratedColumn<String>(
    'outcome_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    startedAt,
    endedAt,
    outcomeJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      outcomeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_json'],
      ),
    );
  }

  @override
  Sessions createAlias(String alias) {
    return Sessions(attachedDatabase, alias);
  }
}

class SessionsData extends DataClass implements Insertable<SessionsData> {
  final int id;
  final String mode;
  final int startedAt;
  final int? endedAt;
  final String? outcomeJson;
  const SessionsData({
    required this.id,
    required this.mode,
    required this.startedAt,
    this.endedAt,
    this.outcomeJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mode'] = Variable<String>(mode);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    if (!nullToAbsent || outcomeJson != null) {
      map['outcome_json'] = Variable<String>(outcomeJson);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      mode: Value(mode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      outcomeJson: outcomeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(outcomeJson),
    );
  }

  factory SessionsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionsData(
      id: serializer.fromJson<int>(json['id']),
      mode: serializer.fromJson<String>(json['mode']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      outcomeJson: serializer.fromJson<String?>(json['outcomeJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mode': serializer.toJson<String>(mode),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'outcomeJson': serializer.toJson<String?>(outcomeJson),
    };
  }

  SessionsData copyWith({
    int? id,
    String? mode,
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    Value<String?> outcomeJson = const Value.absent(),
  }) => SessionsData(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    outcomeJson: outcomeJson.present ? outcomeJson.value : this.outcomeJson,
  );
  SessionsData copyWithCompanion(SessionsCompanion data) {
    return SessionsData(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      outcomeJson: data.outcomeJson.present
          ? data.outcomeJson.value
          : this.outcomeJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionsData(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('outcomeJson: $outcomeJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mode, startedAt, endedAt, outcomeJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionsData &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.outcomeJson == this.outcomeJson);
}

class SessionsCompanion extends UpdateCompanion<SessionsData> {
  final Value<int> id;
  final Value<String> mode;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<String?> outcomeJson;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.outcomeJson = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String mode,
    required int startedAt,
    this.endedAt = const Value.absent(),
    this.outcomeJson = const Value.absent(),
  }) : mode = Value(mode),
       startedAt = Value(startedAt);
  static Insertable<SessionsData> custom({
    Expression<int>? id,
    Expression<String>? mode,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<String>? outcomeJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (outcomeJson != null) 'outcome_json': outcomeJson,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? mode,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<String?>? outcomeJson,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      outcomeJson: outcomeJson ?? this.outcomeJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (outcomeJson.present) {
      map['outcome_json'] = Variable<String>(outcomeJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('outcomeJson: $outcomeJson')
          ..write(')'))
        .toString();
  }
}

class MoveEvents extends Table with TableInfo<MoveEvents, MoveEventsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MoveEvents(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  late final GeneratedColumn<String> kindId = GeneratedColumn<String>(
    'kind_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> heuristicTag = GeneratedColumn<String>(
    'heuristic_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
    'latency_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> wasCorrect = GeneratedColumn<bool>(
    'was_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_correct" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<bool> hintRequested = GeneratedColumn<bool>(
    'hint_requested',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hint_requested" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<int> hintStepReached = GeneratedColumn<int>(
    'hint_step_reached',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<bool> contaminatedFlag = GeneratedColumn<bool>(
    'contaminated_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("contaminated_flag" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<bool> idleSoftSignal = GeneratedColumn<bool>(
    'idle_soft_signal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("idle_soft_signal" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<bool> motionSignal = GeneratedColumn<bool>(
    'motion_signal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("motion_signal" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<bool> lifecycleSignal = GeneratedColumn<bool>(
    'lifecycle_signal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("lifecycle_signal" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> chainIndex = GeneratedColumn<int>(
    'chain_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    kindId,
    heuristicTag,
    latencyMs,
    wasCorrect,
    hintRequested,
    hintStepReached,
    contaminatedFlag,
    idleSoftSignal,
    motionSignal,
    lifecycleSignal,
    mode,
    chainIndex,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'move_events';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoveEventsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoveEventsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      kindId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind_id'],
      )!,
      heuristicTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heuristic_tag'],
      )!,
      latencyMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_ms'],
      )!,
      wasCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_correct'],
      )!,
      hintRequested: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hint_requested'],
      )!,
      hintStepReached: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_step_reached'],
      )!,
      contaminatedFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}contaminated_flag'],
      )!,
      idleSoftSignal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}idle_soft_signal'],
      )!,
      motionSignal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}motion_signal'],
      )!,
      lifecycleSignal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}lifecycle_signal'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      chainIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chain_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  MoveEvents createAlias(String alias) {
    return MoveEvents(attachedDatabase, alias);
  }
}

class MoveEventsData extends DataClass implements Insertable<MoveEventsData> {
  final int id;
  final int sessionId;
  final String kindId;
  final String heuristicTag;
  final int latencyMs;
  final bool wasCorrect;
  final bool hintRequested;
  final int hintStepReached;
  final bool contaminatedFlag;
  final bool idleSoftSignal;
  final bool motionSignal;
  final bool lifecycleSignal;
  final String mode;
  final int chainIndex;
  final int createdAt;
  const MoveEventsData({
    required this.id,
    required this.sessionId,
    required this.kindId,
    required this.heuristicTag,
    required this.latencyMs,
    required this.wasCorrect,
    required this.hintRequested,
    required this.hintStepReached,
    required this.contaminatedFlag,
    required this.idleSoftSignal,
    required this.motionSignal,
    required this.lifecycleSignal,
    required this.mode,
    required this.chainIndex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['kind_id'] = Variable<String>(kindId);
    map['heuristic_tag'] = Variable<String>(heuristicTag);
    map['latency_ms'] = Variable<int>(latencyMs);
    map['was_correct'] = Variable<bool>(wasCorrect);
    map['hint_requested'] = Variable<bool>(hintRequested);
    map['hint_step_reached'] = Variable<int>(hintStepReached);
    map['contaminated_flag'] = Variable<bool>(contaminatedFlag);
    map['idle_soft_signal'] = Variable<bool>(idleSoftSignal);
    map['motion_signal'] = Variable<bool>(motionSignal);
    map['lifecycle_signal'] = Variable<bool>(lifecycleSignal);
    map['mode'] = Variable<String>(mode);
    map['chain_index'] = Variable<int>(chainIndex);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MoveEventsCompanion toCompanion(bool nullToAbsent) {
    return MoveEventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      kindId: Value(kindId),
      heuristicTag: Value(heuristicTag),
      latencyMs: Value(latencyMs),
      wasCorrect: Value(wasCorrect),
      hintRequested: Value(hintRequested),
      hintStepReached: Value(hintStepReached),
      contaminatedFlag: Value(contaminatedFlag),
      idleSoftSignal: Value(idleSoftSignal),
      motionSignal: Value(motionSignal),
      lifecycleSignal: Value(lifecycleSignal),
      mode: Value(mode),
      chainIndex: Value(chainIndex),
      createdAt: Value(createdAt),
    );
  }

  factory MoveEventsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoveEventsData(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      kindId: serializer.fromJson<String>(json['kindId']),
      heuristicTag: serializer.fromJson<String>(json['heuristicTag']),
      latencyMs: serializer.fromJson<int>(json['latencyMs']),
      wasCorrect: serializer.fromJson<bool>(json['wasCorrect']),
      hintRequested: serializer.fromJson<bool>(json['hintRequested']),
      hintStepReached: serializer.fromJson<int>(json['hintStepReached']),
      contaminatedFlag: serializer.fromJson<bool>(json['contaminatedFlag']),
      idleSoftSignal: serializer.fromJson<bool>(json['idleSoftSignal']),
      motionSignal: serializer.fromJson<bool>(json['motionSignal']),
      lifecycleSignal: serializer.fromJson<bool>(json['lifecycleSignal']),
      mode: serializer.fromJson<String>(json['mode']),
      chainIndex: serializer.fromJson<int>(json['chainIndex']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'kindId': serializer.toJson<String>(kindId),
      'heuristicTag': serializer.toJson<String>(heuristicTag),
      'latencyMs': serializer.toJson<int>(latencyMs),
      'wasCorrect': serializer.toJson<bool>(wasCorrect),
      'hintRequested': serializer.toJson<bool>(hintRequested),
      'hintStepReached': serializer.toJson<int>(hintStepReached),
      'contaminatedFlag': serializer.toJson<bool>(contaminatedFlag),
      'idleSoftSignal': serializer.toJson<bool>(idleSoftSignal),
      'motionSignal': serializer.toJson<bool>(motionSignal),
      'lifecycleSignal': serializer.toJson<bool>(lifecycleSignal),
      'mode': serializer.toJson<String>(mode),
      'chainIndex': serializer.toJson<int>(chainIndex),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  MoveEventsData copyWith({
    int? id,
    int? sessionId,
    String? kindId,
    String? heuristicTag,
    int? latencyMs,
    bool? wasCorrect,
    bool? hintRequested,
    int? hintStepReached,
    bool? contaminatedFlag,
    bool? idleSoftSignal,
    bool? motionSignal,
    bool? lifecycleSignal,
    String? mode,
    int? chainIndex,
    int? createdAt,
  }) => MoveEventsData(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    kindId: kindId ?? this.kindId,
    heuristicTag: heuristicTag ?? this.heuristicTag,
    latencyMs: latencyMs ?? this.latencyMs,
    wasCorrect: wasCorrect ?? this.wasCorrect,
    hintRequested: hintRequested ?? this.hintRequested,
    hintStepReached: hintStepReached ?? this.hintStepReached,
    contaminatedFlag: contaminatedFlag ?? this.contaminatedFlag,
    idleSoftSignal: idleSoftSignal ?? this.idleSoftSignal,
    motionSignal: motionSignal ?? this.motionSignal,
    lifecycleSignal: lifecycleSignal ?? this.lifecycleSignal,
    mode: mode ?? this.mode,
    chainIndex: chainIndex ?? this.chainIndex,
    createdAt: createdAt ?? this.createdAt,
  );
  MoveEventsData copyWithCompanion(MoveEventsCompanion data) {
    return MoveEventsData(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      kindId: data.kindId.present ? data.kindId.value : this.kindId,
      heuristicTag: data.heuristicTag.present
          ? data.heuristicTag.value
          : this.heuristicTag,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      wasCorrect: data.wasCorrect.present
          ? data.wasCorrect.value
          : this.wasCorrect,
      hintRequested: data.hintRequested.present
          ? data.hintRequested.value
          : this.hintRequested,
      hintStepReached: data.hintStepReached.present
          ? data.hintStepReached.value
          : this.hintStepReached,
      contaminatedFlag: data.contaminatedFlag.present
          ? data.contaminatedFlag.value
          : this.contaminatedFlag,
      idleSoftSignal: data.idleSoftSignal.present
          ? data.idleSoftSignal.value
          : this.idleSoftSignal,
      motionSignal: data.motionSignal.present
          ? data.motionSignal.value
          : this.motionSignal,
      lifecycleSignal: data.lifecycleSignal.present
          ? data.lifecycleSignal.value
          : this.lifecycleSignal,
      mode: data.mode.present ? data.mode.value : this.mode,
      chainIndex: data.chainIndex.present
          ? data.chainIndex.value
          : this.chainIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoveEventsData(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kindId: $kindId, ')
          ..write('heuristicTag: $heuristicTag, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('hintRequested: $hintRequested, ')
          ..write('hintStepReached: $hintStepReached, ')
          ..write('contaminatedFlag: $contaminatedFlag, ')
          ..write('idleSoftSignal: $idleSoftSignal, ')
          ..write('motionSignal: $motionSignal, ')
          ..write('lifecycleSignal: $lifecycleSignal, ')
          ..write('mode: $mode, ')
          ..write('chainIndex: $chainIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    kindId,
    heuristicTag,
    latencyMs,
    wasCorrect,
    hintRequested,
    hintStepReached,
    contaminatedFlag,
    idleSoftSignal,
    motionSignal,
    lifecycleSignal,
    mode,
    chainIndex,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoveEventsData &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.kindId == this.kindId &&
          other.heuristicTag == this.heuristicTag &&
          other.latencyMs == this.latencyMs &&
          other.wasCorrect == this.wasCorrect &&
          other.hintRequested == this.hintRequested &&
          other.hintStepReached == this.hintStepReached &&
          other.contaminatedFlag == this.contaminatedFlag &&
          other.idleSoftSignal == this.idleSoftSignal &&
          other.motionSignal == this.motionSignal &&
          other.lifecycleSignal == this.lifecycleSignal &&
          other.mode == this.mode &&
          other.chainIndex == this.chainIndex &&
          other.createdAt == this.createdAt);
}

class MoveEventsCompanion extends UpdateCompanion<MoveEventsData> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> kindId;
  final Value<String> heuristicTag;
  final Value<int> latencyMs;
  final Value<bool> wasCorrect;
  final Value<bool> hintRequested;
  final Value<int> hintStepReached;
  final Value<bool> contaminatedFlag;
  final Value<bool> idleSoftSignal;
  final Value<bool> motionSignal;
  final Value<bool> lifecycleSignal;
  final Value<String> mode;
  final Value<int> chainIndex;
  final Value<int> createdAt;
  const MoveEventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.kindId = const Value.absent(),
    this.heuristicTag = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.wasCorrect = const Value.absent(),
    this.hintRequested = const Value.absent(),
    this.hintStepReached = const Value.absent(),
    this.contaminatedFlag = const Value.absent(),
    this.idleSoftSignal = const Value.absent(),
    this.motionSignal = const Value.absent(),
    this.lifecycleSignal = const Value.absent(),
    this.mode = const Value.absent(),
    this.chainIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MoveEventsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String kindId,
    required String heuristicTag,
    required int latencyMs,
    required bool wasCorrect,
    required bool hintRequested,
    this.hintStepReached = const Value.absent(),
    required bool contaminatedFlag,
    required bool idleSoftSignal,
    required bool motionSignal,
    required bool lifecycleSignal,
    required String mode,
    this.chainIndex = const Value.absent(),
    required int createdAt,
  }) : sessionId = Value(sessionId),
       kindId = Value(kindId),
       heuristicTag = Value(heuristicTag),
       latencyMs = Value(latencyMs),
       wasCorrect = Value(wasCorrect),
       hintRequested = Value(hintRequested),
       contaminatedFlag = Value(contaminatedFlag),
       idleSoftSignal = Value(idleSoftSignal),
       motionSignal = Value(motionSignal),
       lifecycleSignal = Value(lifecycleSignal),
       mode = Value(mode),
       createdAt = Value(createdAt);
  static Insertable<MoveEventsData> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? kindId,
    Expression<String>? heuristicTag,
    Expression<int>? latencyMs,
    Expression<bool>? wasCorrect,
    Expression<bool>? hintRequested,
    Expression<int>? hintStepReached,
    Expression<bool>? contaminatedFlag,
    Expression<bool>? idleSoftSignal,
    Expression<bool>? motionSignal,
    Expression<bool>? lifecycleSignal,
    Expression<String>? mode,
    Expression<int>? chainIndex,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (kindId != null) 'kind_id': kindId,
      if (heuristicTag != null) 'heuristic_tag': heuristicTag,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (wasCorrect != null) 'was_correct': wasCorrect,
      if (hintRequested != null) 'hint_requested': hintRequested,
      if (hintStepReached != null) 'hint_step_reached': hintStepReached,
      if (contaminatedFlag != null) 'contaminated_flag': contaminatedFlag,
      if (idleSoftSignal != null) 'idle_soft_signal': idleSoftSignal,
      if (motionSignal != null) 'motion_signal': motionSignal,
      if (lifecycleSignal != null) 'lifecycle_signal': lifecycleSignal,
      if (mode != null) 'mode': mode,
      if (chainIndex != null) 'chain_index': chainIndex,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MoveEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? kindId,
    Value<String>? heuristicTag,
    Value<int>? latencyMs,
    Value<bool>? wasCorrect,
    Value<bool>? hintRequested,
    Value<int>? hintStepReached,
    Value<bool>? contaminatedFlag,
    Value<bool>? idleSoftSignal,
    Value<bool>? motionSignal,
    Value<bool>? lifecycleSignal,
    Value<String>? mode,
    Value<int>? chainIndex,
    Value<int>? createdAt,
  }) {
    return MoveEventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      kindId: kindId ?? this.kindId,
      heuristicTag: heuristicTag ?? this.heuristicTag,
      latencyMs: latencyMs ?? this.latencyMs,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      hintRequested: hintRequested ?? this.hintRequested,
      hintStepReached: hintStepReached ?? this.hintStepReached,
      contaminatedFlag: contaminatedFlag ?? this.contaminatedFlag,
      idleSoftSignal: idleSoftSignal ?? this.idleSoftSignal,
      motionSignal: motionSignal ?? this.motionSignal,
      lifecycleSignal: lifecycleSignal ?? this.lifecycleSignal,
      mode: mode ?? this.mode,
      chainIndex: chainIndex ?? this.chainIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (kindId.present) {
      map['kind_id'] = Variable<String>(kindId.value);
    }
    if (heuristicTag.present) {
      map['heuristic_tag'] = Variable<String>(heuristicTag.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (wasCorrect.present) {
      map['was_correct'] = Variable<bool>(wasCorrect.value);
    }
    if (hintRequested.present) {
      map['hint_requested'] = Variable<bool>(hintRequested.value);
    }
    if (hintStepReached.present) {
      map['hint_step_reached'] = Variable<int>(hintStepReached.value);
    }
    if (contaminatedFlag.present) {
      map['contaminated_flag'] = Variable<bool>(contaminatedFlag.value);
    }
    if (idleSoftSignal.present) {
      map['idle_soft_signal'] = Variable<bool>(idleSoftSignal.value);
    }
    if (motionSignal.present) {
      map['motion_signal'] = Variable<bool>(motionSignal.value);
    }
    if (lifecycleSignal.present) {
      map['lifecycle_signal'] = Variable<bool>(lifecycleSignal.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (chainIndex.present) {
      map['chain_index'] = Variable<int>(chainIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoveEventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kindId: $kindId, ')
          ..write('heuristicTag: $heuristicTag, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('hintRequested: $hintRequested, ')
          ..write('hintStepReached: $hintStepReached, ')
          ..write('contaminatedFlag: $contaminatedFlag, ')
          ..write('idleSoftSignal: $idleSoftSignal, ')
          ..write('motionSignal: $motionSignal, ')
          ..write('lifecycleSignal: $lifecycleSignal, ')
          ..write('mode: $mode, ')
          ..write('chainIndex: $chainIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class MasteryState extends Table
    with TableInfo<MasteryState, MasteryStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MasteryState(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> kindId = GeneratedColumn<String>(
    'kind_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> heuristicTag = GeneratedColumn<String>(
    'heuristic_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> eventCount = GeneratedColumn<int>(
    'event_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<double> ewmaZ = GeneratedColumn<double>(
    'ewma_z',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0.0'),
  );
  late final GeneratedColumn<int> latencyP25Ms = GeneratedColumn<int>(
    'latency_p25_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> latencyMedianMs = GeneratedColumn<int>(
    'latency_median_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> latencyP75Ms = GeneratedColumn<int>(
    'latency_p75_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<double> errorRate = GeneratedColumn<double>(
    'error_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0.0'),
  );
  late final GeneratedColumn<double> hintRate = GeneratedColumn<double>(
    'hint_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0.0'),
  );
  late final GeneratedColumn<String> hintStepCountsJson =
      GeneratedColumn<String>(
        'hint_step_counts_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const CustomExpression('\'{}\''),
      );
  late final GeneratedColumn<int> lastUpdatedAt = GeneratedColumn<int>(
    'last_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> isCalibrating = GeneratedColumn<bool>(
    'is_calibrating',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_calibrating" IN (0, 1))',
    ),
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    kindId,
    heuristicTag,
    eventCount,
    ewmaZ,
    latencyP25Ms,
    latencyMedianMs,
    latencyP75Ms,
    errorRate,
    hintRate,
    hintStepCountsJson,
    lastUpdatedAt,
    isCalibrating,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mastery_state';
  @override
  Set<GeneratedColumn> get $primaryKey => {kindId, heuristicTag};
  @override
  MasteryStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasteryStateData(
      kindId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind_id'],
      )!,
      heuristicTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heuristic_tag'],
      )!,
      eventCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_count'],
      )!,
      ewmaZ: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ewma_z'],
      )!,
      latencyP25Ms: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_p25_ms'],
      ),
      latencyMedianMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_median_ms'],
      ),
      latencyP75Ms: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_p75_ms'],
      ),
      errorRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}error_rate'],
      )!,
      hintRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hint_rate'],
      )!,
      hintStepCountsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hint_step_counts_json'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_updated_at'],
      )!,
      isCalibrating: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_calibrating'],
      )!,
    );
  }

  @override
  MasteryState createAlias(String alias) {
    return MasteryState(attachedDatabase, alias);
  }
}

class MasteryStateData extends DataClass
    implements Insertable<MasteryStateData> {
  final String kindId;
  final String heuristicTag;
  final int eventCount;
  final double ewmaZ;
  final int? latencyP25Ms;
  final int? latencyMedianMs;
  final int? latencyP75Ms;
  final double errorRate;
  final double hintRate;
  final String hintStepCountsJson;
  final int lastUpdatedAt;
  final bool isCalibrating;
  const MasteryStateData({
    required this.kindId,
    required this.heuristicTag,
    required this.eventCount,
    required this.ewmaZ,
    this.latencyP25Ms,
    this.latencyMedianMs,
    this.latencyP75Ms,
    required this.errorRate,
    required this.hintRate,
    required this.hintStepCountsJson,
    required this.lastUpdatedAt,
    required this.isCalibrating,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind_id'] = Variable<String>(kindId);
    map['heuristic_tag'] = Variable<String>(heuristicTag);
    map['event_count'] = Variable<int>(eventCount);
    map['ewma_z'] = Variable<double>(ewmaZ);
    if (!nullToAbsent || latencyP25Ms != null) {
      map['latency_p25_ms'] = Variable<int>(latencyP25Ms);
    }
    if (!nullToAbsent || latencyMedianMs != null) {
      map['latency_median_ms'] = Variable<int>(latencyMedianMs);
    }
    if (!nullToAbsent || latencyP75Ms != null) {
      map['latency_p75_ms'] = Variable<int>(latencyP75Ms);
    }
    map['error_rate'] = Variable<double>(errorRate);
    map['hint_rate'] = Variable<double>(hintRate);
    map['hint_step_counts_json'] = Variable<String>(hintStepCountsJson);
    map['last_updated_at'] = Variable<int>(lastUpdatedAt);
    map['is_calibrating'] = Variable<bool>(isCalibrating);
    return map;
  }

  MasteryStateCompanion toCompanion(bool nullToAbsent) {
    return MasteryStateCompanion(
      kindId: Value(kindId),
      heuristicTag: Value(heuristicTag),
      eventCount: Value(eventCount),
      ewmaZ: Value(ewmaZ),
      latencyP25Ms: latencyP25Ms == null && nullToAbsent
          ? const Value.absent()
          : Value(latencyP25Ms),
      latencyMedianMs: latencyMedianMs == null && nullToAbsent
          ? const Value.absent()
          : Value(latencyMedianMs),
      latencyP75Ms: latencyP75Ms == null && nullToAbsent
          ? const Value.absent()
          : Value(latencyP75Ms),
      errorRate: Value(errorRate),
      hintRate: Value(hintRate),
      hintStepCountsJson: Value(hintStepCountsJson),
      lastUpdatedAt: Value(lastUpdatedAt),
      isCalibrating: Value(isCalibrating),
    );
  }

  factory MasteryStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasteryStateData(
      kindId: serializer.fromJson<String>(json['kindId']),
      heuristicTag: serializer.fromJson<String>(json['heuristicTag']),
      eventCount: serializer.fromJson<int>(json['eventCount']),
      ewmaZ: serializer.fromJson<double>(json['ewmaZ']),
      latencyP25Ms: serializer.fromJson<int?>(json['latencyP25Ms']),
      latencyMedianMs: serializer.fromJson<int?>(json['latencyMedianMs']),
      latencyP75Ms: serializer.fromJson<int?>(json['latencyP75Ms']),
      errorRate: serializer.fromJson<double>(json['errorRate']),
      hintRate: serializer.fromJson<double>(json['hintRate']),
      hintStepCountsJson: serializer.fromJson<String>(
        json['hintStepCountsJson'],
      ),
      lastUpdatedAt: serializer.fromJson<int>(json['lastUpdatedAt']),
      isCalibrating: serializer.fromJson<bool>(json['isCalibrating']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kindId': serializer.toJson<String>(kindId),
      'heuristicTag': serializer.toJson<String>(heuristicTag),
      'eventCount': serializer.toJson<int>(eventCount),
      'ewmaZ': serializer.toJson<double>(ewmaZ),
      'latencyP25Ms': serializer.toJson<int?>(latencyP25Ms),
      'latencyMedianMs': serializer.toJson<int?>(latencyMedianMs),
      'latencyP75Ms': serializer.toJson<int?>(latencyP75Ms),
      'errorRate': serializer.toJson<double>(errorRate),
      'hintRate': serializer.toJson<double>(hintRate),
      'hintStepCountsJson': serializer.toJson<String>(hintStepCountsJson),
      'lastUpdatedAt': serializer.toJson<int>(lastUpdatedAt),
      'isCalibrating': serializer.toJson<bool>(isCalibrating),
    };
  }

  MasteryStateData copyWith({
    String? kindId,
    String? heuristicTag,
    int? eventCount,
    double? ewmaZ,
    Value<int?> latencyP25Ms = const Value.absent(),
    Value<int?> latencyMedianMs = const Value.absent(),
    Value<int?> latencyP75Ms = const Value.absent(),
    double? errorRate,
    double? hintRate,
    String? hintStepCountsJson,
    int? lastUpdatedAt,
    bool? isCalibrating,
  }) => MasteryStateData(
    kindId: kindId ?? this.kindId,
    heuristicTag: heuristicTag ?? this.heuristicTag,
    eventCount: eventCount ?? this.eventCount,
    ewmaZ: ewmaZ ?? this.ewmaZ,
    latencyP25Ms: latencyP25Ms.present ? latencyP25Ms.value : this.latencyP25Ms,
    latencyMedianMs: latencyMedianMs.present
        ? latencyMedianMs.value
        : this.latencyMedianMs,
    latencyP75Ms: latencyP75Ms.present ? latencyP75Ms.value : this.latencyP75Ms,
    errorRate: errorRate ?? this.errorRate,
    hintRate: hintRate ?? this.hintRate,
    hintStepCountsJson: hintStepCountsJson ?? this.hintStepCountsJson,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    isCalibrating: isCalibrating ?? this.isCalibrating,
  );
  MasteryStateData copyWithCompanion(MasteryStateCompanion data) {
    return MasteryStateData(
      kindId: data.kindId.present ? data.kindId.value : this.kindId,
      heuristicTag: data.heuristicTag.present
          ? data.heuristicTag.value
          : this.heuristicTag,
      eventCount: data.eventCount.present
          ? data.eventCount.value
          : this.eventCount,
      ewmaZ: data.ewmaZ.present ? data.ewmaZ.value : this.ewmaZ,
      latencyP25Ms: data.latencyP25Ms.present
          ? data.latencyP25Ms.value
          : this.latencyP25Ms,
      latencyMedianMs: data.latencyMedianMs.present
          ? data.latencyMedianMs.value
          : this.latencyMedianMs,
      latencyP75Ms: data.latencyP75Ms.present
          ? data.latencyP75Ms.value
          : this.latencyP75Ms,
      errorRate: data.errorRate.present ? data.errorRate.value : this.errorRate,
      hintRate: data.hintRate.present ? data.hintRate.value : this.hintRate,
      hintStepCountsJson: data.hintStepCountsJson.present
          ? data.hintStepCountsJson.value
          : this.hintStepCountsJson,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
      isCalibrating: data.isCalibrating.present
          ? data.isCalibrating.value
          : this.isCalibrating,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasteryStateData(')
          ..write('kindId: $kindId, ')
          ..write('heuristicTag: $heuristicTag, ')
          ..write('eventCount: $eventCount, ')
          ..write('ewmaZ: $ewmaZ, ')
          ..write('latencyP25Ms: $latencyP25Ms, ')
          ..write('latencyMedianMs: $latencyMedianMs, ')
          ..write('latencyP75Ms: $latencyP75Ms, ')
          ..write('errorRate: $errorRate, ')
          ..write('hintRate: $hintRate, ')
          ..write('hintStepCountsJson: $hintStepCountsJson, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('isCalibrating: $isCalibrating')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kindId,
    heuristicTag,
    eventCount,
    ewmaZ,
    latencyP25Ms,
    latencyMedianMs,
    latencyP75Ms,
    errorRate,
    hintRate,
    hintStepCountsJson,
    lastUpdatedAt,
    isCalibrating,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasteryStateData &&
          other.kindId == this.kindId &&
          other.heuristicTag == this.heuristicTag &&
          other.eventCount == this.eventCount &&
          other.ewmaZ == this.ewmaZ &&
          other.latencyP25Ms == this.latencyP25Ms &&
          other.latencyMedianMs == this.latencyMedianMs &&
          other.latencyP75Ms == this.latencyP75Ms &&
          other.errorRate == this.errorRate &&
          other.hintRate == this.hintRate &&
          other.hintStepCountsJson == this.hintStepCountsJson &&
          other.lastUpdatedAt == this.lastUpdatedAt &&
          other.isCalibrating == this.isCalibrating);
}

class MasteryStateCompanion extends UpdateCompanion<MasteryStateData> {
  final Value<String> kindId;
  final Value<String> heuristicTag;
  final Value<int> eventCount;
  final Value<double> ewmaZ;
  final Value<int?> latencyP25Ms;
  final Value<int?> latencyMedianMs;
  final Value<int?> latencyP75Ms;
  final Value<double> errorRate;
  final Value<double> hintRate;
  final Value<String> hintStepCountsJson;
  final Value<int> lastUpdatedAt;
  final Value<bool> isCalibrating;
  final Value<int> rowid;
  const MasteryStateCompanion({
    this.kindId = const Value.absent(),
    this.heuristicTag = const Value.absent(),
    this.eventCount = const Value.absent(),
    this.ewmaZ = const Value.absent(),
    this.latencyP25Ms = const Value.absent(),
    this.latencyMedianMs = const Value.absent(),
    this.latencyP75Ms = const Value.absent(),
    this.errorRate = const Value.absent(),
    this.hintRate = const Value.absent(),
    this.hintStepCountsJson = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.isCalibrating = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MasteryStateCompanion.insert({
    required String kindId,
    required String heuristicTag,
    this.eventCount = const Value.absent(),
    this.ewmaZ = const Value.absent(),
    this.latencyP25Ms = const Value.absent(),
    this.latencyMedianMs = const Value.absent(),
    this.latencyP75Ms = const Value.absent(),
    this.errorRate = const Value.absent(),
    this.hintRate = const Value.absent(),
    this.hintStepCountsJson = const Value.absent(),
    required int lastUpdatedAt,
    this.isCalibrating = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kindId = Value(kindId),
       heuristicTag = Value(heuristicTag),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<MasteryStateData> custom({
    Expression<String>? kindId,
    Expression<String>? heuristicTag,
    Expression<int>? eventCount,
    Expression<double>? ewmaZ,
    Expression<int>? latencyP25Ms,
    Expression<int>? latencyMedianMs,
    Expression<int>? latencyP75Ms,
    Expression<double>? errorRate,
    Expression<double>? hintRate,
    Expression<String>? hintStepCountsJson,
    Expression<int>? lastUpdatedAt,
    Expression<bool>? isCalibrating,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kindId != null) 'kind_id': kindId,
      if (heuristicTag != null) 'heuristic_tag': heuristicTag,
      if (eventCount != null) 'event_count': eventCount,
      if (ewmaZ != null) 'ewma_z': ewmaZ,
      if (latencyP25Ms != null) 'latency_p25_ms': latencyP25Ms,
      if (latencyMedianMs != null) 'latency_median_ms': latencyMedianMs,
      if (latencyP75Ms != null) 'latency_p75_ms': latencyP75Ms,
      if (errorRate != null) 'error_rate': errorRate,
      if (hintRate != null) 'hint_rate': hintRate,
      if (hintStepCountsJson != null)
        'hint_step_counts_json': hintStepCountsJson,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (isCalibrating != null) 'is_calibrating': isCalibrating,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MasteryStateCompanion copyWith({
    Value<String>? kindId,
    Value<String>? heuristicTag,
    Value<int>? eventCount,
    Value<double>? ewmaZ,
    Value<int?>? latencyP25Ms,
    Value<int?>? latencyMedianMs,
    Value<int?>? latencyP75Ms,
    Value<double>? errorRate,
    Value<double>? hintRate,
    Value<String>? hintStepCountsJson,
    Value<int>? lastUpdatedAt,
    Value<bool>? isCalibrating,
    Value<int>? rowid,
  }) {
    return MasteryStateCompanion(
      kindId: kindId ?? this.kindId,
      heuristicTag: heuristicTag ?? this.heuristicTag,
      eventCount: eventCount ?? this.eventCount,
      ewmaZ: ewmaZ ?? this.ewmaZ,
      latencyP25Ms: latencyP25Ms ?? this.latencyP25Ms,
      latencyMedianMs: latencyMedianMs ?? this.latencyMedianMs,
      latencyP75Ms: latencyP75Ms ?? this.latencyP75Ms,
      errorRate: errorRate ?? this.errorRate,
      hintRate: hintRate ?? this.hintRate,
      hintStepCountsJson: hintStepCountsJson ?? this.hintStepCountsJson,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isCalibrating: isCalibrating ?? this.isCalibrating,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kindId.present) {
      map['kind_id'] = Variable<String>(kindId.value);
    }
    if (heuristicTag.present) {
      map['heuristic_tag'] = Variable<String>(heuristicTag.value);
    }
    if (eventCount.present) {
      map['event_count'] = Variable<int>(eventCount.value);
    }
    if (ewmaZ.present) {
      map['ewma_z'] = Variable<double>(ewmaZ.value);
    }
    if (latencyP25Ms.present) {
      map['latency_p25_ms'] = Variable<int>(latencyP25Ms.value);
    }
    if (latencyMedianMs.present) {
      map['latency_median_ms'] = Variable<int>(latencyMedianMs.value);
    }
    if (latencyP75Ms.present) {
      map['latency_p75_ms'] = Variable<int>(latencyP75Ms.value);
    }
    if (errorRate.present) {
      map['error_rate'] = Variable<double>(errorRate.value);
    }
    if (hintRate.present) {
      map['hint_rate'] = Variable<double>(hintRate.value);
    }
    if (hintStepCountsJson.present) {
      map['hint_step_counts_json'] = Variable<String>(hintStepCountsJson.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<int>(lastUpdatedAt.value);
    }
    if (isCalibrating.present) {
      map['is_calibrating'] = Variable<bool>(isCalibrating.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MasteryStateCompanion(')
          ..write('kindId: $kindId, ')
          ..write('heuristicTag: $heuristicTag, ')
          ..write('eventCount: $eventCount, ')
          ..write('ewmaZ: $ewmaZ, ')
          ..write('latencyP25Ms: $latencyP25Ms, ')
          ..write('latencyMedianMs: $latencyMedianMs, ')
          ..write('latencyP75Ms: $latencyP75Ms, ')
          ..write('errorRate: $errorRate, ')
          ..write('hintRate: $hintRate, ')
          ..write('hintStepCountsJson: $hintStepCountsJson, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('isCalibrating: $isCalibrating, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FsrsCards extends Table with TableInfo<FsrsCards, FsrsCardsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FsrsCards(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> kindId = GeneratedColumn<String>(
    'kind_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> heuristicTag = GeneratedColumn<String>(
    'heuristic_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<i2.Uint8List> stateBlob =
      GeneratedColumn<i2.Uint8List>(
        'state_blob',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> lastReviewedAt = GeneratedColumn<int>(
    'last_reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    kindId,
    heuristicTag,
    stateBlob,
    dueAt,
    lastReviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fsrs_cards';
  @override
  Set<GeneratedColumn> get $primaryKey => {kindId, heuristicTag};
  @override
  FsrsCardsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FsrsCardsData(
      kindId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind_id'],
      )!,
      heuristicTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heuristic_tag'],
      )!,
      stateBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}state_blob'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reviewed_at'],
      ),
    );
  }

  @override
  FsrsCards createAlias(String alias) {
    return FsrsCards(attachedDatabase, alias);
  }
}

class FsrsCardsData extends DataClass implements Insertable<FsrsCardsData> {
  final String kindId;
  final String heuristicTag;
  final i2.Uint8List stateBlob;
  final int dueAt;
  final int? lastReviewedAt;
  const FsrsCardsData({
    required this.kindId,
    required this.heuristicTag,
    required this.stateBlob,
    required this.dueAt,
    this.lastReviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind_id'] = Variable<String>(kindId);
    map['heuristic_tag'] = Variable<String>(heuristicTag);
    map['state_blob'] = Variable<i2.Uint8List>(stateBlob);
    map['due_at'] = Variable<int>(dueAt);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt);
    }
    return map;
  }

  FsrsCardsCompanion toCompanion(bool nullToAbsent) {
    return FsrsCardsCompanion(
      kindId: Value(kindId),
      heuristicTag: Value(heuristicTag),
      stateBlob: Value(stateBlob),
      dueAt: Value(dueAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory FsrsCardsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FsrsCardsData(
      kindId: serializer.fromJson<String>(json['kindId']),
      heuristicTag: serializer.fromJson<String>(json['heuristicTag']),
      stateBlob: serializer.fromJson<i2.Uint8List>(json['stateBlob']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
      lastReviewedAt: serializer.fromJson<int?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kindId': serializer.toJson<String>(kindId),
      'heuristicTag': serializer.toJson<String>(heuristicTag),
      'stateBlob': serializer.toJson<i2.Uint8List>(stateBlob),
      'dueAt': serializer.toJson<int>(dueAt),
      'lastReviewedAt': serializer.toJson<int?>(lastReviewedAt),
    };
  }

  FsrsCardsData copyWith({
    String? kindId,
    String? heuristicTag,
    i2.Uint8List? stateBlob,
    int? dueAt,
    Value<int?> lastReviewedAt = const Value.absent(),
  }) => FsrsCardsData(
    kindId: kindId ?? this.kindId,
    heuristicTag: heuristicTag ?? this.heuristicTag,
    stateBlob: stateBlob ?? this.stateBlob,
    dueAt: dueAt ?? this.dueAt,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
  );
  FsrsCardsData copyWithCompanion(FsrsCardsCompanion data) {
    return FsrsCardsData(
      kindId: data.kindId.present ? data.kindId.value : this.kindId,
      heuristicTag: data.heuristicTag.present
          ? data.heuristicTag.value
          : this.heuristicTag,
      stateBlob: data.stateBlob.present ? data.stateBlob.value : this.stateBlob,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FsrsCardsData(')
          ..write('kindId: $kindId, ')
          ..write('heuristicTag: $heuristicTag, ')
          ..write('stateBlob: $stateBlob, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kindId,
    heuristicTag,
    $driftBlobEquality.hash(stateBlob),
    dueAt,
    lastReviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FsrsCardsData &&
          other.kindId == this.kindId &&
          other.heuristicTag == this.heuristicTag &&
          $driftBlobEquality.equals(other.stateBlob, this.stateBlob) &&
          other.dueAt == this.dueAt &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class FsrsCardsCompanion extends UpdateCompanion<FsrsCardsData> {
  final Value<String> kindId;
  final Value<String> heuristicTag;
  final Value<i2.Uint8List> stateBlob;
  final Value<int> dueAt;
  final Value<int?> lastReviewedAt;
  final Value<int> rowid;
  const FsrsCardsCompanion({
    this.kindId = const Value.absent(),
    this.heuristicTag = const Value.absent(),
    this.stateBlob = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FsrsCardsCompanion.insert({
    required String kindId,
    required String heuristicTag,
    required i2.Uint8List stateBlob,
    required int dueAt,
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kindId = Value(kindId),
       heuristicTag = Value(heuristicTag),
       stateBlob = Value(stateBlob),
       dueAt = Value(dueAt);
  static Insertable<FsrsCardsData> custom({
    Expression<String>? kindId,
    Expression<String>? heuristicTag,
    Expression<i2.Uint8List>? stateBlob,
    Expression<int>? dueAt,
    Expression<int>? lastReviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kindId != null) 'kind_id': kindId,
      if (heuristicTag != null) 'heuristic_tag': heuristicTag,
      if (stateBlob != null) 'state_blob': stateBlob,
      if (dueAt != null) 'due_at': dueAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FsrsCardsCompanion copyWith({
    Value<String>? kindId,
    Value<String>? heuristicTag,
    Value<i2.Uint8List>? stateBlob,
    Value<int>? dueAt,
    Value<int?>? lastReviewedAt,
    Value<int>? rowid,
  }) {
    return FsrsCardsCompanion(
      kindId: kindId ?? this.kindId,
      heuristicTag: heuristicTag ?? this.heuristicTag,
      stateBlob: stateBlob ?? this.stateBlob,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kindId.present) {
      map['kind_id'] = Variable<String>(kindId.value);
    }
    if (heuristicTag.present) {
      map['heuristic_tag'] = Variable<String>(heuristicTag.value);
    }
    if (stateBlob.present) {
      map['state_blob'] = Variable<i2.Uint8List>(stateBlob.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FsrsCardsCompanion(')
          ..write('kindId: $kindId, ')
          ..write('heuristicTag: $heuristicTag, ')
          ..write('stateBlob: $stateBlob, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV1 extends GeneratedDatabase {
  DatabaseAtV1(QueryExecutor e) : super(e);
  late final Sessions sessions = Sessions(this);
  late final MoveEvents moveEvents = MoveEvents(this);
  late final MasteryState masteryState = MasteryState(this);
  late final FsrsCards fsrsCards = FsrsCards(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    moveEvents,
    masteryState,
    fsrsCards,
  ];
  @override
  int get schemaVersion => 1;
}
