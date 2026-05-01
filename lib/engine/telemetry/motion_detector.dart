import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

/// Single accelerometer reading в м/с². Каноничный источник —
/// `userAccelerometerEvents` из sensors_plus (gravity-removed).
/// Отдельный тип, чтобы не привязывать engine к sensors_plus —
/// интеграционный слой адаптирует.
class MotionSample {
  const MotionSample({required this.x, required this.y, required this.z});
  final double x;
  final double y;
  final double z;

  double get magnitude => math.sqrt(x * x + y * y + z * z);
}

/// Детектор stationary-окон по userAccelerometer (R14).
///
/// Логика:
///   * Скользящее окно последних [windowSize] сэмплов.
///   * Среднее magnitude по окну < [thresholdMs2] → текущий tick
///     stationary. Иначе — moving.
///   * `_stationarySince` ставится в первый stationary-tick после
///     любого moving (или null-init); сбрасывается на любой moving.
///   * `isStationaryDurationOver(d)` отвечает true, если сейчас
///     stationary и `now - _stationarySince ≥ d`.
///
/// Стартовые пороги (плановое решение, калибруется empirically):
///   * windowSize = 5 (≈ 1 сек @ 5 Hz sensors_plus)
///   * thresholdMs2 = 0.2 м/с²
///   * stationary порог для motion_signal — 30 секунд (R14, R16)
class MotionDetector {
  MotionDetector({
    required Stream<MotionSample> samples,
    DateTime Function()? now,
    this.windowSize = 5,
    this.thresholdMs2 = 0.2,
  }) : _now = now ?? DateTime.now {
    _subscription = samples.listen(_onSample);
  }

  final DateTime Function() _now;
  final int windowSize;
  final double thresholdMs2;

  late final StreamSubscription<MotionSample> _subscription;
  final Queue<double> _window = Queue<double>();
  DateTime? _stationarySince;
  bool _disposed = false;

  // Map<thresholdMs, _ThresholdEmitter> — один эмиттер на каждый
  // запрошенный stationary-порог. Позволяет нескольким consumer-ам
  // подписаться на разные пороги (полезно для будущей калибровки).
  final Map<int, _ThresholdEmitter> _emitters = <int, _ThresholdEmitter>{};

  /// True, если детектор сейчас в stationary-окне и оно длится ≥ d.
  bool isStationaryDurationOver(Duration d) {
    final since = _stationarySince;
    if (since == null) return false;
    return _now().difference(since) >= d;
  }

  /// Stream-наблюдение за переходом state(stationary >= d) ↔
  /// state(stationary < d или moving). Эмитит true когда state
  /// становится истинным, false — когда падает обратно.
  Stream<bool> stationaryStateChanges(Duration threshold) {
    final key = threshold.inMilliseconds;
    final emitter = _emitters.putIfAbsent(
      key,
      () => _ThresholdEmitter(threshold),
    );
    return emitter.stream;
  }

  void _onSample(MotionSample sample) {
    if (_disposed) return;

    _window.addLast(sample.magnitude);
    if (_window.length > windowSize) {
      _window.removeFirst();
    }

    if (_window.length < windowSize) {
      // Окно ещё не наполнено — не выносим решения.
      return;
    }

    final mean = _window.reduce((a, b) => a + b) / _window.length;
    final stationaryNow = mean < thresholdMs2;

    if (stationaryNow) {
      _stationarySince ??= _now();
    } else {
      _stationarySince = null;
    }

    _updateEmitters();
  }

  void _updateEmitters() {
    for (final emitter in _emitters.values) {
      final active = isStationaryDurationOver(emitter.threshold);
      emitter.update(active);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription.cancel();
    for (final emitter in _emitters.values) {
      await emitter.close();
    }
    _emitters.clear();
  }
}

class _ThresholdEmitter {
  _ThresholdEmitter(this.threshold);

  final Duration threshold;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  bool _lastState = false;

  Stream<bool> get stream => _controller.stream;

  void update(bool active) {
    if (active == _lastState) return;
    _lastState = active;
    _controller.add(active);
  }

  Future<void> close() => _controller.close();
}
