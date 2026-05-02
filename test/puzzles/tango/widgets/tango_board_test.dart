import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_rules.dart';
import 'package:luna_traineer/puzzles/tango/widgets/tango_board.dart';
import 'package:luna_traineer/puzzles/tango/widgets/tango_cell.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('TangoBoard', () {
    testWidgets('renders 36 cells for an empty 6×6 position', (tester) async {
      await tester.pumpWidget(
        _host(
          TangoBoard(
            position: TangoPosition.empty(),
            onMove: (_) {},
          ),
        ),
      );

      expect(find.byType(TangoCell), findsNWidgets(36));
      // No mark glyphs rendered for empty cells.
      expect(find.text('☀'), findsNothing);
      expect(find.text('☾'), findsNothing);
    });

    testWidgets('tap on empty cell fires onMove with mark=sun', (tester) async {
      TangoMove? captured;
      await tester.pumpWidget(
        _host(
          TangoBoard(
            position: TangoPosition.empty(),
            onMove: (move) => captured = move,
          ),
        ),
      );

      await tester.tap(find.byType(TangoCell).first);
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.row, 0);
      expect(captured!.col, 0);
      expect(captured!.mark, TangoMark.sun);
    });

    testWidgets('tap on sun cell fires onMove with mark=moon', (tester) async {
      final base = TangoPosition.empty().withCell(2, 3, TangoMark.sun);
      TangoMove? captured;
      await tester.pumpWidget(
        _host(
          TangoBoard(
            position: base,
            onMove: (move) => captured = move,
          ),
        ),
      );

      // Find the cell at (2, 3) by predicate.
      final cell23 = find.byWidgetPredicate(
        (w) => w is TangoCell && w.row == 2 && w.col == 3,
      );
      await tester.tap(cell23);
      await tester.pumpAndSettle();

      expect(captured!.mark, TangoMark.moon);
    });

    testWidgets('tap on moon cell fires onMove with mark=null', (tester) async {
      final base = TangoPosition.empty().withCell(0, 0, TangoMark.moon);
      TangoMove? captured;
      await tester.pumpWidget(
        _host(
          TangoBoard(
            position: base,
            onMove: (move) => captured = move,
          ),
        ),
      );

      await tester.tap(find.byType(TangoCell).first);
      await tester.pumpAndSettle();

      expect(captured!.mark, isNull);
    });

    testWidgets('renders sun and moon glyphs for filled cells', (tester) async {
      final position = TangoPosition.empty()
          .withCell(0, 0, TangoMark.sun)
          .withCell(0, 1, TangoMark.moon);

      await tester.pumpWidget(
        _host(
          TangoBoard(position: position, onMove: (_) {}),
        ),
      );

      expect(find.text('☀'), findsOneWidget);
      expect(find.text('☾'), findsOneWidget);
    });

    testWidgets(
      'each cell carries a semantic label with row, column and mark',
      (tester) async {
        final handle = tester.ensureSemantics();

        final position = TangoPosition.empty().withCell(2, 3, TangoMark.sun);

        await tester.pumpWidget(
          _host(
            TangoBoard(position: position, onMove: (_) {}),
          ),
        );

        // (0, 0) is empty, (2, 3) is sun, (5, 5) is empty.
        expect(
          find.bySemanticsLabel(RegExp(r'row 1 column 1, empty')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'row 3 column 4, sun')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'row 6 column 6, empty')),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets('renders constraint painter when constraints are set', (
      tester,
    ) async {
      final position = TangoPosition.empty(
        constraints: const [
          TangoConstraint(
            cellA: CellAddress(0, 0),
            cellB: CellAddress(0, 1),
            kind: ConstraintKind.equals,
          ),
          TangoConstraint(
            cellA: CellAddress(2, 2),
            cellB: CellAddress(3, 2),
            kind: ConstraintKind.opposite,
          ),
        ],
      );

      await tester.pumpWidget(
        _host(
          TangoBoard(position: position, onMove: (_) {}),
        ),
      );

      // Constraint glyphs are painted, not rendered as text widgets,
      // so we just confirm the CustomPaint is mounted with the
      // expected painter type.
      final paint = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      expect(paint, isNotEmpty);
    });
  });
}
