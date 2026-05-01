import 'contamination_detector.dart';

/// Метаданные одного завершённого хода — то, что caller записывает в
/// `move_events` через [MoveEventsRepository.commit] (R14, R15, R16).
/// `latencyMs` = wall-clock дельта; пользователь его не видит (R16).
class MoveTimingMetadata {
  const MoveTimingMetadata({
    required this.startedAt,
    required this.endedAt,
    required this.latencyMs,
    required this.signals,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int latencyMs;
  final MoveSignals signals;

  bool get contaminatedFlag => signals.contaminatedFlag;

  @override
  String toString() =>
      'MoveTimingMetadata(latency=${latencyMs}ms, $signals)';
}

/// Тонкий wrapper над [ContaminationDetector] + clock. Хранит
/// startedAt-snapshot одного активного хода. Не thread-safe, не
/// re-entrant: один экземпляр на одну текущую move-сессию.
///
/// Idle-порог [idleThreshold] (стартово 8 сек, R14): пока что грубое
/// «ход занял дольше idleThreshold» = idle_soft_signal=true. В
/// будущем можно расширить на gesture-tracking, но пока внутри одного
/// хода нет промежуточных input-event-ов.
class MoveTimerService {
  MoveTimerService({
    required ContaminationDetector contamination,
    DateTime Function()? now,
    this.idleThreshold = const Duration(seconds: 8),
  })  : _contamination = contamination,
        _now = now ?? DateTime.now;

  final ContaminationDetector _contamination;
  final DateTime Function() _now;
  final Duration idleThreshold;

  DateTime? _startedAt;

  bool get isActive => _startedAt != null;

  /// Открывает окно контаминационного мониторинга и фиксирует
  /// started_at. Повторный startMove поверх активного окна
  /// перезапускает таймер (предыдущий ход отбрасывается).
  void startMove() {
    _startedAt = _now();
    _contamination.startWindow();
  }

  /// Закрывает окно и возвращает агрегированные тайминги. Если
  /// [startMove] не звался — бросает [StateError].
  MoveTimingMetadata commitMove() {
    final start = _startedAt;
    if (start == null) {
      throw StateError('commitMove() called without an active move window');
    }
    final end = _now();
    _startedAt = null;

    final latency = end.difference(start);
    final core = _contamination.endWindow();
    final idle = latency >= idleThreshold;

    return MoveTimingMetadata(
      startedAt: start,
      endedAt: end,
      latencyMs: latency.inMilliseconds,
      signals: core.copyWith(idleSoftSignal: idle),
    );
  }

  Future<void> dispose() async {
    _startedAt = null;
    await _contamination.dispose();
  }
}
