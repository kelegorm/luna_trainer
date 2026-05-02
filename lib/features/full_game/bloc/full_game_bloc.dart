import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/move_events_repository.dart';
import '../../../data/repositories/sessions_repository.dart';
import '../../../engine/domain/heuristic.dart';
import '../../../engine/mastery/mastery_scorer.dart';
import '../../../engine/telemetry/move_mode_classifier.dart';
import '../../../engine/telemetry/move_timer_service.dart';
import '../../../puzzles/tango/domain/tango_mark.dart';
import '../../../puzzles/tango/domain/tango_position.dart';
import '../../../puzzles/tango/domain/tango_rules.dart';
import '../../../puzzles/tango/generator/board_shape.dart';
import '../../../puzzles/tango/generator/difficulty_band.dart';
import '../../../puzzles/tango/generator/generator_result.dart';
import '../../../puzzles/tango/generator/tango_level_generator.dart';
import '../../../puzzles/tango/generator/tango_puzzle.dart';
import '../../../puzzles/tango/generator/target_mix.dart';
import '../../../puzzles/tango/solver/tango_deduction.dart';
import '../../../puzzles/tango/solver/tango_solver.dart';
import '../replay_diff.dart';

// ────────────────────────────────────────────────────────────────────
// Events
// ────────────────────────────────────────────────────────────────────

abstract class FullGameEvent extends Equatable {
  const FullGameEvent();

  @override
  List<Object?> get props => const [];
}

/// Старт партии. Bloc генерит puzzle, открывает сессию, стартует
/// таймер первого хода.
class GameStarted extends FullGameEvent {
  const GameStarted({this.seed});
  final int? seed;

  @override
  List<Object?> get props => [seed];
}

/// Игрок поставил/снял знак. Bloc классифицирует ход через solver,
/// записывает MoveEvent, обновляет position и стартует таймер
/// следующего хода (или завершает партию).
class MoveCommitted extends FullGameEvent {
  const MoveCommitted({
    required this.row,
    required this.col,
    required this.mark,
  });

  final int row;
  final int col;
  final TangoMark? mark;

  @override
  List<Object?> get props => [row, col, mark];
}

/// Пользователь открыл лесенку hint (R12, R13). step → 1.
class HintRequested extends FullGameEvent {
  const HintRequested();
}

/// Пользователь нажал «дальше» в overlay-е лесенки. step++ (1 → 2 → 3 →
/// 4). На step 4 таймер паузится (R13 / AE2).
class HintStepAdvanced extends FullGameEvent {
  const HintStepAdvanced();
}

/// Пользователь закрыл overlay лесенки. Если был на step 4 — таймер
/// resumes.
class HintDismissed extends FullGameEvent {
  const HintDismissed();
}

/// Финальный ход дописан. Запускает replay-diff + summary, переводит
/// status в `completed`. Можно слать снаружи (например, из UI после
/// детектирования isComplete) или сам Bloc решит сделать после
/// MoveCommitted.
class GameCompleted extends FullGameEvent {
  const GameCompleted();
}

// ────────────────────────────────────────────────────────────────────
// State
// ────────────────────────────────────────────────────────────────────

enum FullGameStatus { idle, generating, playing, completed, failed }

class FullGameState extends Equatable {
  const FullGameState({
    this.status = FullGameStatus.idle,
    this.position,
    this.puzzle,
    this.sessionId,
    this.hintStep = 0,
    this.hintOverlayOpen = false,
    this.suggestedDeduction,
    this.recordedMoves = const [],
    this.replayDiff,
    this.errorMessage,
  });

  final FullGameStatus status;

  /// Текущая позиция доски. `null` пока партия не сгенерирована.
  final TangoPosition? position;

  /// Сгенерированный puzzle (initial + solution). `null` до старта.
  final TangoPuzzle? puzzle;

  /// id сессии, открытой в `sessions`-таблице.
  final int? sessionId;

  /// Шаг лесенки (0 = не открыта, 1..4 = step из R13).
  final int hintStep;

  /// Открыт ли overlay лесенки (отделено от `hintStep` чтобы можно
  /// было закрыть UI без потери max-step-а в данных).
  final bool hintOverlayOpen;

  /// Solver-предсказание для подсветки в overlay-е (step 2/3). `null`
  /// если позиция уже не имеет cheap-deduction-ов.
  final TangoDeduction? suggestedDeduction;

  /// Все committed-MoveEvent-ы текущей партии — нужны для replay-diff
  /// в GameCompleted и для summary-блока.
  final List<RecordedMove> recordedMoves;

  /// Результат replay-diff после завершения партии (R18).
  final ReplayDiffResult? replayDiff;

