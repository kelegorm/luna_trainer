import '../../../../engine/domain/heuristic.dart';
import '../../domain/tango_constraint.dart';
import '../../domain/tango_mark.dart';
import '../../domain/tango_rules.dart';
import '../line_view.dart';
import '../tango_deduction.dart';
import 'heuristic_base.dart';

/// Multi-cell line composition.
///
/// Two flavours fire here:
///
/// 1. **Edge-trap patterns (R30/R33).** Two filled cells with the same
///    mark at line indices `(0, 4)` or `(1, 5)` — the "edge_1_5" and
///    "edge_2_6" traps from the concept taxonomy. The four empties
///    cannot be filled to satisfy anti-triple + count balance unless
///    the lone outside cell takes the opposite mark. These deductions
///    carry the namespaced sub-tags `AdvancedMidLineInference/edge_1_5`
///    / `/edge_2_6` so the drill planner can rotate each sub-form
///    separately.
/// 2. **Two-empty enumeration.** For any line with exactly two empty
///    cells, enumerate the four (sun, moon) assignments and keep only
///    those that yield a legal line — i.e. no anti-triple, no count
///    imbalance, and no in-line `=`/`×` constraint violations. If
///    exactly one assignment survives, emit one deduction per mark for
///    the cells it pins. These keep the base `AdvancedMidLineInference`
///    tag (the "прочее" sub-class).
class AdvancedMidLineInference extends LineHeuristic {
  const AdvancedMidLineInference();

  static const Heuristic _tag =
      Heuristic('tango', 'AdvancedMidLineInference');
  static const Heuristic _edgeOneFiveTag =
      Heuristic('tango', 'AdvancedMidLineInference/edge_1_5');
  static const Heuristic _edgeTwoSixTag =
      Heuristic('tango', 'AdvancedMidLineInference/edge_2_6');

  @override
  Iterable<TangoDeduction> apply(LineView view) sync* {
    yield* _edgeTraps(view);
    yield* _twoEmptyEnumeration(view);
  }

  Iterable<TangoDeduction> _edgeTraps(LineView view) sync* {
    final cells = view.cells;
    // Edge traps are a 6-cell phenomenon (positions 1/5 or 2/6 in the
    // concept's 1-indexed taxonomy). Skip non-canonical line lengths so
    // the heuristic stays well-defined on hypothetical fragments.
    if (cells.length != 6) return;

    final a0 = cells[0];
    final a4 = cells[4];
    // edge_1_5: A _ _ _ A _ — same mark at indices 0 and 4, every other
    // cell empty. Anti-triple forces index 5 to the opposite of A
    // (otherwise indices 1..3 must all hold the opposite, making three
    // in a row).
    if (a0 != null &&
        a4 != null &&
        a0 == a4 &&
        cells[1] == null &&
        cells[2] == null &&
        cells[3] == null &&
        cells[5] == null) {
      yield TangoDeduction(
        heuristic: _edgeOneFiveTag,
        forcedCells: [view.cellAddressAt(5)],
        forcedMark: _opposite(a0),
      );
    }

    final b1 = cells[1];
    final b5 = cells[5];
    // edge_2_6: _ A _ _ _ A — mirror of edge_1_5, forces index 0.
    if (b1 != null &&
        b5 != null &&
        b1 == b5 &&
        cells[0] == null &&
        cells[2] == null &&
        cells[3] == null &&
        cells[4] == null) {
      yield TangoDeduction(
        heuristic: _edgeTwoSixTag,
        forcedCells: [view.cellAddressAt(0)],
        forcedMark: _opposite(b1),
      );
    }
  }

  Iterable<TangoDeduction> _twoEmptyEnumeration(LineView view) sync* {
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

TangoMark _opposite(TangoMark m) =>
    m == TangoMark.sun ? TangoMark.moon : TangoMark.sun;

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
