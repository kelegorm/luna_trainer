import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/solver/heuristics/parity_fill.dart';
import 'package:luna_traineer/puzzles/tango/solver/line_view.dart';
import 'package:luna_traineer/puzzles/tango/solver/tango_deduction.dart';

import '../fixtures/positions.dart';

Iterable<TangoDeduction> _runRow(int r, TangoPosition position) =>
    const ParityFill().apply(LineView.fromPosition(
      position,
      axis: LineAxis.row,
      index: r,
    ));

Iterable<TangoDeduction> _runCol(int c, TangoPosition position) =>
    const ParityFill().apply(LineView.fromPosition(
      position,
      axis: LineAxis.column,
      index: c,
    ));

void main() {
  group('ParityFill', () {
    test('three suns force the remaining empties to moon', () {
      // Row: S S _ S _ _ — three suns already, three empties → moons.
      final p = pos('SS_S__' '______' '______' '______' '______' '______');
      final d = _runRow(0, p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells, {
        const CellAddress(0, 2),
        const CellAddress(0, 4),
        const CellAddress(0, 5),
      });
    });

    test('three moons force the remaining empties to sun', () {
      final p = pos('M_M_M_' '______' '______' '______' '______' '______');
      final d = _runRow(0, p).single;
      expect(d.forcedMark, TangoMark.sun);
      expect(d.forcedCells.toSet(), {
        const CellAddress(0, 1),
        const CellAddress(0, 3),
        const CellAddress(0, 5),
      });
    });

    test('three suns + two moons leaves one cell forced to moon', () {
      // S S S M M _
      final p = pos('SSSMM_' '______' '______' '______' '______' '______');
      final d = _runRow(0, p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells, [const CellAddress(0, 5)]);
    });

    test('column variant', () {
      // Column 0: S S _ S _ _ — three suns, three empties. ParityFill
      // forces moons at (2,0), (4,0), (5,0).
      final p = pos('S_____' 'S_____' '______' 'S_____' '______' '______');
      final d = _runCol(0, p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells.toSet(), {
        const CellAddress(2, 0),
        const CellAddress(4, 0),
        const CellAddress(5, 0),
      });
    });

    test('does not fire when neither mark hits the half quota', () {
      final p = pos('S_M_S_' '______' '______' '______' '______' '______');
      expect(_runRow(0, p), isEmpty);
    });

    test('does not fire on a fully-filled line', () {
      final p = pos('SSMSMM' '______' '______' '______' '______' '______');
      expect(_runRow(0, p), isEmpty);
    });
  });
}
