import 'package:equatable/equatable.dart';

import '../../../puzzle/puzzle_kind.dart';
import 'tango_constraint.dart';
import 'tango_mark.dart';

/// Side length of every Tango board in the MVP.
const int kTangoBoardSize = 6;

/// Immutable snapshot of a Tango board: a [kTangoBoardSize] × [kTangoBoardSize]
/// grid of optional [TangoMark]s plus the puzzle's edge [TangoConstraint]s.
///
/// Mutation is by clone — see [withCell]. Equality is structural so the
/// solver can memoize on positions (R1).
class TangoPosition extends Position with EquatableMixin {
  /// Build a position from explicit cells and constraints.
  ///
  /// `cells` must be a 6×6 grid; the constructor copies it into an
  /// unmodifiable view so callers can't mutate the position after
  /// construction.
  TangoPosition({
    required List<List<TangoMark?>> cells,
    required List<TangoConstraint> constraints,
  })  : assert(
          cells.length == kTangoBoardSize,
          'Tango board must have $kTangoBoardSize rows, got ${cells.length}',
        ),
        cells = List.unmodifiable(
          cells.map((row) {
            assert(
              row.length == kTangoBoardSize,
              'Tango board rows must have $kTangoBoardSize cells, '
              'got ${row.length}',
            );
            return List<TangoMark?>.unmodifiable(row);
          }),
        ),
        constraints = List.unmodifiable(constraints);

  /// An empty 6×6 position with the given (optional) constraints.
  factory TangoPosition.empty({
    List<TangoConstraint> constraints = const [],
  }) {
    final emptyCells = List<List<TangoMark?>>.generate(
      kTangoBoardSize,
      (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
    );
    return TangoPosition(cells: emptyCells, constraints: constraints);
  }

  /// 6×6 grid of cells. `null` means empty.
  final List<List<TangoMark?>> cells;

  /// `=` and `×` edge signs that ship with the puzzle.
  final List<TangoConstraint> constraints;

  /// Returns a new position identical to this one except cell
  /// `(row, col)` is set to [mark] (which may be `null` to clear it).
  TangoPosition withCell(int row, int col, TangoMark? mark) {
    assert(row >= 0 && row < kTangoBoardSize, 'row out of range: $row');
    assert(col >= 0 && col < kTangoBoardSize, 'col out of range: $col');
    final newCells = List<List<TangoMark?>>.generate(
      kTangoBoardSize,
      (r) => List<TangoMark?>.from(cells[r]),
    );
    newCells[row][col] = mark;
    return TangoPosition(cells: newCells, constraints: constraints);
  }

  @override
  List<Object?> get props => [
        // Compare cells row-by-row using deep value semantics.
        for (final row in cells) ...row,
        ...constraints,
      ];
}
