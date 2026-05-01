import 'package:flutter/widgets.dart';

import '../../engine/domain/heuristic.dart';
import '../../puzzle/puzzle_kind.dart';
import 'generator/tango_level_generator.dart';
import 'solver/tango_solver.dart';

/// Catalog of MVP heuristics for Tango (R2). `Composite(unknown)` is
/// logged for diagnostics but not eligible for drill (R10).
const _kTangoHeuristics = <HeuristicDescriptor>[
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'PairCompletion'),
    displayName: 'Pair completion',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'TrioAvoidance'),
    displayName: 'Trio avoidance',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'ParityFill'),
    displayName: 'Parity fill',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'SignPropagation'),
    displayName: 'Sign propagation',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'AdvancedMidLineInference'),
    displayName: 'Advanced mid-line inference',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'ChainExtension'),
    displayName: 'Chain extension',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'Composite(unknown)'),
    displayName: 'Composite (unknown)',
    eligibleForDrill: false,
  ),
];

class TangoPuzzleKind extends PuzzleKind {
  const TangoPuzzleKind();

  @override
  String get id => 'tango';

  @override
  List<HeuristicDescriptor> get heuristics => _kTangoHeuristics;

  @override
  Solver get solver => const TangoSolver();

  @override
  LevelGenerator get generator => const TangoLevelGenerator();

  @override
  Widget renderBoard(Position position, void Function(Move move) onMove) {
    throw UnimplementedError('Tango board renderer lands in U10.');
  }

  @override
  Widget renderHintField(Position position, Deduction deduction) {
    throw UnimplementedError('Tango hint field lands in U10/U11.');
  }
}
