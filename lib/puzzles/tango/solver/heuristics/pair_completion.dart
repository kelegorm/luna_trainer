import '../../../../engine/domain/heuristic.dart';
import '../../domain/tango_constraint.dart';
import '../../domain/tango_mark.dart';
import '../line_view.dart';
import '../tango_deduction.dart';
import 'heuristic_base.dart';

/// Two complementary line patterns that "complete a pair":
///
/// 1. **Gap-sandwich.** `[m, _, m]` along consecutive in-line indices
///    forces the middle to the opposite of `m` (placing `m` would make
///    a run of three).
/// 2. **Equals-on-empty pair.** Two empty cells joined by an `=` such
///    that one of their *outer* neighbours along the same line carries
///    the same mark forces both empties to the opposite mark — putting
///    that mark on either empty would create a triple together with
///    the outer neighbour.
///
/// The second pattern is the canonical "pair completion" technique
/// from brohitbrose's `line.js`: an `=`-joined empty pair next to a
/// filled cell flips both empties.
class PairCompletion extends LineHeuristic {
  const PairCompletion();

  static const Heuristic _tag = Heuristic('tango', 'PairCompletion');

  @override
  Iterable<TangoDeduction> apply(LineView view) sync* {
    yield* _gapSandwich(view);
    yield* _equalsOnEmptyPair(view);
  }

  Iterable<TangoDeduction> _gapSandwich(LineView view) sync* {
    final cells = view.cells;
    for (var i = 0; i + 2 < cells.length; i++) {
      final a = cells[i];
      final mid = cells[i + 1];
      final c = cells[i + 2];
      if (a == null || c == null || mid != null) continue;
      if (a != c) continue;
      final opposite = a == TangoMark.sun ? TangoMark.moon : TangoMark.sun;
      yield TangoDeduction(
        heuristic: _tag,
        forcedCells: [view.cellAddressAt(i + 1)],
        forcedMark: opposite,
      );
    }
  }

  Iterable<TangoDeduction> _equalsOnEmptyPair(LineView view) sync* {
    final cells = view.cells;
    for (var i = 0; i + 1 < cells.length; i++) {
      if (cells[i] != null || cells[i + 1] != null) continue;
      final c = view.constraintBetween(i, i + 1);
      if (c == null || c.kind != ConstraintKind.equals) continue;

      // Outer neighbour to the left of the pair: index i-1.
      if (i - 1 >= 0 && cells[i - 1] != null) {
        final outer = cells[i - 1]!;
        // If both empties were `outer`, [outer, outer, outer] triple.
        // So both empties = opposite of outer.
        final forced =
            outer == TangoMark.sun ? TangoMark.moon : TangoMark.sun;
        yield TangoDeduction(
          heuristic: _tag,
          forcedCells: [
            view.cellAddressAt(i),
            view.cellAddressAt(i + 1),
          ],
          forcedMark: forced,
        );
        continue;
      }

      // Outer neighbour to the right of the pair: index i+2.
      if (i + 2 < cells.length && cells[i + 2] != null) {
        final outer = cells[i + 2]!;
        final forced =
            outer == TangoMark.sun ? TangoMark.moon : TangoMark.sun;
        yield TangoDeduction(
          heuristic: _tag,
          forcedCells: [
            view.cellAddressAt(i),
            view.cellAddressAt(i + 1),
          ],
          forcedMark: forced,
        );
      }
    }
  }
}
