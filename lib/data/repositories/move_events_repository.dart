import 'package:drift/drift.dart';

import '../../engine/domain/heuristic.dart';
import '../../engine/telemetry/move_event_kind.dart';
import '../../engine/telemetry/move_mode_classifier.dart';
import '../database.dart';
import '../tables/move_events_table.dart';

export '../../engine/telemetry/move_event_kind.dart' show MoveEventKind;
export '../../engine/telemetry/move_mode_classifier.dart' show MoveMode;

/// Thin wrapper over the [MoveEvents] table. Holds zero business
/// logic — mastery scoring, contamination filtering, FSRS rating all
/// live in the engine layer.
class MoveEventsRepository {
  MoveEventsRepository(this._db);

  final LunaDatabase _db;

  /// Persist a single move. The caller (engine telemetry layer in U7,
  /// drill bloc in U12) is responsible for classification — this
  /// method just writes.
  Future<int> commit({
    required int sessionId,
    required Heuristic heuristic,
    required int latencyMs,
    required bool wasCorrect,
    required bool hintRequested,
    required bool contaminated,
    required bool idleSoftSignal,
    required bool motionSignal,
    required bool lifecycleSignal,
    required DateTime createdAt,
    int hintStepReached = 0,
    int chainIndex = 0,
    MoveMode? mode,
    MoveEventKind eventKind = MoveEventKind.production,
    int difficultyBand = 2,
    bool userAdjusted = false,
  }) {
    return _db.into(_db.moveEvents).insert(
          MoveEventsCompanion.insert(
            sessionId: sessionId,
            kindId: heuristic.kindId,
            heuristicTag: heuristic.tagId,
            latencyMs: latencyMs,
            wasCorrect: wasCorrect,
            hintRequested: hintRequested,
            hintStepReached: Value(hintStepReached),
            contaminatedFlag: contaminated,
            idleSoftSignal: idleSoftSignal,
            motionSignal: motionSignal,
            lifecycleSignal: lifecycleSignal,
            mode: Value(mode?.wire),
            eventKind: Value(eventKind.wire),
            chainIndex: Value(chainIndex),
            difficultyBand: Value(difficultyBand),
            userAdjusted: Value(userAdjusted),
            createdAt: createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  /// Lower-level escape hatch (used by existing tests and any caller
  /// that already constructs a Companion).
  Future<int> insert(MoveEventsCompanion companion) {
    return _db.into(_db.moveEvents).insert(companion);
  }

  Future<MoveEventRow?> findById(int id) {
    return (_db.select(_db.moveEvents)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Most recent events for a single [Heuristic], newest first.
  /// Optionally filtered to non-contaminated rows (the default for
  /// mastery-layer consumers).
  Stream<List<MoveEventRow>> watchRecent(
    Heuristic heuristic, {
    int limit = 100,
    bool excludeContaminated = true,
  }) {
    final query = _db.select(_db.moveEvents)
      ..where((t) => t.kindId.equals(heuristic.kindId))
      ..where((t) => t.heuristicTag.equals(heuristic.tagId));
    if (excludeContaminated) {
      query.where((t) => t.contaminatedFlag.equals(false));
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.watch();
  }

  Future<List<MoveEventRow>> recent(
    Heuristic heuristic, {
    int limit = 100,
    bool excludeContaminated = true,
  }) {
    final query = _db.select(_db.moveEvents)
      ..where((t) => t.kindId.equals(heuristic.kindId))
      ..where((t) => t.heuristicTag.equals(heuristic.tagId));
    if (excludeContaminated) {
      query.where((t) => t.contaminatedFlag.equals(false));
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.get();
  }

  Future<int> countSince(DateTime since) {
    final cutoff = since.millisecondsSinceEpoch;
    final query = _db.selectOnly(_db.moveEvents)
      ..addColumns([_db.moveEvents.id.count()])
      ..where(_db.moveEvents.createdAt.isBiggerOrEqualValue(cutoff));
    return query
        .map((row) => row.read(_db.moveEvents.id.count()) ?? 0)
        .getSingle();
  }
}
