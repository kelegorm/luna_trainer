import 'package:flutter/material.dart';

import '../domain/tango_constraint.dart';

/// Paints `=` (equals) and `×` (opposite) signs centered on the edge
/// between two adjacent Tango cells.
///
/// The painter assumes a uniform [rows] × [cols] grid laid out flush
/// inside [Size]. It draws over the grid; the cells render their own
/// borders and marks underneath.
class TangoConstraintPainter extends CustomPainter {
  TangoConstraintPainter({
    required this.constraints,
    required this.rows,
    required this.cols,
    required this.equalsColor,
    required this.oppositeColor,
  });

  final List<TangoConstraint> constraints;
  final int rows;
  final int cols;
  final Color equalsColor;
  final Color oppositeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || cols <= 0) return;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final glyphSize = (cellW < cellH ? cellW : cellH) * 0.32;

    for (final c in constraints) {
      final mid = _edgeMidpoint(c, cellW, cellH);
      if (mid == null) continue;
      final color = c.kind == ConstraintKind.equals
          ? equalsColor
          : oppositeColor;
      _drawGlyph(canvas, mid, glyphSize, c.kind, color);
    }
  }

  Offset? _edgeMidpoint(TangoConstraint c, double cellW, double cellH) {
    final ax = c.cellA.col * cellW + cellW / 2;
    final ay = c.cellA.row * cellH + cellH / 2;
    final bx = c.cellB.col * cellW + cellW / 2;
    final by = c.cellB.row * cellH + cellH / 2;
    final dr = (c.cellA.row - c.cellB.row).abs();
    final dc = (c.cellA.col - c.cellB.col).abs();
    if (dr + dc != 1) return null;
    return Offset((ax + bx) / 2, (ay + by) / 2);
  }

  void _drawGlyph(
    Canvas canvas,
    Offset center,
    double glyphSize,
    ConstraintKind kind,
    Color color,
  ) {
    final text = kind == ConstraintKind.equals ? '=' : '×';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: glyphSize,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bg = Paint()..color = const Color(0xFF101010);
    final radius = glyphSize * 0.55;
    canvas.drawCircle(center, radius, bg);

    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant TangoConstraintPainter old) =>
      old.constraints != constraints ||
      old.rows != rows ||
      old.cols != cols ||
      old.equalsColor != equalsColor ||
      old.oppositeColor != oppositeColor;
}
