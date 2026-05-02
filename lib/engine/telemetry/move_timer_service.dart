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

  /// Накопленная пауза за текущий ход (R13: hint step 4 паузит таймер).
  /// Сбрасывается при [startMove] / [commitMove].
  Duration _pausedAccum = Duration.zero;

  /// Момент начала текущей паузы (`null` если не запаузено).
  DateTime? _pausedAt;

  bool get isActive => _startedAt != null;

  /// True пока таймер запаузен между [pause] и [resume]. Hint-overlay
  /// step 4 (R13 / AE2): отображение объяснения не должно крутить
  /// move-таймер.
  bool get isPaused => _pausedAt != null;

  /// Открывает окно контаминационного мониторинга и фиксирует
  /// started_at. Повторный startMove поверх активного окна
  /// перезапускает таймер (предыдущий ход отбрасывается).
  void startMove() {
    _startedAt = _now();
    _pausedAccum = Duration.zero;
    _pausedAt = null;
    _contamination.startWindow();
  }

  /// Снимает текущий момент с активного хода как старт паузы. Повторный
  /// [pause] над уже запаузенным таймером — no-op (idempotent).
  void pause() {
    if (_startedAt == null) return;
    if (_pausedAt != null) return;
    _pausedAt = _now();
  }

  /// Завершает паузу, накапливая её длительность в `_pausedAccum`.
  /// `resume` без активной паузы — no-op (idempotent).
  void resume() {
    final paused = _pausedAt;
    if (paused == null) return;
    _pausedAccum += _now().difference(paused);
    _pausedAt = null;
  }

  /// Закрывает окно и возвращает агрегированные тайминги. Если
  /// [startMove] не звался — бросает [StateError]. Накопленная пауза
  /// (если [resume] не был вызван) учитывается до момента commit-а.
  MoveTimingMetadata commitMove() {
    final start = _startedAt;
    if (start == null) {
      throw StateError('commitMove() called without an active move window');
    }
    final end = _now();
    // Закрываем дангляющую паузу, если caller забыл [resume].
    final pausedNow = _pausedAt;
    if (pausedNow != null) {
      _pausedAccum += end.difference(pausedNow);
      _pausedAt = null;
    }
    final accumPaused = _pausedAccum;
    _startedAt = null;
    _pausedAccum = Duration.zero;

    final wallClock = end.difference(start);
    final latency = wallClock - accumPaused;
    final core = _contamination.endWindow();
    final idle = latency >= idleThreshold;

    return MoveTimingMetadata(
      startedAt: start,
      endedAt: end,
      latencyMs: latency.inMilliseconds < 0 ? 0 : latency.inMilliseconds,
      signals: core.copyWith(idleSoftSignal: idle),
    );
  }

  Future<void> dispose() async {
    _startedAt = null;
    _pausedAt = null;
    _pausedAccum = Duration.zero;
    await _contamination.dispose();
  }
}
