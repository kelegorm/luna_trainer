import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;

import '../../data/database.dart';
import '../../data/repositories/mastery_repository.dart';
import '../../data/repositories/move_events_repository.dart';
import '../domain/heuristic.dart';
import 'baseline_provider.dart';
import 'bayesian_shrinkage.dart';
import 'ewma.dart';

/// Cold-start population mean used until at least one heuristic
/// crosses the calibration threshold (plan R7 / U8).
const double _coldStartPopulationMean = 0.5;

/// Plan R10: a heuristic stays in calibration mode until it has
/// accumulated this many non-contaminated, non-outlier events.
const int _calibrationThreshold = 10;

/// |z| above this is treated as a measurement outlier and dropped
/// (plan R7 / Frontiers 2021 RT-outlier rule).
const double _outlierZThreshold = 3.0;

/// Window of recent non-contaminated latencies used to recompute
/// p25/median/p75 on each update. v1 is the "growing-buffer" the
/// plan calls out; backed by the move_events table itself.
const int _latencyWindow = 200;

/// Domain-level event view consumed by the scorer. Decouples the
/// scorer from the drift row shape and makes tests trivial to
/// construct without touching SQL.
class MasteryEvent {
  const MasteryEvent({
    required this.heuristic,
    required this.latencyMs,
    required this.wasCorrect,
    required this.hintRequested,
    required this.contaminated,
    this.hintStepReached = 0,
    this.chainIndex = 0,
  });

  final Heuristic heuristic;
  final int latencyMs;
  final bool wasCorrect;
  final bool hintRequested;
  final bool contaminated;
  final int hintStepReached;
  final int chainIndex;

  /// Convenience for the U7 telemetry pipeline once it streams
  /// MoveEventRow into the scorer end-to-end.
  factory MasteryEvent.fromRow(MoveEventRow r) => MasteryEvent(
        heuristic: Heuristic(r.kindId, r.heuristicTag),
        latencyMs: r.latencyMs,
        wasCorrect: r.wasCorrect,
        hintRequested: r.hintRequested,
        contaminated: r.contaminatedFlag,
        hintStepReached: r.hintStepReached,
        chainIndex: r.chainIndex,
      );
}

/// Read model returned by [MasteryScorer.currentScore]. Holds both
/// the raw EWMA (for diagnostics) and the post-shrinkage score
/// (consumed by drill selection / radar UI).
class MasteryScore {
  const MasteryScore({
    required this.heuristic,
    required this.eventCount,
    required this.isCalibrating,
    required this.ewmaPercentile,
    required this.shrunkPercentile,
    required this.errorRate,
    required this.hintRate,
    required this.hintStepCounts,
    required this.outlierCount,
    this.latencyP25Ms,
    this.latencyMedianMs,
    this.latencyP75Ms,
  });

  final Heuristic heuristic;
  final int eventCount;
  final bool isCalibrating;
  final double ewmaPercentile;
  final double shrunkPercentile;
  final double errorRate;
  final double hintRate;
  final Map<int, int> hintStepCounts;
  final int outlierCount;
  final int? latencyP25Ms;
  final int? latencyMedianMs;
  final int? latencyP75Ms;

  /// Mean hint step across all events (∑ step·count / ∑ count).
  /// Returns 0 when no events have been recorded yet.
  double get meanHintStep {
    var stepSum = 0.0;
    var countSum = 0;
    hintStepCounts.forEach((step, count) {
      stepSum += step * count;
      countSum += count;
    });
    return countSum == 0 ? 0.0 : stepSum / countSum;
  }
}

/// Outcome of a single [MasteryScorer.updateOnEvent] call. Useful
/// for the telemetry pipeline to log what the scorer did without
/// having to re-read the persisted row.
enum MasteryUpdateResult { applied, skippedContaminated, droppedOutlier }

/// Per-heuristic mastery scorer. Pure orchestration over the EWMA,
/// shrinkage, and weakness utils — all heavy math lives in those
/// helpers. Persists into `mastery_state` via [MasteryRepository].
class MasteryScorer {
  MasteryScorer({
    required MasteryRepository masteryRepository,
    required MoveEventsRepository moveEventsRepository,
    BaselineProvider? baselineProvider,
    DateTime Function() clock = _defaultClock,
  })  : _mastery = masteryRepository,
        _moves = moveEventsRepository,
        _baselines = baselineProvider ?? const BaselineProvider(),
        _clock = clock;

