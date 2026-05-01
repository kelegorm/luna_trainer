/// Классификация хода по оси propagation/hunt (R31).
///
/// `null` нигде не появляется как состояние «не определено» —
/// классификатор всегда выносит решение; первый ход партии = hunt.
/// MoveEvent.mode остаётся nullable для обратной совместимости и для
/// случаев, когда ход записывается без контекста (например, через
/// admin-инструменты или импорт).
enum MoveMode { propagation, hunt }

extension MoveModeWire on MoveMode {
  /// Стабильное wire-представление для записи в `move_events.mode`.
  /// SQL grep по этим литералам должен находить только legitimate
  /// call-sites — никаких 'full_game'/'drill' (это ушло в
  /// `sessions.mode`).
  String get wire => switch (this) {
        MoveMode.propagation => 'propagation',
        MoveMode.hunt => 'hunt',
      };
}

/// Контекст предыдущего хода, нужный для классификации текущего.
/// Каноничная запись передаётся в classify() как единый объект,
/// чтобы вызывающий слой не разбирал nullable-парсинг построчно.
class PreviousMoveContext {
  const PreviousMoveContext({
    required this.row,
    required this.col,
    required this.at,
  });

  final int row;
  final int col;
  final DateTime at;
}

/// Pure-function classifier для R31. Не имеет состояния — caller
/// (engine telemetry) держит «последний ход» сам и передаёт его в
/// классификатор при коммите следующего.
///
/// Стартовые пороги (плановое решение, калибруется после 2 недель
/// live-use):
///   * радиус ≤ 1 (Chebyshev distance — king-move neighbourhood)
///   * Δt ≤ 5 секунд между ходами
///   * связь по знаку =/× — overrides радиус, всё равно требует
///     Δt-порог
class MoveModeClassifier {
  const MoveModeClassifier._();

  /// Maximum Chebyshev distance, при которой соседство считается
  /// propagation-ом без учёта знаков.
  static const int radiusThreshold = 1;

  /// Δt порог: дольше — пользователь ушёл сканировать доску, это
  /// hunt даже если формально соседняя клетка.
  static const Duration timeThreshold = Duration(milliseconds: 5000);

  static MoveMode classify({
    required PreviousMoveContext? previous,
    required int currentRow,
    required int currentCol,
    required DateTime currentAt,
    required bool previousConnectedBySign,
  }) {
    if (previous == null) return MoveMode.hunt;

    final dt = currentAt.difference(previous.at);
    if (dt > timeThreshold) return MoveMode.hunt;

    final dr = (currentRow - previous.row).abs();
    final dc = (currentCol - previous.col).abs();
    final adjacent = dr <= radiusThreshold && dc <= radiusThreshold;

    if (adjacent || previousConnectedBySign) {
      return MoveMode.propagation;
    }
    return MoveMode.hunt;
  }
}
