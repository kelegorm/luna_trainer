import 'package:equatable/equatable.dart';

import '../../../puzzle/puzzle_kind.dart';
import 'tango_constraint.dart';
import 'tango_mark.dart';
import 'tango_position.dart';

/// A single placement on the Tango board. Lives here (rather than in a
/// dedicated file) because the rule-checker is the only consumer in U4;
/// future modules import it from this file.
///
/// [mark] is nullable to encode the input-handler's empty step in the
/// `empty → sun → moon → empty` cycle (U10): tapping a moon clears the
/// cell, which is a legal "move" from the board widget's perspective.
class TangoMove extends Move with EquatableMixin {
  const TangoMove({
    required this.row,
    required this.col,
    required this.mark,
  });

  final int row;
  final int col;
  final TangoMark? mark;

  @override
  List<Object?> get props => [row, col, mark];

  @override
  String toString() => 'TangoMove($row, $col, $mark)';
}

/// Returns `true` iff [position] currently violates none of the four
/// Tango rules. Empty cells are permissive — a partially filled board
/// is legal as long as the marks already placed are consistent.
bool isLegal(TangoPosition position) {
  // Rules 1 and 2: anti-triple and count balance, per row and per column.
  for (var i = 0; i < kTangoBoardSize; i++) {
    if (!lineLegal(_row(position, i))) return false;
    if (!lineLegal(_col(position, i))) return false;
  }

  // Rules 3 and 4: edge constraints.
  for (final c in position.constraints) {
    final a = position.cells[c.cellA.row][c.cellA.col];
    final b = position.cells[c.cellB.row][c.cellB.col];
    if (a == null || b == null) continue;
    switch (c.kind) {
      case ConstraintKind.equals:
        if (a != b) return false;
      case ConstraintKind.opposite:
        if (a == b) return false;
    }
  }

  return true;
}

/// Returns `true` iff every cell is filled and the position is legal.
bool isComplete(TangoPosition position) {
  for (var r = 0; r < kTangoBoardSize; r++) {
    for (var c = 0; c < kTangoBoardSize; c++) {
      if (position.cells[r][c] == null) return false;
    }
  }
  return isLegal(position);
}

/// Returns `true` iff applying [move] to [position] produces a position
/// that fails [isLegal]. Used by the input-handler to refuse obviously
/// bad placements (R1).
bool wouldViolate(TangoPosition position, TangoMove move) {
  final next = position.withCell(move.row, move.col, move.mark);
  return !isLegal(next);
}

/// Returns `true` iff [line] currently violates neither anti-triple
/// (no three identical non-null marks consecutively) nor count balance
/// (at most 3 of either mark across a full 6-cell line).
///
/// Intended for full-length lines. Fragment shapes apply anti-triple
/// without count-balance and use [shape_rules] helpers instead.
bool lineLegal(List<TangoMark?> line) {
  for (var i = 0; i + 2 < line.length; i++) {
    final a = line[i];
    if (a == null) continue;
    if (a == line[i + 1] && a == line[i + 2]) return false;
  }
  var suns = 0;
  var moons = 0;
  for (final m in line) {
    if (m == TangoMark.sun) suns++;
    if (m == TangoMark.moon) moons++;
  }
  const half = kTangoBoardSize ~/ 2;
  if (suns > half || moons > half) return false;
  return true;
}

// --- internals ---

List<TangoMark?> _row(TangoPosition p, int r) => p.cells[r];

List<TangoMark?> _col(TangoPosition p, int c) =>
    [for (var r = 0; r < kTangoBoardSize; r++) p.cells[r][c]];
