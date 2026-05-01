import 'package:equatable/equatable.dart';

/// A namespaced identifier for a single deduction technique.
///
/// `kindId` partitions techniques across puzzle kinds so that
/// `Heuristic('tango', 'ParityFill')` is distinct from
/// `Heuristic('queens', 'ParityFill')`. The engine never inspects
/// `tagId` semantically — it only uses `Heuristic` as a key for
/// telemetry, mastery state, and FSRS cards.
class Heuristic extends Equatable {
  const Heuristic(this.kindId, this.tagId);

  final String kindId;
  final String tagId;

  @override
  List<Object?> get props => [kindId, tagId];

  @override
  String toString() => 'Heuristic($kindId/$tagId)';
}
