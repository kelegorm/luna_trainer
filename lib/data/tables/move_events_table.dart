import 'package:drift/drift.dart';

import 'sessions_table.dart';

/// One classified move emitted by the player while playing a full game
/// or a drill card. The append-only lifeblood of the diagnostic
/// pipeline (R14): mastery scoring, contamination filtering, FSRS
/// rating, and replay-diff all read from here.
@DataClassName('MoveEventRow')
class MoveEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Namespace partition for [Heuristic]. v1 always 'tango' (R26).
  TextColumn get kindId => text()();

  /// Tag side of the [Heuristic] key (e.g. 'ParityFill').
  TextColumn get heuristicTag => text()();

  IntColumn get latencyMs => integer()();
  BoolColumn get wasCorrect => boolean()();

  BoolColumn get hintRequested => boolean()();

  /// 0 = no hint, 1..4 = hint ladder step the player reached on this
  /// move (F3, R12, R13).
  IntColumn get hintStepReached => integer().withDefault(const Constant(0))();

  /// Effective contamination decision (lifecycle OR motion in v1).
  /// Events where this is true are excluded from mastery aggregates.
  BoolColumn get contaminatedFlag => boolean()();

  /// Independent contamination signals — kept for diagnostics and for
  /// later threshold calibration (Open Questions deferred to impl).
  BoolColumn get idleSoftSignal => boolean()();
  BoolColumn get motionSignal => boolean()();
  BoolColumn get lifecycleSignal => boolean()();

  /// 'full_game' or 'drill'. Mirrors [Sessions.mode] for fast filters.
  TextColumn get mode => text()();

  /// 0 = the originating drill / full-game move; 1..N = ChainExtension
  /// follow-ons within the same drill card (R5).
  IntColumn get chainIndex => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();
}
