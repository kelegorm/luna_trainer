import 'package:equatable/equatable.dart';

import '../../../engine/domain/heuristic.dart';
import '../../../puzzle/puzzle_kind.dart';
import '../domain/tango_constraint.dart';
import '../domain/tango_mark.dart';
import '../domain/tango_position.dart';

/// A concrete deduction reported by the Tango solver.
///
/// Every Tango deduction places the *same* mark in one or more cells.
/// We deliberately picked the simpler `forcedCells + forcedMark` shape
/// over a `List<{address, mark}>` because every heuristic in the U5
/// catalog (TrioAvoidance, ParityFill, SignPropagation, PairCompletion,
/// AdvancedMidLineInference, Composite) emits a mono-mark deduction:
///
/// * line heuristics force a single mark per fired pattern,
/// * AdvancedMidLineInference splits multi-cell forces by mark — when a
///   2-empty backtrack pins one cell to sun and another to moon, the
///   solver returns *two* deductions (one per mark) instead of fusing
///   them into a heterogeneous bundle.
///
/// This keeps `applyTo` and the consumers (drill renderer, mastery
/// updater) trivial: every deduction is "place [forcedMark] in every
/// cell of [forcedCells]".
class TangoDeduction extends Deduction with EquatableMixin {
  const TangoDeduction({
    required this.heuristic,
    required this.forcedCells,
    required this.forcedMark,
  });

  @override
  final Heuristic heuristic;

  /// The cells this deduction forces. Always non-empty.
  final List<CellAddress> forcedCells;

  /// The mark placed in every cell of [forcedCells].
  final TangoMark forcedMark;

  /// Returns a copy of [position] with [forcedMark] placed in every
  /// cell of [forcedCells]. Cells already filled with the same mark are
  /// left as-is; the caller is responsible for not feeding a position
  /// where this deduction would conflict (the solver guards against it).
  TangoPosition applyTo(TangoPosition position) {
    var p = position;
    for (final cell in forcedCells) {
      p = p.withCell(cell.row, cell.col, forcedMark);
    }
    return p;
  }

  /// Returns a deduction identical to this one but with [heuristic]
  /// replaced. Used by `ChainExtension` post-processing.
  TangoDeduction withHeuristic(Heuristic newHeuristic) => TangoDeduction(
        heuristic: newHeuristic,
        forcedCells: forcedCells,
        forcedMark: forcedMark,
      );

  @override
  List<Object?> get props => [heuristic, forcedCells, forcedMark];

  @override
  String toString() =>
      'TangoDeduction($heuristic, $forcedMark @ $forcedCells)';
}
