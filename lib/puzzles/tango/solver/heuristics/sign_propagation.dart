import '../../../../engine/domain/heuristic.dart';
import '../../domain/tango_constraint.dart';
import '../../domain/tango_mark.dart';
import '../../domain/tango_position.dart';
import '../tango_deduction.dart';
import 'heuristic_base.dart';

/// Propagates marks across `=` and `×` edge constraints.
///
/// For every constraint where exactly one of the two endpoints holds a
/// mark and the other is empty:
/// * `equals` (`=`) forces the empty cell to the same mark,
/// * `opposite` (`×`) forces the empty cell to the opposite mark.
///
/// Implemented as a [PositionHeuristic] because a constraint may not
/// lie on a single row/column (in 6×6 Tango it always does, but we
/// don't depend on that), and because iterating constraints once per
/// position is cheaper than re-running this logic for every line.
class SignPropagation extends PositionHeuristic {
  const SignPropagation();

  static const Heuristic _tag = Heuristic('tango', 'SignPropagation');

  @override
  Iterable<TangoDeduction> apply(TangoPosition position) sync* {
    for (final c in position.constraints) {
      final a = position.cells[c.cellA.row][c.cellA.col];
      final b = position.cells[c.cellB.row][c.cellB.col];
      if (a == null && b == null) continue;
      if (a != null && b != null) continue;

      final filled = a ?? b!;
      final emptyAddr = a == null ? c.cellA : c.cellB;
      final TangoMark forced;
      switch (c.kind) {
        case ConstraintKind.equals:
          forced = filled;
        case ConstraintKind.opposite:
          forced = filled == TangoMark.sun ? TangoMark.moon : TangoMark.sun;
      }
      yield TangoDeduction(
        heuristic: _tag,
        forcedCells: [emptyAddr],
        forcedMark: forced,
      );
    }
  }
}
