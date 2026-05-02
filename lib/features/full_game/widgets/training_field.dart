import 'package:flutter/material.dart';

import '../../../puzzles/tango/domain/tango_constraint.dart';
import '../../../puzzles/tango/domain/tango_position.dart';
import '../../../puzzles/tango/solver/tango_deduction.dart';
import '../../../puzzles/tango/widgets/tango_board.dart';

/// Учебная мини-доска для F3 step 2 — показывает preconditions
/// дедукции на отдельном поле, чтобы не пачкать основную партию (R12).
///
/// Read-only: tap-callback NOOP. Положение `position` берётся как
/// snapshot основной доски в момент открытия лесенки; в overlay-е этот
/// виджет рендерится с подсветкой клеток из [deduction.forcedCells].
class TrainingField extends StatelessWidget {
  const TrainingField({
    super.key,
    required this.position,
    required this.deduction,
  });

  final TangoPosition position;
  final TangoDeduction deduction;

  @override
  Widget build(BuildContext context) {
    final highlighted = <CellAddress>{...deduction.forcedCells};
    return Stack(
      children: [
        TangoBoard(
          position: position,
          onMove: (_) {},
        ),
        // Overlay-painter подсветки. IgnorePointer пропускает таппы
        // (которые TangoBoard всё равно игнорит за счёт NOOP onMove).
        IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _HighlightPainter(
                  rows: position.cells.length,
                  cols: position.cells.isEmpty ? 0 : position.cells[0].length,
                  highlighted: highlighted,
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.35),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.rows,
    required this.cols,
    required this.highlighted,
    required this.color,
  });

  final int rows;
  final int cols;
  final Set<CellAddress> highlighted;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows == 0 || cols == 0) return;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final paint = Paint()..color = color;
    for (final cell in highlighted) {
      final rect = Rect.fromLTWH(
        cell.col * cellW,
        cell.row * cellH,
        cellW,
        cellH,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter old) {
    return old.highlighted != highlighted ||
        old.color != color ||
        old.rows != rows ||
        old.cols != cols;
  }
}
