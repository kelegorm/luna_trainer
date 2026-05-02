import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../engine/domain/heuristic.dart';
import '../../../engine/mastery/mastery_scorer.dart';
import '../../../puzzles/tango/domain/tango_position.dart';
import '../../../puzzles/tango/generator/difficulty_band.dart';
import '../../../puzzles/tango/solver/tango_solver.dart';
import '../../full_game/band_rotator.dart';
import '../../full_game/bloc/full_game_bloc.dart';
import '../../full_game/replay_diff.dart';

// ────────────────────────────────────────────────────────────────────
// Events
// ────────────────────────────────────────────────────────────────────

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();

  @override
  List<Object?> get props => const [];
}

/// Триггер сборки экранного summary. Передаёт snapshot moves +
/// replay-diff из FullGameBloc-а (он уже обновил mastery к моменту
/// `GameCompleted`), Bloc сам подтянет per-heuristic deltas из
/// MasteryScorer-а.
class SummaryRequested extends SummaryEvent {
  const SummaryRequested({
    required this.recordedMoves,
    required this.replayDiff,
    this.initialPosition,
  });

  final List<RecordedMove> recordedMoves;
  final ReplayDiffResult? replayDiff;

  /// Стартовая позиция партии — нужна для R32 line_completion bias
  /// детектора. Если `null`, bias-детектор пропускается (например,
  /// в тестах SummaryBloc-а, где доска не реконструируется). Mode
  /// breakdown (R31) считается без этого поля.
  final TangoPosition? initialPosition;

  @override
  List<Object?> get props => [recordedMoves, replayDiff, initialPosition];
}

/// «Следующая» (auto): rotator выбирает band, `userAdjusted=false`.
class NextAuto extends SummaryEvent {
  const NextAuto();
}

/// «Ещё такую же»: тот же band, `userAdjusted=true`. Rotator state
/// **не** сдвигается — следующий auto продолжается с того же места.
class NextSame extends SummaryEvent {
  const NextSame();
}

/// «Сложнее ▲»: `currentBand.bumpUp()` (clamp to hard), `userAdjusted=true`.
class NextHarder extends SummaryEvent {
  const NextHarder();
}

/// «Легче ▼»: `currentBand.bumpDown()` (clamp to easy), `userAdjusted=true`.
class NextEasier extends SummaryEvent {
  const NextEasier();
}

// ────────────────────────────────────────────────────────────────────
// State
// ────────────────────────────────────────────────────────────────────

enum SummaryStatus { idle, loading, ready, failed }

/// Per-heuristic delta — медиана текущей mastery vs «как было раньше».
/// В base U11 нет before/after-снимка mastery, так что direction
/// определяем по errorRate / hintRate знакам в replay-moves.
class HeuristicDelta extends Equatable {
  const HeuristicDelta({
    required this.heuristic,
    required this.medianLatencyMs,
    required this.errorRate,
    required this.hintRate,
    required this.eventCount,
    required this.direction,
  });

  final Heuristic heuristic;
  final int? medianLatencyMs;
  final double errorRate;
  final double hintRate;
  final int eventCount;
  final SummaryDirection direction;

  @override
  List<Object?> get props => [
        heuristic,
        medianLatencyMs,
        errorRate,
        hintRate,
        eventCount,
        direction,
      ];
}

/// Знак изменения. `improved` = «прокачал», `regressed` =
/// «замедлился», `flat` = «без изменений / недостаточно данных».
enum SummaryDirection { improved, regressed, flat }

/// Запрос на запуск следующей партии — что выбрал пользователь
/// четырьмя post-session кнопками (R37). Surfaces в `SummaryState`,
/// чтобы UI мог дернуть `Navigator.pop(result)` и launcher перезапустил
/// `FullGameScreen` с новым band/userAdjusted.
class NextGameRequest extends Equatable {
  const NextGameRequest({
    required this.band,
    required this.userAdjusted,
  });

  final DifficultyBand band;
  final bool userAdjusted;

  @override
  List<Object?> get props => [band, userAdjusted];
}

