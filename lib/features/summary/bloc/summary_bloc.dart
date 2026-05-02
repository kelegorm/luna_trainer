import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../engine/domain/heuristic.dart';
import '../../../engine/mastery/mastery_scorer.dart';
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
  });

  final List<RecordedMove> recordedMoves;
  final ReplayDiffResult? replayDiff;

  @override
  List<Object?> get props => [recordedMoves, replayDiff];
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

class SummaryState extends Equatable {
  const SummaryState({
    this.status = SummaryStatus.idle,
    this.deltas = const [],
    this.replayDiff,
    this.errorMessage,
  });

  final SummaryStatus status;
  final List<HeuristicDelta> deltas;
  final ReplayDiffResult? replayDiff;
  final String? errorMessage;

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
  List<Object?> get props => [status, deltas, replayDiff?.count, errorMessage];

  SummaryState copyWith({
    SummaryStatus? status,
    List<HeuristicDelta>? deltas,
    ReplayDiffResult? replayDiff,
    String? errorMessage,
  }) {
    return SummaryState(
      status: status ?? this.status,
      deltas: deltas ?? this.deltas,
      replayDiff: replayDiff ?? this.replayDiff,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Bloc
// ────────────────────────────────────────────────────────────────────

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  SummaryBloc({
    required MasteryScorer masteryScorer,
  })  : _scorer = masteryScorer,
        super(const SummaryState()) {
    on<SummaryRequested>(_onSummaryRequested);
  }

  final MasteryScorer _scorer;

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

      emit(state.copyWith(
        status: SummaryStatus.ready,
        deltas: deltas,
        replayDiff: event.replayDiff,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SummaryStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }
}
