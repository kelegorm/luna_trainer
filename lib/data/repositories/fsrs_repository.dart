import 'package:drift/drift.dart';

import '../../engine/domain/heuristic.dart';
import '../database.dart';
import '../tables/fsrs_cards_table.dart';

class FsrsRepository {
  FsrsRepository(this._db);

  final LunaDatabase _db;

  Future<FsrsCardRow?> find(Heuristic h) {
    return (_db.select(_db.fsrsCards)
          ..where((t) => t.kindId.equals(h.kindId))
          ..where((t) => t.heuristicTag.equals(h.tagId)))
        .getSingleOrNull();
  }

  Future<void> upsert(FsrsCardsCompanion companion) {
    return _db.into(_db.fsrsCards).insertOnConflictUpdate(companion);
  }

  /// All cards whose review is due at or before [now], ordered by
  /// [FsrsCards.dueAt] (oldest first). Drill selector is the consumer.
  Future<List<FsrsCardRow>> dueAt(DateTime now) {
    final cutoff = now.millisecondsSinceEpoch;
    final query = _db.select(_db.fsrsCards)
      ..where((t) => t.dueAt.isSmallerOrEqualValue(cutoff))
      ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]);
    return query.get();
  }
}
