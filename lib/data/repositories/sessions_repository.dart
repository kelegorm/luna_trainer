import 'package:drift/drift.dart';

import '../database.dart';

/// Authoritative session lifecycle: create on game start, mark ended
/// on game end. Carries the difficulty band that subsequent
/// MoveEvents in this session will denormalize for factorial analysis.
class SessionsRepository {
  SessionsRepository(this._db);

  final LunaDatabase _db;

  /// Open a new session row. [band] (1=easy, 2=medium, 3=hard) and
  /// [userAdjusted] default to medium / unadjusted to match the
  /// schema-level defaults; pass them when the rotator (U11) has
  /// already chosen otherwise.
  Future<int> startSession({
    required String mode,
    required DateTime startedAt,
    int band = 2,
    bool userAdjusted = false,
  }) {
    return _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            mode: mode,
            startedAt: startedAt.millisecondsSinceEpoch,
            difficultyBand: Value(band),
            userAdjusted: Value(userAdjusted),
          ),
        );
  }

  /// Lower-level escape hatch for tests and migration shims.
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
