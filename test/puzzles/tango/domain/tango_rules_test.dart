import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_rules.dart';

const _s = TangoMark.sun;
const _m = TangoMark.moon;

/// A hand-crafted fully-solved 6×6 Tango board with no edge constraints.
/// Each row and column has 3 suns + 3 moons and no three-in-a-row.
final List<List<TangoMark?>> _solvedCells = [
  [_s, _s, _m, _s, _m, _m],
  [_m, _m, _s, _m, _s, _s],
  [_s, _m, _m, _s, _s, _m],
  [_m, _s, _s, _m, _m, _s],
  [_s, _m, _s, _m, _s, _m],
  [_m, _s, _m, _s, _m, _s],
];

TangoPosition _solved() => TangoPosition(
      cells: _solvedCells.map((r) => List<TangoMark?>.from(r)).toList(),
      constraints: const [],
    );

void main() {
  group('isLegal', () {
    test('empty position is legal', () {
      final p = TangoPosition.empty();
      expect(isLegal(p), isTrue);
    });

    test('a fully-solved board is legal', () {
      expect(isLegal(_solved()), isTrue);
    });

    test('three suns in a row violates anti-triple', () {
      var p = TangoPosition.empty();
      p = p.withCell(0, 0, TangoMark.sun);
      p = p.withCell(0, 1, TangoMark.sun);
      p = p.withCell(0, 2, TangoMark.sun);
      expect(isLegal(p), isFalse);
    });

    test('three moons in a column violates anti-triple', () {
      var p = TangoPosition.empty();
      p = p.withCell(2, 4, TangoMark.moon);
      p = p.withCell(3, 4, TangoMark.moon);
      p = p.withCell(4, 4, TangoMark.moon);
      expect(isLegal(p), isFalse);
    });

    test('4 suns / 2 moons in a row violates the count balance', () {
      // Row 0: S S M S M S — no triples, but 4 suns.
      var p = TangoPosition.empty();
      p = p.withCell(0, 0, TangoMark.sun);
      p = p.withCell(0, 1, TangoMark.sun);
      p = p.withCell(0, 2, TangoMark.moon);
      p = p.withCell(0, 3, TangoMark.sun);
      p = p.withCell(0, 4, TangoMark.moon);
      p = p.withCell(0, 5, TangoMark.sun);
      expect(isLegal(p), isFalse);
    });

    test('= constraint with different marks is illegal', () {
      const c = TangoConstraint(
        cellA: CellAddress(0, 0),
        cellB: CellAddress(0, 1),
        kind: ConstraintKind.equals,
      );
      var p = TangoPosition.empty(constraints: [c]);
      p = p.withCell(0, 0, TangoMark.sun);
      p = p.withCell(0, 1, TangoMark.moon);
      expect(isLegal(p), isFalse);
    });

    test('x constraint with same marks is illegal', () {
      const c = TangoConstraint(
        cellA: CellAddress(1, 1),
        cellB: CellAddress(1, 2),
        kind: ConstraintKind.opposite,
      );
      var p = TangoPosition.empty(constraints: [c]);
      p = p.withCell(1, 1, TangoMark.sun);
      p = p.withCell(1, 2, TangoMark.sun);
      expect(isLegal(p), isFalse);
    });

    test('= constraint with one cell empty is permissive', () {
      const c = TangoConstraint(
        cellA: CellAddress(0, 0),
        cellB: CellAddress(0, 1),
        kind: ConstraintKind.equals,
      );
      var p = TangoPosition.empty(constraints: [c]);
      p = p.withCell(0, 0, TangoMark.sun);
      expect(isLegal(p), isTrue);
    });
  });

  group('isComplete', () {
    test('empty position is not complete', () {
      expect(isComplete(TangoPosition.empty()), isFalse);
    });

    test('solved board is complete', () {
      expect(isComplete(_solved()), isTrue);
    });

    test('one empty cell -> not complete but still legal', () {
      final cells =
          _solvedCells.map((r) => List<TangoMark?>.from(r)).toList();
      cells[3][3] = null;
      final p = TangoPosition(cells: cells, constraints: const []);
      expect(isLegal(p), isTrue);
      expect(isComplete(p), isFalse);
    });

    test('full but illegal board is not complete', () {
      // Take a solved board and corrupt it so row 0 has 4 suns.
      final cells =
          _solvedCells.map((r) => List<TangoMark?>.from(r)).toList();
      cells[0][2] = TangoMark.sun; // was moon
      final p = TangoPosition(cells: cells, constraints: const []);
      expect(isComplete(p), isFalse);
    });
  });

  group('wouldViolate', () {
    test('a move that creates a triple is rejected', () {
      var p = TangoPosition.empty();
      p = p.withCell(0, 0, TangoMark.sun);
      p = p.withCell(0, 1, TangoMark.sun);
      const move = TangoMove(row: 0, col: 2, mark: TangoMark.sun);
      expect(wouldViolate(p, move), isTrue);
    });

    test('a legal move is accepted', () {
      final p = TangoPosition.empty();
      const move = TangoMove(row: 0, col: 0, mark: TangoMark.sun);
      expect(wouldViolate(p, move), isFalse);
    });

    test('a move that breaks an = constraint is rejected', () {
      const c = TangoConstraint(
        cellA: CellAddress(0, 0),
        cellB: CellAddress(0, 1),
        kind: ConstraintKind.equals,
      );
      var p = TangoPosition.empty(constraints: [c]);
      p = p.withCell(0, 0, TangoMark.sun);
      const move = TangoMove(row: 0, col: 1, mark: TangoMark.moon);
      expect(wouldViolate(p, move), isTrue);
    });
  });
}
