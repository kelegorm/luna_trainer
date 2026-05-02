import 'package:flutter/widgets.dart';

import '../../engine/domain/heuristic.dart';
import '../../puzzle/puzzle_kind.dart';
import 'domain/tango_position.dart';
import 'generator/tango_level_generator.dart';
import 'solver/tango_solver.dart';
import 'widgets/tango_board.dart';

/// Catalog of MVP heuristics for Tango (R2). `Composite(unknown)` is
/// logged for diagnostics but not eligible for drill (R10).
///
/// Display names follow the concept taxonomy in
/// `docs/tango_trainer_concept_addendum.md` §1 (R33). Engine-side `tagId`s
/// stay machine-readable; the player-facing label is the `displayName`.
///
/// `AdvancedMidLineInference` is sub-classified for drill (R30): the base
/// tag covers the original 2-empty enumeration ("прочее"), and the
/// `/edge_1_5` and `/edge_2_6` sub-tags name the canonical edge-trap
/// patterns so the drill planner can rotate each sub-form independently.
const _kTangoHeuristics = <HeuristicDescriptor>[
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'PairCompletion'),
    displayName: 'Запрет тройки (зазор)',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'TrioAvoidance'),
    displayName: 'Запрет тройки (пара)',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'ParityFill'),
    displayName: 'Баланс линии',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'SignPropagation'),
    displayName: 'Распространение знака',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'AdvancedMidLineInference'),
    displayName: 'Mid-line вывод',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'AdvancedMidLineInference/edge_1_5'),
    displayName: 'Краевая ловушка 1–5',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'AdvancedMidLineInference/edge_2_6'),
    displayName: 'Краевая ловушка 2–6',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'ChainExtension'),
    displayName: 'Цепочка знаков',
    eligibleForDrill: true,
  ),
  HeuristicDescriptor(
    heuristic: Heuristic('tango', 'Composite(unknown)'),
    displayName: 'Композитный вывод',
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
    if (position is! TangoPosition) {
      throw ArgumentError(
        'TangoPuzzleKind.renderBoard expects a TangoPosition, '
        'got ${position.runtimeType}',
      );
    }
    return TangoBoard(position: position, onMove: onMove);
  }

  @override
  Widget renderHintField(Position position, Deduction deduction) {
    throw UnimplementedError('Tango hint field lands in U10/U11.');
  }
}
