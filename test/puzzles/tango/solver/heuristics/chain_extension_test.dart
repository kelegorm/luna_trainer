import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/solver/heuristics/chain_extension.dart';
import 'package:luna_traineer/puzzles/tango/solver/tango_deduction.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';

void main() {
  const trio = Heuristic('tango', 'TrioAvoidance');
  const pair = Heuristic('tango', 'PairCompletion');
  const chain = Heuristic('tango', 'ChainExtension');

  group('ChainExtension', () {
    test('returns empty list unchanged on a single deduction', () {
      final ded = [
        const TangoDeduction(
          heuristic: trio,
          forcedCells: [CellAddress(0, 2)],
          forcedMark: TangoMark.moon,
        ),
      ];
      final tagged = const ChainExtension().tag(ded);
      expect(tagged.length, 1);
      expect(tagged.single.heuristic, trio);
    });

    test('tags second non-conflicting deduction with ChainExtension', () {
      final ded = [
        const TangoDeduction(
          heuristic: trio,
          forcedCells: [CellAddress(0, 2)],
          forcedMark: TangoMark.moon,
        ),
        const TangoDeduction(
          heuristic: pair,
          forcedCells: [CellAddress(1, 1)],
          forcedMark: TangoMark.sun,
        ),
      ];
      final tagged = const ChainExtension().tag(ded);
      expect(tagged.length, 2);
      expect(tagged[0].heuristic, trio);
      expect(tagged[1].heuristic, chain);
    });

    test('does NOT tag overlapping cells as ChainExtension', () {
      final ded = [
        const TangoDeduction(
          heuristic: trio,
          forcedCells: [CellAddress(0, 2)],
          forcedMark: TangoMark.moon,
        ),
        const TangoDeduction(
          heuristic: pair,
          forcedCells: [CellAddress(0, 2)],
          forcedMark: TangoMark.moon,
        ),
      ];
      final tagged = const ChainExtension().tag(ded);
      expect(tagged[1].heuristic, pair);
    });

    test('tags third deduction when independent of all previous', () {
      final ded = [
        const TangoDeduction(
          heuristic: trio,
          forcedCells: [CellAddress(0, 2)],
          forcedMark: TangoMark.moon,
        ),
        const TangoDeduction(
          heuristic: pair,
          forcedCells: [CellAddress(1, 1)],
          forcedMark: TangoMark.sun,
        ),
        const TangoDeduction(
          heuristic: pair,
          forcedCells: [CellAddress(3, 3)],
          forcedMark: TangoMark.moon,
        ),
      ];
      final tagged = const ChainExtension().tag(ded);
      expect(tagged[1].heuristic, chain);
      expect(tagged[2].heuristic, chain);
    });

    test('preserves forced cells and mark', () {
      final ded = [
        const TangoDeduction(
          heuristic: trio,
          forcedCells: [CellAddress(0, 0)],
          forcedMark: TangoMark.sun,
        ),
        const TangoDeduction(
          heuristic: pair,
          forcedCells: [CellAddress(2, 4)],
          forcedMark: TangoMark.moon,
        ),
      ];
      final tagged = const ChainExtension().tag(ded);
      expect(tagged[1].forcedCells, [const CellAddress(2, 4)]);
      expect(tagged[1].forcedMark, TangoMark.moon);
    });

    test('does not mutate the input list', () {
      final ded = [
        const TangoDeduction(
          heuristic: trio,
          forcedCells: [CellAddress(0, 0)],
          forcedMark: TangoMark.sun,
        ),
        const TangoDeduction(
          heuristic: pair,
          forcedCells: [CellAddress(2, 4)],
          forcedMark: TangoMark.moon,
        ),
      ];
      const ChainExtension().tag(ded);
      expect(ded[1].heuristic, pair);
    });
  });
}
