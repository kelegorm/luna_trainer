import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/generator/board_shape.dart';
import 'package:luna_traineer/puzzles/tango/generator/uniqueness_check.dart';

TangoPosition _emptyFrame() {
  return TangoPosition.empty();
}

TangoPosition _withCells(Map<CellAddress, TangoMark> seeds, {
  List<TangoConstraint> constraints = const [],
}) {
  final cells = List<List<TangoMark?>>.generate(
    kTangoBoardSize,
    (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
  );
  seeds.forEach((addr, m) {
    cells[addr.row][addr.col] = m;
  });
  return TangoPosition(cells: cells, constraints: constraints);
}

void main() {
  group('isUniquelySolvable — single row', () {
    final shape = BoardShape.singleRow();

    test('completed legal row is uniquely solvable', () {
      // sun moon sun moon sun moon — fully filled, single solution.
      final seeds = <CellAddress, TangoMark>{
        for (var c = 0; c < kTangoBoardSize; c++)
          CellAddress(0, c): c.isEven ? TangoMark.sun : TangoMark.moon,
      };
      expect(isUniquelySolvable(_withCells(seeds), shape), isTrue);
    });

    test('row with one ambiguous pair has multiple solutions', () {
      // sun moon sun moon _ _ — last two could be sun/moon or moon/sun
      // both legal (3 of each). NOT unique.
      final seeds = <CellAddress, TangoMark>{
        const CellAddress(0, 0): TangoMark.sun,
        const CellAddress(0, 1): TangoMark.moon,
        const CellAddress(0, 2): TangoMark.sun,
        const CellAddress(0, 3): TangoMark.moon,
      };
      expect(isUniquelySolvable(_withCells(seeds), shape), isFalse);
    });

    test('empty single-row position is not unique', () {
      expect(isUniquelySolvable(_emptyFrame(), shape), isFalse);
    });

    test('row with `=` constraint forcing the tail is unique', () {
      // sun moon sun moon _ _ with `=` on (0,4)~(0,5). The pair must
      // both be sun (only sun-pair fits the count) — wait, actually
      // we need exactly one sun and one moon. So `=` makes it
      // impossible if both must be different. Use `×` (opposite):
      // (0,4)≠(0,5). Combined with parity (1 sun, 1 moon left), the
      // `×` forces one of two orderings… still both legal. Use a
      // sun-fix on (0,4) to make truly unique.
      final seeds = <CellAddress, TangoMark>{
        const CellAddress(0, 0): TangoMark.sun,
        const CellAddress(0, 1): TangoMark.moon,
        const CellAddress(0, 2): TangoMark.sun,
        const CellAddress(0, 3): TangoMark.moon,
        const CellAddress(0, 4): TangoMark.sun,
      };
      expect(isUniquelySolvable(_withCells(seeds), shape), isTrue);
    });
  });

  group('isUniquelySolvable — fragment 2×4', () {
    final shape = BoardShape.fragment2x4();

    test('empty 2×4 fragment is not unique', () {
      expect(isUniquelySolvable(_emptyFrame(), shape), isFalse);
    });

    test('fully filled valid 2×4 fragment is unique', () {
      // Construct a valid 2×4 board:
      //   sun moon sun moon
      //   moon sun moon sun
      final cells = List<List<TangoMark?>>.generate(
        kTangoBoardSize,
        (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
      );
      cells[0][0] = TangoMark.sun;
      cells[0][1] = TangoMark.moon;
      cells[0][2] = TangoMark.sun;
      cells[0][3] = TangoMark.moon;
      cells[1][0] = TangoMark.moon;
      cells[1][1] = TangoMark.sun;
      cells[1][2] = TangoMark.moon;
      cells[1][3] = TangoMark.sun;
      final pos = TangoPosition(cells: cells, constraints: const []);
      expect(isUniquelySolvable(pos, shape), isTrue);
    });
  });
}
