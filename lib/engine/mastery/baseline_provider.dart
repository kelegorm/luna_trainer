import '../domain/heuristic.dart';

/// Solver-baseline latency for a single heuristic. The mastery scorer
/// uses this to compute `z = (log(latency) - log(median)) / sigmaLog`
/// (Frontiers 2021 RT-outlier rule, log-transform first).
class BaselineSpec {
  const BaselineSpec({required this.medianMs, required this.sigmaLog});

  /// Solver-baseline median latency in milliseconds. The user's
  /// observed latency is compared against this on the log scale.
  final int medianMs;

  /// Standard deviation on the log scale. v1 uses 0.5 (~ ±50%
  /// spread); will be replaced by an empirical estimate once we
  /// have telemetry across users (see plan note on σ_baseline).
  final double sigmaLog;
}

/// v1: a single flat baseline applied to every heuristic. The plan
/// calls for a per-heuristic table tuned from solver simulations,
/// but until we have empirical data the constant keeps the math
/// well-defined and z-scores at least directionally meaningful.
///
/// TODO(U8 follow-up): replace with per-heuristic table calibrated
/// from solver runs on representative Tango boards.
class BaselineProvider {
  const BaselineProvider({
    BaselineSpec defaultSpec = const BaselineSpec(
      medianMs: 5000,
      sigmaLog: 0.5,
    ),
  }) : _default = defaultSpec;

  final BaselineSpec _default;

  BaselineSpec forHeuristic(Heuristic _) => _default;
}
