import 'package:fsrs/fsrs.dart' as fsrs;

import '../../data/repositories/fsrs_repository.dart';
import '../../engine/domain/heuristic.dart';
import '../../engine/fsrs/fsrs_scheduler.dart';
import '../../engine/mastery/baseline_provider.dart';
import '../../engine/telemetry/move_mode_classifier.dart';
import '../../puzzles/tango/domain/tango_position.dart';
import '../../puzzles/tango/solver/tango_solver.dart';
import 'recorded_move.dart';

/// Один зафиксированный ход партии для post-game replay-diff (R17,
/// R18). Достаточный минимум полей: solver-классификация, задержка,
/// контаминация. Замусориваться полным [MoveEventRow] не нужно —
/// replay-diff живёт чисто на этих данных + baseline-таблице.
class ReplayMove {
  const ReplayMove({
    required this.heuristic,
    required this.latencyMs,
    required this.contaminated,
    this.wasCorrect = true,
    this.hintStepReached = 0,
  });

  final Heuristic heuristic;
  final int latencyMs;
  final bool contaminated;
  final bool wasCorrect;
  final int hintStepReached;
}

/// Один кандидат stuck-move, выбранный replay-diff-ом для drill-card
/// генерации.
class ReplayDiffCandidate {
  const ReplayDiffCandidate({
    required this.heuristic,
    required this.latencyMs,
    required this.baselineMs,
    required this.gapMs,
  });

  final Heuristic heuristic;
  final int latencyMs;
  final int baselineMs;

  /// `latencyMs - baselineMs`. Положительный = ход был медленнее
  /// solver-baseline, кандидат на drill.
  final int gapMs;

  Map<String, dynamic> toJson() => {
        'kind': heuristic.kindId,
        'tag': heuristic.tagId,
        'latency_ms': latencyMs,
        'baseline_ms': baselineMs,
        'gap_ms': gapMs,
      };
}

/// Результат прогона replay-diff-а: список кандидатов (≤ [maxPicks]) и
/// id-карточек, которые попали в FSRS-очередь. Сохраняется в
/// `sessions.outcome_json` как часть summary (R18).
class ReplayDiffResult {
  const ReplayDiffResult({
    required this.candidates,
    required this.scheduledHeuristics,
  });

  final List<ReplayDiffCandidate> candidates;
  final List<Heuristic> scheduledHeuristics;

  bool get isEmpty => candidates.isEmpty;
  int get count => candidates.length;

  Map<String, dynamic> toJson() => {
        'candidates': [for (final c in candidates) c.toJson()],
        'scheduled_count': scheduledHeuristics.length,
      };
}

/// Post-game replay-as-tutor (R17, R18).
///
/// Принимает список фактических ходов партии (с solver-tag + latency)
/// и:
///
/// 1. Дропает контаминированные / Composite(unknown) ходы (R10).
/// 2. По каждому heuristic считает gap = `latency_ms - baselineMs`.
/// 3. Берёт top-[maxPicks] ходов с положительным gap-ом, отсортированных
///    по убыванию.
/// 4. Если по этому heuristic ещё нет FSRS-карточки — создаёт через
///    [FsrsScheduler.reviewCard] с rating Hard (тянет due на завтра).
///    Если карточка существует — тоже review-Hard, что обычно
///    переставляет due в "tomorrow"-окно.
///
/// Pure-ish: вся работа над БД через инжектируемые [FsrsScheduler] и
/// [FsrsRepository]; сам класс stateless, можно держать как const.
class ReplayDiff {
  const ReplayDiff({
    this.maxPicks = 3,
    this.minGapMs = 0,
  });

  /// Максимум cards, который заведётся за один replay-diff. План
  /// называет «2-3 stuck-moments» — `maxPicks=3` соответствует.
  final int maxPicks;

  /// Минимальный gap, ниже которого ход не считается stuck-moment.
  /// Default 0: любой ход медленнее baseline-а — кандидат. Тесты
  /// AE6 / happy-path проверяют 2.5x baseline.
  final int minGapMs;