  final MasteryRepository _mastery;
  final MoveEventsRepository _moves;
  final BaselineProvider _baselines;
  final DateTime Function() _clock;

  static DateTime _defaultClock() => DateTime.now();

  /// Process a single event. Contaminated events and outliers are
  /// dropped per plan R7; surviving events update the EWMA, running
  /// rates, and latency percentiles for the event's heuristic.
  Future<MasteryUpdateResult> updateOnEvent(MasteryEvent event) async {
    if (event.contaminated) {
      return MasteryUpdateResult.skippedContaminated;
    }

    final baseline = _baselines.forHeuristic(event.heuristic);
    final z = _zScore(event.latencyMs, baseline);

    final current = await _mastery.find(event.heuristic);

    if (z.abs() > _outlierZThreshold) {
      // Outlier: bump the diagnostic counter only; latency, rates,
      // and EWMA are left untouched (plan R7).
      await _mastery.upsert(_outlierBump(current, event.heuristic));
      return MasteryUpdateResult.droppedOutlier;
    }

    final percentile = _normalCdf(-z);
    final newEwma = Ewma.next(
      sample: percentile,
      previous: current?.ewmaPercentile,
    );

    final newCount = (current?.eventCount ?? 0) + 1;
    final newErrorRate = _runningRate(
      previousRate: current?.errorRate ?? 0.0,
      previousCount: current?.eventCount ?? 0,
      newSignal: !event.wasCorrect,
    );
    final newHintRate = _runningRate(
      previousRate: current?.hintRate ?? 0.0,
      previousCount: current?.eventCount ?? 0,
      newSignal: event.hintRequested,
    );
    final hintSteps = _bumpHintStep(
      currentJson: current?.hintStepCountsJson,
      step: event.hintStepReached,
    );

    final latencies = await _moves.recent(
      event.heuristic,
      limit: _latencyWindow,
      excludeContaminated: true,
    );
    final percentiles = _latencyPercentiles(latencies);

    await _mastery.upsert(
      MasteryStateCompanion.insert(
        kindId: event.heuristic.kindId,
        heuristicTag: event.heuristic.tagId,
        eventCount: Value(newCount),
        ewmaPercentile: Value(newEwma),
        outlierCount: Value(current?.outlierCount ?? 0),
        latencyP25Ms: Value(percentiles.p25),
        latencyMedianMs: Value(percentiles.median),
        latencyP75Ms: Value(percentiles.p75),
        errorRate: Value(newErrorRate),
        hintRate: Value(newHintRate),
        hintStepCountsJson: Value(jsonEncode(hintSteps)),
        lastUpdatedAt: _clock().millisecondsSinceEpoch,
        isCalibrating: Value(newCount < _calibrationThreshold),
      ),
    );
    return MasteryUpdateResult.applied;
  }

  /// Reads the persisted state for [h] and returns a domain-level
  /// score with the post-shrinkage value. Returns a calibrating
  /// default (population-mean score, eventCount=0) when nothing has
  /// been recorded yet — never null.
  Future<MasteryScore> currentScore(Heuristic h) async {
    final row = await _mastery.find(h);
    final populationMean = await _populationMean();

    if (row == null) {
      return MasteryScore(
        heuristic: h,
        eventCount: 0,
        isCalibrating: true,
        ewmaPercentile: 0.0,
        shrunkPercentile: populationMean,
        errorRate: 0.0,
        hintRate: 0.0,
        hintStepCounts: const {},
        outlierCount: 0,
      );
    }

    final shrunk = BayesianShrinkage.shrink(
      observed: row.ewmaPercentile,
      n: row.eventCount,
      prior: populationMean,
    );

    return MasteryScore(
      heuristic: h,
      eventCount: row.eventCount,
      isCalibrating: row.isCalibrating,
      ewmaPercentile: row.ewmaPercentile,
      shrunkPercentile: shrunk,
      errorRate: row.errorRate,
      hintRate: row.hintRate,
      hintStepCounts: _decodeHintSteps(row.hintStepCountsJson),
      outlierCount: row.outlierCount,
      latencyP25Ms: row.latencyP25Ms,
      latencyMedianMs: row.latencyMedianMs,
      latencyP75Ms: row.latencyP75Ms,
    );
  }

