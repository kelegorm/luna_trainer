import '../../puzzles/tango/generator/target_mix.dart';
import '../domain/heuristic.dart';
import 'drill_selector.dart';

/// Tags the level generator can build a puzzle around. Matches the
/// allow-list inside [TargetMix] — keeping it here lets us filter
/// drill slots before construction (so the builder degrades
/// gracefully instead of throwing on a Composite slot).
const Set<String> _kDrillableTags = {
  'PairCompletion',
  'TrioAvoidance',
  'ParityFill',
  'SignPropagation',
  'AdvancedMidLineInference',
  'AdvancedMidLineInference/edge_1_5',
  'AdvancedMidLineInference/edge_2_6',
  'ChainExtension',
};

/// Turns a [DrillBatch] into one [TargetMix] per puzzle. v1 emits a
/// single-heuristic mix per slot — the level generator (U6) builds a
/// dedicated puzzle for each. Chain-drill packing (R5) lives in the
/// UX layer (U12) and is intentionally out of scope here.
class TargetMixBuilder {
  const TargetMixBuilder();

  List<TargetMix> build(DrillBatch batch) {
    final out = <TargetMix>[];
    for (final slot in batch.slots) {
      if (!_kDrillableTags.contains(slot.heuristic.tagId)) continue;
      out.add(_singleHeuristicMix(slot.heuristic));
    }
    return List.unmodifiable(out);
  }

  TargetMix _singleHeuristicMix(Heuristic h) {
    return TargetMix({h: 1.0});
  }
}