  /// Чистая (не-IO) часть алгоритма: возвращает упорядоченных
  /// кандидатов по gap (по убыванию). Удобно тестировать без БД.
  List<ReplayDiffCandidate> selectCandidates({
    required List<ReplayMove> moves,
    required BaselineProvider baselines,
  }) {
    final candidates = <ReplayDiffCandidate>[];
    for (final m in moves) {
      if (m.contaminated) continue;
      // Composite(unknown) не кладётся в drill (R10).
      if (m.heuristic.tagId == 'Composite(unknown)') continue;
      final spec = baselines.forHeuristic(m.heuristic);
      final gap = m.latencyMs - spec.medianMs;
      if (gap <= minGapMs) continue;
      candidates.add(ReplayDiffCandidate(
        heuristic: m.heuristic,
        latencyMs: m.latencyMs,
        baselineMs: spec.medianMs,
        gapMs: gap,
      ));
    }
    candidates.sort((a, b) => b.gapMs.compareTo(a.gapMs));

    // Дедуп по heuristic — один heuristic = одна drill-card.
    final seen = <Heuristic>{};
    final unique = <ReplayDiffCandidate>[];
    for (final c in candidates) {
      if (seen.add(c.heuristic)) unique.add(c);
      if (unique.length >= maxPicks) break;
    }
    return unique;
  }

