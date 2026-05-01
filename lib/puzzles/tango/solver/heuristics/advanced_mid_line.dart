import '../../../../engine/domain/heuristic.dart';
import '../../domain/tango_constraint.dart';
import '../../domain/tango_mark.dart';
import '../../domain/tango_rules.dart';
import '../line_view.dart';
import '../tango_deduction.dart';
import 'heuristic_base.dart';

/// Multi-cell line composition.
///
/// For any line with exactly two empty cells, enumerate the four
/// (sun, moon) assignments and keep only those that yield a legal
/// line — i.e. no anti-triple, no count imbalance, and no in-line
/// `=`/`×` constraint violations. If exactly one assignment survives,
/// emit one deduction per mark for the cells it pins.
///
/// This catches positions where simpler heuristics see no forced cell
/// individually, but the joint constraints of a 4-filled / 2-empty
/// line force the two empties uniquely.
class AdvancedMidLineInference extends LineHeuristic {
  const AdvancedMidLineInference();

  static const Heuristic _tag =
      Heuristic('tango', 'AdvancedMidLineInference');

  @override
  Iterable<TangoDeduction> apply(LineView view) sync* {
    final empties = <int>[];
    for (var i = 0; i < view.cells.length; i++) {
      if (view.cells[i] == null) empties.add(i);
    }
    if (empties.length != 2) return;

    const marks = TangoMark.values;
    final survivors = <List<TangoMark>>[];
    for (final m0 in marks) {
      for (final m1 in marks) {
        final candidate = List<TangoMark?>.from(view.cells);
        candidate[empties[0]] = m0;
        candidate[empties[1]] = m1;
        if (_lineLegal(candidate, view.constraints, view)) {
          survivors.add([m0, m1]);
        }
      }
    }

    if (survivors.length != 1) return;
    final pin = survivors.single;
    // Group forced cells by mark so consumers always see "mark m goes
    // in cells [...]". In the 2-empty case there's at most one cell
    // per mark, but emitting them as two deductions keeps the contract
    // simple.
    for (var idx = 0; idx < empties.length; idx++) {
      yield TangoDeduction(
        heuristic: _tag,
        forcedCells: [view.cellAddressAt(empties[idx])],
        forcedMark: pin[idx],
      );
    }
  }
}

/// Returns `true` iff the fully-filled candidate line satisfies the
/// anti-triple, count-balance, and in-line constraint rules.
bool _lineLegal(
  List<TangoMark?> line,
  List<TangoConstraint> lineConstraints,
  LineView view,
) {
  if (!lineLegal(line)) return false;
  for (final c in lineConstraints) {
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
