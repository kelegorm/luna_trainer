import 'package:fsrs/fsrs.dart';

/// Inputs the [RatingMapper] needs to classify a single move.
///
/// Decoupled from `MoveEventRow` and `MasteryScore` so the mapper can
/// stay a pure function: the caller is responsible for filtering
/// contaminated events (per plan U9 contract) and for sourcing
/// p25/p75 from the persisted [MasteryScore]. Pre-calibration rows
/// expose null percentiles — `Easy` then collapses to `Good`.
class RatingInputs {
  const RatingInputs({
    required this.wasCorrect,
    required this.hintStepReached,
    required this.latencyMs,
    this.latencyP25Ms,
    this.latencyP75Ms,
    this.contaminationRecovery = false,
  });

  final bool wasCorrect;
  final int hintStepReached;
  final int latencyMs;
  final int? latencyP25Ms;
  final int? latencyP75Ms;

  /// True when the user pushed through a contaminated move (e.g. came
  /// back from background and finished the move). The mastery scorer
  /// drops the latency, but the FSRS rating still gets a Hard so the
  /// scheduler does not overestimate retention. Never set this for
  /// raw contaminated drops — those bypass the mapper entirely.
  final bool contaminationRecovery;
}

/// Maps a single move into an FSRS [Rating] using the table from the
/// plan (High-Level Technical Design § FSRS rating mapping):
///
/// ```
/// error == true OR hint_step ≥ 2          → Again
/// hint_step == 1 OR contamination-recovery → Hard
/// correct, no hint, latency ≤ p25         → Easy
/// correct, no hint, otherwise             → Good
/// ```
///
/// Contaminated events MUST be filtered by the caller — the contract
/// in plan U9 is that they never reach the mapper.
class RatingMapper {
  RatingMapper._();

  static Rating map(RatingInputs i) {
    if (!i.wasCorrect || i.hintStepReached >= 2) return Rating.again;
    if (i.hintStepReached == 1 || i.contaminationRecovery) return Rating.hard;

    final p25 = i.latencyP25Ms;
    if (p25 != null && i.latencyMs <= p25) return Rating.easy;
    return Rating.good;
  }
}
