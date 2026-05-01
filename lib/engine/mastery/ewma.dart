/// Exponentially Weighted Moving Average — `m_t = α·x + (1-α)·m_{t-1}`.
///
/// Mastery scorer (U8) feeds per-event percentile (∈ [0, 1]) through
/// this with α=0.1 (plan R7). Pure recurrence; the scorer owns the
/// running `m_{t-1}` (persisted on `mastery_state.ewma_percentile`).
class Ewma {
  Ewma._();

  static const double defaultAlpha = 0.1;

  /// Returns `m_t`. When [previous] is null this is the very first
  /// sample for the series, so the recurrence collapses to [sample]
  /// (no "start-at-zero" bias).
  static double next({
    required double sample,
    required double? previous,
    double alpha = defaultAlpha,
  }) {
    if (alpha <= 0 || alpha > 1) {
      throw ArgumentError.value(alpha, 'alpha', 'must be in (0, 1]');
    }
    if (previous == null) return sample;
    return alpha * sample + (1 - alpha) * previous;
  }
}
