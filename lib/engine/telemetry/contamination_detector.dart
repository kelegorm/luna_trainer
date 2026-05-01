import 'dart:async';

import 'lifecycle_observer.dart';
import 'motion_detector.dart';

/// Аггрегированные сигналы для одного окна хода. `contaminated_flag`
/// = lifecycle ИЛИ motion. Idle отдельно: только лог, не affects
/// mastery (план R14).
class MoveSignals {
  const MoveSignals({
    required this.lifecycleSignal,
    required this.motionSignal,
    required this.idleSoftSignal,
  });

  final bool lifecycleSignal;
  final bool motionSignal;
  final bool idleSoftSignal;

  bool get contaminatedFlag => lifecycleSignal || motionSignal;

  static const empty = MoveSignals(
    lifecycleSignal: false,
    motionSignal: false,
    idleSoftSignal: false,
  );

  MoveSignals copyWith({
    bool? lifecycleSignal,
    bool? motionSignal,
    bool? idleSoftSignal,
  }) {
    return MoveSignals(
      lifecycleSignal: lifecycleSignal ?? this.lifecycleSignal,
      motionSignal: motionSignal ?? this.motionSignal,
      idleSoftSignal: idleSoftSignal ?? this.idleSoftSignal,
    );
  }

  @override
  String toString() =>
      'MoveSignals(lifecycle=$lifecycleSignal, motion=$motionSignal, '
      'idle=$idleSoftSignal, contaminated=$contaminatedFlag)';
}

/// Aggregator-окно contaminated-сигналов: обёртывает [LifecycleObserver]
/// и [MotionDetector], собирая их сигналы между [startWindow] и
/// [endWindow]. Idle-сигнал [MoveTimerService] добавляет сам, зная
/// длительность хода.
///
/// Окно эксклюзивное — при `startWindow` поверх активного окна
/// предыдущее окно отбрасывается. Caller обязан звать [endWindow]
/// (или [dispose]) когда move-сессия закончилась, чтобы освободить
/// подписки.
class ContaminationDetector {
  ContaminationDetector({
    required LifecycleObserver lifecycle,
    required MotionDetector motion,
    this.motionStationaryThreshold = const Duration(seconds: 30),
  })  : _lifecycle = lifecycle,
        _motion = motion;

  final LifecycleObserver _lifecycle;
  final MotionDetector _motion;
  final Duration motionStationaryThreshold;

  StreamSubscription<LifecycleSignal>? _lifecycleSub;
  StreamSubscription<bool>? _motionSub;

  bool _lifecycleFired = false;
  bool _motionFired = false;

  void startWindow() {
    _cancelSubs();
    _lifecycleFired = false;
    _motionFired = false;

    _lifecycleSub = _lifecycle.signals.listen((_) {
      _lifecycleFired = true;
    });
    _motionSub = _motion
        .stationaryStateChanges(motionStationaryThreshold)
        .listen((active) {
      if (active) _motionFired = true;
    });
  }

  /// Снимает finalized-сигналы за окно. Также консультирует текущий
  /// state детектора движения — если телефон уже >30s неподвижен на
  /// момент commit-а, motionSignal=true даже без свежей smell-эмиссии.
  /// Idle-флаг прикладной слой ([MoveTimerService]) добавляет сам.
  MoveSignals endWindow() {
    final motionNow = _motion.isStationaryDurationOver(motionStationaryThreshold);
    final result = MoveSignals(
      lifecycleSignal: _lifecycleFired,
      motionSignal: _motionFired || motionNow,
      idleSoftSignal: false,
    );
    _cancelSubs();
    return result;
  }

  Future<void> dispose() async {
    await _cancelSubs();
  }

  Future<void> _cancelSubs() async {
    await _lifecycleSub?.cancel();
    await _motionSub?.cancel();
    _lifecycleSub = null;
    _motionSub = null;
  }
}
