import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/puzzles/tango/generator/band_to_params_mapper.dart';
import 'package:luna_traineer/puzzles/tango/generator/difficulty_band.dart';

const _pairCompletion = Heuristic('tango', 'PairCompletion');
const _trioAvoidance = Heuristic('tango', 'TrioAvoidance');
const _signPropagation = Heuristic('tango', 'SignPropagation');
const _advancedMidLine = Heuristic('tango', 'AdvancedMidLineInference');
const _chainExtension = Heuristic('tango', 'ChainExtension');

void main() {
  group('DifficultyBand', () {
    test('clamp() maps out-of-range to nearest legal band', () {
      expect(DifficultyBand.clamp(-5), DifficultyBand.easy);
      expect(DifficultyBand.clamp(0), DifficultyBand.easy);
      expect(DifficultyBand.clamp(1), DifficultyBand.easy);
      expect(DifficultyBand.clamp(2), DifficultyBand.medium);
      expect(DifficultyBand.clamp(3), DifficultyBand.hard);
      expect(DifficultyBand.clamp(99), DifficultyBand.hard);
    });

    test('on-disk integer codes are stable {1,2,3}', () {
      expect(DifficultyBand.easy.value, 1);
      expect(DifficultyBand.medium.value, 2);
      expect(DifficultyBand.hard.value, 3);
    });

    test('bumpUp() saturates at hard', () {
      expect(DifficultyBand.easy.bumpUp(), DifficultyBand.medium);
      expect(DifficultyBand.medium.bumpUp(), DifficultyBand.hard);
      expect(DifficultyBand.hard.bumpUp(), DifficultyBand.hard);
    });

    test('bumpDown() saturates at easy', () {
      expect(DifficultyBand.easy.bumpDown(), DifficultyBand.easy);
      expect(DifficultyBand.medium.bumpDown(), DifficultyBand.easy);
      expect(DifficultyBand.hard.bumpDown(), DifficultyBand.medium);
    });
  });

  group('BandToParamsMapper', () {
    const mapper = BandToParamsMapper();

    test('band=1 (easy): high density, no advanced techniques required', () {
      final p = mapper.mapToParams(DifficultyBand.easy);
      expect(p.density, greaterThanOrEqualTo(0.45));
      expect(p.signDensity, greaterThanOrEqualTo(0.25));
      expect(p.hardAcceptsAlternatives, isFalse);
      expect(p.requiredTechniques.contains(_pairCompletion), isTrue);
      expect(p.requiredTechniques.contains(_trioAvoidance), isTrue);
      expect(p.requiredTechniques.contains(_advancedMidLine), isFalse);
      expect(p.requiredTechniques.contains(_chainExtension), isFalse);
    });

    test('band=2 (medium): SignPropagation in the required set', () {
      final p = mapper.mapToParams(DifficultyBand.medium);
      expect(p.density, lessThan(0.55));
      expect(p.density, greaterThanOrEqualTo(0.30));
      expect(p.requiredTechniques.contains(_signPropagation), isTrue);
      expect(p.hardAcceptsAlternatives, isFalse);
      expect(p.requiredTechniques.contains(_advancedMidLine), isFalse);
    });

    test('band=3 (hard): low density, OR-set of advanced techniques', () {
      final p = mapper.mapToParams(DifficultyBand.hard);
      expect(p.density, lessThanOrEqualTo(0.30));
      expect(p.signDensity, lessThanOrEqualTo(0.20));
      expect(p.hardAcceptsAlternatives, isTrue);
      expect(
        p.requiredTechniques,
        equals(<Heuristic>{_advancedMidLine, _chainExtension}),
      );
    });

    test('mapToParams is pure (same input → same output)', () {
      final a = mapper.mapToParams(DifficultyBand.medium);
      final b = mapper.mapToParams(DifficultyBand.medium);
      expect(a.density, b.density);
      expect(a.signDensity, b.signDensity);
      expect(a.requiredTechniques, equals(b.requiredTechniques));
    });
  });
}
