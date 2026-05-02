import 'package:fsrs/fsrs.dart' as fsrs;

import '../../data/repositories/fsrs_repository.dart';
import '../../engine/domain/heuristic.dart';
import '../../engine/fsrs/fsrs_scheduler.dart';
import '../../engine/mastery/baseline_provider.dart';

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
