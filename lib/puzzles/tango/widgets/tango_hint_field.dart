import 'package:flutter/material.dart';

import '../domain/tango_constraint.dart';
import '../domain/tango_position.dart';
import '../solver/tango_deduction.dart';
import 'tango_board.dart';

/// Read-only mini-board that highlights the cells a [TangoDeduction]
/// forces. Used for hint ladder step 2 (F3 / R12) so the precondition
/// is shown on a separate field without dirtying the main board.
///
/// Reachable through `TangoPuzzleKind.renderHintField` (R26) — the
/// engine never imports this widget directly.
class TangoHintField extends StatelessWidget {
  const TangoHintField({
    super.key,
    required this.position,
    required this.deduction,
  });

  final TangoPosition position;
  final TangoDeduction deduction;

  @override
  Widget build(BuildContext context) {
    final highlighted = <CellAddress>{...deduction.forcedCells};
    final rows = position.cells.length;
    final cols = position.cells.isEmpty ? 0 : position.cells[0].length;
    // Match TangoBoard's AspectRatio so the highlight overlay shares
    // bounded constraints with the board it covers.
    return AspectRatio(
      aspectRatio: cols == 0 || rows == 0 ? 1 : cols / rows,
      child: Stack(
        children: [
          Positioned.fill(
            child: TangoBoard(position: position, onMove: (_) {}),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HighlightPainter(
                  rows: rows,
                  cols: cols,
                  highlighted: highlighted,
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
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
