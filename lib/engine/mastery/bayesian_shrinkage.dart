/// Empirical-Bayes shrinkage toward a population prior.
///
/// `score = (n · observed + k · prior) / (n + k)`
///
/// `k` is the prior pseudocount — at `n = k` the score is the
/// arithmetic mean of `observed` and `prior`. U8 plan fixes `k = 10`
/// (R7).
class BayesianShrinkage {
  BayesianShrinkage._();

  static const int defaultK = 10;

  static double shrink({
    required double observed,
    required int n,
    required double prior,
    int k = defaultK,
  }) {
    if (n < 0) {
      throw ArgumentError.value(n, 'n', 'must be ≥ 0');
    }
    if (k <= 0) {
      throw ArgumentError.value(k, 'k', 'must be > 0');
    }
    return (n * observed + k * prior) / (n + k);
  }
}
