import '../../../../engine/domain/heuristic.dart';
import '../../domain/tango_constraint.dart';
import '../../domain/tango_mark.dart';
import '../../domain/tango_position.dart';
import '../line_view.dart';
import '../tango_deduction.dart';

/// Line-level backtracking fallback.
///
/// For each line with at most [_maxEmpties] empty cells, enumerate
/// every sun/moon assignment of the empties and keep the legal ones.
/// If any in-line cell takes the same mark in *every* legal completion,
/// that cell is forced — emit a `Composite(unknown)` deduction.
///
/// We cap the empty count to keep the worst case at 2^[_maxEmpties]
/// trials per line (16) so the solver stays well under 5 ms on a 6×6
/// board even when called on every line.
class CompositeFallback {
  const CompositeFallback();

  static const Heuristic _tag = Heuristic('tango', 'Composite(unknown)');

  /// Cap the search; a line with more than this many empties is too
  /// shallow for a useful unique-completion result anyway.
  static const int _maxEmpties = 4;

  Iterable<TangoDeduction> apply(TangoPosition position) sync* {
    for (var i = 0; i < kTangoBoardSize; i++) {
      yield* _scanLine(LineView.fromPosition(
        position,
        axis: LineAxis.row,
        index: i,
      ));
      yield* _scanLine(LineView.fromPosition(
        position,
        axis: LineAxis.column,
        index: i,
      ));
    }
  }

  Iterable<TangoDeduction> _scanLine(LineView view) sync* {
    final empties = <int>[];
    for (var i = 0; i < view.cells.length; i++) {
      if (view.cells[i] == null) empties.add(i);
    }
    if (empties.isEmpty || empties.length > _maxEmpties) return;

    final survivors = <List<TangoMark>>[];
    final total = 1 << empties.length;
    for (var mask = 0; mask < total; mask++) {
      final candidate = List<TangoMark?>.from(view.cells);
      final assignment = <TangoMark>[];
      for (var k = 0; k < empties.length; k++) {
        final m =
            ((mask >> k) & 1) == 0 ? TangoMark.sun : TangoMark.moon;
        candidate[empties[k]] = m;
        assignment.add(m);
      }
      if (_lineLegal(candidate, view)) {
        survivors.add(assignment);
      }
    }

    if (survivors.isEmpty) return;

    // For each empty index, see if the surviving completions agree on
    // the mark. Group forced cells by mark.
    final forcedSun = <int>[];
    final forcedMoon = <int>[];
    for (var k = 0; k < empties.length; k++) {
      final first = survivors.first[k];
      var agrees = true;
      for (final s in survivors) {
        if (s[k] != first) {
          agrees = false;
          break;
        }
      }
      if (!agrees) continue;
      if (first == TangoMark.sun) {
        forcedSun.add(empties[k]);
      } else {
        forcedMoon.add(empties[k]);
      }
    }

    if (forcedSun.isNotEmpty) {
      yield TangoDeduction(
        heuristic: _tag,
        forcedCells: [for (final i in forcedSun) view.cellAddressAt(i)],
        forcedMark: TangoMark.sun,
      );
    }
    if (forcedMoon.isNotEmpty) {
      yield TangoDeduction(
        heuristic: _tag,
        forcedCells: [for (final i in forcedMoon) view.cellAddressAt(i)],
        forcedMark: TangoMark.moon,
      );
    }
  }
}

bool _lineLegal(List<TangoMark?> line, LineView view) {
  var suns = 0;
  var moons = 0;
  for (var i = 0; i < line.length; i++) {
    final m = line[i];
    if (m == TangoMark.sun) suns++;
    if (m == TangoMark.moon) moons++;
    if (i + 2 < line.length) {
      final a = line[i];
      final b = line[i + 1];
      final c = line[i + 2];
      if (a != null && a == b && b == c) return false;
    }
  }
  const half = kTangoBoardSize ~/ 2;
  if (suns > half || moons > half) return false;
  for (final c in view.constraints) {
    final ai = view.indexOf(c.cellA);
    final bi = view.indexOf(c.cellB);
    if (ai == null || bi == null) continue;
    final a = line[ai];
    final b = line[bi];
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
