import '../domain/tango_constraint.dart';
import '../domain/tango_mark.dart';
import '../domain/tango_position.dart';
import 'board_shape.dart';

/// Shape-aware variant of [isLegal] for the full 6×6 board and for
/// fragment masks.
///
/// The U4 rule-checker is built for the full 6×6 board: it scans every
/// row and column and applies count-balance everywhere. For fragment
/// shapes this is wrong — a 2×4 sub-grid has 4-cell rows with no
/// count-balance equivalent. So we instead:
///
/// * apply anti-triple on every line in [BoardShape.activeLines],
/// * apply count-balance only on lines in [BoardShape.fullLines]
///   (length 6, capped at 3 of either mark),
/// * apply edge constraints only when *both* endpoints are active.
///
/// Empty cells outside [BoardShape.activeCells] are ignored.
bool isLegalFor(BoardShape shape, TangoPosition position) =>
    isLegalForRaw(shape, position.cells, position.constraints);

/// Returns `true` iff every active cell is filled and the position is
/// legal under [shape].
bool isCompleteFor(BoardShape shape, TangoPosition position) =>
    isCompleteForRaw(shape, position.cells, position.constraints);

/// Mutable-board variant of [isLegalFor] for hot-path backtracking.
///
/// Treats [cells] as a raw mutable 6×6 grid (no copies, no
/// allocations) and applies [shape]-aware rules.
bool isLegalForRaw(
  BoardShape shape,
  List<List<TangoMark?>> cells,
  List<TangoConstraint> constraints,
) {
  for (final line in shape.activeLines) {
    final marks = [for (final a in line) cells[a.row][a.col]];
    if (!_antiTripleOk(marks)) return false;
  }
  for (final line in shape.fullLines) {
    final marks = [for (final a in line) cells[a.row][a.col]];
    if (!_countBalanceOk(marks)) return false;
  }
  final active = shape.activeCellSet;
  for (final c in constraints) {
    if (!active.contains(c.cellA) || !active.contains(c.cellB)) continue;
    final a = cells[c.cellA.row][c.cellA.col];
    final b = cells[c.cellB.row][c.cellB.col];
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

/// Mutable-board variant of [isCompleteFor].
bool isCompleteForRaw(
  BoardShape shape,
  List<List<TangoMark?>> cells,
  List<TangoConstraint> constraints,
) {
  for (final a in shape.activeCells) {
    if (cells[a.row][a.col] == null) return false;
  }
  return isLegalForRaw(shape, cells, constraints);
}

bool _antiTripleOk(List<TangoMark?> line) {
  for (var i = 0; i + 2 < line.length; i++) {
    final a = line[i];
    if (a == null) continue;
    if (a == line[i + 1] && a == line[i + 2]) return false;
  }
  return true;
}

bool _countBalanceOk(List<TangoMark?> line) {
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
