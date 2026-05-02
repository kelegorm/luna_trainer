import 'dart:math' as math;

import '../../../engine/domain/heuristic.dart';
import '../../../puzzle/puzzle_kind.dart';
import '../domain/tango_constraint.dart';
import '../domain/tango_mark.dart';
import '../domain/tango_position.dart';
import '../solver/tango_solver.dart';
import 'band_to_params_mapper.dart';
import 'board_shape.dart';
import 'difficulty_band.dart';
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
  ///
  /// When [band] is supplied (R34/R35), the generator switches to a
  /// **band-driven mode**:
  ///
  /// * [BandToParamsMapper.mapToParams] derives a `GenerationParams` set
  ///   ([density], [signDensity], [requiredTechniques]).
  /// * The carving loop uses **steered removal** — at each step it
  ///   prefers clues whose removal forces one of the required
  ///   techniques over a pure-random removal (see [_carveCluesSteered]).
  /// * After convergence the canonical solve trace is checked against
  ///   [GenerationParams.requiredTechniques]. If the set is not covered
  ///   the candidate is discarded and we retry with a fresh seed.
  /// * [GenerationParams.hardAcceptsAlternatives] turns the required-set
  ///   into an OR-set — used by [DifficultyBand.hard] (Advanced OR
  ///   Chain).
  ///
  /// In band mode the supplied [mix] is still consulted (the carving
  /// loop sets weights to whatever drifts in), but band requirements
  /// take precedence — a puzzle that misses [requiredTechniques] is
  /// rejected even if its histogram falls inside `mix.tolerance`. After
  /// [maxAttempts] outer retries we return `GeneratorBestEffort` with
  /// the closest-drift candidate seen, mirroring the U6 best-effort
  /// semantics.
  GeneratorResult generate({
    required TargetMix mix,
    required BoardShape shape,
    int? seed,
    DiversityFilter? diversity,
    DifficultyBand? band,
  }) {
    // TargetMix construction already rejects Composite(unknown), so by
    // the time we reach `generate` the mix is guaranteed valid.
    final effectiveSeed = seed ?? math.Random().nextInt(1 << 30);
    final rng = math.Random(effectiveSeed);

    final bandParams =
        band == null ? null : const BandToParamsMapper().mapToParams(band);

    GeneratorBestEffort? best;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = _tryGenerate(
        mix: mix,
        shape: shape,
        rng: rng,
        seed: effectiveSeed,
        bandParams: bandParams,
      );
      if (candidate == null) continue;

      // Band gate (R35): if band-mode is active, the required-techniques
      // set must be satisfied by the canonical solve trace before we
      // even consider mix-tolerance acceptance. We use the
      // *available-tags* trace, not the cheapest-only histogram, so
      // band=3 (Advanced/Chain) convergence is achievable — see the
      // doc-comment on [_availableTagsTrace] for the rationale.
      final availableTags = bandParams == null
          ? const <Heuristic>{}
          : _availableTagsTrace(
              candidate.initialPosition,
              candidate.shape,
            );
      if (bandParams != null && !_requiredTechniquesSatisfied(
        availableTags,
        bandParams,
      )) {
        // Track best-effort using mix drift (same metric as the U6 path)
        // so cap-exceed at least returns something playable.
        final drift = candidate.histogram.driftFrom(mix);
        if (best == null || drift < best.mixDrift) {
          best = GeneratorBestEffort(
            puzzle: candidate,
            histogram: candidate.histogram,
            mixDrift: drift,
          );
        }
        continue;
      }

      final drift = candidate.histogram.driftFrom(mix);
      // In band mode we trust the bandParams gate above; mix tolerance
      // is informational. Outside band mode, the U6 tolerance gate
      // applies.
      final passesMix = bandParams != null || drift <= mix.tolerance;
      if (passesMix) {
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

  /// `true` iff [fired] covers [params.requiredTechniques].
  ///
  /// AND-semantics by default; OR-semantics when
  /// [GenerationParams.hardAcceptsAlternatives] is set.
  bool _requiredTechniquesSatisfied(
    Set<Heuristic> fired,
    GenerationParams params,
  ) {
    if (params.hardAcceptsAlternatives) {
      // OR — at least one of the required tags must have fired.
      for (final h in params.requiredTechniques) {
        if (fired.contains(h)) return true;
      }
      return false;
    }
    // AND — every required tag must have fired.
    for (final h in params.requiredTechniques) {
      if (!fired.contains(h)) return false;
    }
    return true;
  }

  TangoPuzzle? _tryGenerate({
    required TargetMix mix,
    required BoardShape shape,
    required math.Random rng,
    required int seed,
    GenerationParams? bandParams,
  }) {
    final solved = _randomCompletion(shape, rng);
    if (solved == null) return null;

    // In band-mode we scale the constraint count by signDensity. Outside
    // band-mode we use the U6 baseline.
    final constraintTarget = bandParams == null
        ? _targetConstraintsFor(shape)
        : _targetConstraintsForBand(shape, bandParams.signDensity);

    final constraints = _sprinkleConstraints(
      solved,
      shape,
      rng,
      constraintTarget,
    );
    final solvedWithConstraints = TangoPosition(
      cells: solved.cells,
      constraints: constraints,
    );

    final initial = bandParams == null
        ? _carveClues(solvedWithConstraints, shape, rng)
        : _carveCluesSteered(solvedWithConstraints, shape, rng, bandParams);
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

  /// Constraint count target for band-mode = `signDensity × adjacency
  /// budget`. Floor-rounded to the nearest int, with a minimum of 1 on
  /// any non-trivial shape (so band=3 doesn't accidentally produce a
  /// constraint-free puzzle).
  int _targetConstraintsForBand(BoardShape shape, double signDensity) {
    final activeSet = shape.activeCellSet;
    var adjCount = 0;
    for (final a in shape.activeCells) {
      for (final delta in const [
        [0, 1],
        [1, 0],
      ]) {
        final b = CellAddress(a.row + delta[0], a.col + delta[1]);
        if (activeSet.contains(b)) adjCount++;
      }
    }
    final raw = (adjCount * signDensity).round();
    if (adjCount == 0) return 0;
    return raw < 1 ? 1 : raw;
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

  /// Band-mode steered carving (R35).
  ///
  /// Same skeleton as [_carveClues] — randomise the active-cell order,
  /// remove cells one at a time keeping uniqueness — with two
  /// modifications:
  ///
  /// 1. **Density floor.** Once seeded-cell count drops below
  ///    `targetSeedCount = round(density × |active|)` we stop accepting
  ///    "free" removals; further removals must be **required-forcing**.
  ///    This keeps band=1 puzzles dense (≥0.45) and lets band=3 carve
  ///    deeply (≤0.30).
  /// 2. **Required-forcing gate.** Below the floor, a removal is only
  ///    kept if the post-removal canonical solve trace introduces a
  ///    [GenerationParams.requiredTechniques] tag that the pre-removal
  ///    trace did not contain. For band=3 (OR-semantics) any of
  ///    `AdvancedMidLineInference` / `ChainExtension` qualifies.
  ///
  /// Rationale: random-retry on band=3 almost never converges because
  /// `AdvancedMidLineInference` / `ChainExtension` rarely arise
  /// spontaneously. Steered removal targets convergence.
  TangoPosition? _carveCluesSteered(
    TangoPosition solved,
    BoardShape shape,
    math.Random rng,
    GenerationParams params,
  ) {
    final cells = List<List<TangoMark?>>.generate(
      kTangoBoardSize,
      (r) => List<TangoMark?>.from(solved.cells[r]),
    );
    final order = List<CellAddress>.from(shape.activeCells)..shuffle(rng);
    final activeCount = shape.activeCells.length;
    // Target seed count derived from band density. Clamp to [1,
    // activeCount-1] so we never carve a no-clue or no-removal puzzle.
    final rawTarget = (activeCount * params.density).round();
    final targetSeedCount = rawTarget.clamp(1, activeCount - 1);

    var seededCount = activeCount; // start fully solved
    Set<Heuristic> currentTrace = _availableTagsTrace(
      TangoPosition(cells: cells, constraints: solved.constraints),
      shape,
    );

    for (final a in order) {
      final saved = cells[a.row][a.col];
      if (saved == null) continue;
      cells[a.row][a.col] = null;
      final attempt =
          TangoPosition(cells: cells, constraints: solved.constraints);
      // Uniqueness gate first.
      if (hasAlternativeSolution(attempt, shape, solved)) {
        cells[a.row][a.col] = saved;
        continue;
      }
      // Above the density floor — accept any uniqueness-preserving
      // removal. (No need to retrace — density alone matters here.)
      if (seededCount - 1 > targetSeedCount) {
        seededCount--;
        continue;
      }
      // At/below floor — only keep removals that introduce a required
      // technique not previously in the trace. Cheap-ish: trace the new
      // position once via the available-tags scan.
      final postTrace = _availableTagsTrace(attempt, shape);
      if (_introducesRequired(currentTrace, postTrace, params)) {
        currentTrace = postTrace;
        seededCount--;
        continue;
      }
      // Otherwise keep the clue.
      cells[a.row][a.col] = saved;
    }
    final initial =
        TangoPosition(cells: cells, constraints: solved.constraints);
    if (hasAlternativeSolution(initial, shape, solved)) return null;
    return initial;
  }

  bool _introducesRequired(
    Set<Heuristic> before,
    Set<Heuristic> after,
    GenerationParams params,
  ) {
    for (final req in params.requiredTechniques) {
      if (!before.contains(req) && after.contains(req)) return true;
    }
    return false;
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

  /// Tags that *appeared at least once* in [solver.availableDeductions]
  /// during the canonical solve, regardless of whether they ended up
  /// being the cheapest deduction picked.
  ///
  /// Why a separate trace? The cheapest-first trace under-reports
  /// advanced techniques: `Advanced` fires only when no `Trio /
  /// ParityFill / SignProp / Pair` deduction exists for the same
  /// position, which is rare. For the band-mode required-techniques
  /// gate (R35) we want to count "this puzzle *features* the
  /// technique" — i.e. the technique was at least *available* — even
  /// if a cheaper one happened to win the tie-break each step. This
  /// makes the band=3 convergence assertion (Advanced OR Chain in ≥80%
  /// of generations) achievable.
  Set<Heuristic> _availableTagsTrace(TangoPosition initial, BoardShape shape) {
    const solver = TangoSolver();
    final tags = <Heuristic>{};
    var pos = initial;
    final guard = shape.activeCells.length + 4;
    var steps = 0;
    while (!isCompleteFor(shape, pos) && steps < guard) {
      final all = solver.availableDeductions(pos);
      if (all.isEmpty) break;
      for (final d in all) {
        tags.add(d.heuristic);
      }
      // Apply the cheapest to advance.
      final d = all.first;
      var applied = false;
      for (final cell in d.forcedCells) {
        if (!shape.isActive(cell.row, cell.col)) continue;
        if (pos.cells[cell.row][cell.col] != null) continue;
        pos = pos.withCell(cell.row, cell.col, d.forcedMark);
        applied = true;
      }
      if (!applied) break;
      steps++;
    }
    return tags;
  }
}

extension _Swap<T> on List<T> {
  void swap(int i, int j) {
    final t = this[i];
    this[i] = this[j];
    this[j] = t;
  }
}