class SummaryState extends Equatable {
  const SummaryState({
    this.status = SummaryStatus.idle,
    this.deltas = const [],
    this.replayDiff,
    this.modeBreakdown,
    this.biasIncidents = const [],
    this.errorMessage,
    this.nextGameRequest,
  });

  final SummaryStatus status;
  final List<HeuristicDelta> deltas;
  final ReplayDiffResult? replayDiff;

  /// R31: propagation/hunt доли + p99 hunt latency per-heuristic.
  /// `null` если SummaryRequested ещё не обработан или партия пустая.
  final ModeBreakdown? modeBreakdown;

  /// R32: список line_completion bias-инцидентов для секции
  /// «Bias-флаги». Пустой = чистая партия без bias.
  final List<BiasIncident> biasIncidents;

  final String? errorMessage;

  /// Set when the user picks one of the 4 post-session buttons.
  /// EndOfSessionScreen listens for the null→non-null transition and
  /// pops with this value so the launcher can restart the next game.
  final NextGameRequest? nextGameRequest;

  /// Удобный getter для UI: топ-улучшение по скорости.
  HeuristicDelta? get topImprovement {
    final improved = deltas.where((d) => d.direction == SummaryDirection.improved);
    if (improved.isEmpty) return null;
    return improved.reduce((a, b) =>
        (a.medianLatencyMs ?? 0) <= (b.medianLatencyMs ?? 0) ? a : b);
  }

  /// Топ-регрессия (самое медленное / hint-heavy).
  HeuristicDelta? get topRegression {
    final regressed =
        deltas.where((d) => d.direction == SummaryDirection.regressed);
    if (regressed.isEmpty) return null;
    return regressed.reduce((a, b) =>
        a.errorRate + a.hintRate >= b.errorRate + b.hintRate ? a : b);
  }

  int get drillCardsAdded => replayDiff?.count ?? 0;

  @override
  List<Object?> get props => [
        status,
        deltas,
        replayDiff?.count,
        modeBreakdown?.totalCounted,
        modeBreakdown?.propagationCount,
        modeBreakdown?.huntCount,
        biasIncidents.length,
        errorMessage,
        nextGameRequest,
      ];