  final String? errorMessage;

  bool get isPlaying => status == FullGameStatus.playing;
  bool get isCompleted => status == FullGameStatus.completed;

  FullGameState copyWith({
    FullGameStatus? status,
    TangoPosition? position,
    TangoPuzzle? puzzle,
    int? sessionId,
    int? hintStep,
    bool? hintOverlayOpen,
    TangoDeduction? suggestedDeduction,
    bool clearSuggestion = false,
    List<RecordedMove>? recordedMoves,
    ReplayDiffResult? replayDiff,
    String? errorMessage,
  }) {
    return FullGameState(
      status: status ?? this.status,
      position: position ?? this.position,
      puzzle: puzzle ?? this.puzzle,
      sessionId: sessionId ?? this.sessionId,
      hintStep: hintStep ?? this.hintStep,
      hintOverlayOpen: hintOverlayOpen ?? this.hintOverlayOpen,
      suggestedDeduction: clearSuggestion
          ? null
          : (suggestedDeduction ?? this.suggestedDeduction),
      recordedMoves: recordedMoves ?? this.recordedMoves,
      replayDiff: replayDiff ?? this.replayDiff,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        position,
        puzzle?.seed,
        sessionId,
        hintStep,
        hintOverlayOpen,
        suggestedDeduction,
        recordedMoves.length,
        replayDiff?.count,
        errorMessage,
      ];
}

/// Снапшот одного зафиксированного хода — нужен для post-game
/// replay-diff-а и mastery-стриминга. Поля совпадают с
/// `MoveEvent`-ами, что пишет Bloc, чтобы не перечитывать БД.
class RecordedMove extends Equatable {
  const RecordedMove({
    required this.heuristic,
    required this.row,
    required this.col,
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

// ────────────────────────────────────────────────────────────────────
// Bloc
// ────────────────────────────────────────────────────────────────────

/// Контракт для replay-diff: тонкий wrapper над U9 FSRS scheduler-ом.
typedef ReplayDiffRunner = Future<ReplayDiffResult> Function(
  List<ReplayMove> moves,
);

/// Подключаемая mastery-стриминговая функция. Вызывается на
/// GameCompleted один раз для каждого не-контаминированного moveEvent.
typedef MasteryUpdater = Future<void> Function(MasteryEvent event);

class FullGameBloc extends Bloc<FullGameEvent, FullGameState> {
  FullGameBloc({
    required SessionsRepository sessionsRepository,
    required MoveEventsRepository moveEventsRepository,
    required MoveTimerService moveTimer,
    required ReplayDiffRunner replayDiffRunner,
    required MasteryUpdater masteryUpdater,
    TangoLevelGenerator? levelGenerator,
    TangoSolver solver = const TangoSolver(),
    DifficultyBand band = DifficultyBand.medium,
    DateTime Function() clock = _systemClock,
  })  : _sessions = sessionsRepository,
        _moves = moveEventsRepository,
        _moveTimer = moveTimer,
        _replayDiff = replayDiffRunner,
        _masteryUpdater = masteryUpdater,
        _generator = levelGenerator ?? const TangoLevelGenerator(),
        _solver = solver,
        _band = band,
        _clock = clock,
        super(const FullGameState()) {
    on<GameStarted>(_onGameStarted);
    on<MoveCommitted>(_onMoveCommitted);
    on<HintRequested>(_onHintRequested);
    on<HintStepAdvanced>(_onHintStepAdvanced);
    on<HintDismissed>(_onHintDismissed);
    on<GameCompleted>(_onGameCompleted);
  }

  final SessionsRepository _sessions;
  final MoveEventsRepository _moves;
  final MoveTimerService _moveTimer;
  final ReplayDiffRunner _replayDiff;
  final MasteryUpdater _masteryUpdater;
  final TangoLevelGenerator _generator;
  final TangoSolver _solver;
  final DifficultyBand _band;
  final DateTime Function() _clock;

  /// Контекст последнего хода — нужен MoveModeClassifier-у.
  PreviousMoveContext? _previousMove;

  /// Hint-step, фиксируемый в следующий MoveEvent (R13 — мы хотим
  /// чтобы heuristic, дойдя до hint-ладдер step k и затем игрок
  /// сделал ход, имел `hint_step_reached=k` в этой записи).
  int _pendingHintStep = 0;
  bool _pendingHintRequested = false;

  static DateTime _systemClock() => DateTime.now();

  // ── Handlers ──────────────────────────────────────────────────

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<FullGameState> emit,
  ) async {
    emit(state.copyWith(status: FullGameStatus.generating));
    try {
      final mix = _defaultMix();
      final result = _generator.generate(
        mix: mix,
        shape: BoardShape.full6x6(),
        seed: event.seed,
        band: _band,
      );
      final puzzle = _puzzleFrom(result);
      if (puzzle == null) {
        emit(state.copyWith(
          status: FullGameStatus.failed,
          errorMessage: 'Generator failed to produce a puzzle',
        ));
        return;
      }
      final sessionId = await _sessions.startSession(
        mode: 'full_game',
        startedAt: _clock(),
        band: _band.value,
      );
      _previousMove = null;
      _pendingHintStep = 0;
      _pendingHintRequested = false;
      _moveTimer.startMove();
      emit(FullGameState(
        status: FullGameStatus.playing,
        position: puzzle.initialPosition,
        puzzle: puzzle,
        sessionId: sessionId,
        recordedMoves: const [],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FullGameStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onMoveCommitted(
    MoveCommitted event,
    Emitter<FullGameState> emit,
  ) async {
    final pos = state.position;
    final sessionId = state.sessionId;
    if (pos == null || sessionId == null || !state.isPlaying) return;

    // Solver классифицирует ход по cheapest-deduction-у текущей
    // позиции. Если ход совпадает с одной из cheap-deductions, берём
    // её heuristic; иначе — Composite(unknown). Это согласуется с
    // tracing-логикой генератора (R10).
    final available = _solver.availableDeductions(pos);
    final matchedDeduction = _matchDeduction(available, event);
    final heuristic = matchedDeduction?.heuristic ??
        const Heuristic('tango', 'Composite(unknown)');

    // Корректность хода = совпадает с solution-ом (R1).
    final solution = state.puzzle?.solution;
    final wasCorrect = solution == null
        ? true
        : solution.cells[event.row][event.col] == event.mark;

    final timing = _moveTimer.commitMove();
    final commitAt = _clock();

    final mode = MoveModeClassifier.classify(
      previous: _previousMove,
      currentRow: event.row,
      currentCol: event.col,
      currentAt: commitAt,
      previousConnectedBySign: _connectedBySign(pos, event.row, event.col),
    );

    final hintStepReached = _pendingHintStep;
    final hintRequested = _pendingHintRequested;
    _pendingHintStep = 0;
    _pendingHintRequested = false;

    await _moves.commit(
      sessionId: sessionId,
      heuristic: heuristic,
      latencyMs: timing.latencyMs,
      wasCorrect: wasCorrect,
      hintRequested: hintRequested,
      hintStepReached: hintStepReached,
      contaminated: timing.contaminatedFlag,
      idleSoftSignal: timing.signals.idleSoftSignal,
      motionSignal: timing.signals.motionSignal,
      lifecycleSignal: timing.signals.lifecycleSignal,
      createdAt: commitAt,
      mode: mode,
      eventKind: MoveEventKind.production,
      difficultyBand: _band.value,
      userAdjusted: false,
    );

    // Stream mastery per-move (was: batched at GameCompleted). Batching
    // 28 mastery updates after the final tap added ~half a second of
    // perceived UI lag before the end-of-session screen appeared. With
    // streaming each individual move pays a few ms during normal play
    // when the user is looking at the board, not waiting for a route
    // transition. MasteryScorer.updateOnEvent itself drops contaminated
    // events, so the filter does not need to live here.
    await _masteryUpdater(MasteryEvent(
      heuristic: heuristic,
      latencyMs: timing.latencyMs,
      wasCorrect: wasCorrect,
      hintRequested: hintRequested,
      contaminated: timing.contaminatedFlag,
      hintStepReached: hintStepReached,
    ));

    final recorded = RecordedMove(
      heuristic: heuristic,
      row: event.row,
      col: event.col,
      latencyMs: timing.latencyMs,
      contaminated: timing.contaminatedFlag,
      idleSoftSignal: timing.signals.idleSoftSignal,
      motionSignal: timing.signals.motionSignal,
      lifecycleSignal: timing.signals.lifecycleSignal,
      wasCorrect: wasCorrect,
      hintRequested: hintRequested,
      hintStepReached: hintStepReached,
      mode: mode,
      createdAt: commitAt,
    );

    final newPos = pos.withCell(event.row, event.col, event.mark);
    final updatedMoves = [...state.recordedMoves, recorded];
    _previousMove = PreviousMoveContext(
      row: event.row,
      col: event.col,
      at: commitAt,
    );

    emit(state.copyWith(
      position: newPos,
      recordedMoves: updatedMoves,
      hintStep: 0,
      hintOverlayOpen: false,
      clearSuggestion: true,
    ));

    if (isComplete(newPos)) {
      add(const GameCompleted());
    } else {
      _moveTimer.startMove();
    }
  }

  void _onHintRequested(
    HintRequested event,
    Emitter<FullGameState> emit,
  ) {
    if (!state.isPlaying) return;
    final available = _solver.availableDeductions(state.position!);
    final suggestion = available.isEmpty ? null : available.first;
    _pendingHintRequested = true;
    _pendingHintStep = 1;
    emit(state.copyWith(
      hintStep: 1,
      hintOverlayOpen: true,
      suggestedDeduction: suggestion,
    ));
  }

  void _onHintStepAdvanced(
    HintStepAdvanced event,
    Emitter<FullGameState> emit,
  ) {
    if (!state.isPlaying || !state.hintOverlayOpen) return;
    final next = (state.hintStep + 1).clamp(1, 4);
    if (next == state.hintStep) return;
    if (next > _pendingHintStep) _pendingHintStep = next;
    if (next == 4) {
      _moveTimer.pause();
    }
    emit(state.copyWith(hintStep: next));
  }

  void _onHintDismissed(
    HintDismissed event,
    Emitter<FullGameState> emit,
  ) {
    if (!state.hintOverlayOpen) return;
    if (state.hintStep == 4) {
      _moveTimer.resume();
    }
    emit(state.copyWith(
      hintOverlayOpen: false,
    ));
  }

  Future<void> _onGameCompleted(
    GameCompleted event,
    Emitter<FullGameState> emit,
  ) async {
    if (state.status == FullGameStatus.completed) return;
    final sessionId = state.sessionId;
    final replayMoves = [
      for (final m in state.recordedMoves)
        ReplayMove(
          heuristic: m.heuristic,
          latencyMs: m.latencyMs,
          contaminated: m.contaminated,
          wasCorrect: m.wasCorrect,
          hintStepReached: m.hintStepReached,
        ),
    ];

    final diff = await _replayDiff(replayMoves);

    // Mastery updates are now streamed per-move in [_onMoveCommitted];
    // see the comment there for the rationale.

    if (sessionId != null) {
      await _sessions.markEnded(
        id: sessionId,
        endedAt: _clock(),
        outcomeJson: _encodeOutcome(diff),
      );
    }

    emit(state.copyWith(
      status: FullGameStatus.completed,
      replayDiff: diff,
      hintOverlayOpen: false,
    ));
  }

  // ── helpers ───────────────────────────────────────────────────

  TargetMix _defaultMix() {
    // План: «`TangoLevelGenerator.generate(TargetMix.unconstrained(),
    // shape=full)`» — но фабрика unconstrained отсутствует. В
    // band-режиме mix-tolerance gate отключён (см.
    // [TangoLevelGenerator.generate]), так что mix здесь —
    // информационный. Берём uniform по basic-heuristics.
    return TargetMix.uniform(over: const [
      Heuristic('tango', 'PairCompletion'),
      Heuristic('tango', 'TrioAvoidance'),
      Heuristic('tango', 'ParityFill'),
      Heuristic('tango', 'SignPropagation'),
    ]);
  }

  TangoPuzzle? _puzzleFrom(GeneratorResult result) {
    if (result is GeneratorSuccess) return result.puzzle;
    if (result is GeneratorBestEffort) return result.puzzle;
    return null;
  }

  /// Совпадает ли ход с одной из cheap-deductions. Разрешаем ход на
  /// клетку из `forcedCells` с правильной маркой. Иначе — null
  /// (Composite(unknown)).
  TangoDeduction? _matchDeduction(
    List<TangoDeduction> available,
    MoveCommitted event,
  ) {
    if (event.mark == null) return null;
    for (final d in available) {
      if (d.forcedMark != event.mark) continue;
      for (final cell in d.forcedCells) {
        if (cell.row == event.row && cell.col == event.col) return d;
      }
    }
    return null;
  }

  /// True, если предыдущий ход связан с (row,col) =/× constraint-ом.
  bool _connectedBySign(TangoPosition pos, int row, int col) {
    final prev = _previousMove;
    if (prev == null) return false;
    for (final c in pos.constraints) {
      final touchesPrev = (c.cellA.row == prev.row && c.cellA.col == prev.col) ||
          (c.cellB.row == prev.row && c.cellB.col == prev.col);
      final touchesCurrent = (c.cellA.row == row && c.cellA.col == col) ||
          (c.cellB.row == row && c.cellB.col == col);
      if (touchesPrev && touchesCurrent) return true;
    }
    return false;
  }

  String _encodeOutcome(ReplayDiffResult diff) {
    return jsonEncode({'replay_diff': diff.toJson()});
  }
}
