import 'package:equatable/equatable.dart';

/// Kind of edge sign joining two adjacent Tango cells.
///
/// `equals` (`=`) requires the two cells to hold the same mark.
/// `opposite` (`×`) requires them to hold different marks.
enum ConstraintKind { equals, opposite }

/// Coordinates of a single cell on the 6×6 Tango board.
///
/// Lives here (rather than in its own file) because constraints are the
/// primary place where a cell needs to be referenced by value; the rest
/// of the domain works with bare `(int row, int col)` indices into
/// [TangoPosition.cells].
class CellAddress extends Equatable {
  const CellAddress(this.row, this.col);

  final int row;
  final int col;

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => 'CellAddress($row, $col)';
}

/// A single `=` or `×` sign between two adjacent cells on the Tango
/// board. The puzzle definition ships with these baked in; the solver
/// and rule-checker treat them as immutable inputs.
class TangoConstraint extends Equatable {
  const TangoConstraint({
    required this.cellA,
    required this.cellB,
    required this.kind,
  });

  final CellAddress cellA;
  final CellAddress cellB;
  final ConstraintKind kind;

  @override
  List<Object?> get props => [cellA, cellB, kind];

  @override
  String toString() => 'TangoConstraint($cellA, $cellB, $kind)';
}