  SummaryState copyWith({
    SummaryStatus? status,
    List<HeuristicDelta>? deltas,
    ReplayDiffResult? replayDiff,
    ModeBreakdown? modeBreakdown,
    List<BiasIncident>? biasIncidents,
    String? errorMessage,
    NextGameRequest? nextGameRequest,
  }) {
    return SummaryState(
      status: status ?? this.status,
      deltas: deltas ?? this.deltas,
      replayDiff: replayDiff ?? this.replayDiff,
      modeBreakdown: modeBreakdown ?? this.modeBreakdown,
      biasIncidents: biasIncidents ?? this.biasIncidents,
      errorMessage: errorMessage ?? this.errorMessage,
      nextGameRequest: nextGameRequest ?? this.nextGameRequest,
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Bloc
// ────────────────────────────────────────────────────────────────────

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  SummaryBloc({
    required MasteryScorer masteryScorer,
    BandRotator? bandRotator,
    DifficultyBand currentBand = DifficultyBand.medium,
    TangoSolver solver = const TangoSolver(),
  })  : _scorer = masteryScorer,
        _rotator = bandRotator,
        _currentBand = currentBand,
        _solver = solver,
        super(const SummaryState()) {
    on<SummaryRequested>(_onSummaryRequested);
    on<NextAuto>(_onNextAuto);
    on<NextSame>(_onNextSame);
    on<NextHarder>(_onNextHarder);
    on<NextEasier>(_onNextEasier);
  }

  final MasteryScorer _scorer;

  /// Rotator drives auto «Следующая» band selection. Optional so legacy
  /// callers (and tests that don't exercise the post-session buttons)
  /// can keep the old constructor shape; if `null`, [NextAuto] falls
  /// back to keeping `_currentBand` (no rotation).
  final BandRotator? _rotator;

  /// Band of the session that just ended. Set per-construction by the
  /// launcher (one SummaryBloc per session).
  final DifficultyBand _currentBand;

  /// Solver — нужен для R32 line_completion bias детектора. Default
  /// `const TangoSolver()` — stateless, можно держать singleton.
  final TangoSolver _solver;

  Future<void> _onSummaryRequested(
    SummaryRequested event,
    Emitter<SummaryState> emit,
  ) async {
    emit(state.copyWith(status: SummaryStatus.loading));
    try {
      // Группируем moves по heuristic — берём только не-contaminated.
      final groups = <Heuristic, List<RecordedMove>>{};
      for (final m in event.recordedMoves) {
        if (m.contaminated) continue;
        if (m.heuristic.tagId == 'Composite(unknown)') continue;
        groups.putIfAbsent(m.heuristic, () => <RecordedMove>[]).add(m);
      }

      final deltas = <HeuristicDelta>[];
      for (final entry in groups.entries) {
        final h = entry.key;
        final moves = entry.value;
        final latencies = moves.map((m) => m.latencyMs).toList()..sort();
        final median = latencies.isEmpty
            ? null
            : latencies[latencies.length ~/ 2];
        final errorCount = moves.where((m) => !m.wasCorrect).length;
        final hintCount = moves.where((m) => m.hintRequested).length;
        final errorRate = errorCount / moves.length;
        final hintRate = hintCount / moves.length;

        // Direction: replay-diff уже отметил heuristic как stuck →
        // regression. Иначе — если errorRate=0 и hintRate=0 →
        // improvement; иначе flat.
        SummaryDirection direction;
        final isStuck = event.replayDiff?.scheduledHeuristics.contains(h) ??
            false;
        if (isStuck || errorRate > 0 || hintRate > 0) {
          direction = isStuck ? SummaryDirection.regressed : SummaryDirection.flat;
          if (errorRate > 0.5) direction = SummaryDirection.regressed;
        } else {
          // Сверяемся с MasteryScorer — если EWMA уже выше среднего,
          // считаем improvement.
          final score = await _scorer.currentScore(h);
          direction = score.shrunkPercentile >= 0.5
              ? SummaryDirection.improved
              : SummaryDirection.flat;
        }

        deltas.add(HeuristicDelta(
          heuristic: h,
          medianLatencyMs: median,
          errorRate: errorRate,
          hintRate: hintRate,
          eventCount: moves.length,
          direction: direction,
        ));
      }

      // R31 — propagation/hunt summary (доли + p99 hunt latency).
      final modeBreakdown = computeModeBreakdown(event.recordedMoves);

      // R32 — line_completion bias детектор. Требует initialPosition;
      // если её нет (например, в legacy-тестах SummaryBloc), пропускаем
      // детекцию — UX-секция «Bias-флаги» просто не отрендерится.
      final List<BiasIncident> biasIncidents = event.initialPosition == null
          ? const []
          : detectLineCompletionBias(
              initialPosition: event.initialPosition!,
              moves: event.recordedMoves,
              solver: _solver,
            );

      emit(state.copyWith(
        status: SummaryStatus.ready,
        deltas: deltas,
        replayDiff: event.replayDiff,
        modeBreakdown: modeBreakdown,
        biasIncidents: biasIncidents,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SummaryStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onNextAuto(NextAuto event, Emitter<SummaryState> emit) async {
    final rotator = _rotator;
    final band = rotator == null
        ? _currentBand
        : await rotator.next(_currentBand);
    emit(state.copyWith(
      nextGameRequest: NextGameRequest(band: band, userAdjusted: false),
    ));
  }

  void _onNextSame(NextSame event, Emitter<SummaryState> emit) {
    // Rotator state не сдвигается: следующий auto продолжается с
    // того же step-а, что был бы выбран без «Ещё такую же».
    emit(state.copyWith(
      nextGameRequest: NextGameRequest(
        band: _currentBand,
        userAdjusted: true,
      ),
    ));
  }

  void _onNextHarder(NextHarder event, Emitter<SummaryState> emit) {
    emit(state.copyWith(
      nextGameRequest: NextGameRequest(
        band: _currentBand.bumpUp(),
        userAdjusted: true,
      ),
    ));
  }

  void _onNextEasier(NextEasier event, Emitter<SummaryState> emit) {
    emit(state.copyWith(
      nextGameRequest: NextGameRequest(
        band: _currentBand.bumpDown(),
        userAdjusted: true,
      ),
    ));
  }
}
