/// Combines mastery signals into a single weakness scalar in [0, 1].
///
/// `weakness = 0.4·latency + 0.3·error + 0.2·hint + 0.1·hint_step`
/// (plan R7). Higher weakness ⇒ higher drill priority. Inputs are
/// clamped to [0, 1] before weighting so the result is always
/// well-defined for the radar UI and drill selector.
class WeaknessCalculator {
  WeaknessCalculator._();

  static double compute({
    required double latencyPercentile,
    required double errorRate,
    required double hintRate,
    required double meanHintStep,
  }) {
    final l = _clamp01(latencyPercentile);
    final e = _clamp01(errorRate);
    final h = _clamp01(hintRate);
    final s = _clamp01(meanHintStep);
    return 0.4 * l + 0.3 * e + 0.2 * h + 0.1 * s;
  }

  static double _clamp01(double v) {
    if (v.isNaN) return 0.0;
    if (v < 0) return 0.0;
    if (v > 1) return 1.0;
    return v;
  }
}
