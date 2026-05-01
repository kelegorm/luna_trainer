import 'package:equatable/equatable.dart';

import '../domain/tango_position.dart';
import 'board_shape.dart';
import 'mix_histogram.dart';

/// A single generated Tango puzzle bundle.
///
/// `initialPosition` ships with the seed marks/constraints the player
/// sees; `solution` is the unique completion of those seeds under
/// [shape]. Inactive cells (outside `shape.activeCells`) are `null` in
/// both positions.
class TangoPuzzle extends Equatable {
  const TangoPuzzle({
    required this.initialPosition,
    required this.solution,
    required this.shape,
    required this.histogram,
    required this.seed,
  });

  final TangoPosition initialPosition;
  final TangoPosition solution;
  final BoardShape shape;
  final MixHistogram histogram;
  final int seed;

  @override
  List<Object?> get props => [
        initialPosition,
        solution,
        shape.kind,
        histogram,
        seed,
      ];
}
