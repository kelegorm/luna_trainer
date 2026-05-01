// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeJsonMeta = const VerificationMeta(
    'outcomeJson',
  );
  @override
  late final GeneratedColumn<String> outcomeJson = GeneratedColumn<String>(
    'outcome_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyBandMeta = const VerificationMeta(
    'difficultyBand',
  );
  @override
  late final GeneratedColumn<int> difficultyBand = GeneratedColumn<int>(
    'difficulty_band',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _userAdjustedMeta = const VerificationMeta(
    'userAdjusted',
  );
  @override
  late final GeneratedColumn<bool> userAdjusted = GeneratedColumn<bool>(
    'user_adjusted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_adjusted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    startedAt,
    endedAt,
    outcomeJson,
    difficultyBand,
    userAdjusted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('outcome_json')) {
      context.handle(
        _outcomeJsonMeta,
        outcomeJson.isAcceptableOrUnknown(
          data['outcome_json']!,
          _outcomeJsonMeta,
        ),
      );
    }
    if (data.containsKey('difficulty_band')) {
      context.handle(
        _difficultyBandMeta,
        difficultyBand.isAcceptableOrUnknown(
          data['difficulty_band']!,
          _difficultyBandMeta,
        ),
      );
    }
    if (data.containsKey('user_adjusted')) {
      context.handle(
        _userAdjustedMeta,
        userAdjusted.isAcceptableOrUnknown(
          data['user_adjusted']!,
          _userAdjustedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
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
      difficultyBand: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty_band'],
      )!,
      userAdjusted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_adjusted'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;

  /// 'full_game' or 'drill'. Stored as text to keep the schema legible
  /// across migrations without enum-renaming hazards.
  final String mode;
  final int startedAt;
  final int? endedAt;

  /// JSON-encoded summary surface (per-heuristic deltas, replay-diff
  /// drill-card ids, etc.). Free-form so summary shape can evolve
  /// without migrations.
  final String? outcomeJson;

  /// Difficulty band под которым партия была сгенерирована: 1=easy,
  /// 2=medium, 3=hard (R36). Authoritative для партии — MoveEvent-ы
  /// наследуют это значение при записи.
  final int difficultyBand;

  /// Был ли band подкручен пользователем post-session nudge-кнопкой
  /// относительно автоматической ротации rotator-а (R38).
  final bool userAdjusted;
  const SessionRow({
    required this.id,
    required this.mode,
    required this.startedAt,
    this.endedAt,
    this.outcomeJson,
    required this.difficultyBand,
    required this.userAdjusted,
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
    map['difficulty_band'] = Variable<int>(difficultyBand);
    map['user_adjusted'] = Variable<bool>(userAdjusted);
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
      difficultyBand: Value(difficultyBand),
      userAdjusted: Value(userAdjusted),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      mode: serializer.fromJson<String>(json['mode']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      outcomeJson: serializer.fromJson<String?>(json['outcomeJson']),
      difficultyBand: serializer.fromJson<int>(json['difficultyBand']),
      userAdjusted: serializer.fromJson<bool>(json['userAdjusted']),
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
      'difficultyBand': serializer.toJson<int>(difficultyBand),
      'userAdjusted': serializer.toJson<bool>(userAdjusted),
    };
  }

  SessionRow copyWith({
    int? id,
    String? mode,
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    Value<String?> outcomeJson = const Value.absent(),
    int? difficultyBand,
    bool? userAdjusted,
  }) => SessionRow(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    outcomeJson: outcomeJson.present ? outcomeJson.value : this.outcomeJson,
    difficultyBand: difficultyBand ?? this.difficultyBand,
    userAdjusted: userAdjusted ?? this.userAdjusted,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      outcomeJson: data.outcomeJson.present
          ? data.outcomeJson.value
          : this.outcomeJson,
      difficultyBand: data.difficultyBand.present
          ? data.difficultyBand.value
          : this.difficultyBand,
      userAdjusted: data.userAdjusted.present
          ? data.userAdjusted.value
          : this.userAdjusted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('outcomeJson: $outcomeJson, ')
          ..write('difficultyBand: $difficultyBand, ')
          ..write('userAdjusted: $userAdjusted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    startedAt,
    endedAt,
    outcomeJson,
    difficultyBand,
    userAdjusted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.outcomeJson == this.outcomeJson &&
          other.difficultyBand == this.difficultyBand &&
          other.userAdjusted == this.userAdjusted);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<String> mode;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<String?> outcomeJson;
  final Value<int> difficultyBand;
  final Value<bool> userAdjusted;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.outcomeJson = const Value.absent(),
    this.difficultyBand = const Value.absent(),
    this.userAdjusted = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String mode,
    required int startedAt,
    this.endedAt = const Value.absent(),
    this.outcomeJson = const Value.absent(),
    this.difficultyBand = const Value.absent(),
    this.userAdjusted = const Value.absent(),
  }) : mode = Value(mode),
       startedAt = Value(startedAt);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<String>? mode,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<String>? outcomeJson,
    Expression<int>? difficultyBand,
    Expression<bool>? userAdjusted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (outcomeJson != null) 'outcome_json': outcomeJson,
      if (difficultyBand != null) 'difficulty_band': difficultyBand,
      if (userAdjusted != null) 'user_adjusted': userAdjusted,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? mode,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<String?>? outcomeJson,
    Value<int>? difficultyBand,
    Value<bool>? userAdjusted,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      outcomeJson: outcomeJson ?? this.outcomeJson,
      difficultyBand: difficultyBand ?? this.difficultyBand,
      userAdjusted: userAdjusted ?? this.userAdjusted,
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
    if (difficultyBand.present) {
      map['difficulty_band'] = Variable<int>(difficultyBand.value);
    }
    if (userAdjusted.present) {
      map['user_adjusted'] = Variable<bool>(userAdjusted.value);
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
          ..write('outcomeJson: $outcomeJson, ')
          ..write('difficultyBand: $difficultyBand, ')
          ..write('userAdjusted: $userAdjusted')
          ..write(')'))
        .toString();
  }
}

class $MoveEventsTable extends MoveEvents
    with TableInfo<$MoveEventsTable, MoveEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoveEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
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
  static const VerificationMeta _kindIdMeta = const VerificationMeta('kindId');
  @override
  late final GeneratedColumn<String> kindId = GeneratedColumn<String>(
    'kind_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heuristicTagMeta = const VerificationMeta(
    'heuristicTag',
  );
  @override
  late final GeneratedColumn<String> heuristicTag = GeneratedColumn<String>(
    'heuristic_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latencyMsMeta = const VerificationMeta(
    'latencyMs',
  );
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
    'latency_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasCorrectMeta = const VerificationMeta(
    'wasCorrect',
  );
  @override
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
  static const VerificationMeta _hintRequestedMeta = const VerificationMeta(
    'hintRequested',
  );
  @override
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
  static const VerificationMeta _hintStepReachedMeta = const VerificationMeta(
    'hintStepReached',
  );
  @override
  late final GeneratedColumn<int> hintStepReached = GeneratedColumn<int>(
    'hint_step_reached',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contaminatedFlagMeta = const VerificationMeta(
    'contaminatedFlag',
  );
  @override
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
  static const VerificationMeta _idleSoftSignalMeta = const VerificationMeta(
    'idleSoftSignal',
  );
  @override
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
  static const VerificationMeta _motionSignalMeta = const VerificationMeta(
    'motionSignal',
  );
  @override
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
  static const VerificationMeta _lifecycleSignalMeta = const VerificationMeta(
    'lifecycleSignal',
  );
  @override
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
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventKindMeta = const VerificationMeta(
    'eventKind',
  );
  @override
  late final GeneratedColumn<String> eventKind = GeneratedColumn<String>(
    'event_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('production'),
  );
  static const VerificationMeta _chainIndexMeta = const VerificationMeta(
    'chainIndex',
  );
  @override
  late final GeneratedColumn<int> chainIndex = GeneratedColumn<int>(
    'chain_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _difficultyBandMeta = const VerificationMeta(
    'difficultyBand',
  );
  @override
  late final GeneratedColumn<int> difficultyBand = GeneratedColumn<int>(
    'difficulty_band',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _userAdjustedMeta = const VerificationMeta(
    'userAdjusted',
  );
  @override
  late final GeneratedColumn<bool> userAdjusted = GeneratedColumn<bool>(
    'user_adjusted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_adjusted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
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
    eventKind,
    chainIndex,
    difficultyBand,
    userAdjusted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'move_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoveEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('kind_id')) {
      context.handle(
        _kindIdMeta,
        kindId.isAcceptableOrUnknown(data['kind_id']!, _kindIdMeta),
      );
    } else if (isInserting) {
      context.missing(_kindIdMeta);
    }
    if (data.containsKey('heuristic_tag')) {
      context.handle(
        _heuristicTagMeta,
        heuristicTag.isAcceptableOrUnknown(
          data['heuristic_tag']!,
          _heuristicTagMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_heuristicTagMeta);
    }
    if (data.containsKey('latency_ms')) {
      context.handle(
        _latencyMsMeta,
        latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta),
      );
    } else if (isInserting) {
      context.missing(_latencyMsMeta);
    }
    if (data.containsKey('was_correct')) {
      context.handle(
        _wasCorrectMeta,
        wasCorrect.isAcceptableOrUnknown(data['was_correct']!, _wasCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_wasCorrectMeta);
    }
    if (data.containsKey('hint_requested')) {
      context.handle(
        _hintRequestedMeta,
        hintRequested.isAcceptableOrUnknown(
          data['hint_requested']!,
          _hintRequestedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hintRequestedMeta);
    }
    if (data.containsKey('hint_step_reached')) {
      context.handle(
        _hintStepReachedMeta,
        hintStepReached.isAcceptableOrUnknown(
          data['hint_step_reached']!,
          _hintStepReachedMeta,
        ),
      );
    }
    if (data.containsKey('contaminated_flag')) {
      context.handle(
        _contaminatedFlagMeta,
        contaminatedFlag.isAcceptableOrUnknown(
          data['contaminated_flag']!,
          _contaminatedFlagMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contaminatedFlagMeta);
    }
    if (data.containsKey('idle_soft_signal')) {
      context.handle(
        _idleSoftSignalMeta,
        idleSoftSignal.isAcceptableOrUnknown(
          data['idle_soft_signal']!,
          _idleSoftSignalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idleSoftSignalMeta);
    }
    if (data.containsKey('motion_signal')) {
      context.handle(
        _motionSignalMeta,
        motionSignal.isAcceptableOrUnknown(
          data['motion_signal']!,
          _motionSignalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_motionSignalMeta);
    }
    if (data.containsKey('lifecycle_signal')) {
      context.handle(
        _lifecycleSignalMeta,
        lifecycleSignal.isAcceptableOrUnknown(
          data['lifecycle_signal']!,
          _lifecycleSignalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lifecycleSignalMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('event_kind')) {
      context.handle(
        _eventKindMeta,
        eventKind.isAcceptableOrUnknown(data['event_kind']!, _eventKindMeta),
      );
    }
    if (data.containsKey('chain_index')) {
      context.handle(
        _chainIndexMeta,
        chainIndex.isAcceptableOrUnknown(data['chain_index']!, _chainIndexMeta),
      );
    }
    if (data.containsKey('difficulty_band')) {
      context.handle(
        _difficultyBandMeta,
        difficultyBand.isAcceptableOrUnknown(
          data['difficulty_band']!,
          _difficultyBandMeta,
        ),
      );
    }
    if (data.containsKey('user_adjusted')) {
      context.handle(
        _userAdjustedMeta,
        userAdjusted.isAcceptableOrUnknown(
          data['user_adjusted']!,
          _userAdjustedMeta,
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
  MoveEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoveEventRow(
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
      ),
      eventKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_kind'],
      )!,
      chainIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chain_index'],
      )!,
      difficultyBand: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty_band'],
      )!,
      userAdjusted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_adjusted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MoveEventsTable createAlias(String alias) {
    return $MoveEventsTable(attachedDatabase, alias);
  }
}

class MoveEventRow extends DataClass implements Insertable<MoveEventRow> {
  final int id;
  final int sessionId;

  /// Namespace partition for [Heuristic]. v1 always 'tango' (R26).
  final String kindId;

  /// Tag side of the [Heuristic] key (e.g. 'ParityFill').
  final String heuristicTag;
  final int latencyMs;
  final bool wasCorrect;
  final bool hintRequested;

  /// 0 = no hint, 1..4 = hint ladder step the player reached on this
  /// move (F3, R12, R13).
  final int hintStepReached;

  /// Effective contamination decision (lifecycle OR motion in v1).
  /// Events where this is true are excluded from mastery aggregates.
  final bool contaminatedFlag;

  /// Independent contamination signals — kept for diagnostics and for
  /// later threshold calibration (Open Questions deferred to impl).
  final bool idleSoftSignal;
  final bool motionSignal;
  final bool lifecycleSignal;

  /// 'propagation' | 'hunt' (R31). Партионный режим (full_game/drill)
  /// живёт в [Sessions.mode]; здесь — только классификация хода.
  /// Nullable: первый ход партии или пока классификатор не вынес
  /// решение.
  final String? mode;

  /// 'production' | 'recognition_hit' | 'recognition_correct_reject' |
  /// 'recognition_false_alarm' (R29). Phase C всегда 'production';
  /// recognition-варианты добавляются в Phase D (U12) без миграции.
  final String eventKind;

  /// 0 = the originating drill / full-game move; 1..N = ChainExtension
  /// follow-ons within the same drill card (R5).
  final int chainIndex;

  /// Difficulty band под которым партия была сгенерирована: 1=easy,
  /// 2=medium, 3=hard (R36). Denormalized с [Sessions.difficultyBand]
  /// для будущего factorial-анализа без JOIN. В v1 mastery/FSRS не
  /// читают это поле.
  final int difficultyBand;

  /// Был ли band в этой партии подкручен пользователем post-session
  /// nudge-кнопкой относительно автоматической ротации (R38).
  /// Denormalized с [Sessions.userAdjusted].
  final bool userAdjusted;
  final int createdAt;
  const MoveEventRow({
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
    this.mode,
    required this.eventKind,
    required this.chainIndex,
    required this.difficultyBand,
    required this.userAdjusted,
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
    if (!nullToAbsent || mode != null) {
      map['mode'] = Variable<String>(mode);
    }
    map['event_kind'] = Variable<String>(eventKind);
    map['chain_index'] = Variable<int>(chainIndex);
    map['difficulty_band'] = Variable<int>(difficultyBand);
    map['user_adjusted'] = Variable<bool>(userAdjusted);
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
      mode: mode == null && nullToAbsent ? const Value.absent() : Value(mode),
      eventKind: Value(eventKind),
      chainIndex: Value(chainIndex),
      difficultyBand: Value(difficultyBand),
      userAdjusted: Value(userAdjusted),
      createdAt: Value(createdAt),
    );
  }

  factory MoveEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoveEventRow(
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
      mode: serializer.fromJson<String?>(json['mode']),
      eventKind: serializer.fromJson<String>(json['eventKind']),
      chainIndex: serializer.fromJson<int>(json['chainIndex']),
      difficultyBand: serializer.fromJson<int>(json['difficultyBand']),
      userAdjusted: serializer.fromJson<bool>(json['userAdjusted']),
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
      'mode': serializer.toJson<String?>(mode),
      'eventKind': serializer.toJson<String>(eventKind),
      'chainIndex': serializer.toJson<int>(chainIndex),
      'difficultyBand': serializer.toJson<int>(difficultyBand),
      'userAdjusted': serializer.toJson<bool>(userAdjusted),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  MoveEventRow copyWith({
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
    Value<String?> mode = const Value.absent(),
    String? eventKind,
    int? chainIndex,
    int? difficultyBand,
    bool? userAdjusted,
    int? createdAt,
  }) => MoveEventRow(
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
    mode: mode.present ? mode.value : this.mode,
    eventKind: eventKind ?? this.eventKind,
    chainIndex: chainIndex ?? this.chainIndex,
    difficultyBand: difficultyBand ?? this.difficultyBand,
    userAdjusted: userAdjusted ?? this.userAdjusted,
    createdAt: createdAt ?? this.createdAt,
  );
  MoveEventRow copyWithCompanion(MoveEventsCompanion data) {
    return MoveEventRow(
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
      eventKind: data.eventKind.present ? data.eventKind.value : this.eventKind,
      chainIndex: data.chainIndex.present
          ? data.chainIndex.value
          : this.chainIndex,
      difficultyBand: data.difficultyBand.present
          ? data.difficultyBand.value
          : this.difficultyBand,
      userAdjusted: data.userAdjusted.present
          ? data.userAdjusted.value
          : this.userAdjusted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoveEventRow(')
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
          ..write('eventKind: $eventKind, ')
          ..write('chainIndex: $chainIndex, ')
          ..write('difficultyBand: $difficultyBand, ')
          ..write('userAdjusted: $userAdjusted, ')
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
    eventKind,
    chainIndex,
    difficultyBand,
    userAdjusted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoveEventRow &&
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
          other.eventKind == this.eventKind &&
          other.chainIndex == this.chainIndex &&
          other.difficultyBand == this.difficultyBand &&
          other.userAdjusted == this.userAdjusted &&
          other.createdAt == this.createdAt);
}

class MoveEventsCompanion extends UpdateCompanion<MoveEventRow> {
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
  final Value<String?> mode;
  final Value<String> eventKind;
  final Value<int> chainIndex;
  final Value<int> difficultyBand;
  final Value<bool> userAdjusted;
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
    this.eventKind = const Value.absent(),
    this.chainIndex = const Value.absent(),
    this.difficultyBand = const Value.absent(),
    this.userAdjusted = const Value.absent(),
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
    this.mode = const Value.absent(),
    this.eventKind = const Value.absent(),
    this.chainIndex = const Value.absent(),
    this.difficultyBand = const Value.absent(),
    this.userAdjusted = const Value.absent(),
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
       createdAt = Value(createdAt);
  static Insertable<MoveEventRow> custom({
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
    Expression<String>? eventKind,
    Expression<int>? chainIndex,
    Expression<int>? difficultyBand,
    Expression<bool>? userAdjusted,
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
      if (eventKind != null) 'event_kind': eventKind,
      if (chainIndex != null) 'chain_index': chainIndex,
      if (difficultyBand != null) 'difficulty_band': difficultyBand,
      if (userAdjusted != null) 'user_adjusted': userAdjusted,
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
    Value<String?>? mode,
    Value<String>? eventKind,
    Value<int>? chainIndex,
    Value<int>? difficultyBand,
    Value<bool>? userAdjusted,
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
      eventKind: eventKind ?? this.eventKind,
      chainIndex: chainIndex ?? this.chainIndex,
      difficultyBand: difficultyBand ?? this.difficultyBand,
      userAdjusted: userAdjusted ?? this.userAdjusted,
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
    if (eventKind.present) {
      map['event_kind'] = Variable<String>(eventKind.value);
    }
    if (chainIndex.present) {
      map['chain_index'] = Variable<int>(chainIndex.value);
    }
    if (difficultyBand.present) {
      map['difficulty_band'] = Variable<int>(difficultyBand.value);
    }
    if (userAdjusted.present) {
      map['user_adjusted'] = Variable<bool>(userAdjusted.value);
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
          ..write('eventKind: $eventKind, ')
          ..write('chainIndex: $chainIndex, ')
          ..write('difficultyBand: $difficultyBand, ')
          ..write('userAdjusted: $userAdjusted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MasteryStateTable extends MasteryState
    with TableInfo<$MasteryStateTable, MasteryStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MasteryStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindIdMeta = const VerificationMeta('kindId');
  @override
  late final GeneratedColumn<String> kindId = GeneratedColumn<String>(
    'kind_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heuristicTagMeta = const VerificationMeta(
    'heuristicTag',
  );
  @override
  late final GeneratedColumn<String> heuristicTag = GeneratedColumn<String>(
    'heuristic_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventCountMeta = const VerificationMeta(
    'eventCount',
  );
  @override
  late final GeneratedColumn<int> eventCount = GeneratedColumn<int>(
    'event_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ewmaZMeta = const VerificationMeta('ewmaZ');
  @override
  late final GeneratedColumn<double> ewmaZ = GeneratedColumn<double>(
    'ewma_z',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _latencyP25MsMeta = const VerificationMeta(
    'latencyP25Ms',
  );
  @override
  late final GeneratedColumn<int> latencyP25Ms = GeneratedColumn<int>(
    'latency_p25_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latencyMedianMsMeta = const VerificationMeta(
    'latencyMedianMs',
  );
  @override
  late final GeneratedColumn<int> latencyMedianMs = GeneratedColumn<int>(
    'latency_median_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latencyP75MsMeta = const VerificationMeta(
    'latencyP75Ms',
  );
  @override
  late final GeneratedColumn<int> latencyP75Ms = GeneratedColumn<int>(
    'latency_p75_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorRateMeta = const VerificationMeta(
    'errorRate',
  );
  @override
  late final GeneratedColumn<double> errorRate = GeneratedColumn<double>(
    'error_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hintRateMeta = const VerificationMeta(
    'hintRate',
  );
  @override
  late final GeneratedColumn<double> hintRate = GeneratedColumn<double>(
    'hint_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hintStepCountsJsonMeta =
      const VerificationMeta('hintStepCountsJson');
  @override
  late final GeneratedColumn<String> hintStepCountsJson =
      GeneratedColumn<String>(
        'hint_step_counts_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> lastUpdatedAt = GeneratedColumn<int>(
    'last_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCalibratingMeta = const VerificationMeta(
    'isCalibrating',
  );
  @override
  late final GeneratedColumn<bool> isCalibrating = GeneratedColumn<bool>(
    'is_calibrating',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_calibrating" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  VerificationContext validateIntegrity(
    Insertable<MasteryStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind_id')) {
      context.handle(
        _kindIdMeta,
        kindId.isAcceptableOrUnknown(data['kind_id']!, _kindIdMeta),
      );
    } else if (isInserting) {
      context.missing(_kindIdMeta);
    }
    if (data.containsKey('heuristic_tag')) {
      context.handle(
        _heuristicTagMeta,
        heuristicTag.isAcceptableOrUnknown(
          data['heuristic_tag']!,
          _heuristicTagMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_heuristicTagMeta);
    }
    if (data.containsKey('event_count')) {
      context.handle(
        _eventCountMeta,
        eventCount.isAcceptableOrUnknown(data['event_count']!, _eventCountMeta),
      );
    }
    if (data.containsKey('ewma_z')) {
      context.handle(
        _ewmaZMeta,
        ewmaZ.isAcceptableOrUnknown(data['ewma_z']!, _ewmaZMeta),
      );
    }
    if (data.containsKey('latency_p25_ms')) {
      context.handle(
        _latencyP25MsMeta,
        latencyP25Ms.isAcceptableOrUnknown(
          data['latency_p25_ms']!,
          _latencyP25MsMeta,
        ),
      );
    }
    if (data.containsKey('latency_median_ms')) {
      context.handle(
        _latencyMedianMsMeta,
        latencyMedianMs.isAcceptableOrUnknown(
          data['latency_median_ms']!,
          _latencyMedianMsMeta,
        ),
      );
    }
    if (data.containsKey('latency_p75_ms')) {
      context.handle(
        _latencyP75MsMeta,
        latencyP75Ms.isAcceptableOrUnknown(
          data['latency_p75_ms']!,
          _latencyP75MsMeta,
        ),
      );
    }
    if (data.containsKey('error_rate')) {
      context.handle(
        _errorRateMeta,
        errorRate.isAcceptableOrUnknown(data['error_rate']!, _errorRateMeta),
      );
    }
    if (data.containsKey('hint_rate')) {
      context.handle(
        _hintRateMeta,
        hintRate.isAcceptableOrUnknown(data['hint_rate']!, _hintRateMeta),
      );
    }
    if (data.containsKey('hint_step_counts_json')) {
      context.handle(
        _hintStepCountsJsonMeta,
        hintStepCountsJson.isAcceptableOrUnknown(
          data['hint_step_counts_json']!,
          _hintStepCountsJsonMeta,
        ),
      );
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    if (data.containsKey('is_calibrating')) {
      context.handle(
        _isCalibratingMeta,
        isCalibrating.isAcceptableOrUnknown(
          data['is_calibrating']!,
          _isCalibratingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kindId, heuristicTag};
  @override
  MasteryStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasteryStateRow(
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
  $MasteryStateTable createAlias(String alias) {
    return $MasteryStateTable(attachedDatabase, alias);
  }
}

class MasteryStateRow extends DataClass implements Insertable<MasteryStateRow> {
  final String kindId;
  final String heuristicTag;
  final int eventCount;
  final double ewmaZ;
  final int? latencyP25Ms;
  final int? latencyMedianMs;
  final int? latencyP75Ms;
  final double errorRate;
  final double hintRate;

  /// JSON map of `{ "0": int, "1": int, ... }` — count of events per
  /// hint step reached. Stored as JSON to keep the schema flat.
  final String hintStepCountsJson;
  final int lastUpdatedAt;

  /// True until [eventCount] crosses the cold-start threshold (R10).
  /// Calibrating heuristics are kept out of the drill queue.
  final bool isCalibrating;
  const MasteryStateRow({
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

  factory MasteryStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasteryStateRow(
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

  MasteryStateRow copyWith({
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
  }) => MasteryStateRow(
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
  MasteryStateRow copyWithCompanion(MasteryStateCompanion data) {
    return MasteryStateRow(
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
    return (StringBuffer('MasteryStateRow(')
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
      (other is MasteryStateRow &&
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

class MasteryStateCompanion extends UpdateCompanion<MasteryStateRow> {
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
  static Insertable<MasteryStateRow> custom({
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

class $FsrsCardsTable extends FsrsCards
    with TableInfo<$FsrsCardsTable, FsrsCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FsrsCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindIdMeta = const VerificationMeta('kindId');
  @override
  late final GeneratedColumn<String> kindId = GeneratedColumn<String>(
    'kind_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heuristicTagMeta = const VerificationMeta(
    'heuristicTag',
  );
  @override
  late final GeneratedColumn<String> heuristicTag = GeneratedColumn<String>(
    'heuristic_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateBlobMeta = const VerificationMeta(
    'stateBlob',
  );
  @override
  late final GeneratedColumn<Uint8List> stateBlob = GeneratedColumn<Uint8List>(
    'state_blob',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
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
  VerificationContext validateIntegrity(
    Insertable<FsrsCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind_id')) {
      context.handle(
        _kindIdMeta,
        kindId.isAcceptableOrUnknown(data['kind_id']!, _kindIdMeta),
      );
    } else if (isInserting) {
      context.missing(_kindIdMeta);
    }
    if (data.containsKey('heuristic_tag')) {
      context.handle(
        _heuristicTagMeta,
        heuristicTag.isAcceptableOrUnknown(
          data['heuristic_tag']!,
          _heuristicTagMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_heuristicTagMeta);
    }
    if (data.containsKey('state_blob')) {
      context.handle(
        _stateBlobMeta,
        stateBlob.isAcceptableOrUnknown(data['state_blob']!, _stateBlobMeta),
      );
    } else if (isInserting) {
      context.missing(_stateBlobMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kindId, heuristicTag};
  @override
  FsrsCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FsrsCardRow(
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
  $FsrsCardsTable createAlias(String alias) {
    return $FsrsCardsTable(attachedDatabase, alias);
  }
}

class FsrsCardRow extends DataClass implements Insertable<FsrsCardRow> {
  final String kindId;
  final String heuristicTag;

  /// Opaque serialization of the `fsrs` Card object (v1: JSON bytes).
  /// We treat this as a black box — never read from app code, only
  /// round-trip through `fsrs`.
  final Uint8List stateBlob;

  /// Unix epoch ms; indexed for fast `due_at <= now` queries.
  final int dueAt;
  final int? lastReviewedAt;
  const FsrsCardRow({
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
    map['state_blob'] = Variable<Uint8List>(stateBlob);
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

  factory FsrsCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FsrsCardRow(
      kindId: serializer.fromJson<String>(json['kindId']),
      heuristicTag: serializer.fromJson<String>(json['heuristicTag']),
      stateBlob: serializer.fromJson<Uint8List>(json['stateBlob']),
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
      'stateBlob': serializer.toJson<Uint8List>(stateBlob),
      'dueAt': serializer.toJson<int>(dueAt),
      'lastReviewedAt': serializer.toJson<int?>(lastReviewedAt),
    };
  }

  FsrsCardRow copyWith({
    String? kindId,
    String? heuristicTag,
    Uint8List? stateBlob,
    int? dueAt,
    Value<int?> lastReviewedAt = const Value.absent(),
  }) => FsrsCardRow(
    kindId: kindId ?? this.kindId,
    heuristicTag: heuristicTag ?? this.heuristicTag,
    stateBlob: stateBlob ?? this.stateBlob,
    dueAt: dueAt ?? this.dueAt,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
  );
  FsrsCardRow copyWithCompanion(FsrsCardsCompanion data) {
    return FsrsCardRow(
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
    return (StringBuffer('FsrsCardRow(')
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
      (other is FsrsCardRow &&
          other.kindId == this.kindId &&
          other.heuristicTag == this.heuristicTag &&
          $driftBlobEquality.equals(other.stateBlob, this.stateBlob) &&
          other.dueAt == this.dueAt &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class FsrsCardsCompanion extends UpdateCompanion<FsrsCardRow> {
  final Value<String> kindId;
  final Value<String> heuristicTag;
  final Value<Uint8List> stateBlob;
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
    required Uint8List stateBlob,
    required int dueAt,
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kindId = Value(kindId),
       heuristicTag = Value(heuristicTag),
       stateBlob = Value(stateBlob),
       dueAt = Value(dueAt);
  static Insertable<FsrsCardRow> custom({
    Expression<String>? kindId,
    Expression<String>? heuristicTag,
    Expression<Uint8List>? stateBlob,
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
    Value<Uint8List>? stateBlob,
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
      map['state_blob'] = Variable<Uint8List>(stateBlob.value);
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

abstract class _$LunaDatabase extends GeneratedDatabase {
  _$LunaDatabase(QueryExecutor e) : super(e);
  $LunaDatabaseManager get managers => $LunaDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MoveEventsTable moveEvents = $MoveEventsTable(this);
  late final $MasteryStateTable masteryState = $MasteryStateTable(this);
  late final $FsrsCardsTable fsrsCards = $FsrsCardsTable(this);
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
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('move_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required String mode,
      required int startedAt,
      Value<int?> endedAt,
      Value<String?> outcomeJson,
      Value<int> difficultyBand,
      Value<bool> userAdjusted,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<String> mode,
      Value<int> startedAt,
      Value<int?> endedAt,
      Value<String?> outcomeJson,
      Value<int> difficultyBand,
      Value<bool> userAdjusted,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$LunaDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MoveEventsTable, List<MoveEventRow>>
  _moveEventsRefsTable(_$LunaDatabase db) => MultiTypedResultKey.fromTable(
    db.moveEvents,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.moveEvents.sessionId),
  );

  $$MoveEventsTableProcessedTableManager get moveEventsRefs {
    final manager = $$MoveEventsTableTableManager(
      $_db,
      $_db.moveEvents,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_moveEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$LunaDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeJson => $composableBuilder(
    column: $table.outcomeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficultyBand => $composableBuilder(
    column: $table.difficultyBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userAdjusted => $composableBuilder(
    column: $table.userAdjusted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> moveEventsRefs(
    Expression<bool> Function($$MoveEventsTableFilterComposer f) f,
  ) {
    final $$MoveEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moveEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoveEventsTableFilterComposer(
            $db: $db,
            $table: $db.moveEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$LunaDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeJson => $composableBuilder(
    column: $table.outcomeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficultyBand => $composableBuilder(
    column: $table.difficultyBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userAdjusted => $composableBuilder(
    column: $table.userAdjusted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$LunaDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get outcomeJson => $composableBuilder(
    column: $table.outcomeJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get difficultyBand => $composableBuilder(
    column: $table.difficultyBand,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userAdjusted => $composableBuilder(
    column: $table.userAdjusted,
    builder: (column) => column,
  );

  Expression<T> moveEventsRefs<T extends Object>(
    Expression<T> Function($$MoveEventsTableAnnotationComposer a) f,
  ) {
    final $$MoveEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moveEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoveEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.moveEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$LunaDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool moveEventsRefs})
        > {
  $$SessionsTableTableManager(_$LunaDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<String?> outcomeJson = const Value.absent(),
                Value<int> difficultyBand = const Value.absent(),
                Value<bool> userAdjusted = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                outcomeJson: outcomeJson,
                difficultyBand: difficultyBand,
                userAdjusted: userAdjusted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mode,
                required int startedAt,
                Value<int?> endedAt = const Value.absent(),
                Value<String?> outcomeJson = const Value.absent(),
                Value<int> difficultyBand = const Value.absent(),
                Value<bool> userAdjusted = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                outcomeJson: outcomeJson,
                difficultyBand: difficultyBand,
                userAdjusted: userAdjusted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({moveEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (moveEventsRefs) db.moveEvents],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (moveEventsRefs)
                    await $_getPrefetchedData<
                      SessionRow,
                      $SessionsTable,
                      MoveEventRow
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._moveEventsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).moveEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunaDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool moveEventsRefs})
    >;
typedef $$MoveEventsTableCreateCompanionBuilder =
    MoveEventsCompanion Function({
      Value<int> id,
      required int sessionId,
      required String kindId,
      required String heuristicTag,
      required int latencyMs,
      required bool wasCorrect,
      required bool hintRequested,
      Value<int> hintStepReached,
      required bool contaminatedFlag,
      required bool idleSoftSignal,
      required bool motionSignal,
      required bool lifecycleSignal,
      Value<String?> mode,
      Value<String> eventKind,
      Value<int> chainIndex,
      Value<int> difficultyBand,
      Value<bool> userAdjusted,
      required int createdAt,
    });
typedef $$MoveEventsTableUpdateCompanionBuilder =
    MoveEventsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> kindId,
      Value<String> heuristicTag,
      Value<int> latencyMs,
      Value<bool> wasCorrect,
      Value<bool> hintRequested,
      Value<int> hintStepReached,
      Value<bool> contaminatedFlag,
      Value<bool> idleSoftSignal,
      Value<bool> motionSignal,
      Value<bool> lifecycleSignal,
      Value<String?> mode,
      Value<String> eventKind,
      Value<int> chainIndex,
      Value<int> difficultyBand,
      Value<bool> userAdjusted,
      Value<int> createdAt,
    });

final class $$MoveEventsTableReferences
    extends BaseReferences<_$LunaDatabase, $MoveEventsTable, MoveEventRow> {
  $$MoveEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$LunaDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.moveEvents.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MoveEventsTableFilterComposer
    extends Composer<_$LunaDatabase, $MoveEventsTable> {
  $$MoveEventsTableFilterComposer({
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

  ColumnFilters<String> get kindId => $composableBuilder(
    column: $table.kindId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hintRequested => $composableBuilder(
    column: $table.hintRequested,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintStepReached => $composableBuilder(
    column: $table.hintStepReached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get contaminatedFlag => $composableBuilder(
    column: $table.contaminatedFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get idleSoftSignal => $composableBuilder(
    column: $table.idleSoftSignal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get motionSignal => $composableBuilder(
    column: $table.motionSignal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lifecycleSignal => $composableBuilder(
    column: $table.lifecycleSignal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventKind => $composableBuilder(
    column: $table.eventKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chainIndex => $composableBuilder(
    column: $table.chainIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficultyBand => $composableBuilder(
    column: $table.difficultyBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userAdjusted => $composableBuilder(
    column: $table.userAdjusted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoveEventsTableOrderingComposer
    extends Composer<_$LunaDatabase, $MoveEventsTable> {
  $$MoveEventsTableOrderingComposer({
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

  ColumnOrderings<String> get kindId => $composableBuilder(
    column: $table.kindId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hintRequested => $composableBuilder(
    column: $table.hintRequested,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintStepReached => $composableBuilder(
    column: $table.hintStepReached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get contaminatedFlag => $composableBuilder(
    column: $table.contaminatedFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get idleSoftSignal => $composableBuilder(
    column: $table.idleSoftSignal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get motionSignal => $composableBuilder(
    column: $table.motionSignal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lifecycleSignal => $composableBuilder(
    column: $table.lifecycleSignal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventKind => $composableBuilder(
    column: $table.eventKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chainIndex => $composableBuilder(
    column: $table.chainIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficultyBand => $composableBuilder(
    column: $table.difficultyBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userAdjusted => $composableBuilder(
    column: $table.userAdjusted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoveEventsTableAnnotationComposer
    extends Composer<_$LunaDatabase, $MoveEventsTable> {
  $$MoveEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kindId =>
      $composableBuilder(column: $table.kindId, builder: (column) => column);

  GeneratedColumn<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latencyMs =>
      $composableBuilder(column: $table.latencyMs, builder: (column) => column);

  GeneratedColumn<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hintRequested => $composableBuilder(
    column: $table.hintRequested,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hintStepReached => $composableBuilder(
    column: $table.hintStepReached,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get contaminatedFlag => $composableBuilder(
    column: $table.contaminatedFlag,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get idleSoftSignal => $composableBuilder(
    column: $table.idleSoftSignal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get motionSignal => $composableBuilder(
    column: $table.motionSignal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lifecycleSignal => $composableBuilder(
    column: $table.lifecycleSignal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get eventKind =>
      $composableBuilder(column: $table.eventKind, builder: (column) => column);

  GeneratedColumn<int> get chainIndex => $composableBuilder(
    column: $table.chainIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get difficultyBand => $composableBuilder(
    column: $table.difficultyBand,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userAdjusted => $composableBuilder(
    column: $table.userAdjusted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoveEventsTableTableManager
    extends
        RootTableManager<
          _$LunaDatabase,
          $MoveEventsTable,
          MoveEventRow,
          $$MoveEventsTableFilterComposer,
          $$MoveEventsTableOrderingComposer,
          $$MoveEventsTableAnnotationComposer,
          $$MoveEventsTableCreateCompanionBuilder,
          $$MoveEventsTableUpdateCompanionBuilder,
          (MoveEventRow, $$MoveEventsTableReferences),
          MoveEventRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$MoveEventsTableTableManager(_$LunaDatabase db, $MoveEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoveEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoveEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoveEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> kindId = const Value.absent(),
                Value<String> heuristicTag = const Value.absent(),
                Value<int> latencyMs = const Value.absent(),
                Value<bool> wasCorrect = const Value.absent(),
                Value<bool> hintRequested = const Value.absent(),
                Value<int> hintStepReached = const Value.absent(),
                Value<bool> contaminatedFlag = const Value.absent(),
                Value<bool> idleSoftSignal = const Value.absent(),
                Value<bool> motionSignal = const Value.absent(),
                Value<bool> lifecycleSignal = const Value.absent(),
                Value<String?> mode = const Value.absent(),
                Value<String> eventKind = const Value.absent(),
                Value<int> chainIndex = const Value.absent(),
                Value<int> difficultyBand = const Value.absent(),
                Value<bool> userAdjusted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => MoveEventsCompanion(
                id: id,
                sessionId: sessionId,
                kindId: kindId,
                heuristicTag: heuristicTag,
                latencyMs: latencyMs,
                wasCorrect: wasCorrect,
                hintRequested: hintRequested,
                hintStepReached: hintStepReached,
                contaminatedFlag: contaminatedFlag,
                idleSoftSignal: idleSoftSignal,
                motionSignal: motionSignal,
                lifecycleSignal: lifecycleSignal,
                mode: mode,
                eventKind: eventKind,
                chainIndex: chainIndex,
                difficultyBand: difficultyBand,
                userAdjusted: userAdjusted,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String kindId,
                required String heuristicTag,
                required int latencyMs,
                required bool wasCorrect,
                required bool hintRequested,
                Value<int> hintStepReached = const Value.absent(),
                required bool contaminatedFlag,
                required bool idleSoftSignal,
                required bool motionSignal,
                required bool lifecycleSignal,
                Value<String?> mode = const Value.absent(),
                Value<String> eventKind = const Value.absent(),
                Value<int> chainIndex = const Value.absent(),
                Value<int> difficultyBand = const Value.absent(),
                Value<bool> userAdjusted = const Value.absent(),
                required int createdAt,
              }) => MoveEventsCompanion.insert(
                id: id,
                sessionId: sessionId,
                kindId: kindId,
                heuristicTag: heuristicTag,
                latencyMs: latencyMs,
                wasCorrect: wasCorrect,
                hintRequested: hintRequested,
                hintStepReached: hintStepReached,
                contaminatedFlag: contaminatedFlag,
                idleSoftSignal: idleSoftSignal,
                motionSignal: motionSignal,
                lifecycleSignal: lifecycleSignal,
                mode: mode,
                eventKind: eventKind,
                chainIndex: chainIndex,
                difficultyBand: difficultyBand,
                userAdjusted: userAdjusted,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MoveEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$MoveEventsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$MoveEventsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$MoveEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunaDatabase,
      $MoveEventsTable,
      MoveEventRow,
      $$MoveEventsTableFilterComposer,
      $$MoveEventsTableOrderingComposer,
      $$MoveEventsTableAnnotationComposer,
      $$MoveEventsTableCreateCompanionBuilder,
      $$MoveEventsTableUpdateCompanionBuilder,
      (MoveEventRow, $$MoveEventsTableReferences),
      MoveEventRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$MasteryStateTableCreateCompanionBuilder =
    MasteryStateCompanion Function({
      required String kindId,
      required String heuristicTag,
      Value<int> eventCount,
      Value<double> ewmaZ,
      Value<int?> latencyP25Ms,
      Value<int?> latencyMedianMs,
      Value<int?> latencyP75Ms,
      Value<double> errorRate,
      Value<double> hintRate,
      Value<String> hintStepCountsJson,
      required int lastUpdatedAt,
      Value<bool> isCalibrating,
      Value<int> rowid,
    });
typedef $$MasteryStateTableUpdateCompanionBuilder =
    MasteryStateCompanion Function({
      Value<String> kindId,
      Value<String> heuristicTag,
      Value<int> eventCount,
      Value<double> ewmaZ,
      Value<int?> latencyP25Ms,
      Value<int?> latencyMedianMs,
      Value<int?> latencyP75Ms,
      Value<double> errorRate,
      Value<double> hintRate,
      Value<String> hintStepCountsJson,
      Value<int> lastUpdatedAt,
      Value<bool> isCalibrating,
      Value<int> rowid,
    });

class $$MasteryStateTableFilterComposer
    extends Composer<_$LunaDatabase, $MasteryStateTable> {
  $$MasteryStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kindId => $composableBuilder(
    column: $table.kindId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventCount => $composableBuilder(
    column: $table.eventCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ewmaZ => $composableBuilder(
    column: $table.ewmaZ,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyP25Ms => $composableBuilder(
    column: $table.latencyP25Ms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyMedianMs => $composableBuilder(
    column: $table.latencyMedianMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyP75Ms => $composableBuilder(
    column: $table.latencyP75Ms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get errorRate => $composableBuilder(
    column: $table.errorRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hintRate => $composableBuilder(
    column: $table.hintRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hintStepCountsJson => $composableBuilder(
    column: $table.hintStepCountsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCalibrating => $composableBuilder(
    column: $table.isCalibrating,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MasteryStateTableOrderingComposer
    extends Composer<_$LunaDatabase, $MasteryStateTable> {
  $$MasteryStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kindId => $composableBuilder(
    column: $table.kindId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventCount => $composableBuilder(
    column: $table.eventCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ewmaZ => $composableBuilder(
    column: $table.ewmaZ,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyP25Ms => $composableBuilder(
    column: $table.latencyP25Ms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyMedianMs => $composableBuilder(
    column: $table.latencyMedianMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyP75Ms => $composableBuilder(
    column: $table.latencyP75Ms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get errorRate => $composableBuilder(
    column: $table.errorRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hintRate => $composableBuilder(
    column: $table.hintRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hintStepCountsJson => $composableBuilder(
    column: $table.hintStepCountsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCalibrating => $composableBuilder(
    column: $table.isCalibrating,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MasteryStateTableAnnotationComposer
    extends Composer<_$LunaDatabase, $MasteryStateTable> {
  $$MasteryStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kindId =>
      $composableBuilder(column: $table.kindId, builder: (column) => column);

  GeneratedColumn<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get eventCount => $composableBuilder(
    column: $table.eventCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ewmaZ =>
      $composableBuilder(column: $table.ewmaZ, builder: (column) => column);

  GeneratedColumn<int> get latencyP25Ms => $composableBuilder(
    column: $table.latencyP25Ms,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latencyMedianMs => $composableBuilder(
    column: $table.latencyMedianMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latencyP75Ms => $composableBuilder(
    column: $table.latencyP75Ms,
    builder: (column) => column,
  );

  GeneratedColumn<double> get errorRate =>
      $composableBuilder(column: $table.errorRate, builder: (column) => column);

  GeneratedColumn<double> get hintRate =>
      $composableBuilder(column: $table.hintRate, builder: (column) => column);

  GeneratedColumn<String> get hintStepCountsJson => $composableBuilder(
    column: $table.hintStepCountsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCalibrating => $composableBuilder(
    column: $table.isCalibrating,
    builder: (column) => column,
  );
}

class $$MasteryStateTableTableManager
    extends
        RootTableManager<
          _$LunaDatabase,
          $MasteryStateTable,
          MasteryStateRow,
          $$MasteryStateTableFilterComposer,
          $$MasteryStateTableOrderingComposer,
          $$MasteryStateTableAnnotationComposer,
          $$MasteryStateTableCreateCompanionBuilder,
          $$MasteryStateTableUpdateCompanionBuilder,
          (
            MasteryStateRow,
            BaseReferences<_$LunaDatabase, $MasteryStateTable, MasteryStateRow>,
          ),
          MasteryStateRow,
          PrefetchHooks Function()
        > {
  $$MasteryStateTableTableManager(_$LunaDatabase db, $MasteryStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MasteryStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MasteryStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MasteryStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kindId = const Value.absent(),
                Value<String> heuristicTag = const Value.absent(),
                Value<int> eventCount = const Value.absent(),
                Value<double> ewmaZ = const Value.absent(),
                Value<int?> latencyP25Ms = const Value.absent(),
                Value<int?> latencyMedianMs = const Value.absent(),
                Value<int?> latencyP75Ms = const Value.absent(),
                Value<double> errorRate = const Value.absent(),
                Value<double> hintRate = const Value.absent(),
                Value<String> hintStepCountsJson = const Value.absent(),
                Value<int> lastUpdatedAt = const Value.absent(),
                Value<bool> isCalibrating = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasteryStateCompanion(
                kindId: kindId,
                heuristicTag: heuristicTag,
                eventCount: eventCount,
                ewmaZ: ewmaZ,
                latencyP25Ms: latencyP25Ms,
                latencyMedianMs: latencyMedianMs,
                latencyP75Ms: latencyP75Ms,
                errorRate: errorRate,
                hintRate: hintRate,
                hintStepCountsJson: hintStepCountsJson,
                lastUpdatedAt: lastUpdatedAt,
                isCalibrating: isCalibrating,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kindId,
                required String heuristicTag,
                Value<int> eventCount = const Value.absent(),
                Value<double> ewmaZ = const Value.absent(),
                Value<int?> latencyP25Ms = const Value.absent(),
                Value<int?> latencyMedianMs = const Value.absent(),
                Value<int?> latencyP75Ms = const Value.absent(),
                Value<double> errorRate = const Value.absent(),
                Value<double> hintRate = const Value.absent(),
                Value<String> hintStepCountsJson = const Value.absent(),
                required int lastUpdatedAt,
                Value<bool> isCalibrating = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasteryStateCompanion.insert(
                kindId: kindId,
                heuristicTag: heuristicTag,
                eventCount: eventCount,
                ewmaZ: ewmaZ,
                latencyP25Ms: latencyP25Ms,
                latencyMedianMs: latencyMedianMs,
                latencyP75Ms: latencyP75Ms,
                errorRate: errorRate,
                hintRate: hintRate,
                hintStepCountsJson: hintStepCountsJson,
                lastUpdatedAt: lastUpdatedAt,
                isCalibrating: isCalibrating,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MasteryStateTableProcessedTableManager =
    ProcessedTableManager<
      _$LunaDatabase,
      $MasteryStateTable,
      MasteryStateRow,
      $$MasteryStateTableFilterComposer,
      $$MasteryStateTableOrderingComposer,
      $$MasteryStateTableAnnotationComposer,
      $$MasteryStateTableCreateCompanionBuilder,
      $$MasteryStateTableUpdateCompanionBuilder,
      (
        MasteryStateRow,
        BaseReferences<_$LunaDatabase, $MasteryStateTable, MasteryStateRow>,
      ),
      MasteryStateRow,
      PrefetchHooks Function()
    >;
typedef $$FsrsCardsTableCreateCompanionBuilder =
    FsrsCardsCompanion Function({
      required String kindId,
      required String heuristicTag,
      required Uint8List stateBlob,
      required int dueAt,
      Value<int?> lastReviewedAt,
      Value<int> rowid,
    });
typedef $$FsrsCardsTableUpdateCompanionBuilder =
    FsrsCardsCompanion Function({
      Value<String> kindId,
      Value<String> heuristicTag,
      Value<Uint8List> stateBlob,
      Value<int> dueAt,
      Value<int?> lastReviewedAt,
      Value<int> rowid,
    });

class $$FsrsCardsTableFilterComposer
    extends Composer<_$LunaDatabase, $FsrsCardsTable> {
  $$FsrsCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kindId => $composableBuilder(
    column: $table.kindId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get stateBlob => $composableBuilder(
    column: $table.stateBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FsrsCardsTableOrderingComposer
    extends Composer<_$LunaDatabase, $FsrsCardsTable> {
  $$FsrsCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kindId => $composableBuilder(
    column: $table.kindId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get stateBlob => $composableBuilder(
    column: $table.stateBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FsrsCardsTableAnnotationComposer
    extends Composer<_$LunaDatabase, $FsrsCardsTable> {
  $$FsrsCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kindId =>
      $composableBuilder(column: $table.kindId, builder: (column) => column);

  GeneratedColumn<String> get heuristicTag => $composableBuilder(
    column: $table.heuristicTag,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get stateBlob =>
      $composableBuilder(column: $table.stateBlob, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );
}

class $$FsrsCardsTableTableManager
    extends
        RootTableManager<
          _$LunaDatabase,
          $FsrsCardsTable,
          FsrsCardRow,
          $$FsrsCardsTableFilterComposer,
          $$FsrsCardsTableOrderingComposer,
          $$FsrsCardsTableAnnotationComposer,
          $$FsrsCardsTableCreateCompanionBuilder,
          $$FsrsCardsTableUpdateCompanionBuilder,
          (
            FsrsCardRow,
            BaseReferences<_$LunaDatabase, $FsrsCardsTable, FsrsCardRow>,
          ),
          FsrsCardRow,
          PrefetchHooks Function()
        > {
  $$FsrsCardsTableTableManager(_$LunaDatabase db, $FsrsCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FsrsCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FsrsCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FsrsCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kindId = const Value.absent(),
                Value<String> heuristicTag = const Value.absent(),
                Value<Uint8List> stateBlob = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                Value<int?> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FsrsCardsCompanion(
                kindId: kindId,
                heuristicTag: heuristicTag,
                stateBlob: stateBlob,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kindId,
                required String heuristicTag,
                required Uint8List stateBlob,
                required int dueAt,
                Value<int?> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FsrsCardsCompanion.insert(
                kindId: kindId,
                heuristicTag: heuristicTag,
                stateBlob: stateBlob,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FsrsCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunaDatabase,
      $FsrsCardsTable,
      FsrsCardRow,
      $$FsrsCardsTableFilterComposer,
      $$FsrsCardsTableOrderingComposer,
      $$FsrsCardsTableAnnotationComposer,
      $$FsrsCardsTableCreateCompanionBuilder,
      $$FsrsCardsTableUpdateCompanionBuilder,
      (
        FsrsCardRow,
        BaseReferences<_$LunaDatabase, $FsrsCardsTable, FsrsCardRow>,
      ),
      FsrsCardRow,
      PrefetchHooks Function()
    >;

class $LunaDatabaseManager {
  final _$LunaDatabase _db;
  $LunaDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MoveEventsTableTableManager get moveEvents =>
      $$MoveEventsTableTableManager(_db, _db.moveEvents);
  $$MasteryStateTableTableManager get masteryState =>
      $$MasteryStateTableTableManager(_db, _db.masteryState);
  $$FsrsCardsTableTableManager get fsrsCards =>
      $$FsrsCardsTableTableManager(_db, _db.fsrsCards);
}
