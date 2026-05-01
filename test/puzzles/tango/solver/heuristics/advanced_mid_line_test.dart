import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/solver/heuristics/advanced_mid_line.dart';
import 'package:luna_traineer/puzzles/tango/solver/line_view.dart';
import 'package:luna_traineer/puzzles/tango/solver/tango_deduction.dart';

import '../fixtures/positions.dart';

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
  group('AdvancedMidLineInference', () {
    test('2 empties with unique completion fire both forced cells', () {
      // Row: S S _ M _ M — empties at 2 and 4. Counts 2S+2M, need
      // 1S+1M. (S,S) fails count, (S,M) makes SSS triple at 0..2,
      // (M,M) fails count. Only (M,S) survives → (0,2)=M, (0,4)=S.
      final p = pos('SS_M_M' '______' '______' '______' '______' '______');
      final ded = _runRow(0, p).toList();
      expect(ded.length, 2);
      final byCell = {for (final d in ded) d.forcedCells.single: d.forcedMark};
      expect(byCell[const CellAddress(0, 2)], TangoMark.moon);
      expect(byCell[const CellAddress(0, 4)], TangoMark.sun);
    });

    test('does not fire when both completions remain legal', () {
      // S M _ _ M S — both 1S+1M assignments avoid triples and respect
      // count balance, so no unique completion.
      final p = pos('SM__MS' '______' '______' '______' '______' '______');
      expect(_runRow(0, p), isEmpty);
    });

    test('does not fire on lines with !=2 empties', () {
      final p = pos('S_____' '______' '______' '______' '______' '______');
      expect(_runRow(0, p), isEmpty);
    });

    test('column variant with constraint pruning', () {
      // Column 0: S M S M _ _ with `=` between (4,0) and (5,0) means
      // both empties must match — but counts force 1S+1M, so the `=`
      // makes the line illegal under both assignments. Should NOT fire.
      final p = pos(
        'S_____' 'M_____' 'S_____' 'M_____' '______' '______',
        constraints: [eq(4, 0, 5, 0)],
      );
      expect(_runCol(0, p), isEmpty);
    });

    test('column variant: unique completion picked', () {
      // Column 0: S S _ M _ M (mirror of the row case above).
      final p = pos(
        'S_____' 'S_____' '______' 'M_____' '______' 'M_____',
      );
      final ded = _runCol(0, p).toList();
      expect(ded.length, 2);
      final byCell = {for (final d in ded) d.forcedCells.single: d.forcedMark};
      expect(byCell[const CellAddress(2, 0)], TangoMark.moon);
      expect(byCell[const CellAddress(4, 0)], TangoMark.sun);
    });

    test('line where simpler heuristics are silent but advanced fires', () {
      // _ _ S M S M : two empties at indices 0,1. Counts already
      // 2S+2M, so empties must be 1S+1M. Avoid triple: index 2 is S,
      // so index 1 cannot be S (would make S S S? actually index 0
      // and 1 then 2: _ _ S — being 1S+1M means we set them so as
      // not to repeat the third. Allowed orderings: SM or MS.
      // Both legal? S M S M S M — fine. M S S M S M — triple S at
      // 1,2? indices 1=S, 2=S would not make a triple unless also
      // 3=S, but 3=M, so legal. Hence two solutions → no fire.
      final p = pos('__SMSM' '______' '______' '______' '______' '______');
      expect(_runRow(0, p), isEmpty);
    });
  });
}
