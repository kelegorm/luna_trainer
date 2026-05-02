import 'package:flutter/material.dart';

import '../domain/tango_position.dart';
import '../domain/tango_rules.dart';
import 'tango_cell.dart';
import 'tango_constraint_painter.dart';
import 'tango_input_handler.dart';

/// A Tango board renderer.
///
/// Stateless by design — the parent owns the position and rebuilds the
/// board after each [onMove]. The widget reads grid dimensions from
/// `position.cells`, so the same widget renders both full 6×6 boards
/// and drill fragments (e.g. 2×4) once the position type carries them.
///
/// Carries no progress / mastery indicators (R22). The constraint
/// painter is overlaid on top of the cells so `=` / `×` signs land on
/// the edges shared by the two adjacent cells they refer to.
class TangoBoard extends StatelessWidget {
  const TangoBoard({
    super.key,
    required this.position,
    required this.onMove,
  });

  final TangoPosition position;
  final void Function(TangoMove move) onMove;

  int get _rows => position.cells.length;
  int get _cols => position.cells.isEmpty ? 0 : position.cells[0].length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: _cols / _rows,
      child: Stack(
        children: [
          Positioned.fill(child: _grid()),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: TangoConstraintPainter(
                  constraints: position.constraints,
                  rows: _rows,
                  cols: _cols,
                  equalsColor: colors.tertiary,
                  oppositeColor: colors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid() {
    return Column(
      children: [
        for (var r = 0; r < _rows; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < _cols; c++)
                  Expanded(
                    child: TangoCell(
                      row: r,
                      col: c,
                      mark: position.cells[r][c],
                      onTap: () => onMove(
                        TangoMove(
                          row: r,
                          col: c,
                          mark: nextTangoMark(position.cells[r][c]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
