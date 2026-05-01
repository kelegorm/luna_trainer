import 'mix_histogram.dart';
import 'tango_puzzle.dart';

/// Outcome of a single [TangoLevelGenerator.generate] call.
sealed class GeneratorResult {
  const GeneratorResult();
}

/// Generation succeeded and the resulting puzzle's mix histogram is
/// within [TargetMix.tolerance] of the request.
class GeneratorSuccess extends GeneratorResult {
  const GeneratorSuccess({required this.puzzle, required this.histogram});

  final TangoPuzzle puzzle;
  final MixHistogram histogram;
}

/// 200 attempts exhausted but a *valid* (uniquely-solvable) puzzle was
/// produced — the closest one in mix terms is returned, with the
/// observed L1 [mixDrift] from the requested target.
class GeneratorBestEffort extends GeneratorResult {
  const GeneratorBestEffort({
    required this.puzzle,
    required this.histogram,
    required this.mixDrift,
  });

  final TangoPuzzle puzzle;
  final MixHistogram histogram;
  final double mixDrift;
}

/// Generation refused outright (e.g. an invalid target mix). The
/// generator never returns this for "I tried hard but couldn't" — that
/// path goes through [GeneratorBestEffort].
class GeneratorFailure extends GeneratorResult {
  const GeneratorFailure(this.reason);

  final String reason;
}
