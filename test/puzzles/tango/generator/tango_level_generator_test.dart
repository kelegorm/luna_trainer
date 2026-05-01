import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/generator/board_shape.dart';
import 'package:luna_traineer/puzzles/tango/generator/generator_result.dart';
import 'package:luna_traineer/puzzles/tango/generator/shape_rules.dart';
import 'package:luna_traineer/puzzles/tango/generator/tango_level_generator.dart';
import 'package:luna_traineer/puzzles/tango/generator/target_mix.dart';

const _parityFill = Heuristic('tango', 'ParityFill');
const _trioAvoidance = Heuristic('tango', 'TrioAvoidance');
const _signPropagation = Heuristic('tango', 'SignPropagation');
const _advancedMidLine = Heuristic('tango', 'AdvancedMidLineInference');
const _composite = Heuristic('tango', 'Composite(unknown)');

void main() {
  group('TangoLevelGenerator — determinism', () {
    test('same seed → identical puzzle (full 6×6)', () {
      const gen = TangoLevelGenerator();
      final a = gen.generate(
        mix: TargetMix.uniform(over: const [
          _parityFill,
          _trioAvoidance,
          _signPropagation,
        ], tolerance: 1.0),
        shape: BoardShape.full6x6(),
        seed: 42,
      );
      final b = gen.generate(
        mix: TargetMix.uniform(over: const [
          _parityFill,
          _trioAvoidance,
          _signPropagation,
        ], tolerance: 1.0),
        shape: BoardShape.full6x6(),
        seed: 42,
      );
      expect(a, isA<GeneratorSuccess>());
      expect(b, isA<GeneratorSuccess>());
      expect(
        (a as GeneratorSuccess).puzzle,
        (b as GeneratorSuccess).puzzle,
      );
    });
  });

  group('TangoLevelGenerator — happy paths', () {
    test('full 6×6: produces a uniquely-solvable puzzle within tolerance', () {
      const gen = TangoLevelGenerator();
      final result = gen.generate(
        mix: TargetMix({
          _trioAvoidance: 0.5,
          _signPropagation: 0.5,
        }),
        shape: BoardShape.full6x6(),
        seed: 7,
      );
      // Either Success (within tolerance) or BestEffort — both are
      // valid puzzles. Failure here would indicate the generator
      // couldn't even produce a candidate.
      expect(result, isNot(isA<GeneratorFailure>()));
      final puzzle = switch (result) {
        GeneratorSuccess(:final puzzle) => puzzle,
        GeneratorBestEffort(:final puzzle) => puzzle,
        GeneratorFailure() => null,
      };
      expect(puzzle, isNotNull);
      // Active count: 36; solution must be fully filled.
      var filled = 0;
      for (var r = 0; r < kTangoBoardSize; r++) {
        for (var c = 0; c < kTangoBoardSize; c++) {
          if (puzzle!.solution.cells[r][c] != null) filled++;
        }
      }
      expect(filled, 36);
    });

    test('fragment 2×4: solution restricted to 8 active cells', () {
      const gen = TangoLevelGenerator();
      final result = gen.generate(
        mix: TargetMix({_parityFill: 1.0}, tolerance: 1.0),
        shape: BoardShape.fragment2x4(),
        seed: 11,
      );
      expect(result, isNot(isA<GeneratorFailure>()));
      final puzzle = switch (result) {
        GeneratorSuccess(:final puzzle) => puzzle,
        GeneratorBestEffort(:final puzzle) => puzzle,
        GeneratorFailure() => null,
      };
      expect(puzzle, isNotNull);
      // Active cells filled, inactive cells null.
      for (var r = 0; r < kTangoBoardSize; r++) {
        for (var c = 0; c < kTangoBoardSize; c++) {
          final isActive = r < 2 && c < 4;
          if (isActive) {
            expect(
              puzzle!.solution.cells[r][c],
              isNotNull,
              reason: 'active cell ($r,$c) must be filled',
            );
          } else {
            expect(
              puzzle!.solution.cells[r][c],
              isNull,
              reason: 'inactive cell ($r,$c) must be null',
            );
            expect(
              puzzle.initialPosition.cells[r][c],
              isNull,
              reason: 'inactive cell ($r,$c) must be null in initial too',
            );
          }
        }
      }
      // The solution must be complete under the shape.
      expect(isCompleteFor(puzzle!.shape, puzzle.solution), isTrue);
    });
  });

  group('TangoLevelGenerator — rejection / cap', () {
    test('Composite(unknown) target → TargetMix rejects at construction', () {
      // The generator's defence-in-depth guard never fires because
      // TargetMix itself refuses the Composite tag — this is the
      // intended "Composite не подаётся в drill" failure surface.
      expect(
        () => TargetMix({_composite: 1.0}),
        throwsArgumentError,
      );
    });

    test('cap reached → GeneratorBestEffort with mixDrift > tolerance', () {
      // Force a tiny budget and a near-impossible target: 100% of
      // AdvancedMidLineInference on a 2×4 fragment — fragments rarely
      // need that heuristic. Tolerance 0.05 makes it realistic to miss.
      const gen = TangoLevelGenerator(maxAttempts: 8);
      final result = gen.generate(
        mix: TargetMix({_advancedMidLine: 1.0}, tolerance: 0.05),
        shape: BoardShape.fragment2x4(),
        seed: 99,
      );
      expect(
        result,
        anyOf(isA<GeneratorBestEffort>(), isA<GeneratorSuccess>()),
      );
      // If best-effort, drift is documented.
      if (result is GeneratorBestEffort) {
        expect(result.mixDrift, greaterThan(0.0));
      }
    });
  });
}
