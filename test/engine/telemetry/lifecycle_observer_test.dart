import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/telemetry/lifecycle_observer.dart';

void main() {
  group('LifecycleObserver', () {
    late LifecycleObserver observer;
    late _FakeClock clock;

    setUp(() {
      clock = _FakeClock(DateTime(2026, 5, 1));
      observer = LifecycleObserver(now: clock.now);
    });

    tearDown(() {
      observer.dispose();
    });

    test('paused → resumed after 5s emits signal with bg_duration_ms=5000',
        () async {
      final received = <LifecycleSignal>[];
      observer.signals.listen(received.add);

      observer.onState(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 5));
      observer.onState(AppLifecycleState.resumed);

      await Future<void>.delayed(Duration.zero);
      expect(received.length, 1);
      expect(received.single.bgDuration.inMilliseconds, 5000);
    });

    test('iOS pitfall: inactive < 500ms then resumed → no signal', () async {
      final received = <LifecycleSignal>[];
      observer.signals.listen(received.add);

      observer.onState(AppLifecycleState.inactive);
      clock.advance(const Duration(milliseconds: 200));
      observer.onState(AppLifecycleState.resumed);

      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty,
          reason: 'inactive < 500ms is debounced (iOS Control Center swipe)');
    });

    test('inactive ≥ 500ms then resumed → signal fires', () async {
      final received = <LifecycleSignal>[];
      observer.signals.listen(received.add);

      observer.onState(AppLifecycleState.inactive);
      clock.advance(const Duration(milliseconds: 500));
      observer.onState(AppLifecycleState.resumed);

      await Future<void>.delayed(Duration.zero);
      expect(received.length, 1);
      expect(received.single.bgDuration.inMilliseconds, 500);
    });

    test('inactive → paused → resumed measures from first non-resumed state',
        () async {
      final received = <LifecycleSignal>[];
      observer.signals.listen(received.add);

      observer.onState(AppLifecycleState.inactive);
      clock.advance(const Duration(milliseconds: 100));
      observer.onState(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 10));
      observer.onState(AppLifecycleState.resumed);

      await Future<void>.delayed(Duration.zero);
      expect(received.length, 1);
      expect(received.single.bgDuration.inMilliseconds, 10100);
    });

    test('resumed without a prior pause is a no-op', () async {
      final received = <LifecycleSignal>[];
      observer.signals.listen(received.add);

      observer.onState(AppLifecycleState.resumed);
      observer.onState(AppLifecycleState.resumed);

      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);
    });

    test('multiple pause/resume cycles each emit one signal', () async {
      final received = <LifecycleSignal>[];
      observer.signals.listen(received.add);

      observer.onState(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 1));
      observer.onState(AppLifecycleState.resumed);
      clock.advance(const Duration(seconds: 30));
      observer.onState(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 2));
      observer.onState(AppLifecycleState.resumed);

      await Future<void>.delayed(Duration.zero);
      expect(received.length, 2);
      expect(received[0].bgDuration.inSeconds, 1);
      expect(received[1].bgDuration.inSeconds, 2);
    });

    test('dispose closes the stream — no further signals', () async {
      observer.dispose();
      // Should not throw, should not emit.
      observer.onState(AppLifecycleState.paused);
      observer.onState(AppLifecycleState.resumed);
      // No assertion: just confirms dispose is idempotent and safe.
    });
  });
}

class _FakeClock {
  _FakeClock(DateTime start) : _now = start;
  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}
