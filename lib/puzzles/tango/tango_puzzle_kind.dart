import 'package:flutter/widgets.dart';

import '../../engine/domain/heuristic.dart';
import '../../puzzle/puzzle_kind.dart';

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

class _TangoSolverStub extends Solver {
  const _TangoSolverStub();

  @override
  List<Deduction> availableDeductions(Position p) {
    throw UnimplementedError('Tango solver lands in U5.');
  }
}

class _TangoGeneratorStub extends LevelGenerator {
  const _TangoGeneratorStub();
}

class TangoPuzzleKind extends PuzzleKind {
  const TangoPuzzleKind();

  @override
  String get id => 'tango';

  @override
  List<HeuristicDescriptor> get heuristics => _kTangoHeuristics;

  @override
  Solver get solver => const _TangoSolverStub();

  @override
  LevelGenerator get generator => const _TangoGeneratorStub();

  @override
  Widget renderBoard(Position position, void Function(Move move) onMove) {
    throw UnimplementedError('Tango board renderer lands in U10.');
  }

  @override
  Widget renderHintField(Position position, Deduction deduction) {
    throw UnimplementedError('Tango hint field lands in U10/U11.');
  }
}
