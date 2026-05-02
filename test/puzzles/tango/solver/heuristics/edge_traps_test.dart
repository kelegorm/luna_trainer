import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/solver/heuristics/advanced_mid_line.dart';
import 'package:luna_traineer/puzzles/tango/solver/line_view.dart';
import 'package:luna_traineer/puzzles/tango/solver/tango_deduction.dart';

import '../fixtures/positions.dart';

const Heuristic _edgeOneFive =
    Heuristic('tango', 'AdvancedMidLineInference/edge_1_5');
const Heuristic _edgeTwoSix =
    Heuristic('tango', 'AdvancedMidLineInference/edge_2_6');

Iterable<TangoDeduction> _runRow(int r, TangoPosition position) =>
    const AdvancedMidLineInference().apply(LineView.fromPosition(
      position,
      axis: LineAxis.row,
      index: r,
    ));

Iterable<TangoDeduction> _runCol(int c, TangoPosition position) =>
    const AdvancedMidLineInference().apply(LineView.fromPosition(
      position,
      axis: LineAxis.column,
      index: c,
    ));

void main() {
  group('AdvancedMidLineInference — edge_1_5 trap', () {
    test('row [S,_,_,_,S,_] forces opposite at index 5 with edge_1_5 tag', () {
      // S _ _ _ S _ : putting S at index 5 would force three M at
      // indices 1..3 (anti-triple). Index 5 must be M.
      final p = pos('S___S_' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p).toList();

      expect(ded, hasLength(1));
      expect(ded.single.heuristic, _edgeOneFive);
      expect(ded.single.forcedCells, [const CellAddress(0, 5)]);
      expect(ded.single.forcedMark, TangoMark.moon);
    });

    test('mark symmetry: row [M,_,_,_,M,_] forces sun at index 5', () {
      final p = pos('M___M_' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p).toList();

      expect(ded, hasLength(1));
      expect(ded.single.heuristic, _edgeOneFive);
      expect(ded.single.forcedMark, TangoMark.sun);
    });

    test('column variant fires with edge_1_5 tag', () {
      // Column 0: S _ _ _ S _ — forced moon at row 5.
      final p = pos(
        'S_____' '______' '______' '______' 'S_____' '______',
      );
      final ded = _runCol(0, p).toList();

      expect(ded, hasLength(1));
      expect(ded.single.heuristic, _edgeOneFive);
      expect(ded.single.forcedCells, [const CellAddress(5, 0)]);
      expect(ded.single.forcedMark, TangoMark.moon);
    });

    test('does not fire when filled cells differ in mark', () {
      // S _ _ _ M _ — pattern broken, no forced edge cell.
      final p = pos('S___M_' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p)
          .where((d) =>
              d.heuristic == _edgeOneFive || d.heuristic == _edgeTwoSix)
          .toList();
      expect(ded, isEmpty);
    });

    test('does not fire when extra middle cell is filled', () {
      // S _ M _ S _ — middle is filled, so the trap pattern does not hold.
      final p = pos('S_M_S_' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p)
          .where((d) =>
              d.heuristic == _edgeOneFive || d.heuristic == _edgeTwoSix)
          .toList();
      expect(ded, isEmpty);
    });
  });

  group('AdvancedMidLineInference — edge_2_6 trap', () {
    test('row [_,S,_,_,_,S] forces opposite at index 0 with edge_2_6 tag', () {
      final p = pos('_S___S' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p).toList();

      expect(ded, hasLength(1));
      expect(ded.single.heuristic, _edgeTwoSix);
      expect(ded.single.forcedCells, [const CellAddress(0, 0)]);
      expect(ded.single.forcedMark, TangoMark.moon);
    });

    test('mark symmetry: row [_,M,_,_,_,M] forces sun at index 0', () {
      final p = pos('_M___M' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p).toList();

      expect(ded, hasLength(1));
      expect(ded.single.heuristic, _edgeTwoSix);
      expect(ded.single.forcedMark, TangoMark.sun);
    });

    test('column variant fires with edge_2_6 tag', () {
      // Column 0: _ S _ _ _ S — forced moon at row 0.
      final p = pos(
        '______' 'S_____' '______' '______' '______' 'S_____',
      );
      final ded = _runCol(0, p).toList();

      expect(ded, hasLength(1));
      expect(ded.single.heuristic, _edgeTwoSix);
      expect(ded.single.forcedCells, [const CellAddress(0, 0)]);
      expect(ded.single.forcedMark, TangoMark.moon);
    });

    test('does not fire when filled cells differ in mark', () {
      // _ S _ _ _ M — pattern broken.
      final p = pos('_S___M' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p)
          .where((d) =>
              d.heuristic == _edgeOneFive || d.heuristic == _edgeTwoSix)
          .toList();
      expect(ded, isEmpty);
    });
  });

  group('AdvancedMidLineInference — base 2-empty case keeps base tag', () {
    test('2-empty unique completion still tagged AdvancedMidLineInference', () {
      // S S _ M _ M — same fixture as the existing advanced_mid_line_test.
      // Verifies edge-trap detection does not steal this case from the
      // base 2-empty enumeration path.
      final p = pos('SS_M_M' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p).toList();

      expect(ded, hasLength(2));
      for (final d in ded) {
        expect(
          d.heuristic,
          const Heuristic('tango', 'AdvancedMidLineInference'),
          reason: '2-empty enumeration path must keep the base tag',
        );
      }
    });
  });
}
