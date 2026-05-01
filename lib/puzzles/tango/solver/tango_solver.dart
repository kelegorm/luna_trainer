import '../../../puzzle/puzzle_kind.dart';
import '../domain/tango_constraint.dart';
import '../domain/tango_position.dart';
import '../domain/tango_rules.dart';
import 'heuristics/advanced_mid_line.dart';
import 'heuristics/chain_extension.dart';
import 'heuristics/composite_fallback.dart';
import 'heuristics/heuristic_base.dart';
import 'heuristics/pair_completion.dart';
import 'heuristics/parity_fill.dart';
import 'heuristics/sign_propagation.dart';
import 'heuristics/trio_avoidance.dart';
import 'line_view.dart';
import 'tango_deduction.dart';

/// Concrete Tango solver wired into [PuzzleKind.solver] (R26).
///
/// Heuristics fire in cheapness order:
/// `TrioAvoidance, ParityFill, SignPropagation, PairCompletion,
/// AdvancedMidLineInference`. If none of them returns anything the
/// solver falls back to [CompositeFallback]. Finally,
/// [ChainExtension.tag] re-tags non-conflicting follow-up deductions.
class TangoSolver extends Solver {
  const TangoSolver();

  static const PositionHeuristic _signPropagation = SignPropagation();
  static const CompositeFallback _composite = CompositeFallback();
  static const ChainExtension _chain = ChainExtension();

  @override
  List<TangoDeduction> availableDeductions(Position p) {
    if (p is! TangoPosition) return const [];
    if (!isLegal(p)) return const [];

    // 1. Run cheap heuristics. Position-level first to keep its
    //    deductions ahead of equivalent line-level ones.
    final raw = <TangoDeduction>[];

    // Per-plan ordering: TrioAvoidance, ParityFill, SignPropagation,
    // PairCompletion, AdvancedMidLineInference. We interleave by
    // calling SignPropagation between ParityFill and PairCompletion.
    raw.addAll(_runLineHeuristic(const TrioAvoidance(), p));
    raw.addAll(_runLineHeuristic(const ParityFill(), p));
    raw.addAll(_signPropagation.apply(p));
    raw.addAll(_runLineHeuristic(const PairCompletion(), p));
    raw.addAll(_runLineHeuristic(const AdvancedMidLineInference(), p));

    var deduped = _dedupe(raw, p);

    // 2. Composite fallback only if nothing cheap fired.
    if (deduped.isEmpty) {
      deduped = _dedupe(_composite.apply(p).toList(), p);
    }

    // 3. ChainExtension meta-tag pass.
    return _chain.tag(deduped);
  }

  /// Returns the cheapest single deduction available from [p], or
  /// `null` if there is none. Cheapness follows the heuristic order
  /// declared above.
  TangoDeduction? cheapest(TangoPosition p) {
    final all = availableDeductions(p);
    return all.isEmpty ? null : all.first;
  }

  /// Convenience wrapper exposed for symmetry with the plan; identical
  /// to reading [TangoDeduction.forcedCells].
  List<CellAddress> forcedCellsFor(TangoDeduction d) => d.forcedCells;

  Iterable<TangoDeduction> _runLineHeuristic(
    LineHeuristic h,
    TangoPosition p,
  ) sync* {
    for (var i = 0; i < kTangoBoardSize; i++) {
      yield* h.apply(LineView.fromPosition(
        p,
        axis: LineAxis.row,
        index: i,
      ));
      yield* h.apply(LineView.fromPosition(
        p,
        axis: LineAxis.column,
        index: i,
      ));
    }
  }

  /// Drops deductions whose `(cell, mark)` pairs are already covered
  /// by an earlier deduction in cheapness order; also drops deductions
  /// that try to re-place the existing mark or contradict the board.
  /// Same `(cell, mark)` keeps the earlier (cheaper) heuristic tag.
  List<TangoDeduction> _dedupe(
    List<TangoDeduction> raw,
    TangoPosition p,
  ) {
    final seen = <String>{};
    final out = <TangoDeduction>[];
    for (final d in raw) {
      final filtered = <CellAddress>[];
      for (final cell in d.forcedCells) {
        final existing = p.cells[cell.row][cell.col];
        // Skip cells that already hold the same mark or a contradicting
        // mark — a contradicting mark means the heuristic fired on a
        // position the caller didn't fully validate; we silently drop
        // it rather than throw.
        if (existing == d.forcedMark) continue;
        if (existing != null && existing != d.forcedMark) continue;
        final key = '${cell.row},${cell.col},${d.forcedMark.name}';
        if (seen.add(key)) filtered.add(cell);
      }
      if (filtered.isEmpty) continue;
      if (filtered.length == d.forcedCells.length) {
        out.add(d);
      } else {
        out.add(TangoDeduction(
          heuristic: d.heuristic,
          forcedCells: filtered,
          forcedMark: d.forcedMark,
        ));
      }
    }
    return out;
  }
}
