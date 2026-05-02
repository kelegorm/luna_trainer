import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/puzzle/puzzle_kind.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/solver/tango_deduction.dart';
import 'package:luna_traineer/puzzles/tango/tango_puzzle_kind.dart';
import 'package:luna_traineer/puzzles/tango/widgets/tango_board.dart';
import 'package:luna_traineer/puzzles/tango/widgets/tango_cell.dart';
import 'package:luna_traineer/puzzles/tango/widgets/tango_hint_field.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 300, height: 300, child: child)),
    );

void main() {
  group('TangoPuzzleKind.renderHintField (R26 / U10 amendment)', () {
    testWidgets('returns a TangoHintField wrapped over the board',
        (tester) async {
      const kind = TangoPuzzleKind();
      final position = TangoPosition.empty();
      const deduction = TangoDeduction(
        heuristic: Heuristic('tango', 'ParityFill'),
        forcedCells: [CellAddress(1, 2), CellAddress(1, 3)],
        forcedMark: TangoMark.sun,
      );

      await tester.pumpWidget(_host(kind.renderHintField(position, deduction)));

      expect(find.byType(TangoHintField), findsOneWidget);
      expect(find.byType(TangoBoard), findsOneWidget);
      expect(find.byType(TangoCell), findsNWidgets(36));
    });

    test('rejects non-Tango position', () {
      const kind = TangoPuzzleKind();
      const deduction = TangoDeduction(
        heuristic: Heuristic('tango', 'ParityFill'),
        forcedCells: [CellAddress(0, 0)],
        forcedMark: TangoMark.sun,
      );
      expect(
        () => kind.renderHintField(const _AlienPosition(), deduction),
        throwsArgumentError,
      );
    });
  });
}

class _AlienPosition extends Position {
  const _AlienPosition();
}
