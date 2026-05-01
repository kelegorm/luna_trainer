import 'package:drift/drift.dart';

/// Per-heuristic rolling aggregates derived from [MoveEvents]. Updated
/// on session end (and optionally streamed mid-session). The Mastery
/// screen subscribes directly to this table.
@DataClassName('MasteryStateRow')
class MasteryState extends Table {
  TextColumn get kindId => text()();
  TextColumn get heuristicTag => text()();

  IntColumn get eventCount => integer().withDefault(const Constant(0))();

  /// EWMA of per-event percentile (not z). Stored on [0, 1].
  RealColumn get ewmaPercentile => real().withDefault(const Constant(0))();

  /// Count of events whose `|z| > 3` led to a drop (R7 outlier rule).
  /// Diagnostic-only — does not flow into mastery score.
  IntColumn get outlierCount => integer().withDefault(const Constant(0))();

  IntColumn get latencyP25Ms => integer().nullable()();
  IntColumn get latencyMedianMs => integer().nullable()();
  IntColumn get latencyP75Ms => integer().nullable()();

  RealColumn get errorRate => real().withDefault(const Constant(0))();
  RealColumn get hintRate => real().withDefault(const Constant(0))();

  /// JSON map of `{ "0": int, "1": int, ... }` — count of events per
  /// hint step reached. Stored as JSON to keep the schema flat.
  TextColumn get hintStepCountsJson =>
      text().withDefault(const Constant('{}'))();

  IntColumn get lastUpdatedAt => integer()();

  /// True until [eventCount] crosses the cold-start threshold (R10).
  /// Calibrating heuristics are kept out of the drill queue.
  BoolColumn get isCalibrating =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {kindId, heuristicTag};
}
