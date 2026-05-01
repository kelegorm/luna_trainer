import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/mastery_repository.dart';
import 'package:luna_traineer/data/repositories/move_events_repository.dart';
import 'package:luna_traineer/data/repositories/sessions_repository.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/engine/mastery/baseline_provider.dart';
import 'package:luna_traineer/engine/mastery/mastery_scorer.dart';

const _parityFill = Heuristic('tango', 'ParityFill');
const _signProp = Heuristic('tango', 'SignPropagation');
const _trio = Heuristic('tango', 'TrioAvoidance');

const _baselineMs = 5000;
const _baseline = BaselineProvider(
  defaultSpec: BaselineSpec(medianMs: _baselineMs, sigmaLog: 0.5),
);

void main() {
  late LunaDatabase db;
  late MasteryRepository masteryRepo;
  late MoveEventsRepository movesRepo;
  late SessionsRepository sessionsRepo;
  late MasteryScorer scorer;
  late int sessionId;
  var nowMs = 0;

  DateTime tick() {
    nowMs += 1000;
    return DateTime.fromMillisecondsSinceEpoch(nowMs);
  }

  setUp(() async {
    db = LunaDatabase.forTesting(NativeDatabase.memory());
    masteryRepo = MasteryRepository(db);
    movesRepo = MoveEventsRepository(db);
    sessionsRepo = SessionsRepository(db);
    sessionId = await sessionsRepo.startSession(
      mode: 'drill',
      startedAt: DateTime.utc(2026, 5, 1),
    );
    nowMs = 0;
    scorer = MasteryScorer(
      masteryRepository: masteryRepo,
      moveEventsRepository: movesRepo,
      baselineProvider: _baseline,
      clock: tick,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // Persist a MoveEvent and feed it to the scorer.
  Future<MasteryUpdateResult> ingest({
    required Heuristic h,
    int latencyMs = _baselineMs,
    bool wasCorrect = true,
    bool hintRequested = false,
    int hintStepReached = 0,
    bool contaminated = false,
    int chainIndex = 0,
  }) async {
    await movesRepo.commit(
      sessionId: sessionId,
      heuristic: h,
      latencyMs: latencyMs,
      wasCorrect: wasCorrect,
      hintRequested: hintRequested,
      hintStepReached: hintStepReached,
      contaminated: contaminated,
      idleSoftSignal: false,
      motionSignal: false,
      lifecycleSignal: false,
      createdAt: tick(),
      chainIndex: chainIndex,
    );
    return scorer.updateOnEvent(MasteryEvent(
      heuristic: h,
      latencyMs: latencyMs,
      wasCorrect: wasCorrect,
      hintRequested: hintRequested,
      hintStepReached: hintStepReached,
      contaminated: contaminated,
      chainIndex: chainIndex,
    ));
  }

  group('updateOnEvent — happy paths', () {
    test('first event: count=1, isCalibrating=true, EWMA = sample percentile',
        () async {
      // latency = baseline ⇒ z = 0 ⇒ percentile = 0.5.
      final result = await ingest(h: _parityFill);
      expect(result, MasteryUpdateResult.applied);

      final score = await scorer.currentScore(_parityFill);
      expect(score.eventCount, 1);
      expect(score.isCalibrating, isTrue);
      expect(score.ewmaPercentile, closeTo(0.5, 1e-9));
      // n=1, prior=0.5 → shrinkage pulls heavily toward 0.5
      // ((1·0.5 + 10·0.5) / 11 = 0.5).
      expect(score.shrunkPercentile, closeTo(0.5, 1e-9));
    });

    test('50 events at baseline → EWMA converges to ~0.5', () async {
      for (var i = 0; i < 50; i++) {
        await ingest(h: _parityFill, latencyMs: _baselineMs);
      }
      final score = await scorer.currentScore(_parityFill);
      expect(score.eventCount, 50);
      expect(score.ewmaPercentile, closeTo(0.5, 1e-3));
    });

    test('50 events at baseline/2 → high mastery score (faster than baseline)',
        () async {
      for (var i = 0; i < 50; i++) {
        await ingest(h: _parityFill, latencyMs: _baselineMs ~/ 2);
      }
      final score = await scorer.currentScore(_parityFill);
      // z ≈ -1.386, percentile ≈ 0.917; EWMA after many events
      // approaches that, then shrinkage with n=50, k=10 pulls
      // slightly back toward 0.5 → still well above 0.7.
      expect(score.ewmaPercentile, greaterThan(0.85));
      expect(score.shrunkPercentile, greaterThan(0.7));
    });
  });

  group('updateOnEvent — contamination + outliers', () {
    test('contaminated event is skipped — eventCount does NOT increment',
        () async {
      final result = await ingest(h: _parityFill, contaminated: true);
      expect(result, MasteryUpdateResult.skippedContaminated);

      final row = await masteryRepo.find(_parityFill);
      expect(row, isNull, reason: 'no row created — nothing happened');
    });

    test('|z| > 3 → outlier, drop, outlierCount++, ewma not moved', () async {
      // Establish a baseline EWMA first with a non-outlier event.
      await ingest(h: _parityFill, latencyMs: _baselineMs);
      final baselineRow = await masteryRepo.find(_parityFill);
      final baselineEwma = baselineRow!.ewmaPercentile;

      // baseline·100 → log ratio ≈ 4.6, z ≈ 9.2 → drop.
      final result = await ingest(h: _parityFill, latencyMs: _baselineMs * 100);
      expect(result, MasteryUpdateResult.droppedOutlier);

      final after = await masteryRepo.find(_parityFill);
      expect(after!.outlierCount, 1);
      expect(after.eventCount, 1, reason: 'outlier does not count');
      expect(after.ewmaPercentile, baselineEwma,
          reason: 'EWMA frozen on outlier');
    });
  });

  group('updateOnEvent — calibration threshold (R10 / AE3)', () {
    test('9 events → still calibrating; 10th → calibrated', () async {
      for (var i = 0; i < 9; i++) {
        await ingest(h: _parityFill, latencyMs: _baselineMs);
      }
      var score = await scorer.currentScore(_parityFill);
      expect(score.isCalibrating, isTrue);
      expect(score.eventCount, 9);

      await ingest(h: _parityFill, latencyMs: _baselineMs);
      score = await scorer.currentScore(_parityFill);
      expect(score.isCalibrating, isFalse);
      expect(score.eventCount, 10);
    });

    test('AE3: 7 events → still calibrating', () async {
      for (var i = 0; i < 7; i++) {
        await ingest(h: _parityFill, latencyMs: _baselineMs);
      }
      final score = await scorer.currentScore(_parityFill);
      expect(score.isCalibrating, isTrue);
    });
  });

  group('currentScore — defaults + cold-start', () {
    test('empty state — currentScore returns calibrating default, never null',
        () async {
      final score = await scorer.currentScore(_parityFill);
      expect(score.eventCount, 0);
      expect(score.isCalibrating, isTrue);
      // No calibrated heuristics yet → population mean = 0.5.
      expect(score.shrunkPercentile, 0.5);
    });

    test(
        'cold-start: first event in DB uses 0.5 fallback, score finite (no NaN)',
        () async {
      await ingest(h: _parityFill, latencyMs: _baselineMs);
      final score = await scorer.currentScore(_parityFill);
      expect(score.shrunkPercentile.isFinite, isTrue);
      expect(score.shrunkPercentile, closeTo(0.5, 1e-9));
    });

    test(
        'cold-start transition: after one heuristic calibrates, '
        'population mean used for others reflects its EWMA', () async {
      // Calibrate ParityFill at high mastery (latency = baseline/2).
      for (var i = 0; i < 10; i++) {
        await ingest(h: _parityFill, latencyMs: _baselineMs ~/ 2);
      }
      final calibrated = await scorer.currentScore(_parityFill);
      expect(calibrated.isCalibrating, isFalse);

      // Now ask for a heuristic with no events. Its prior should
      // equal the calibrated heuristic's EWMA, not the 0.5 fallback.
      final fresh = await scorer.currentScore(_signProp);
      expect(fresh.shrunkPercentile,
          closeTo(calibrated.ewmaPercentile, 1e-9));
      expect(fresh.shrunkPercentile, greaterThan(0.5),
          reason: 'population mean reflects calibrated high-mastery row');
    });
  });

  group('rates and hint-step counts', () {
    test('error_rate is the running mean of !wasCorrect', () async {
      await ingest(h: _parityFill, wasCorrect: true);
      await ingest(h: _parityFill, wasCorrect: false);
      await ingest(h: _parityFill, wasCorrect: true);
      await ingest(h: _parityFill, wasCorrect: false);
      final row = await masteryRepo.find(_parityFill);
      expect(row!.errorRate, closeTo(0.5, 1e-9));
    });

    test('hint_rate is the running mean of hintRequested', () async {
      await ingest(h: _parityFill, hintRequested: true);
      await ingest(h: _parityFill, hintRequested: false);
      await ingest(h: _parityFill, hintRequested: false);
      await ingest(h: _parityFill, hintRequested: true);
      final row = await masteryRepo.find(_parityFill);
      expect(row!.hintRate, closeTo(0.5, 1e-9));
    });

    test('hintStepCounts JSON tracks per-step bucket counts', () async {
      await ingest(h: _parityFill, hintStepReached: 0);
      await ingest(h: _parityFill, hintStepReached: 1);
      await ingest(h: _parityFill, hintStepReached: 1);
      await ingest(h: _parityFill, hintStepReached: 2);

      final row = await masteryRepo.find(_parityFill);
      final decoded = jsonDecode(row!.hintStepCountsJson) as Map<String, dynamic>;
      expect(decoded['0'], 1);
      expect(decoded['1'], 2);
      expect(decoded['2'], 1);

      final score = await scorer.currentScore(_parityFill);
      // (0·1 + 1·2 + 2·1) / 4 = 1.0
      expect(score.meanHintStep, closeTo(1.0, 1e-9));
    });
  });

  group('latency percentiles', () {
    test('p25 < median < p75 across a spread of latencies', () async {
      final latencies = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000];
      for (final ms in latencies) {
        await ingest(h: _parityFill, latencyMs: ms);
      }
      final row = await masteryRepo.find(_parityFill);
      expect(row!.latencyP25Ms, lessThan(row.latencyMedianMs!));
      expect(row.latencyMedianMs, lessThan(row.latencyP75Ms!));
      expect(row.latencyMedianMs, 5000);
    });
  });

  group('chain-event aggregation (plan F2 closure)', () {
    test('chain_index>0 updates its own heuristic (separate row)', () async {
      // ParityFill drill (chain_index=0) + SignProp chain extension
      // (chain_index=1). Each should land in its own mastery_state row.
      await ingest(h: _parityFill, chainIndex: 0);
      await ingest(h: _signProp, chainIndex: 1);

      final parity = await masteryRepo.find(_parityFill);
      final sign = await masteryRepo.find(_signProp);
      expect(parity!.eventCount, 1);
      expect(sign!.eventCount, 1);
    });

    test(
        'chain-event WRONG: error_rate increments only for the extending '
        'heuristic, not the original', () async {
      await ingest(h: _parityFill, wasCorrect: true, chainIndex: 0);
      await ingest(h: _signProp, wasCorrect: false, chainIndex: 1);

      final parity = await masteryRepo.find(_parityFill);
      final sign = await masteryRepo.find(_signProp);
      expect(parity!.errorRate, 0.0);
      expect(sign!.errorRate, 1.0);
    });
  });

  group('cross-heuristic isolation', () {
    test('events for one heuristic do not move another', () async {
      await ingest(h: _parityFill, latencyMs: _baselineMs ~/ 2);
      final trio = await masteryRepo.find(_trio);
      expect(trio, isNull);

      final parity = await masteryRepo.find(_parityFill);
      expect(parity!.eventCount, 1);
    });
  });

  group('z→percentile direction (sanity)', () {
    test('sub-baseline latency yields percentile > 0.5', () {
      // Math direct check: z<0 ⇒ CDF(-z) > 0.5.
      // log(2500/5000) = -ln(2) ≈ -0.693, z ≈ -1.386.
      // CDF(1.386) ≈ 0.917.
      const z = -1.386;
      final p = 0.5 * (1 + _erfApprox(-z / math.sqrt2));
      expect(p, greaterThan(0.85));
    });

    test('above-baseline latency yields percentile < 0.5', () {
      const z = 1.386;
      final p = 0.5 * (1 + _erfApprox(-z / math.sqrt2));
      expect(p, lessThan(0.15));
    });
  });
}

double _erfApprox(double x) {
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
