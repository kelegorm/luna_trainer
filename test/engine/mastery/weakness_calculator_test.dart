import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/mastery/weakness_calculator.dart';

void main() {
  group('WeaknessCalculator.compute', () {
    test('matches the plan example: 0.4·0.5 + 0.3·0.1 + 0.2·0.2 + 0.1·1 = 0.37',
        () {
      final w = WeaknessCalculator.compute(
        latencyPercentile: 0.5,
        errorRate: 0.1,
        hintRate: 0.2,
        meanHintStep: 1.0,
      );
      expect(w, closeTo(0.37, 1e-12));
    });

    test('all-zero inputs → 0', () {
      final w = WeaknessCalculator.compute(
        latencyPercentile: 0.0,
        errorRate: 0.0,
        hintRate: 0.0,
        meanHintStep: 0.0,
      );
      expect(w, 0.0);
    });

    test('all-one inputs → 1.0 (weights sum to 1)', () {
      final w = WeaknessCalculator.compute(
        latencyPercentile: 1.0,
        errorRate: 1.0,
        hintRate: 1.0,
        meanHintStep: 1.0,
      );
      expect(w, closeTo(1.0, 1e-12));
    });

    test('clamps inputs above 1.0', () {
      // meanHintStep can technically exceed 1 (it is a count), but
      // for the weakness scalar we clamp so the score stays in [0,1].
      final w = WeaknessCalculator.compute(
        latencyPercentile: 1.5,
        errorRate: 1.5,
        hintRate: 1.5,
        meanHintStep: 5.0,
      );
      expect(w, closeTo(1.0, 1e-12));
    });

    test('clamps inputs below 0', () {
      final w = WeaknessCalculator.compute(
        latencyPercentile: -0.2,
        errorRate: -0.2,
        hintRate: -0.2,
        meanHintStep: -1.0,
      );
      expect(w, 0.0);
    });
  });
}
