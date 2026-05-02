import 'package:equatable/equatable.dart';

import '../../engine/domain/heuristic.dart';
import '../../engine/telemetry/move_mode_classifier.dart';
import '../../puzzles/tango/domain/tango_mark.dart';

/// Снапшот одного зафиксированного хода — нужен для post-game
/// replay-diff-а, mastery-стриминга и summary-метрик. Поля совпадают с
/// `MoveEvent`-ами, что пишет Bloc, чтобы не перечитывать БД.
///
/// Вынесено в отдельный файл (а не в `full_game_bloc.dart`), чтобы
/// `replay_diff.dart` мог импортировать его без циклической
/// зависимости с Bloc-ом. `full_game_bloc.dart` re-export-ит этот
/// `RecordedMove` для backwards compat импорт-сайтов.
class RecordedMove extends Equatable {
  const RecordedMove({
    required this.heuristic,
    required this.row,
    required this.col,
    required this.mark,
    required this.latencyMs,
    required this.contaminated,
    required this.idleSoftSignal,
    required this.motionSignal,
    required this.lifecycleSignal,
    required this.wasCorrect,
    required this.hintRequested,
    required this.hintStepReached,
    required this.mode,
    required this.createdAt,
  });

  final Heuristic heuristic;
  final int row;
  final int col;

  /// Mark, фактически поставленный пользователем (`null` = снятие
  /// знака). Нужен post-game-детекторам (R32 line_completion bias)
  /// чтобы реконструировать позицию доски, не перечитывая БД.
  final TangoMark? mark;

  final int latencyMs;
  final bool contaminated;
  final bool idleSoftSignal;
  final bool motionSignal;
  final bool lifecycleSignal;
  final bool wasCorrect;
  final bool hintRequested;
  final int hintStepReached;
  final MoveMode mode;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        heuristic,
        row,
        col,
        mark,
        latencyMs,
        contaminated,
        idleSoftSignal,
        motionSignal,
        lifecycleSignal,
        wasCorrect,
        hintRequested,
        hintStepReached,
        mode,
        createdAt,
      ];
}
