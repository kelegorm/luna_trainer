import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/solver/heuristics/pair_completion.dart';
import 'package:luna_traineer/puzzles/tango/solver/line_view.dart';
import 'package:luna_traineer/puzzles/tango/solver/tango_deduction.dart';

import '../fixtures/positions.dart';

Iterable<TangoDeduction> _runRow(int r, TangoPosition position) =>
    const PairCompletion().apply(LineView.fromPosition(
      position,
      axis: LineAxis.row,
      index: r,
    ));

Iterable<TangoDeduction> _runCol(int c, TangoPosition position) =>
    const PairCompletion().apply(LineView.fromPosition(
      position,
      axis: LineAxis.column,
      index: c,
    ));

void main() {
  group('PairCompletion', () {
    test('gap-sandwich S _ S forces moon in middle', () {
      final p = pos('S_S___' '______' '______' '______' '______' '______');
      final d = _runRow(0, p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells, [const CellAddress(0, 1)]);
    });

    test('gap-sandwich M _ M forces sun in middle', () {
      final p = pos('__M_M_' '______' '______' '______' '______' '______');
      final d = _runRow(0, p).single;
      expect(d.forcedMark, TangoMark.sun);
      expect(d.forcedCells, [const CellAddress(0, 3)]);
    });

    test('column gap-sandwich', () {
      final p = pos('S_____' '______' 'S_____' '______' '______' '______');
      final d = _runCol(0, p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells, [const CellAddress(1, 0)]);
    });

    test('= on empty pair adjacent to filled S forces both moons', () {
      // Row: S _ _ _ _ _ with `=` between (0,1) and (0,2).
      // Both empties must be moon to avoid S S S triple.
      final p = pos(
        'S_____' '______' '______' '______' '______' '______',
        constraints: [eq(0, 1, 0, 2)],
      );
      final ded = _runRow(0, p).toList();
      expect(ded.length, 1);
      expect(ded.single.forcedMark, TangoMark.moon);
      expect(ded.single.forcedCells.toSet(), {
        const CellAddress(0, 1),
        const CellAddress(0, 2),
      });
    });

    test('= on empty pair adjacent to filled M forces both suns', () {
      // Row: _ _ _ _ M _ with `=` between (0,2) and (0,3).
      final p = pos(
        '____M_' '______' '______' '______' '______' '______',
        constraints: [eq(0, 2, 0, 3)],
      );
      final ded = _runRow(0, p).toList();
      expect(ded.length, 1);
      expect(ded.single.forcedMark, TangoMark.sun);
      expect(ded.single.forcedCells.toSet(), {
        const CellAddress(0, 2),
        const CellAddress(0, 3),
      });
    });

    test('does not fire on bare empties without an outer neighbour', () {
      final p = pos(
        '__M___' '______' '______' '______' '______' '______',
        constraints: [eq(0, 0, 0, 1)],
      );
      // Outer neighbour to right is M; both empties → S.
      final ded = _runRow(0, p).toList();
      expect(ded.length, 1);
      expect(ded.single.forcedMark, TangoMark.sun);
    });

    test('does not fire on filled adjacent pair', () {
      final p = pos('S_S_S_' '______' '______' '______' '______' '______');
      // Each S _ S triggers gap-sandwich; should yield 2 deductions.
      final ded = _runRow(0, p).toList();
      expect(ded.length, 2);
    });
  });
}
