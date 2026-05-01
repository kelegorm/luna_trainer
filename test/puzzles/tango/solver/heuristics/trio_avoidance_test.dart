import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/solver/heuristics/trio_avoidance.dart';
import 'package:luna_traineer/puzzles/tango/solver/line_view.dart';
import 'package:luna_traineer/puzzles/tango/solver/tango_deduction.dart';

import '../fixtures/positions.dart';

Iterable<TangoDeduction> _runRow(int r, TangoPosition position) =>
    const TrioAvoidance().apply(LineView.fromPosition(
      position,
      axis: LineAxis.row,
      index: r,
    ));

Iterable<TangoDeduction> _runCol(int c, TangoPosition position) =>
    const TrioAvoidance().apply(LineView.fromPosition(
      position,
      axis: LineAxis.column,
      index: c,
    ));

void main() {
  group('TrioAvoidance', () {
    test('two suns then empty forces moon to the right', () {
      final p = pos('SS____' '______' '______' '______' '______' '______');
      final d = _runRow(0, p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells, [const CellAddress(0, 2)]);
    });

    test('two moons then empty forces sun to the right', () {
      final p = pos('MM____' '______' '______' '______' '______' '______');
      final d = _runRow(0, p).single;
      expect(d.forcedMark, TangoMark.sun);
      expect(d.forcedCells, [const CellAddress(0, 2)]);
    });

    test('empty then two moons forces sun on both sides', () {
      // _ M M _ _ _ — pair at 1,2 forces sun at 0 (left) and 3 (right).
      final p = pos('______' '_MM___' '______' '______' '______' '______');
      final ded = _runRow(1, p).toList();
      expect(ded.length, 2);
      final cells = {for (final d in ded) d.forcedCells.single};
      expect(cells, {const CellAddress(1, 0), const CellAddress(1, 3)});
      for (final d in ded) {
        expect(d.forcedMark, TangoMark.sun);
      }
    });

    test('two suns mid-line forces moon on both sides', () {
      // _ S S _ _ _ — moons forced at indices 0 and 3.
      final p = pos('_SS___' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p).toList();
      expect(ded.length, 2);
      final cells = {for (final d in ded) d.forcedCells.single};
      expect(cells, {const CellAddress(0, 0), const CellAddress(0, 3)});
      for (final d in ded) {
        expect(d.forcedMark, TangoMark.moon);
      }
    });

    test('column variant fires too', () {
      final p = pos('S_____' 'S_____' '______' '______' '______' '______');
      final d = _runCol(0, p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells, [const CellAddress(2, 0)]);
    });

    test('does not fire on gap-sandwich (S _ S)', () {
      final p = pos('S_S___' '______' '______' '______' '______' '______');
      expect(_runRow(0, p), isEmpty);
    });

    test('does not fire when adjacent neighbour is already filled', () {
      // S S M  — third cell already filled; no deduction (and no
      // illegal triple).
      final p = pos('SSM___' '______' '______' '______' '______' '______');
      expect(_runRow(0, p), isEmpty);
    });
  });
}
