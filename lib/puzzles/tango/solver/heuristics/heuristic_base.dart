import '../../domain/tango_position.dart';
import '../line_view.dart';
import '../tango_deduction.dart';

/// A heuristic that reasons about a single row or column at a time.
///
/// Most Tango techniques (TrioAvoidance, ParityFill, PairCompletion,
/// AdvancedMidLineInference) only need the marks already on a single
/// line plus the edge constraints internal to that line, so they
/// implement this interface.
///
/// A LineHeuristic does *not* receive the full [TangoPosition]: cross-
/// line context belongs to [PositionHeuristic]. This split keeps the
/// solver from doing duplicate work — running a constraint-based
/// heuristic once per line would emit the same deduction twelve times.
abstract class LineHeuristic {
  const LineHeuristic();

  Iterable<TangoDeduction> apply(LineView view);
}

/// A heuristic that reasons about the whole position at once.
///
/// `SignPropagation` is the canonical case: a `=` or `×` constraint
/// can join two cells that don't sit on the same row or column (every
/// orthogonal-neighbour constraint actually does sit on a shared line,
/// but the heuristic naturally iterates `position.constraints` rather
/// than scanning lines, so we model it here for symmetry and to avoid
/// per-line dedupe).
abstract class PositionHeuristic {
  const PositionHeuristic();

  Iterable<TangoDeduction> apply(TangoPosition position);
}
