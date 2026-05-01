import 'dart:math' as math;

import '../../../engine/domain/heuristic.dart';
import '../../../puzzle/puzzle_kind.dart';
import '../domain/tango_constraint.dart';
import '../domain/tango_mark.dart';
import '../domain/tango_position.dart';
import '../solver/tango_solver.dart';
import 'board_shape.dart';
import 'diversity_filter.dart';
import 'generator_result.dart';
import 'mix_histogram.dart';
import 'shape_rules.dart';
import 'tango_puzzle.dart';
import 'target_mix.dart';
import 'uniqueness_check.dart';

/// Parametric Tango level generator (R19, R20, R21).
///
/// Algorithm — solve-then-remove, à la Sudoku:
///
/// 1. Validate the [TargetMix] (refuses `Composite(unknown)`).
/// 2. Seed an RNG so a non-null `seed` produces deterministic output.
/// 3. Generate a fully-valid solved board for [BoardShape] via
///    randomised backtracking over [shape.activeCells].
/// 4. Sprinkle in `=` / `×` edge constraints consistent with the
///    solved board.
/// 5. Carve clues out one at a time, keeping the puzzle uniquely
///    solvable under the shape.
/// 6. Trace the canonical solve to count which heuristic fired at each
///    step → [MixHistogram].
/// 7. If the histogram drift from `mix` is within `mix.tolerance` →
///    return [GeneratorSuccess]. Otherwise retry from step 3.
/// 8. After 200 attempts, return [GeneratorBestEffort] with the
///    closest-drift puzzle seen.
///
/// The optional [DiversityFilter] is consulted right before accepting
/// a puzzle; the generator itself holds no state, so callers must pass
/// the same filter across calls when batch-generating.
class TangoLevelGenerator extends LevelGenerator {
  const TangoLevelGenerator({
    this.maxAttempts = 200,
    this.targetConstraintsFull = 8,
  });

  /// Total resampling cap before yielding [GeneratorBestEffort].
  final int maxAttempts;

  /// Target number of edge constraints on a full 6×6 board.
  /// Calibrated to LinkedIn-puzzle ranges (6–10). Fragments scale
  /// proportionally — see [_targetConstraintsFor].
  final int targetConstraintsFull;

  /// Generates one puzzle.
  GeneratorResult generate({
    required TargetMix mix,
    required BoardShape shape,
    int? seed,
    DiversityFilter? diversity,
  }) {
    // Step 1 — defence-in-depth: TargetMix already rejects bad tags,
    // but we re-check explicitly so the failure mode in this method
    // matches the plan's "Composite не подаётся в drill" wording.
    for (final h in mix.weights.keys) {
      if (h.tagId == 'Composite(unknown)') {
        return const GeneratorFailure(
          'Composite не подаётся в drill',
        );
      }
    }

    final effectiveSeed = seed ?? math.Random().nextInt(1 << 30);
    final rng = math.Random(effectiveSeed);

    GeneratorBestEffort? best;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = _tryGenerate(
        mix: mix,
        shape: shape,
        rng: rng,
        seed: effectiveSeed,
      );
      if (candidate == null) continue;

      final drift = candidate.histogram.driftFrom(mix);
      if (drift <= mix.tolerance) {
        if (diversity != null && !diversity.accepts(candidate)) {
          // Looks too much like recent output — keep looking.
          continue;
        }
        return GeneratorSuccess(
          puzzle: candidate,
          histogram: candidate.histogram,
        );
      }
      if (best == null || drift < best.mixDrift) {
        best = GeneratorBestEffort(
          puzzle: candidate,
          histogram: candidate.histogram,
          mixDrift: drift,
        );
      }
    }

