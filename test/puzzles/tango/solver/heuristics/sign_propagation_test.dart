import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/solver/heuristics/sign_propagation.dart';

import '../fixtures/positions.dart';

void main() {
  group('SignPropagation', () {
    test('= constraint propagates same mark', () {
      final p = pos(
        'S_____' '______' '______' '______' '______' '______',
        constraints: [eq(0, 0, 0, 1)],
      );
      final d = const SignPropagation().apply(p).single;
      expect(d.forcedMark, TangoMark.sun);
      expect(d.forcedCells, [const CellAddress(0, 1)]);
    });

    test('× constraint propagates opposite mark', () {
      final p = pos(
        'S_____' '______' '______' '______' '______' '______',
        constraints: [xx(0, 0, 0, 1)],
      );
      final d = const SignPropagation().apply(p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells, [const CellAddress(0, 1)]);
    });

    test('vertical = constraint between rows', () {
      final p = pos(
        'M_____' '______' '______' '______' '______' '______',
        constraints: [eq(0, 0, 1, 0)],
      );
      final d = const SignPropagation().apply(p).single;
      expect(d.forcedMark, TangoMark.moon);
      expect(d.forcedCells, [const CellAddress(1, 0)]);
    });

    test('does not fire when both endpoints are empty', () {
      final p = pos(
        '______' '______' '______' '______' '______' '______',
        constraints: [eq(0, 0, 0, 1)],
      );
      expect(const SignPropagation().apply(p), isEmpty);
    });

    test('does not fire when both endpoints are filled', () {
      final p = pos(
        'SS____' '______' '______' '______' '______' '______',
        constraints: [eq(0, 0, 0, 1)],
      );
      expect(const SignPropagation().apply(p), isEmpty);
    });

    test('multiple constraints fire independently', () {
      final p = pos(
        'S_____' 'M_____' '______' '______' '______' '______',
        constraints: [
          eq(0, 0, 0, 1),
          xx(1, 0, 1, 1),
        ],
      );
      final ded = const SignPropagation().apply(p).toList();
      expect(ded.length, 2);
      final byCell = {for (final d in ded) d.forcedCells.single: d.forcedMark};
      expect(byCell[const CellAddress(0, 1)], TangoMark.sun);
      expect(byCell[const CellAddress(1, 1)], TangoMark.sun);
    });
  });
}
