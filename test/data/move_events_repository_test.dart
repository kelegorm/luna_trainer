import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/move_events_repository.dart';
import 'package:luna_traineer/data/repositories/sessions_repository.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';

const _parityFill = Heuristic('tango', 'ParityFill');
const _trioAvoidance = Heuristic('tango', 'TrioAvoidance');

void main() {
  late LunaDatabase db;
  late MoveEventsRepository repo;
  late SessionsRepository sessions;
  late int sessionId;

  setUp(() async {
    db = LunaDatabase.forTesting(NativeDatabase.memory());
    repo = MoveEventsRepository(db);
    sessions = SessionsRepository(db);
    sessionId = await sessions.startSession(
      mode: 'drill',
      startedAt: DateTime.utc(2026, 5, 1),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> commit({
    required Heuristic h,
    required int latencyMs,
    required int createdAt,
    bool wasCorrect = true,
    bool hintRequested = false,
    int hintStepReached = 0,
    bool contaminated = false,
    int chainIndex = 0,
    MoveMode? mode,
    MoveEventKind eventKind = MoveEventKind.production,
    int difficultyBand = 2,
    bool userAdjusted = false,
  }) {
    return repo.commit(
      sessionId: sessionId,
      heuristic: h,
      latencyMs: latencyMs,
      wasCorrect: wasCorrect,
      hintRequested: hintRequested,
      hintStepReached: hintStepReached,
      contaminated: contaminated,
      idleSoftSignal: false,
      motionSignal: false,
      lifecycleSignal: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      chainIndex: chainIndex,
      mode: mode,
      eventKind: eventKind,
      difficultyBand: difficultyBand,
      userAdjusted: userAdjusted,
    );
  }

  test('commit + findById round-trip preserves all fields', () async {
    final id = await commit(
      h: _parityFill,
      latencyMs: 1234,
      createdAt: 1,
      hintStepReached: 2,
    );

    final row = await repo.findById(id);

    expect(row, isNotNull);
    expect(row!.kindId, 'tango');
    expect(row.heuristicTag, 'ParityFill');
    expect(row.latencyMs, 1234);
    expect(row.wasCorrect, isTrue);
    expect(row.hintStepReached, 2);
    expect(row.contaminatedFlag, isFalse);
    expect(row.chainIndex, 0);
  });

  test('commit defaults: mode null, eventKind production, band=2, '
      'userAdjusted=false', () async {
    final id = await commit(h: _parityFill, latencyMs: 100, createdAt: 1);
    final row = await repo.findById(id);
    expect(row!.mode, isNull,
        reason: 'no propagation/hunt classification by default');
    expect(row.eventKind, 'production');
    expect(row.difficultyBand, 2);
    expect(row.userAdjusted, isFalse);
  });

  test('commit with explicit MoveMode persists wire string', () async {
    final propId = await commit(
      h: _parityFill,
      latencyMs: 100,
      createdAt: 1,
      mode: MoveMode.propagation,
    );
    final huntId = await commit(
      h: _parityFill,
      latencyMs: 200,
      createdAt: 2,
      mode: MoveMode.hunt,
    );

    expect((await repo.findById(propId))!.mode, 'propagation');
    expect((await repo.findById(huntId))!.mode, 'hunt');
  });

  test('commit with band/userAdjusted persists denormalized fields',
      () async {
    final id = await commit(
      h: _parityFill,
      latencyMs: 100,
      createdAt: 1,
      difficultyBand: 3,
      userAdjusted: true,
    );
    final row = await repo.findById(id);
    expect(row!.difficultyBand, 3);
    expect(row.userAdjusted, isTrue);
  });

  test('commit with recognition eventKind persists wire string', () async {
    final id = await commit(
      h: _parityFill,
      latencyMs: 100,
      createdAt: 1,
      eventKind: MoveEventKind.recognitionFalseAlarm,
    );
    final row = await repo.findById(id);
    expect(row!.eventKind, 'recognition_false_alarm');
  });

  test('watchRecent streams newest first and respects limit', () async {
    await commit(h: _parityFill, latencyMs: 100, createdAt: 1);
    await commit(h: _parityFill, latencyMs: 200, createdAt: 5);
    await commit(h: _parityFill, latencyMs: 300, createdAt: 3);

    final rows = await repo.watchRecent(_parityFill, limit: 100).first;

    expect(
      rows.map((r) => r.createdAt).toList(),
      [5, 3, 1],
      reason: 'createdAt DESC ordering',
    );
  });

  test('watchRecent excludes contaminated events by default', () async {
    await commit(h: _parityFill, latencyMs: 100, createdAt: 1);
    await commit(
      h: _parityFill,
      latencyMs: 200,
      createdAt: 2,
      contaminated: true,
    );

    final clean = await repo.watchRecent(_parityFill).first;
    final all = await repo
        .watchRecent(_parityFill, excludeContaminated: false)
        .first;

    expect(clean.length, 1);
    expect(clean.single.contaminatedFlag, isFalse);
    expect(all.length, 2);
  });

  test('watchRecent filters by Heuristic — same kind, different tag',
      () async {
    await commit(h: _parityFill, latencyMs: 100, createdAt: 1);
    await commit(h: _trioAvoidance, latencyMs: 200, createdAt: 2);

    final parity = await repo.watchRecent(_parityFill).first;
    final trio = await repo.watchRecent(_trioAvoidance).first;

    expect(parity.single.heuristicTag, 'ParityFill');
    expect(trio.single.heuristicTag, 'TrioAvoidance');
  });

  test('empty DB — watchRecent yields empty list, no exception', () async {
    final rows = await repo.watchRecent(_parityFill).first;
    expect(rows, isEmpty);
  });

  test('chainIndex defaults to 0 and round-trips', () async {
    await commit(h: _parityFill, latencyMs: 100, createdAt: 1);
    await commit(h: _parityFill, latencyMs: 100, createdAt: 2, chainIndex: 1);

    final rows = await repo.watchRecent(_parityFill).first;
    expect(rows.map((r) => r.chainIndex).toList(), [1, 0]);
  });

  test('cascade delete via Sessions FK', () async {
    await commit(h: _parityFill, latencyMs: 100, createdAt: 1);
    await commit(h: _parityFill, latencyMs: 100, createdAt: 2);

    await (db.delete(db.sessions)..where((t) => t.id.equals(sessionId))).go();

    final rows = await repo.watchRecent(_parityFill).first;
    expect(rows, isEmpty, reason: 'ON DELETE CASCADE removes child events');
  });

  group('SessionsRepository', () {
    test('startSession persists band and userAdjusted', () async {
      final id = await sessions.startSession(
        mode: 'full_game',
        startedAt: DateTime.utc(2026, 5, 1),
        band: 3,
        userAdjusted: true,
      );
      final row = await sessions.findById(id);
      expect(row!.mode, 'full_game');
      expect(row.difficultyBand, 3);
      expect(row.userAdjusted, isTrue);
    });

    test('startSession defaults match schema (band=2, userAdjusted=false)',
        () async {
      final id = await sessions.startSession(
        mode: 'drill',
        startedAt: DateTime.utc(2026, 5, 1),
      );
      final row = await sessions.findById(id);
      expect(row!.difficultyBand, 2);
      expect(row.userAdjusted, isFalse);
    });
  });
}
