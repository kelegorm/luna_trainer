import 'package:drift/drift.dart';

import '../../engine/domain/heuristic.dart';
import '../database.dart';
import '../tables/move_events_table.dart';

/// Thin wrapper over the [MoveEvents] table. Holds zero business
/// logic — mastery scoring, contamination filtering, FSRS rating all
/// live in the engine layer.
class MoveEventsRepository {
  MoveEventsRepository(this._db);

  final LunaDatabase _db;

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
