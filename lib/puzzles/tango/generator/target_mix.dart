import '../../../engine/domain/heuristic.dart';

/// Heuristic tags allowed in a [TargetMix]. `Composite(unknown)` is
/// explicitly excluded because the plan rejects "Composite не подаётся
/// в drill" — it's a fallback marker, not a teachable technique.
const Set<String> _kAllowedTags = {
  'PairCompletion',
  'TrioAvoidance',
  'ParityFill',
  'SignPropagation',
  'AdvancedMidLineInference',
  'AdvancedMidLineInference/edge_1_5',
  'AdvancedMidLineInference/edge_2_6',
  'ChainExtension',
};

/// Bag of `Heuristic → weight` entries describing the desired mix of
/// techniques required to solve a generated puzzle.
///
/// Weights are normalised internally (must sum within ±5% of 1.0). A
/// puzzle's actual heuristic histogram is compared via L1 distance —
/// see [tolerance] for the in-tolerance threshold.
class TargetMix {
  TargetMix(Map<Heuristic, double> weights, {this.tolerance = 0.20})
      : weights = _validateAndNormalise(weights);

  /// Uniform mix over [over].
  factory TargetMix.uniform({
    required Iterable<Heuristic> over,
    double tolerance = 0.20,
  }) {
    final list = over.toList();
    if (list.isEmpty) {
      throw ArgumentError.value(over, 'over', 'must contain ≥1 heuristic');
    }
    final w = 1.0 / list.length;
    return TargetMix(
      {for (final h in list) h: w},
      tolerance: tolerance,
    );
  }

  /// Normalised weights summing to exactly 1.0.
  final Map<Heuristic, double> weights;

  /// Permissible L1 drift between the puzzle's actual mix and this
  /// target before the generator regenerates. Default 0.20.
  final double tolerance;

  static Map<Heuristic, double> _validateAndNormalise(
    Map<Heuristic, double> raw,
  ) {
    if (raw.isEmpty) {
      throw ArgumentError.value(raw, 'weights', 'must be non-empty');
    }
    for (final h in raw.keys) {
      if (!_kAllowedTags.contains(h.tagId)) {
        throw ArgumentError.value(
          h,
          'weights.key',
          'tag "${h.tagId}" is not eligible for drill '
              '(Composite не подаётся в drill)',
        );
      }
    }
    var sum = 0.0;
    for (final v in raw.values) {
      if (v < 0) {
        throw ArgumentError.value(v, 'weights.value', 'must be ≥ 0');
      }
      sum += v;
    }
    if (sum < 0.95 || sum > 1.05) {
      throw ArgumentError.value(
        sum,
        'weights.sum',
        'must sum to ~1.0 (got $sum); accepted range 0.95..1.05',
      );
    }
    return {for (final e in raw.entries) e.key: e.value / sum};
  }
}
