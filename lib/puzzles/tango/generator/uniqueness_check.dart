import '../domain/tango_constraint.dart';
import '../domain/tango_mark.dart';
import '../domain/tango_position.dart';
import 'board_shape.dart';
import 'shape_rules.dart';

/// Returns `true` iff [seed] has *exactly one* completion under [shape].
///
/// Implementation: ordinary backtracking search over [shape.activeCells]
/// (in stable order). The search aborts as soon as it finds a second
/// solution, so worst-case work is bounded by the size of the active
/// region — fine for both fragments and the full 6×6 board.
bool isUniquelySolvable(TangoPosition seed, BoardShape shape) {
  return _countSolutions(seed, shape, cap: 2) == 1;
}

/// Optimised variant for the generator's carving loop: caller already
/// knows [seed] has *at least one* completion (the pre-carved board),
/// so we only need to verify "no other solution exists". Returns
/// `true` iff zero solutions other than the implicit known one are
/// found — i.e. the puzzle is uniquely solvable.
///
/// The search order pins [knownSolution]'s mark *last* at each empty
/// active cell, so the first branch is always the *alternative* path.
/// If any complete legal alternative exists we abort early.
bool hasAlternativeSolution(
  TangoPosition seed,
  BoardShape shape,
  TangoPosition knownSolution,
) {
  final cells = <List<TangoMark?>>[
    for (var r = 0; r < kTangoBoardSize; r++)
      List<TangoMark?>.from(seed.cells[r]),
  ];
  return _findAlt(
    cells: cells,
    constraints: seed.constraints,
    shape: shape,
    order: shape.activeCells,
    cursor: 0,
    knownSolution: knownSolution,
    sawDifference: false,
  );
}

bool _findAlt({
  required List<List<TangoMark?>> cells,
  required List<TangoConstraint> constraints,
  required BoardShape shape,
  required List<CellAddress> order,
  required int cursor,
  required TangoPosition knownSolution,
  required bool sawDifference,
}) {
  while (cursor < order.length) {
    final a = order[cursor];
    if (cells[a.row][a.col] == null) break;
    cursor++;
  }
  if (cursor == order.length) {
    if (!sawDifference) return false;
    return isCompleteForRaw(shape, cells, constraints);
  }
  final addr = order[cursor];
  final known = knownSolution.cells[addr.row][addr.col];
  // Try the *other* mark first so an alternative is found early.
  final other = known == TangoMark.sun ? TangoMark.moon : TangoMark.sun;
  for (final m in [other, known]) {
    cells[addr.row][addr.col] = m;
    if (isLegalForRaw(shape, cells, constraints)) {
      final found = _findAlt(
        cells: cells,
        constraints: constraints,
        shape: shape,
        order: order,
        cursor: cursor + 1,
        knownSolution: knownSolution,
        sawDifference: sawDifference || m != known,
      );
      if (found) {
        cells[addr.row][addr.col] = null;
        return true;
      }
    }
    cells[addr.row][addr.col] = null;
  }
  return false;
}

/// Counts solutions up to [cap]; returns the actual count when ≤ cap,
/// otherwise returns [cap] (no point continuing past the cap).
int countSolutionsUpTo(TangoPosition seed, BoardShape shape, {int cap = 2}) {
  return _countSolutions(seed, shape, cap: cap);
}

/// Returns *one* completion of [seed] under [shape], or `null` if the
/// position has no solution. Used by the generator to seed a solved
/// board it then carves clues out of.
TangoPosition? findAnySolution(TangoPosition seed, BoardShape shape) {
  // Mutable buffer so backtracking is allocation-free.
  final cells = <List<TangoMark?>>[
    for (var r = 0; r < kTangoBoardSize; r++)
      List<TangoMark?>.from(seed.cells[r]),
  ];
  final order = shape.activeCells;
  final found = _backtrack(
    cells: cells,
    constraints: seed.constraints,
    shape: shape,
    order: order,
    cursor: 0,
    cap: 1,
    counter: _Counter(),
    captureFirst: true,
  );
  if (found == null) return null;
  return found;
}

int _countSolutions(TangoPosition seed, BoardShape shape, {required int cap}) {
  final cells = <List<TangoMark?>>[
    for (var r = 0; r < kTangoBoardSize; r++)
      List<TangoMark?>.from(seed.cells[r]),
  ];
  final counter = _Counter();
  _backtrack(
    cells: cells,
    constraints: seed.constraints,
    shape: shape,
    order: shape.activeCells,
    cursor: 0,
    cap: cap,
    counter: counter,
    captureFirst: false,
  );
  return counter.count > cap ? cap : counter.count;
}

class _Counter {
  int count = 0;
}

/// Backtracking core. Returns the first completed [TangoPosition] when
/// `captureFirst` is true; otherwise returns `null` and only updates
/// [counter]. Stops as soon as `counter.count >= cap`.
TangoPosition? _backtrack({
  required List<List<TangoMark?>> cells,
  required List<TangoConstraint> constraints,
  required BoardShape shape,
  required List<CellAddress> order,
  required int cursor,
  required int cap,
  required _Counter counter,
  required bool captureFirst,
}) {
  if (counter.count >= cap) return null;

  // Skip to the next active cell that is still empty — pre-filled
  // active cells (seed clues) are fixed.
  while (cursor < order.length) {
    final a = order[cursor];
    if (cells[a.row][a.col] == null) break;
    cursor++;
  }
  if (cursor == order.length) {
    if (isCompleteForRaw(shape, cells, constraints)) {
      counter.count++;
      if (captureFirst) {
        return TangoPosition(cells: cells, constraints: constraints);
      }
    }
    return null;
  }

  final addr = order[cursor];
  for (final m in const [TangoMark.sun, TangoMark.moon]) {
    cells[addr.row][addr.col] = m;
    if (isLegalForRaw(shape, cells, constraints)) {
      final found = _backtrack(
        cells: cells,
        constraints: constraints,
        shape: shape,
        order: order,
        cursor: cursor + 1,
        cap: cap,
        counter: counter,
        captureFirst: captureFirst,
      );
      if (found != null) {
        cells[addr.row][addr.col] = null;
        return found;
      }
      if (counter.count >= cap) {
        cells[addr.row][addr.col] = null;
        return null;
      }
    }
    cells[addr.row][addr.col] = null;
  }
  return null;
}
