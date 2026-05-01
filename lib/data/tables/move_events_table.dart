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

  /// 'propagation' | 'hunt' (R31). Партионный режим (full_game/drill)
  /// живёт в [Sessions.mode]; здесь — только классификация хода.
  /// Nullable: первый ход партии или пока классификатор не вынес
  /// решение.
  TextColumn get mode => text().nullable()();

  /// 'production' | 'recognition_hit' | 'recognition_correct_reject' |
  /// 'recognition_false_alarm' (R29). Phase C всегда 'production';
  /// recognition-варианты добавляются в Phase D (U12) без миграции.
  TextColumn get eventKind =>
      text().withDefault(const Constant('production'))();

  /// 0 = the originating drill / full-game move; 1..N = ChainExtension
  /// follow-ons within the same drill card (R5).
  IntColumn get chainIndex => integer().withDefault(const Constant(0))();

  /// Difficulty band под которым партия была сгенерирована: 1=easy,
  /// 2=medium, 3=hard (R36). Denormalized с [Sessions.difficultyBand]
  /// для будущего factorial-анализа без JOIN. В v1 mastery/FSRS не
  /// читают это поле.
  IntColumn get difficultyBand => integer().withDefault(const Constant(2))();

  /// Был ли band в этой партии подкручен пользователем post-session
  /// nudge-кнопкой относительно автоматической ротации (R38).
  /// Denormalized с [Sessions.userAdjusted].
  BoolColumn get userAdjusted =>
      boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();
}
