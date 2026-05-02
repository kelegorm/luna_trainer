import 'package:flutter/material.dart';

import '../domain/tango_mark.dart';

/// A single Tango cell. Renders the current [mark] (or empty) and
/// fires [onTap] on tap. Mark cycling is the parent's responsibility
/// (see `nextTangoMark`).
///
/// Carries a Semantics label of the form
/// `"row R column C, sun|moon|empty"` so screen readers can describe
/// the board state without poking at internals (R22 is about UI
/// indicators of mastery, not a11y — accessibility stays).
class TangoCell extends StatelessWidget {
  const TangoCell({
    super.key,
    required this.row,
    required this.col,
    required this.mark,
    required this.onTap,
  });

  final int row;
  final int col;
  final TangoMark? mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'row ${row + 1} column ${col + 1}, ${_markLabel(mark)}',
      button: true,
      container: true,
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Center(
            child: _MarkGlyph(mark: mark),
          ),
        ),
      ),
    );
  }
}

class _MarkGlyph extends StatelessWidget {
  const _MarkGlyph({required this.mark});

  final TangoMark? mark;

  @override
  Widget build(BuildContext context) {
    if (mark == null) return const SizedBox.shrink();
    return Text(
      mark == TangoMark.sun ? '☀' : '☾',
      style: const TextStyle(fontSize: 28),
    );
  }
}

String _markLabel(TangoMark? mark) {
  switch (mark) {
    case null:
      return 'empty';
    case TangoMark.sun:
      return 'sun';
    case TangoMark.moon:
      return 'moon';
  }
}
