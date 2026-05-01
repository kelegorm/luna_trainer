import '../../../../engine/domain/heuristic.dart';
import '../../domain/tango_mark.dart';
import '../line_view.dart';
import '../tango_deduction.dart';
import 'heuristic_base.dart';

/// Two same-mark neighbours force the third cell on either side to the
/// opposite mark to avoid an anti-triple.
///
/// Patterns covered (per line, per mark `m`):
/// * `[m, m, _, …]` → forced opposite at index 2.
/// * `[_, m, m, …]` → forced opposite at index 0.
/// * Generally: indices `i, i+1` are equal and non-null, `i+2` empty
///   → opposite at `i+2`; symmetric on the left of the pair.
///
/// The "gap-sandwich" (`[m, _, m]`) belongs to [PairCompletion], not
/// here.
class TrioAvoidance extends LineHeuristic {
  const TrioAvoidance();

  static const Heuristic _tag = Heuristic('tango', 'TrioAvoidance');

  @override
  Iterable<TangoDeduction> apply(LineView view) sync* {
    final cells = view.cells;
    for (var i = 0; i < cells.length - 1; i++) {
      final a = cells[i];
      final b = cells[i + 1];
      if (a == null || a != b) continue;

      final opposite = a == TangoMark.sun ? TangoMark.moon : TangoMark.sun;

      // Right of the pair: cell at i+2.
      if (i + 2 < cells.length && cells[i + 2] == null) {
        yield TangoDeduction(
          heuristic: _tag,
          forcedCells: [view.cellAddressAt(i + 2)],
          forcedMark: opposite,
        );
      }
      // Left of the pair: cell at i-1.
      if (i - 1 >= 0 && cells[i - 1] == null) {
        yield TangoDeduction(
          heuristic: _tag,
          forcedCells: [view.cellAddressAt(i - 1)],
          forcedMark: opposite,
        );
      }
    }
  }
}
