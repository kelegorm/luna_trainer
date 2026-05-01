import '../../../../engine/domain/heuristic.dart';
import '../../domain/tango_constraint.dart';
import '../tango_deduction.dart';

/// Meta-heuristic: tags a deduction as a [chainExtension] when it
/// chains off an earlier deduction in the same batch.
///
/// **Chain-detection rule.** Take the deductions in cheapness order.
/// Walk them left-to-right and keep a running set of cells already
/// pinned by *previous* deductions in the walk. A deduction is a chain
/// extension iff *any* of its forced cells is the same as a cell that
/// an earlier deduction in the walk would already have pinned —
/// equivalently, it would have been derivable only after applying that
/// earlier deduction.
///
/// In practice the line and constraint heuristics already see each
/// other's preconditions because they look at the original position;
/// the situation `ChainExtension` flags is "two independent deductions
/// fired off the same starting position" — i.e. there are two or more
/// deductions in the batch that touch *disjoint* cells, so applying
/// the first does not invalidate the second. To match the plan's
/// "позиция допускает > 1 cheap deduction — это и есть chain-context",
/// we tag the second-and-later non-conflicting deductions.
///
/// Conflict rule used here: two deductions conflict if they share any
/// forced cell. Two non-conflicting deductions in the batch ⇒ the
/// later ones get the [chainExtension] tag.
class ChainExtension {
  const ChainExtension();

  static const Heuristic chainExtension =
      Heuristic('tango', 'ChainExtension');

  /// Returns a new list where the second-and-later deductions whose
  /// forced cells don't collide with any *earlier* deduction's forced
  /// cells are re-tagged with [chainExtension]. The original list is
  /// not mutated.
  List<TangoDeduction> tag(List<TangoDeduction> deductions) {
    if (deductions.length < 2) return List.of(deductions);

    final result = <TangoDeduction>[];
    final claimed = <CellAddress>{};
    var sawAny = false;
    for (final d in deductions) {
      final overlaps = d.forcedCells.any(claimed.contains);
      if (sawAny && !overlaps) {
        result.add(d.withHeuristic(chainExtension));
      } else {
        result.add(d);
      }
      claimed.addAll(d.forcedCells);
      sawAny = true;
    }
    return result;
  }
}
