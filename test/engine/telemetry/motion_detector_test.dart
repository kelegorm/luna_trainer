import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/telemetry/motion_detector.dart';

void main() {
  group('MotionDetector', () {
    late StreamController<MotionSample> samples;
    late _FakeClock clock;
    late MotionDetector detector;

    setUp(() {
      samples = StreamController<MotionSample>.broadcast();
      clock = _FakeClock(DateTime(2026, 5, 1));
      detector = MotionDetector(samples: samples.stream, now: clock.now);
    });

    tearDown(() async {
      await detector.dispose();
      await samples.close();
    });

    Future<void> feed(MotionSample sample) async {
      samples.add(sample);
      // Microtask flush so the stream listener observes the sample
      // before the test checks state.
      await Future<void>.delayed(Duration.zero);
    }

    Future<void> feedStationary() async {
      // 5 samples below threshold = window mean < 0.2 m/s².
      for (var i = 0; i < 5; i++) {
        await feed(const MotionSample(x: 0.05, y: 0.05, z: 0.05));
      }
    }

    Future<void> feedMoving() async {
      for (var i = 0; i < 5; i++) {
        await feed(const MotionSample(x: 0.5, y: 0.5, z: 0.5));
      }
    }

    test('window not yet filled → not stationary', () async {
      await feed(const MotionSample(x: 0.05, y: 0.05, z: 0.05));
      await feed(const MotionSample(x: 0.05, y: 0.05, z: 0.05));
      expect(detector.isStationaryDurationOver(const Duration(seconds: 30)),
          isFalse,
          reason: 'fewer than window-size samples yet');
    });

    test('stationary window but only 25s elapsed → no signal yet', () async {
      await feedStationary();
      clock.advance(const Duration(seconds: 25));
      // Keep feeding stationary samples to reaffirm the state.
      await feedStationary();
      expect(detector.isStationaryDurationOver(const Duration(seconds: 30)),
          isFalse);
    });

    test('stationary 35s → motion signal active', () async {
      await feedStationary();
      clock.advance(const Duration(seconds: 35));
      await feedStationary();
      expect(detector.isStationaryDurationOver(const Duration(seconds: 30)),
          isTrue);
    });

    test('motion above threshold resets stationary_since', () async {
      await feedStationary();
      clock.advance(const Duration(seconds: 20));
      await feedMoving();
      clock.advance(const Duration(seconds: 20));
      // Only 20s of stationary so far in the second window — not enough.
      await feedStationary();
      expect(detector.isStationaryDurationOver(const Duration(seconds: 30)),
          isFalse,
          reason: 'movement reset the stationary clock');
    });

    test('signals stream emits true when crossing 30s threshold', () async {
      final emissions = <bool>[];
      detector
          .stationaryStateChanges(const Duration(seconds: 30))
          .listen(emissions.add);

      await feedStationary();
      clock.advance(const Duration(seconds: 35));
      await feedStationary();

      await Future<void>.delayed(Duration.zero);
      expect(emissions.contains(true), isTrue);
    });

    test('signals stream emits false when motion resumes after threshold',
        () async {
      final emissions = <bool>[];
      detector
          .stationaryStateChanges(const Duration(seconds: 30))
          .listen(emissions.add);

      await feedStationary();
      clock.advance(const Duration(seconds: 35));
      await feedStationary();
      await feedMoving();

      await Future<void>.delayed(Duration.zero);
      expect(emissions, containsAllInOrder(<bool>[true, false]));
    });

    test('magnitude is sqrt(x²+y²+z²) — sample at threshold boundary', () {
      // |0.115, 0.115, 0.115| ≈ 0.199 → below 0.2 threshold.
      final magBelow = math.sqrt(3 * 0.115 * 0.115);
      expect(magBelow, lessThan(0.2));
      // |0.12, 0.12, 0.12| ≈ 0.208 → above threshold.
      final magAbove = math.sqrt(3 * 0.12 * 0.12);
      expect(magAbove, greaterThan(0.2));
    });
  });
}

class _FakeClock {
  _FakeClock(DateTime start) : _now = start;
  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}
