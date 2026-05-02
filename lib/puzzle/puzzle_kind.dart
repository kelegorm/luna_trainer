import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../engine/domain/heuristic.dart';

/// Marker for a puzzle position. Concrete shape lives inside the
/// puzzle-kind module (e.g. `TangoPosition`).
abstract class Position {
  const Position();
}

/// Marker for a single move applied to a [Position].
abstract class Move {
  const Move();
}

/// A deduction the [Solver] reports as available from a position.
/// Carries the [Heuristic] tag and the cells it forces.
abstract class Deduction {
  const Deduction();

  Heuristic get heuristic;
}

/// Catalog metadata about one heuristic supported by a [PuzzleKind].
class HeuristicDescriptor extends Equatable {
  const HeuristicDescriptor({
    required this.heuristic,
    required this.displayName,
    required this.eligibleForDrill,
  });

  final Heuristic heuristic;
  final String displayName;

  /// Whether this heuristic may surface in a drill batch. The fallback
  /// `Composite(unknown)` is logged but not eligible (R10).
  final bool eligibleForDrill;

  @override
  List<Object?> get props => [heuristic, displayName, eligibleForDrill];
}

/// Strategy that classifies positions and reports cheapest deductions.
abstract class Solver {
  const Solver();

  List<Deduction> availableDeductions(Position p);
}

/// Strategy that produces fresh puzzles for full-game and drill modes.
abstract class LevelGenerator {
  const LevelGenerator();
}

/// Contract every puzzle kind must satisfy to plug into the engine.
///
/// The engine never imports from `lib/puzzles/...` directly — it only
/// talks to a [PuzzleKind] obtained from the registry. This is the
/// minimum surface that lets the engine drive telemetry, mastery, and
/// drills puzzle-agnostically (R26).
abstract class PuzzleKind {
  const PuzzleKind();

  String get id;
  List<HeuristicDescriptor> get heuristics;
  Solver get solver;
  LevelGenerator get generator;

  Widget renderBoard(Position position, void Function(Move move) onMove);
  Widget renderHintField(Position position, Deduction deduction);

  /// Player-facing label for [h] from the kind's [heuristics] catalog
  /// (R33). Returns `null` if the heuristic is not catalogued — callers
  /// fall back to `heuristic.tagId` for diagnostics.
  String? displayNameFor(Heuristic h) {
    for (final d in heuristics) {
      if (d.heuristic == h) return d.displayName;
    }
    return null;
  }
}