  /// Полный прогон: выбирает кандидатов и заводит/обновляет FSRS
  /// карточки. Возвращает [ReplayDiffResult] для сохранения в
  /// sessions.outcome_json.
  Future<ReplayDiffResult> run({
    required List<ReplayMove> moves,
    required BaselineProvider baselines,
    required FsrsScheduler scheduler,
    required FsrsRepository fsrsRepository,
    DateTime? now,
  }) async {
    final candidates = selectCandidates(moves: moves, baselines: baselines);
    final scheduled = <Heuristic>[];
    for (final c in candidates) {
      // Hard rating ≈ "посчитай это слабым" — FSRS подвинет due на
      // завтра-послезавтра в зависимости от истории. План говорит
      // «due_at = tomorrow», тест AE6 проверяет, что due ≤ now+2дня.
      await scheduler.reviewCard(c.heuristic, fsrs.Rating.hard, now: now);
      scheduled.add(c.heuristic);
    }
    return ReplayDiffResult(
      candidates: candidates,
      scheduledHeuristics: scheduled,
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// R31 — propagation/hunt summary
// ────────────────────────────────────────────────────────────────────

/// Резюме propagation/hunt (R31) для одной партии.
///
/// Считается из `RecordedMove.mode` после фильтра контаминации /
/// Composite(unknown). [propagationFraction] + [huntFraction] всегда
/// суммируются ≈ 1.0 (модулo пустой партии — 0.0).
///
/// [p99HuntLatencyByHeuristic] — на каждый heuristic, у которого был
/// хотя бы один hunt-ход в партии, p99 latency среди этих ходов
/// (округление по nearest-rank percentile). Для одного hunt-хода
/// равно его latency. [slowestHuntHeuristic] = heuristic с
/// максимальным p99.
class ModeBreakdown {
  const ModeBreakdown({
    required this.totalCounted,
    required this.propagationCount,
    required this.huntCount,
    required this.p99HuntLatencyByHeuristic,
    required this.slowestHuntHeuristic,
  });

  final int totalCounted;
  final int propagationCount;
  final int huntCount;
  final Map<Heuristic, int> p99HuntLatencyByHeuristic;
  final Heuristic? slowestHuntHeuristic;

  double get propagationFraction =>
      totalCounted == 0 ? 0.0 : propagationCount / totalCounted;
  double get huntFraction =>
      totalCounted == 0 ? 0.0 : huntCount / totalCounted;

  bool get isEmpty => totalCounted == 0;

  Map<String, dynamic> toJson() => {
        'total': totalCounted,
        'propagation': propagationCount,
        'hunt': huntCount,
        'p99_hunt_ms': {
          for (final e in p99HuntLatencyByHeuristic.entries)
            e.key.tagId: e.value,
        },
        if (slowestHuntHeuristic != null)
          'slowest_hunt': slowestHuntHeuristic!.tagId,
      };
}

/// Pure-функция: сворачивает список [moves] в [ModeBreakdown].
/// Контаминированные и Composite(unknown)-ходы исключаются — те же
/// фильтры, что и в `selectCandidates` / mastery (R10).
ModeBreakdown computeModeBreakdown(List<RecordedMove> moves) {
  var prop = 0;
  var hunt = 0;
  final huntLatencies = <Heuristic, List<int>>{};
  for (final m in moves) {
    if (m.contaminated) continue;
    if (m.heuristic.tagId == 'Composite(unknown)') continue;
    switch (m.mode) {
      case MoveMode.propagation:
        prop++;
      case MoveMode.hunt:
        hunt++;
        huntLatencies.putIfAbsent(m.heuristic, () => <int>[]).add(m.latencyMs);
    }
  }

  final p99 = <Heuristic, int>{};
  for (final entry in huntLatencies.entries) {
    final sorted = [...entry.value]..sort();
    p99[entry.key] = _nearestRankPercentile(sorted, 0.99);
  }

  Heuristic? slowest;
  var slowestVal = -1;
  for (final entry in p99.entries) {
    if (entry.value > slowestVal) {
      slowest = entry.key;
      slowestVal = entry.value;
    }
  }

  return ModeBreakdown(
    totalCounted: prop + hunt,
    propagationCount: prop,
    huntCount: hunt,
    p99HuntLatencyByHeuristic: Map.unmodifiable(p99),
    slowestHuntHeuristic: slowest,
  );
}

int _nearestRankPercentile(List<int> sortedAsc, double p) {
  if (sortedAsc.isEmpty) return 0;
  // Nearest-rank: index = ceil(p * N) - 1 (clamped). Для N=1 → index=0.
  final n = sortedAsc.length;
  var idx = ((p * n).ceil() - 1);
  if (idx < 0) idx = 0;
  if (idx >= n) idx = n - 1;
  return sortedAsc[idx];
}

// ────────────────────────────────────────────────────────────────────
// R32 — line_completion bias detector
// ────────────────────────────────────────────────────────────────────

/// Один зафиксированный «прошёл мимо line-completion» инцидент
/// (R32). UX-only: не вешает penalty на ParityFill mastery
/// (`mastery_state` не обновляется этим сигналом — см. R32 в плане).
class BiasIncident {
  const BiasIncident({
    required this.atMoveIndex,
    required this.missedRow,
    required this.missedCol,
    required this.elapsedMs,
    required this.reason,
  });

  /// Индекс хода (0-based) в исходном списке `RecordedMove`-ов, в
  /// который пользователь сделал «другой» ход вместо очевидной
  /// 1-empty ParityFill.
  final int atMoveIndex;
  final int missedRow;
  final int missedCol;

  /// Сколько мс прошло между моментом, когда 1-empty ParityFill
  /// стал доступен, и моментом, когда пользователь зафиксировал
  /// «другой» ход.
  final int elapsedMs;

  /// Человекочитаемое объяснение для summary («прошёл мимо
  /// line_completion»).
  final String reason;

  Map<String, dynamic> toJson() => {
        'at_move': atMoveIndex,
        'missed_cell': [missedRow, missedCol],
        'elapsed_ms': elapsedMs,
        'reason': reason,
      };
}

/// Pure-функция: сканирует ходы партии и возвращает список инцидентов
/// «прошёл мимо line_completion» (R32).
///
/// Алгоритм:
/// 1. Реплейим [moves] поверх [initialPosition], запоминая позицию
///    после каждого хода. Перед применением хода K смотрим
///    solver-deductions на позиции после хода K-1, фильтруем 1-empty
///    ParityFill.
/// 2. Если ход K *не* совпадает ни с одной forced-cell такой
///    deduction-и И прошло ≥ [threshold] от момента, когда 1-empty
///    ParityFill *впервые* стал доступен, — фиксируем инцидент.
///
/// «Впервые стал доступен» отслеживается per (cell, mark) ключ, чтобы
/// одна и та же доступная ParityFill, проигнорированная несколько
/// ходов подряд, флагалась один раз.
///
/// Bias-флаг — UX-only сигнал; не уменьшает mastery ParityFill (R32).
List<BiasIncident> detectLineCompletionBias({
  required TangoPosition initialPosition,
  required List<RecordedMove> moves,
  TangoSolver solver = const TangoSolver(),
  Duration threshold = const Duration(seconds: 3),
  DateTime? sessionStartedAt,
}) {
  if (moves.isEmpty) return const [];
  final incidents = <BiasIncident>[];
  final firstSeenAt = <_BiasKey, DateTime>{};
  // Once a (cell, mark) has been flagged as bias, don't re-flag it
  // even if the position keeps the same ParityFill available across
  // subsequent irrelevant moves. One game → one signal per missed
  // line_completion.
  final alreadyFlagged = <_BiasKey>{};

  // Initial-position deductions «доступны» с момента старта сессии.
  // Если вызывающий не передал `sessionStartedAt`, аппроксимируем
  // его как `moves.first.createdAt - moves.first.latencyMs`.
  final startedAt = sessionStartedAt ??
      moves.first.createdAt
          .subtract(Duration(milliseconds: moves.first.latencyMs));

  _refreshFirstSeen(initialPosition, solver, firstSeenAt, startedAt);

  var position = initialPosition;
  for (var i = 0; i < moves.length; i++) {
    final move = moves[i];
    final consumed = <_BiasKey>{};
    for (final entry in firstSeenAt.entries) {
      final key = entry.key;
      if (key.row == move.row && key.col == move.col) {
        // Пользователь занял ту самую клетку — не bias, перестаём
        // отслеживать (после применения хода ParityFill уже не
        // существует в той же форме).
        consumed.add(key);
        continue;
      }
      if (alreadyFlagged.contains(key)) continue;
      final elapsed = move.createdAt.difference(entry.value);
      if (elapsed >= threshold) {
        incidents.add(BiasIncident(
          atMoveIndex: i,
          missedRow: key.row,
          missedCol: key.col,
          elapsedMs: elapsed.inMilliseconds,
          reason: 'прошёл мимо line_completion',
        ));
        alreadyFlagged.add(key);
        consumed.add(key);
      }
    }
    for (final k in consumed) {
      firstSeenAt.remove(k);
    }

    position = position.withCell(move.row, move.col, move.mark);
    _refreshFirstSeen(position, solver, firstSeenAt, move.createdAt);
  }

  return incidents;
}

void _refreshFirstSeen(
  TangoPosition pos,
  TangoSolver solver,
  Map<_BiasKey, DateTime> firstSeenAt,
  DateTime asOf,
) {
  final available = solver.availableDeductions(pos);
  final present = <_BiasKey>{};
  for (final d in available) {
    if (d.heuristic.tagId != 'ParityFill') continue;
    if (d.forcedCells.length != 1) continue;
    final cell = d.forcedCells.single;
    final key = _BiasKey(cell.row, cell.col, d.forcedMark.name);
    present.add(key);
    firstSeenAt.putIfAbsent(key, () => asOf);
  }
  // Снимаем tracking с ParityFill-ей, которые больше не 1-empty
  // доступны (например, line была заполнена другим ходом).
  firstSeenAt.removeWhere((key, _) => !present.contains(key));
}

class _BiasKey {
  const _BiasKey(this.row, this.col, this.markName);
  final int row;
  final int col;
  final String markName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BiasKey &&
          row == other.row &&
          col == other.col &&
          markName == other.markName;

  @override
  int get hashCode => Object.hash(row, col, markName);
}
