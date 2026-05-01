import '../../engine/domain/heuristic.dart';
import '../database.dart';

class MasteryRepository {
  MasteryRepository(this._db);

  final LunaDatabase _db;

  Future<MasteryStateRow?> find(Heuristic h) {
    return (_db.select(_db.masteryState)
          ..where((t) => t.kindId.equals(h.kindId))
          ..where((t) => t.heuristicTag.equals(h.tagId)))
        .getSingleOrNull();
  }

  /// Insert-or-replace a row keyed by `(kindId, heuristicTag)`. The
  /// composite PK guarantees there is at most one row per heuristic.
  Future<void> upsert(MasteryStateCompanion companion) {
    return _db
        .into(_db.masteryState)
        .insertOnConflictUpdate(companion);
  }

  /// Live snapshot of every persisted mastery row — drives the
  /// Mastery screen radar.
  Stream<List<MasteryStateRow>> watchAll() {
    return _db.select(_db.masteryState).watch();
  }

  /// One-shot read of every persisted mastery row. Used by the
  /// scorer to recompute population mean across non-calibrating
  /// heuristics.
  Future<List<MasteryStateRow>> all() {
    return _db.select(_db.masteryState).get();
  }
}
