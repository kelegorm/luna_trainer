import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/telemetry/contamination_detector.dart';
import 'package:luna_traineer/engine/telemetry/lifecycle_observer.dart';
import 'package:luna_traineer/engine/telemetry/motion_detector.dart';
import 'package:luna_traineer/engine/telemetry/move_timer_service.dart';

void main() {
  late _FakeClock clock;
  late LifecycleObserver lifecycle;
  late StreamController<MotionSample> motionSamples;
  late MotionDetector motion;
  late ContaminationDetector contamination;
  late MoveTimerService timer;

  setUp(() {
    clock = _FakeClock(DateTime(2026, 5, 1));
    lifecycle = LifecycleObserver(now: clock.now);
    motionSamples = StreamController<MotionSample>.broadcast();
    motion = MotionDetector(samples: motionSamples.stream, now: clock.now);
    contamination = ContaminationDetector(
      lifecycle: lifecycle,
      motion: motion,
      motionStationaryThreshold: const Duration(seconds: 30),
    );
    timer = MoveTimerService(
      contamination: contamination,
      now: clock.now,
      idleThreshold: const Duration(seconds: 8),
    );
  });

  tearDown(() async {
    await timer.dispose();
    lifecycle.dispose();
    await motion.dispose();
    await motionSamples.close();
  });

  Future<void> feedStationarySample() async {
    motionSamples.add(const MotionSample(x: 0.05, y: 0.05, z: 0.05));
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> warmUpStationaryWindow() async {
    for (var i = 0; i < 5; i++) {
      await feedStationarySample();
    }
  }

  test('happy path: 3s move, no bg, no motion → not contaminated', () async {
    timer.startMove();
    clock.advance(const Duration(seconds: 3));
    final meta = timer.commitMove();

    expect(meta.latencyMs, 3000);
    expect(meta.signals.lifecycleSignal, isFalse);
    expect(meta.signals.motionSignal, isFalse);
    expect(meta.signals.idleSoftSignal, isFalse);
    expect(meta.contaminatedFlag, isFalse);
  });

  test('lifecycle: pause 5s + resume 10s later → contaminated, lifecycle=true',
      () async {
    timer.startMove();
    clock.advance(const Duration(seconds: 5));
    lifecycle.onState(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 10));
    lifecycle.onState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    final meta = timer.commitMove();

    expect(meta.signals.lifecycleSignal, isTrue);
    expect(meta.signals.motionSignal, isFalse);
    expect(meta.contaminatedFlag, isTrue);
  });

  test('motion: stationary 35s during move → contaminated, motion=true',
      () async {
    timer.startMove();
    await warmUpStationaryWindow();
    clock.advance(const Duration(seconds: 35));
    await feedStationarySample();
    final meta = timer.commitMove();

    expect(meta.signals.motionSignal, isTrue);
    expect(meta.signals.lifecycleSignal, isFalse);
    expect(meta.contaminatedFlag, isTrue);
  });

  test('iOS pitfall: inactive < 500ms → debounced, not contaminated',
      () async {
    timer.startMove();
    lifecycle.onState(AppLifecycleState.inactive);
    clock.advance(const Duration(milliseconds: 200));
    lifecycle.onState(AppLifecycleState.resumed);
    clock.advance(const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);
    final meta = timer.commitMove();

    expect(meta.signals.lifecycleSignal, isFalse);
    expect(meta.contaminatedFlag, isFalse);
  });

  test('idle: 12s thinking, no lifecycle, no motion → idle_soft=true, '
      'not contaminated', () async {
    timer.startMove();
    clock.advance(const Duration(seconds: 12));
    final meta = timer.commitMove();

    expect(meta.signals.idleSoftSignal, isTrue);
    expect(meta.signals.lifecycleSignal, isFalse);
    expect(meta.signals.motionSignal, isFalse);
    expect(meta.contaminatedFlag, isFalse,
        reason: 'idle is soft-only — does not contaminate');
  });

  test('stationary < 30s during move → motion=false, not contaminated',
      () async {
    timer.startMove();
    await warmUpStationaryWindow();
    clock.advance(const Duration(seconds: 25));
    await feedStationarySample();
    final meta = timer.commitMove();

    expect(meta.signals.motionSignal, isFalse);
    expect(meta.contaminatedFlag, isFalse);
  });

  test('integration AE5: 12s pause → contaminated row in metadata',
      () async {
    timer.startMove();
    clock.advance(const Duration(seconds: 1));
    lifecycle.onState(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 12));
    lifecycle.onState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    clock.advance(const Duration(seconds: 1));
    final meta = timer.commitMove();

    expect(meta.contaminatedFlag, isTrue);
    expect(meta.latencyMs, 14000);
  });

  test('commitMove without startMove throws StateError', () {
    expect(timer.commitMove, throwsStateError);
  });

  test('startMove called twice resets timer (previous discarded)', () async {
    timer.startMove();
    clock.advance(const Duration(seconds: 5));
    timer.startMove(); // restart
    clock.advance(const Duration(seconds: 1));
    final meta = timer.commitMove();

    expect(meta.latencyMs, 1000,
        reason: 'second startMove resets the timer');
  });

  test('dispose is safe and idempotent — multiple cycles do not leak', () async {
    for (var i = 0; i < 3; i++) {
      timer.startMove();
      clock.advance(const Duration(seconds: 1));
      timer.commitMove();
    }
    await timer.dispose();
    await timer.dispose(); // idempotent
  });

  // ───────── R13 / AE2: hint step 4 pauses the move timer ─────────

  test('pause/resume: 4s thinking, 6s paused, 2s thinking → latency=6s', () {
    timer.startMove();
    clock.advance(const Duration(seconds: 4));
    timer.pause();
    expect(timer.isPaused, isTrue);
    clock.advance(const Duration(seconds: 6));
    timer.resume();
    expect(timer.isPaused, isFalse);
    clock.advance(const Duration(seconds: 2));
    final meta = timer.commitMove();

    expect(
      meta.latencyMs,
      6000,
      reason: 'wall-clock 12s − 6s paused = 6s reported',
    );
  });

  test('pause/resume: idempotent — repeated pause keeps original start', () {
    timer.startMove();
    clock.advance(const Duration(seconds: 1));
    timer.pause();
    clock.advance(const Duration(seconds: 5));
    timer.pause(); // second pause is no-op, must not reset start-of-pause
    clock.advance(const Duration(seconds: 5));
    timer.resume();
    clock.advance(const Duration(seconds: 1));
    final meta = timer.commitMove();

    expect(
      meta.latencyMs,
      2000,
      reason: '12s wall-clock − 10s paused = 2s; second pause is no-op',
    );
  });

  test('resume without active pause is a no-op', () {
    timer.startMove();
    clock.advance(const Duration(seconds: 1));
    timer.resume(); // no active pause — silently ignored
    clock.advance(const Duration(seconds: 1));
    final meta = timer.commitMove();

    expect(meta.latencyMs, 2000);
  });

  test('dangling pause auto-closes at commitMove', () {
    timer.startMove();
    clock.advance(const Duration(seconds: 2));
    timer.pause();
    clock.advance(const Duration(seconds: 5));
    // Forgot to call resume — commit must clamp the open pause window.
    final meta = timer.commitMove();

    expect(
      meta.latencyMs,
      2000,
      reason: 'open pause window covers the trailing 5s and is subtracted',
    );
  });

  test('latency clamped to 0 when paused longer than wall-clock cannot underflow',
      () {
    timer.startMove();
    timer.pause();
    clock.advance(const Duration(seconds: 5));
    timer.resume();
    final meta = timer.commitMove();

    expect(meta.latencyMs, 0,
        reason: 'all wall-clock was paused → reported 0ms, never negative');
  });

  test('startMove resets pause accumulator from a prior aborted move', () {
    timer.startMove();
    clock.advance(const Duration(seconds: 2));
    timer.pause();
    clock.advance(const Duration(seconds: 5));
    // Restart without committing — pause state must not leak into next move.
    timer.startMove();
    expect(timer.isPaused, isFalse);
    clock.advance(const Duration(seconds: 3));
    final meta = timer.commitMove();

    expect(meta.latencyMs, 3000);
  });
}

class _FakeClock {
  _FakeClock(DateTime start) : _now = start;
  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}