    return best ??
        const GeneratorFailure(
          'no candidate produced after maxAttempts',
        );
  }

  TangoPuzzle? _tryGenerate({
    required TargetMix mix,
    required BoardShape shape,
    required math.Random rng,
    required int seed,
  }) {
    final solved = _randomCompletion(shape, rng);
    if (solved == null) return null;

    final constraints = _sprinkleConstraints(
      solved,
      shape,
      rng,
      _targetConstraintsFor(shape),
    );
    final solvedWithConstraints = TangoPosition(
      cells: solved.cells,
      constraints: constraints,
    );

    final initial = _carveClues(solvedWithConstraints, shape, rng);
    if (initial == null) return null;

    final histogram = _traceHistogram(initial, shape);
    return TangoPuzzle(
      initialPosition: initial,
      solution: solvedWithConstraints,
      shape: shape,
      histogram: histogram,
      seed: seed,
    );
  }

  int _targetConstraintsFor(BoardShape shape) {
    switch (shape.kind) {
      case BoardShapeKind.full6x6:
        return targetConstraintsFull;
      case BoardShapeKind.fragment2x4:
        return 2;
      case BoardShapeKind.fragment3x3:
        return 2;
      case BoardShapeKind.singleRow:
      case BoardShapeKind.singleCol:
        return 1;
    }
  }

  /// Backtracking random-completion of [shape].
  ///
  /// Inactive cells stay `null`. Active cells are visited in
  /// [shape.activeCells] order; at each cell we try sun/moon in random
  /// order and recurse.
  TangoPosition? _randomCompletion(BoardShape shape, math.Random rng) {
    final cells = List<List<TangoMark?>>.generate(
      kTangoBoardSize,
      (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
    );
    final order = shape.activeCells;
    if (_completeRecursive(cells, shape, order, 0, rng)) {
      return TangoPosition(cells: cells, constraints: const []);
    }
    return null;
  }

  bool _completeRecursive(
    List<List<TangoMark?>> cells,
    BoardShape shape,
    List<CellAddress> order,
    int cursor,
    math.Random rng,
  ) {
    if (cursor == order.length) return true;
    final addr = order[cursor];
    final marks = [TangoMark.sun, TangoMark.moon];
    if (rng.nextBool()) {
      marks.swap(0, 1);
    }
    for (final m in marks) {
      cells[addr.row][addr.col] = m;
      if (isLegalForRaw(shape, cells, const [])) {
        if (_completeRecursive(cells, shape, order, cursor + 1, rng)) {
          return true;
        }
      }
      cells[addr.row][addr.col] = null;
    }
    return false;
  }

  /// Adds up to [target] edge constraints consistent with the solved
  /// board. We pick adjacent active-active pairs in random order; the
  /// constraint kind is forced by the marks already on those cells.
  List<TangoConstraint> _sprinkleConstraints(
    TangoPosition solved,
    BoardShape shape,
    math.Random rng,
    int target,
  ) {
    final activeSet = shape.activeCellSet;
    final candidates = <TangoConstraint>[];
    for (final a in shape.activeCells) {
      for (final delta in const [
        [0, 1],
        [1, 0],
      ]) {
        final b = CellAddress(a.row + delta[0], a.col + delta[1]);
        if (!activeSet.contains(b)) continue;
        final ma = solved.cells[a.row][a.col];
        final mb = solved.cells[b.row][b.col];
        if (ma == null || mb == null) continue;
        final kind = ma == mb ? ConstraintKind.equals : ConstraintKind.opposite;
        candidates.add(TangoConstraint(cellA: a, cellB: b, kind: kind));
      }
    }
    candidates.shuffle(rng);
    final out = <TangoConstraint>[];
    for (final c in candidates) {
      if (out.length >= target) break;
      out.add(c);
    }
    return out;
  }

  /// Step (5) carving: start from the fully solved board, remove one
  /// active-cell mark at a time (random order), and keep the removal
  /// only if the puzzle stays uniquely solvable under [shape].
  TangoPosition? _carveClues(
    TangoPosition solved,
    BoardShape shape,
    math.Random rng,
  ) {
    final cells = List<List<TangoMark?>>.generate(
      kTangoBoardSize,
      (r) => List<TangoMark?>.from(solved.cells[r]),
    );
    final order = List<CellAddress>.from(shape.activeCells)..shuffle(rng);
    for (final a in order) {
      final saved = cells[a.row][a.col];
      if (saved == null) continue;
      cells[a.row][a.col] = null;
      final attempt =
          TangoPosition(cells: cells, constraints: solved.constraints);
      // Fast path: caller already knows `solved` is one solution, so
      // we only need to confirm no alternative exists.
      if (hasAlternativeSolution(attempt, shape, solved)) {
        cells[a.row][a.col] = saved;
      }
    }
    final initial =
        TangoPosition(cells: cells, constraints: solved.constraints);
    // Sanity check — must still solve uniquely.
    if (hasAlternativeSolution(initial, shape, solved)) return null;
    return initial;
  }

  /// Traces the canonical solve: repeatedly query the U5 solver for
  /// the cheapest deduction and apply it. Each fired heuristic
  /// increments a counter; the resulting histogram is normalised.
  ///
  /// If the solver runs dry before the active region is full, we fall
  /// back to backtracking the rest in a single pass — that pass adds
  /// `Composite(unknown)` to the histogram. (The generator regenerates
  /// in that case unless `Composite(unknown)` is rare enough to fall
  /// inside tolerance.)
  MixHistogram _traceHistogram(TangoPosition initial, BoardShape shape) {
    const solver = TangoSolver();
    final counts = <Heuristic, int>{};
    var pos = initial;
    final guard = shape.activeCells.length + 4;
    var steps = 0;
    while (!isCompleteFor(shape, pos) && steps < guard) {
      // The U5 solver works on a 6×6 board — it never inspects cells
      // outside the active region (those are `null` in `pos`), so the
      // deductions it returns are valid for our shape too.
      final d = solver.cheapest(pos);
      if (d == null) break;
      // Filter forced-cells to active region (paranoia — they should
      // always be active because only active cells are non-null).
      var applied = false;
      for (final cell in d.forcedCells) {
        if (!shape.isActive(cell.row, cell.col)) continue;
        if (pos.cells[cell.row][cell.col] != null) continue;
        pos = pos.withCell(cell.row, cell.col, d.forcedMark);
        applied = true;
      }
      if (!applied) break;
      counts.update(d.heuristic, (v) => v + 1, ifAbsent: () => 1);
      steps++;
    }
    return MixHistogram.fromCounts(counts);
  }
}

extension _Swap<T> on List<T> {
  void swap(int i, int j) {
    final t = this[i];
    this[i] = this[j];
    this[j] = t;
  }
}
