import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:luna_traineer/engine/fsrs/rating_mapper.dart';

void main() {
  group('RatingMapper.map', () {
    test('error → Again', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: false,
        hintStepReached: 0,
        latencyMs: 1000,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.again);
    });

    test('hint_step >= 2 → Again', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 2,
        latencyMs: 500,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.again);
    });

    test('hint_step == 1 → Hard', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 1,
        latencyMs: 800,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.hard);
    });

    test('contamination-recovery → Hard', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 0,
        latencyMs: 800,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
        contaminationRecovery: true,
      ));
      expect(r, Rating.hard);
    });

    test('correct, no hint, latency = 0.8·p25 → Easy', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 0,
        latencyMs: 800, // 0.8 * 1000
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.easy);
    });

    test('correct, no hint, latency = p25 → Easy (boundary inclusive)', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 0,
        latencyMs: 1000,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.easy);
    });

    test('correct, no hint, latency between p25 and p75 → Good', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 0,
        latencyMs: 3000,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.good);
    });

    test('correct, no hint, latency > p75 → Good (slow but correct)', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 0,
        latencyMs: 9000,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.good);
    });

    test('correct, no hint, no baseline (calibrating) → Good', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 0,
        latencyMs: 100,
        // p25/p75 null — pre-calibration.
      ));
      expect(r, Rating.good);
    });

    test('precedence: error beats fast latency', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: false,
        hintStepReached: 0,
        latencyMs: 100,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.again);
    });

    test('precedence: hint_step=2 beats fast latency', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 2,
        latencyMs: 100,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.again);
    });

    test('precedence: hint_step=1 beats fast latency', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 1,
        latencyMs: 100,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.hard);
    });

    test('latencyMs <= 0 still classifies safely as Easy when correct', () {
      final r = RatingMapper.map(const RatingInputs(
        wasCorrect: true,
        hintStepReached: 0,
        latencyMs: 0,
        latencyP25Ms: 1000,
        latencyP75Ms: 5000,
      ));
      expect(r, Rating.easy);
    });
  });
}
