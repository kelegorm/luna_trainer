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
    sessionId = await sessions.insert(
      SessionsCompanion.insert(
        mode: 'drill',
        startedAt: DateTime.utc(2026, 5, 1).millisecondsSinceEpoch,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  MoveEventsCompanion event({
    required Heuristic h,
    required int latencyMs,
    required int createdAt,
    bool wasCorrect = true,
    bool hintRequested = false,
    int hintStepReached = 0,
    bool contaminated = false,
    int chainIndex = 0,
    String mode = 'drill',
  }) {
    return MoveEventsCompanion.insert(
      sessionId: sessionId,
      kindId: h.kindId,
      heuristicTag: h.tagId,
      latencyMs: latencyMs,
      wasCorrect: wasCorrect,
      hintRequested: hintRequested,
      hintStepReached: Value(hintStepReached),
      contaminatedFlag: contaminated,
      idleSoftSignal: false,
      motionSignal: false,
      lifecycleSignal: false,
      mode: mode,
      chainIndex: Value(chainIndex),
      createdAt: createdAt,
    );
  }

  test('insert + findById round-trip preserves all fields', () async {
    final id = await repo.insert(
      event(h: _parityFill, latencyMs: 1234, createdAt: 1, hintStepReached: 2),
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

  test('watchRecent streams newest first and respects limit', () async {
    await repo.insert(event(h: _parityFill, latencyMs: 100, createdAt: 1));
    await repo.insert(event(h: _parityFill, latencyMs: 200, createdAt: 5));
    await repo.insert(event(h: _parityFill, latencyMs: 300, createdAt: 3));

    final rows = await repo.watchRecent(_parityFill, limit: 100).first;

    expect(
      rows.map((r) => r.createdAt).toList(),
      [5, 3, 1],
      reason: 'createdAt DESC ordering',
    );
  });

  test('watchRecent excludes contaminated events by default', () async {
    await repo.insert(
      event(h: _parityFill, latencyMs: 100, createdAt: 1),
    );
    await repo.insert(
      event(h: _parityFill, latencyMs: 200, createdAt: 2, contaminated: true),
    );

    final clean = await repo.watchRecent(_parityFill).first;
    final all = await repo
        .watchRecent(_parityFill, excludeContaminated: false)
        .first;

    expect(clean.length, 1);
    expect(clean.single.contaminatedFlag, isFalse);
    expect(all.length, 2);
  });

  test('watchRecent filters by Heuristic — same kind, different tag', () async {
    await repo.insert(event(h: _parityFill, latencyMs: 100, createdAt: 1));
    await repo.insert(event(h: _trioAvoidance, latencyMs: 200, createdAt: 2));

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
    await repo.insert(event(h: _parityFill, latencyMs: 100, createdAt: 1));
    await repo.insert(
      event(h: _parityFill, latencyMs: 100, createdAt: 2, chainIndex: 1),
    );

    final rows = await repo.watchRecent(_parityFill).first;
    expect(rows.map((r) => r.chainIndex).toList(), [1, 0]);
  });

  test('cascade delete via Sessions FK', () async {
    await repo.insert(event(h: _parityFill, latencyMs: 100, createdAt: 1));
    await repo.insert(event(h: _parityFill, latencyMs: 100, createdAt: 2));

    await (db.delete(db.sessions)..where((t) => t.id.equals(sessionId))).go();

    final rows = await repo.watchRecent(_parityFill).first;
    expect(rows, isEmpty, reason: 'ON DELETE CASCADE removes child events');
  });
}
