import 'dart:convert';

import '../../data/database.dart';
import '../../data/repositories/fsrs_repository.dart';
import '../../data/repositories/mastery_repository.dart';
import '../domain/heuristic.dart';
import '../fsrs/fsrs_scheduler.dart';
import '../mastery/weakness_calculator.dart';

/// Why a heuristic ended up in the drill batch.
///
/// `due` — the FSRS scheduler said it is due for review.
/// `weaknessFill` — backstop pick when there are not enough due cards;
///   ranked by weakness scalar across non-calibrating heuristics.
/// `exploration` — last-resort pad with a calibrating heuristic. Plan
///   R10 forbids these from counting as drill events; the UI must
///   surface them as exploration prompts, not as drill rounds.
enum DrillSlotKind { due, weaknessFill, exploration }

/// One entry in a drill batch — a heuristic plus the reason it was
/// picked. The plan keeps this list flat (no per-puzzle aggregation)
/// because chain-drill packing happens later in [TargetMixBuilder].
class DrillSlot {
  const DrillSlot({required this.heuristic, required this.kind});

  final Heuristic heuristic;
  final DrillSlotKind kind;
}

/// Output of [DrillSelector.pickNext]. Holds the ordered slot list
/// and a convenience [isEmpty] for the "nothing to drill" UI state
/// the plan calls out.
class DrillBatch {
  const DrillBatch(this.slots);

  final List<DrillSlot> slots;

  bool get isEmpty => slots.isEmpty;
  int get length => slots.length;
}

/// Picks the next batch of heuristics for a drill session by combining
/// FSRS-due cards (R8) with a weakness-driven backstop (R10/R20).
///
/// Algorithm (plan U9):
/// 1. Take all FSRS-due cards (oldest first), keep only those whose
///    mastery is non-calibrating. R10 forbids drilling calibrating
///    heuristics.
/// 2. If still below `count`, fill with the weakest non-calibrating
///    heuristics that are NOT already in the due list, ranked by the
///    weakness scalar (`WeaknessCalculator`).
/// 3. v1 stops here. The plan reserves an `exploration` pad for
///    calibrating heuristics, but reaching that branch in v1 means
///    nothing to drill — return an empty batch.
class DrillSelector {
  DrillSelector({
    required FsrsScheduler scheduler,
    required MasteryRepository masteryRepository,
    required FsrsRepository fsrsRepository,
  })  : _scheduler = scheduler,
        _mastery = masteryRepository,
        _fsrs = fsrsRepository;

  final FsrsScheduler _scheduler;
  final MasteryRepository _mastery;
  final FsrsRepository _fsrs;

  Future<DrillBatch> pickNext({int count = 10, DateTime? now}) async {
    final clock = (now ?? DateTime.now()).toUtc();

    final masteryRows = await _mastery.all();
    final masteryByHeuristic = <Heuristic, MasteryStateRow>{
      for (final row in masteryRows) Heuristic(row.kindId, row.heuristicTag): row,
    };

    final dueCards = await _scheduler.dueCards(now: clock);

    final picked = <DrillSlot>[];
    final pickedHeuristics = <Heuristic>{};

    for (final card in dueCards) {
      if (picked.length >= count) break;
      final mastery = masteryByHeuristic[card.heuristic];
      if (mastery == null || mastery.isCalibrating) continue;
      picked.add(DrillSlot(
        heuristic: card.heuristic,
        kind: DrillSlotKind.due,
      ));
      pickedHeuristics.add(card.heuristic);
    }

    if (picked.length < count) {
      final scheduledHeuristics = (await _fsrs.all())
          .map((row) => Heuristic(row.kindId, row.heuristicTag))
          .toSet();

      final fillCandidates = masteryRows
          .where((row) => !row.isCalibrating)
          .map((row) {
            final h = Heuristic(row.kindId, row.heuristicTag);
            return _Candidate(h, _weaknessOf(row));
          })
          // Skip heuristics already picked as `due` and any heuristic
          // that already has an FSRS card — once it's in the cycle,
          // FSRS owns its drill timing.
          .where((c) =>
              !pickedHeuristics.contains(c.heuristic) &&
              !scheduledHeuristics.contains(c.heuristic))
          .toList(growable: false)
        ..sort((a, b) => b.weakness.compareTo(a.weakness));

      for (final c in fillCandidates) {
        if (picked.length >= count) break;
        picked.add(DrillSlot(
          heuristic: c.heuristic,
          kind: DrillSlotKind.weaknessFill,
        ));
        pickedHeuristics.add(c.heuristic);
      }
    }

    return DrillBatch(List.unmodifiable(picked));
  }

  double _weaknessOf(MasteryStateRow row) {
    // ewmaPercentile is the user's *speed* percentile (high = fast).
    // Weakness wants the slow direction, so we invert it before
    // feeding the slot used by the formula. errorRate / hintRate are
    // already weakness-aligned.
    return WeaknessCalculator.compute(
      latencyPercentile: 1.0 - row.ewmaPercentile,
      errorRate: row.errorRate,
      hintRate: row.hintRate,
      meanHintStep: _meanHintStep(row.hintStepCountsJson),
    );
  }

  double _meanHintStep(String json) {
    if (json.isEmpty) return 0.0;
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    if (decoded.isEmpty) return 0.0;
    var stepSum = 0.0;
    var countSum = 0;
    decoded.forEach((k, v) {
      final step = int.parse(k);
      final count = (v as num).toInt();
      stepSum += step * count;
      countSum += count;
    });
    return countSum == 0 ? 0.0 : stepSum / countSum;
  }
}

class _Candidate {
  const _Candidate(this.heuristic, this.weakness);
  final Heuristic heuristic;
  final double weakness;
}