  // --- internals -------------------------------------------------

  double _zScore(int latencyMs, BaselineSpec b) {
    // Latencies are always positive (move timer guarantees ≥ 1ms).
    // The check below guards tests that hand in 0 or negative.
    final safe = latencyMs <= 0 ? 1 : latencyMs;
    return (math.log(safe) - math.log(b.medianMs)) / b.sigmaLog;
  }

  MasteryStateCompanion _outlierBump(MasteryStateRow? current, Heuristic h) {
    return MasteryStateCompanion.insert(
      kindId: h.kindId,
      heuristicTag: h.tagId,
      eventCount: Value(current?.eventCount ?? 0),
      ewmaPercentile: Value(current?.ewmaPercentile ?? 0.0),
      outlierCount: Value((current?.outlierCount ?? 0) + 1),
      latencyP25Ms: Value(current?.latencyP25Ms),
      latencyMedianMs: Value(current?.latencyMedianMs),
      latencyP75Ms: Value(current?.latencyP75Ms),
      errorRate: Value(current?.errorRate ?? 0.0),
      hintRate: Value(current?.hintRate ?? 0.0),
      hintStepCountsJson: Value(current?.hintStepCountsJson ?? '{}'),
      lastUpdatedAt: _clock().millisecondsSinceEpoch,
      isCalibrating: Value(
        (current?.eventCount ?? 0) < _calibrationThreshold,
      ),
    );
  }

  double _runningRate({
    required double previousRate,
    required int previousCount,
    required bool newSignal,
  }) {
    final newCount = previousCount + 1;
    return (previousRate * previousCount + (newSignal ? 1 : 0)) / newCount;
  }

  Map<String, int> _bumpHintStep({String? currentJson, required int step}) {
    final map = _decodeHintSteps(currentJson)
        .map((k, v) => MapEntry(k.toString(), v));
    map.update(step.toString(), (v) => v + 1, ifAbsent: () => 1);
    return map;
  }

  Map<int, int> _decodeHintSteps(String? json) {
    if (json == null || json.isEmpty) return const {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  _Percentiles _latencyPercentiles(List<MoveEventRow> rows) {
    if (rows.isEmpty) return const _Percentiles();
    final sorted = rows.map((r) => r.latencyMs).toList()..sort();
    return _Percentiles(
      p25: _quantile(sorted, 0.25),
      median: _quantile(sorted, 0.5),
      p75: _quantile(sorted, 0.75),
    );
  }

  /// Linear-interpolation quantile over a pre-sorted ascending list.
  /// Matches numpy's default ("linear") method for our small windows.
  int _quantile(List<int> sorted, double q) {
    if (sorted.length == 1) return sorted.first;
    final pos = q * (sorted.length - 1);
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sorted[lo];
    final frac = pos - lo;
    return (sorted[lo] + (sorted[hi] - sorted[lo]) * frac).round();
  }

  Future<double> _populationMean() async {
    final rows = await _mastery.all();
    final calibrated =
        rows.where((r) => !r.isCalibrating).toList(growable: false);
    if (calibrated.isEmpty) return _coldStartPopulationMean;
    final sum =
        calibrated.fold<double>(0.0, (a, r) => a + r.ewmaPercentile);
    return sum / calibrated.length;
  }
}

/// Standard normal CDF via Abramowitz & Stegun 7.1.26 (max error
/// ~1.5e-7). Sufficient for percentile mapping.
double _normalCdf(double x) {
  return 0.5 * (1.0 + _erf(x / math.sqrt2));
}

double _erf(double x) {
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;
  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  final t = 1.0 / (1.0 + p * ax);
  final y = 1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}

class _Percentiles {
  const _Percentiles({this.p25, this.median, this.p75});
  final int? p25;
  final int? median;
  final int? p75;
}
