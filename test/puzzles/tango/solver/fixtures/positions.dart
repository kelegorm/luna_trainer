import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';

const TangoMark s = TangoMark.sun;
const TangoMark m = TangoMark.moon;

/// Build a 6×6 [TangoPosition] from a single string of length 36.
///
/// Characters: `S` = sun, `M` = moon, `_` (or `.`) = empty. Whitespace
/// is ignored so callers can use multi-line strings for legibility.
TangoPosition pos(
  String spec, {
  List<TangoConstraint> constraints = const [],
}) {
  final clean = spec.replaceAll(RegExp(r'\s+'), '');
  if (clean.length != 36) {
    throw ArgumentError(
      'Tango position spec must encode 36 cells, got ${clean.length}: '
      '"$spec"',
    );
  }
  final cells = <List<TangoMark?>>[];
  for (var r = 0; r < 6; r++) {
    final row = <TangoMark?>[];
    for (var c = 0; c < 6; c++) {
      final ch = clean[r * 6 + c];
      switch (ch) {
        case 'S':
          row.add(TangoMark.sun);
        case 'M':
          row.add(TangoMark.moon);
        case '_':
        case '.':
          row.add(null);
        default:
          throw ArgumentError('Unknown cell char "$ch" in "$spec"');
      }
    }
    cells.add(row);
  }
  return TangoPosition(cells: cells, constraints: constraints);
}

/// Convenience for an `=` constraint between two adjacent cells.
TangoConstraint eq(int rA, int cA, int rB, int cB) => TangoConstraint(
      cellA: CellAddress(rA, cA),
      cellB: CellAddress(rB, cB),
      kind: ConstraintKind.equals,
    );

/// Convenience for a `×` constraint between two adjacent cells.
TangoConstraint xx(int rA, int cA, int rB, int cB) => TangoConstraint(
      cellA: CellAddress(rA, cA),
      cellB: CellAddress(rB, cB),
      kind: ConstraintKind.opposite,
    );
