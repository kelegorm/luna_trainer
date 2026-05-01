import 'package:equatable/equatable.dart';

import '../domain/tango_constraint.dart';
import '../domain/tango_mark.dart';
import '../domain/tango_position.dart';

/// Which axis a [LineView] follows.
///
/// `row` means the line moves along increasing column indices, `column`
/// along increasing row indices.
enum LineAxis { row, column }

/// Read-only window onto a single row or column of a [TangoPosition].
///
/// Line heuristics scan a sequence of marks together with the edge
/// constraints that fall *inside* the line (i.e. between two cells on
/// the same line). Constraints that span two lines (e.g. a `=` between
/// `(0,0)` and `(1,0)` is *not* on row 0) are NOT exposed here — they
/// are handled by [PositionHeuristic] implementations such as
/// `SignPropagation` which read `position.constraints` directly.
class LineView extends Equatable {
  const LineView({
    required this.axis,
    required this.index,
    required this.cells,
    required this.constraints,
  }) : assert(cells.length == kTangoBoardSize, 'line must be 6 cells');

  /// The full position this line was sliced from. Set at construction
  /// when callers want context (e.g. to ask "what mark is at (r,c)?");
  /// not part of equality.
  factory LineView.fromPosition(
    TangoPosition position, {
    required LineAxis axis,
    required int index,
  }) {
    final cells = <TangoMark?>[];
    for (var i = 0; i < kTangoBoardSize; i++) {
      cells.add(_cellAt(position, axis, index, i));
    }
    final lineConstraints = <TangoConstraint>[];
    for (final c in position.constraints) {
      if (_constraintInLine(c, axis, index)) {
        lineConstraints.add(c);
      }
    }
    return LineView(
      axis: axis,
      index: index,
      cells: List<TangoMark?>.unmodifiable(cells),
      constraints: List<TangoConstraint>.unmodifiable(lineConstraints),
    );
  }

  final LineAxis axis;

  /// Row index when [axis] is row, column index otherwise.
  final int index;

  /// 6 cells along the line, in increasing index order.
  final List<TangoMark?> cells;

  /// Constraints where *both* endpoints lie on this line.
  final List<TangoConstraint> constraints;

  /// Returns the [CellAddress] of the [indexInLine]th cell along this
  /// line.
  CellAddress cellAddressAt(int indexInLine) {
    assert(
      indexInLine >= 0 && indexInLine < kTangoBoardSize,
      'indexInLine out of range: $indexInLine',
    );
    switch (axis) {
      case LineAxis.row:
        return CellAddress(index, indexInLine);
      case LineAxis.column:
        return CellAddress(indexInLine, index);
    }
  }

  /// Returns the in-line index of [cell] if it lies on this line, or
  /// `null` if it doesn't.
  int? indexOf(CellAddress cell) {
    switch (axis) {
      case LineAxis.row:
        return cell.row == index ? cell.col : null;
      case LineAxis.column:
        return cell.col == index ? cell.row : null;
    }
  }

  /// Returns the constraint between adjacent in-line indices [a] and
  /// [b], or `null` if no such constraint exists.
  TangoConstraint? constraintBetween(int a, int b) {
    final addrA = cellAddressAt(a);
    final addrB = cellAddressAt(b);
    for (final c in constraints) {
      if ((c.cellA == addrA && c.cellB == addrB) ||
          (c.cellA == addrB && c.cellB == addrA)) {
        return c;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [axis, index, cells, constraints];

  // --- internals ---

  static TangoMark? _cellAt(
    TangoPosition position,
    LineAxis axis,
    int index,
    int offset,
  ) {
    switch (axis) {
      case LineAxis.row:
        return position.cells[index][offset];
      case LineAxis.column:
        return position.cells[offset][index];
    }
  }

  static bool _constraintInLine(
    TangoConstraint c,
    LineAxis axis,
    int index,
  ) {
    switch (axis) {
      case LineAxis.row:
        return c.cellA.row == index && c.cellB.row == index;
      case LineAxis.column:
        return c.cellA.col == index && c.cellB.col == index;
    }
  }
}
