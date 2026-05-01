import 'package:drift/drift.dart';

import '../database.dart';

class SessionsRepository {
  SessionsRepository(this._db);

  final LunaDatabase _db;

  Future<int> insert(SessionsCompanion companion) {
    return _db.into(_db.sessions).insert(companion);
  }

  Future<SessionRow?> findById(int id) {
    return (_db.select(_db.sessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> markEnded({
    required int id,
    required DateTime endedAt,
    String? outcomeJson,
  }) {
    return (_db.update(_db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        endedAt: Value(endedAt.millisecondsSinceEpoch),
        outcomeJson: Value(outcomeJson),
      ),
    );
  }
}
