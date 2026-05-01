import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';

void main() {
  group('TangoPosition', () {
    test('empty() builds a 6x6 grid of nulls', () {
      final p = TangoPosition.empty();
      expect(p.cells.length, kTangoBoardSize);
      for (final row in p.cells) {
        expect(row.length, kTangoBoardSize);
        expect(row.every((c) => c == null), isTrue);
      }
      expect(p.constraints, isEmpty);
    });

    test('empty() carries the supplied constraints', () {
      const c = TangoConstraint(
        cellA: CellAddress(0, 0),
        cellB: CellAddress(0, 1),
        kind: ConstraintKind.equals,
      );
      final p = TangoPosition.empty(constraints: [c]);
      expect(p.constraints, [c]);
    });

    test('withCell returns a new object and does not mutate the original',
        () {
      final orig = TangoPosition.empty();
      final next = orig.withCell(2, 3, TangoMark.sun);

      expect(identical(orig, next), isFalse);
      expect(orig.cells[2][3], isNull);
      expect(next.cells[2][3], TangoMark.sun);
    });

    test('withCell preserves constraints', () {
      const c = TangoConstraint(
        cellA: CellAddress(0, 0),
        cellB: CellAddress(0, 1),
        kind: ConstraintKind.opposite,
      );
      final orig = TangoPosition.empty(constraints: [c]);
      final next = orig.withCell(0, 0, TangoMark.moon);
      expect(next.constraints, [c]);
    });

    test('positions with the same cells/constraints are equal', () {
      final a = TangoPosition.empty().withCell(1, 1, TangoMark.sun);
      final b = TangoPosition.empty().withCell(1, 1, TangoMark.sun);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('cells list is unmodifiable', () {
      final p = TangoPosition.empty();
      expect(() => p.cells[0][0] = TangoMark.sun, throwsUnsupportedError);
      expect(
        () => p.cells.add(List<TangoMark?>.filled(kTangoBoardSize, null)),
        throwsUnsupportedError,
      );
    });
  });
}
