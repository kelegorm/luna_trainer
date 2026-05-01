import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/mastery/bayesian_shrinkage.dart';

void main() {
  group('BayesianShrinkage.shrink', () {
    test('n=0 returns the prior unchanged', () {
      expect(
        BayesianShrinkage.shrink(observed: 0.9, n: 0, prior: 0.5),
        0.5,
      );
    });

    test('n→∞ converges to the observed value', () {
      // n=10_000, k=10 → weight on observed is 1000× the weight on
      // prior, so the result should be within 1e-3 of observed.
      final s = BayesianShrinkage.shrink(observed: 0.9, n: 10000, prior: 0.5);
      expect(s, closeTo(0.9, 1e-3));
    });

    test('at n=k the result is exactly midway between observed and prior', () {
      // (k·observed + k·prior) / (k+k) = (observed + prior) / 2
      final s = BayesianShrinkage.shrink(observed: 0.9, n: 10, prior: 0.5);
      expect(s, closeTo(0.7, 1e-12));
    });

    test('matches the plan formula for arbitrary n', () {
      // (5·0.8 + 10·0.5) / (5 + 10) = 9.0 / 15 = 0.6
      expect(
        BayesianShrinkage.shrink(observed: 0.8, n: 5, prior: 0.5),
        closeTo(0.6, 1e-12),
      );
    });

    test('default k = 10 (plan R7)', () {
      // Same as the n=k test above but using the default k.
      final s = BayesianShrinkage.shrink(observed: 0.9, n: 10, prior: 0.5);
      expect(s, closeTo(0.7, 1e-12));
    });

    test('monotone in n: more evidence pulls result toward observed', () {
      const observed = 0.9;
      const prior = 0.3;
      double last = BayesianShrinkage.shrink(
        observed: observed,
        n: 0,
        prior: prior,
      );
      for (var n = 1; n <= 100; n++) {
        final s =
            BayesianShrinkage.shrink(observed: observed, n: n, prior: prior);
        // Each additional event moves result strictly toward observed.
        expect(s, greaterThan(last));
        expect(s, lessThanOrEqualTo(observed));
        last = s;
      }
    });

    test('rejects negative n and non-positive k', () {
      expect(
        () => BayesianShrinkage.shrink(observed: 0.5, n: -1, prior: 0.5),
        throwsArgumentError,
      );
      expect(
        () => BayesianShrinkage.shrink(
            observed: 0.5, n: 5, prior: 0.5, k: 0),
        throwsArgumentError,
      );
    });
  });
}
