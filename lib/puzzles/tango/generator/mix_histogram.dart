import 'package:equatable/equatable.dart';

import '../../../engine/domain/heuristic.dart';
import 'target_mix.dart';

/// Distribution of heuristic firings observed when canonically solving
/// a generated puzzle.
///
/// Constructed from raw counts via [MixHistogram.fromCounts]; weights
/// are normalised so that they sum to 1.0 (or exactly 0.0 when no
/// heuristic fired, which only happens for trivial / pre-solved
/// positions).
class MixHistogram extends Equatable {
  const MixHistogram(this.weights);

  /// Builds a histogram from raw firing counts. The sum of [counts]
  /// becomes the denominator; an empty input yields an empty histogram.
  factory MixHistogram.fromCounts(Map<Heuristic, int> counts) {
    if (counts.isEmpty) return const MixHistogram({});
    var total = 0;
    for (final c in counts.values) {
      if (c < 0) {
        throw ArgumentError.value(c, 'counts.value', 'must be ≥ 0');
      }
      total += c;
    }
    if (total == 0) return const MixHistogram({});
    final out = <Heuristic, double>{};
    counts.forEach((h, c) {
      if (c > 0) out[h] = c / total;
    });
    return MixHistogram(Map.unmodifiable(out));
  }

  /// Heuristic → normalised weight in [0, 1].
  final Map<Heuristic, double> weights;

  /// L1 distance from [target.weights] (sum of absolute differences).
  ///
  /// We pick L1 (not L1/2) because the calling code thinks in
  /// "additive total drift" terms — `tolerance: 0.20` means "the
  /// histogram is allowed to be off by 20 percentage points across all
  /// tags combined". L1/2 would add a confusing factor-of-two.
  double driftFrom(TargetMix target) {
    final keys = <Heuristic>{...weights.keys, ...target.weights.keys};
    var drift = 0.0;
    for (final k in keys) {
      final a = weights[k] ?? 0.0;
      final b = target.weights[k] ?? 0.0;
      drift += (a - b).abs();
    }
    return drift;
  }

  @override
  List<Object?> get props => [
        // Map equality for `Equatable` requires sorted entries.
        ..._sortedEntries(weights).expand((e) => [e.key, e.value]),
      ];

  static List<MapEntry<Heuristic, double>> _sortedEntries(
    Map<Heuristic, double> w,
  ) {
    final entries = w.entries.toList()
      ..sort((a, b) {
        final byKind = a.key.kindId.compareTo(b.key.kindId);
        if (byKind != 0) return byKind;
        return a.key.tagId.compareTo(b.key.tagId);
      });
    return entries;
  }
}
