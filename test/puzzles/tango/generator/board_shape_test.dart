import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/generator/board_shape.dart';
import 'package:luna_traineer/puzzles/tango/generator/shape_rules.dart';

void main() {
  group('BoardShape active-cell counts', () {
    test('full 6×6 has 36 active cells', () {
      expect(BoardShape.full6x6().activeCells.length, 36);
    });
    test('fragment 2×4 has 8 active cells', () {
      expect(BoardShape.fragment2x4().activeCells.length, 8);
    });
    test('fragment 3×3 has 9 active cells', () {
      expect(BoardShape.fragment3x3().activeCells.length, 9);
    });
    test('single row has 6 active cells', () {
      expect(BoardShape.singleRow().activeCells.length, 6);
    });
    test('single column has 6 active cells', () {
      expect(BoardShape.singleCol().activeCells.length, 6);
    });

    test('full 6×6 reports 12 full lines (6 rows + 6 cols)', () {
      expect(BoardShape.full6x6().fullLines.length, 12);
    });

    test('fragment 2×4 reports no full lines (no count balance)', () {
      expect(BoardShape.fragment2x4().fullLines, isEmpty);
    });
  });

  group('isLegalFor', () {
    test('anti-triple violation inside active line is rejected (2×4)', () {
      final shape = BoardShape.fragment2x4();
      final cells = List<List<TangoMark?>>.generate(
        kTangoBoardSize,
        (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
      );
      // Three suns in a row inside the active 2×4 area.
      cells[0][0] = TangoMark.sun;
      cells[0][1] = TangoMark.sun;
      cells[0][2] = TangoMark.sun;
      final pos = TangoPosition(cells: cells, constraints: const []);
      expect(isLegalFor(shape, pos), isFalse);
    });

    test('anti-triple in inactive area is ignored (2×4)', () {
      final shape = BoardShape.fragment2x4();
      final cells = List<List<TangoMark?>>.generate(
        kTangoBoardSize,
        (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
      );
      // Three suns in row 5 (outside active fragment) — illegal on
      // full board, fine here.
      cells[5][0] = TangoMark.sun;
      cells[5][1] = TangoMark.sun;
      cells[5][2] = TangoMark.sun;
      final pos = TangoPosition(cells: cells, constraints: const []);
      expect(isLegalFor(shape, pos), isTrue);
    });

    test('count balance fires only on full lines (single row, 4 suns)', () {
      final shape = BoardShape.singleRow();
      final cells = List<List<TangoMark?>>.generate(
        kTangoBoardSize,
        (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
      );
      // Row 0: 4 suns + 2 moons (no triples). Should be illegal.
      cells[0][0] = TangoMark.sun;
      cells[0][1] = TangoMark.sun;
      cells[0][2] = TangoMark.moon;
      cells[0][3] = TangoMark.sun;
      cells[0][4] = TangoMark.moon;
      cells[0][5] = TangoMark.sun;
      final pos = TangoPosition(cells: cells, constraints: const []);
      expect(isLegalFor(shape, pos), isFalse);
    });

    test('constraints crossing active/inactive boundary are skipped', () {
      final shape = BoardShape.fragment2x4();
      final cells = List<List<TangoMark?>>.generate(
        kTangoBoardSize,
        (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
      );
      cells[0][0] = TangoMark.sun;
      // (5,5) is inactive; constraint cellA active, cellB inactive.
      final pos = TangoPosition(
        cells: cells,
        constraints: const [
          TangoConstraint(
            cellA: CellAddress(0, 0),
            cellB: CellAddress(5, 5),
            kind: ConstraintKind.opposite,
          ),
        ],
      );
      // Even though (5,5) is null, the rule must skip this constraint
      // (boundary-crossing) and return legal.
      expect(isLegalFor(shape, pos), isTrue);
    });
  });
}
