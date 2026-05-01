import '../../../../engine/domain/heuristic.dart';
import '../../domain/tango_mark.dart';
import '../../domain/tango_position.dart';
import '../line_view.dart';
import '../tango_deduction.dart';
import 'heuristic_base.dart';

/// When a line already holds `kTangoBoardSize / 2` of one mark, every
/// remaining empty cell must hold the opposite mark.
///
/// Single deduction emitted per line per mark, listing every forced
/// empty cell.
class ParityFill extends LineHeuristic {
  const ParityFill();

  static const Heuristic _tag = Heuristic('tango', 'ParityFill');

  @override
  Iterable<TangoDeduction> apply(LineView view) sync* {
    const half = kTangoBoardSize ~/ 2;
    var suns = 0;
    var moons = 0;
    final empties = <int>[];
    for (var i = 0; i < view.cells.length; i++) {
      final m = view.cells[i];
      if (m == TangoMark.sun) {
        suns++;
      } else if (m == TangoMark.moon) {
        moons++;
      } else {
        empties.add(i);
      }
    }

    if (empties.isEmpty) return;

    if (suns >= half) {
      yield TangoDeduction(
        heuristic: _tag,
        forcedCells: [for (final i in empties) view.cellAddressAt(i)],
        forcedMark: TangoMark.moon,
      );
    } else if (moons >= half) {
      yield TangoDeduction(
        heuristic: _tag,
        forcedCells: [for (final i in empties) view.cellAddressAt(i)],
        forcedMark: TangoMark.sun,
      );
    }
  }
}
