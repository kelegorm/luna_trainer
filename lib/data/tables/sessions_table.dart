import 'package:drift/drift.dart';

/// One session of either Full-game or Drill mode.
@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'full_game' or 'drill'. Stored as text to keep the schema legible
  /// across migrations without enum-renaming hazards.
  TextColumn get mode => text()();

  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();

  /// JSON-encoded summary surface (per-heuristic deltas, replay-diff
  /// drill-card ids, etc.). Free-form so summary shape can evolve
  /// without migrations.
  TextColumn get outcomeJson => text().nullable()();
}
