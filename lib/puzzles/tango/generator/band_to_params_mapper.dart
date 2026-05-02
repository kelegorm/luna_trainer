import '../../../engine/domain/heuristic.dart';
import 'difficulty_band.dart';

/// Heuristic tags used by [BandToParamsMapper]. Kept private — public
/// API is the [GenerationParams] bag.
const Heuristic _pairCompletion = Heuristic('tango', 'PairCompletion');
const Heuristic _trioAvoidance = Heuristic('tango', 'TrioAvoidance');
const Heuristic _parityFill = Heuristic('tango', 'ParityFill');
const Heuristic _signPropagation = Heuristic('tango', 'SignPropagation');
const Heuristic _advancedMidLine =
    Heuristic('tango', 'AdvancedMidLineInference');
const Heuristic _chainExtension = Heuristic('tango', 'ChainExtension');

/// Output bundle from [BandToParamsMapper.mapToParams] — feeds the
/// generator's steered-removal loop (R35).
///
/// * [density] — target *clue density* (filled active cells ÷ active
///   cells) for the carved puzzle. Higher density = easier (fewer empty
///   cells to deduce).
/// * [signDensity] — target *constraint density* (`=` / `×` markers ÷
///   adjacent-active-pair count) for the carved puzzle.
/// * [requiredTechniques] — set of `Heuristic` tags that the canonical
///   solve must hit at least once for the puzzle to be accepted by the
///   band. For [DifficultyBand.hard] one of `AdvancedMidLineInference`
///   *or* `ChainExtension` is sufficient — see [hardAcceptsAlternatives].
///
/// Numeric thresholds are starting values per the plan ("Deferred to
/// Implementation"). Calibrate after ~20–30 generated puzzles.
class GenerationParams {
  const GenerationParams({
    required this.density,
    required this.signDensity,
    required this.requiredTechniques,
    this.hardAcceptsAlternatives = false,
  });

  /// Target ratio of seeded cells over active cells in the carved puzzle.
  final double density;

  /// Target ratio of `=` / `×` markers over adjacent-active-pair count.
  final double signDensity;

  /// Heuristic tags that must each appear at least once in the canonical
  /// solve trace. For `hardAcceptsAlternatives = true` the set is
  /// satisfied if **any** of its members fired (band=3 OR semantics).
  final Set<Heuristic> requiredTechniques;

  /// When `true`, the generator treats [requiredTechniques] as an
  /// OR-set: the puzzle is accepted if at least one tag from the set
  /// appears in the trace. Used by band=3 (Advanced OR Chain).
  final bool hardAcceptsAlternatives;
}

/// Pure mapping `DifficultyBand → GenerationParams` (R35).
///
/// Stateless on purpose — `const` constructor lets the generator hold a
/// single shared instance.
class BandToParamsMapper {
  const BandToParamsMapper();

  /// Returns the [GenerationParams] for [band].
  ///
  /// Numeric values below are starting points (Deferred to
  /// Implementation per the plan). Tune after first calibration sweep.
  GenerationParams mapToParams(DifficultyBand band) {
    switch (band) {
      case DifficultyBand.easy:
        // Easy: dense board, lots of signs, only the elementary
        // techniques required. ParityFill always fires on a solvable
        // 6×6, so we list it last — the *real* signal is that the
        // puzzle reaches PairCompletion / TrioAvoidance.
        return GenerationParams(
          density: 0.55,
          signDensity: 0.35,
          requiredTechniques: {
            _pairCompletion,
            _trioAvoidance,
            _parityFill,
          },
        );
      case DifficultyBand.medium:
        // Medium: moderate density + SignPropagation must fire at least
        // once. AE11 happy path checks this exactly.
        return GenerationParams(
          density: 0.40,
          signDensity: 0.25,
          requiredTechniques: {
            _pairCompletion,
            _trioAvoidance,
            _parityFill,
            _signPropagation,
          },
        );
      case DifficultyBand.hard:
        // Hard: sparse board, few signs, requires AdvancedMidLine OR
        // ChainExtension. The OR is encoded via
        // [hardAcceptsAlternatives].
        return GenerationParams(
          density: 0.25,
          signDensity: 0.15,
          requiredTechniques: {
            _advancedMidLine,
            _chainExtension,
          },
          hardAcceptsAlternatives: true,
        );
    }
  }
}
