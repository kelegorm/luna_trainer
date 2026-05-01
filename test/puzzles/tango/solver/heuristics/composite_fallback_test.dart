import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_constraint.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/solver/heuristics/composite_fallback.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';

import '../fixtures/positions.dart';

void main() {
  group('CompositeFallback', () {
    test('produces forced cells when a unique line completion exists', () {
      // Row 0: S S _ M _ M — unique completion is moon at (0,2) and
      // sun at (0,4). Columns mostly empty, beyond cap.
      final p = pos('SS_M_M' '______' '______' '______' '______' '______');
      final ded = const CompositeFallback().apply(p).toList();
      const tag = Heuristic('tango', 'Composite(unknown)');
      final rowDeds = ded.where((d) => d.heuristic == tag).toList();
      expect(rowDeds, isNotEmpty);
      final placements = <CellAddress, TangoMark>{};
      for (final d in rowDeds) {
        for (final c in d.forcedCells) {
          placements[c] = d.forcedMark;
        }
      }
      expect(placements[const CellAddress(0, 2)], TangoMark.moon);
      expect(placements[const CellAddress(0, 4)], TangoMark.sun);
    });

    test('returns empty when every line has too many empties', () {
      // Empty board: every line has 6 empties (> max 4). Should be
      // empty.
      final p = pos('______' '______' '______' '______' '______' '______');
      expect(const CompositeFallback().apply(p), isEmpty);
    });

    test('respects in-line = constraints', () {
      // Row: S _ _ _ M _ with `=` between (0,1) and (0,2). 4 empties.
      // Survivors: assignment must keep counts <=3 each, no triples,
      // and (0,1)==(0,2).
      // Try S _ _ _ M _ candidates with empties at 1,2,3,5:
      //   (1=2)=S,3=S — but then row [S S S _ M _] has triple → out
      //   (1=2)=S,3=M,5=S → S S S? indices 0,1,2 = S S S → triple
      //   so (1=2)=M permitted: S M M _ M _ counts: 1S+3M+ remaining
      //   3 must be S, 5 must be S → SMMSMS. counts 3S/3M, no triple,
      //   constraint M=M ok. unique survivor.
      final p = pos(
        'S___M_' '______' '______' '______' '______' '______',
        constraints: [eq(0, 1, 0, 2)],
      );
      final ded = const CompositeFallback().apply(p).toList();
      const tag = Heuristic('tango', 'Composite(unknown)');
      final rowDeds = ded.where((d) => d.heuristic == tag).toList();
      expect(rowDeds, isNotEmpty);
      final placements = <CellAddress, TangoMark>{};
      for (final d in rowDeds) {
        for (final c in d.forcedCells) {
          placements[c] = d.forcedMark;
        }
      }
      expect(placements[const CellAddress(0, 1)], TangoMark.moon);
      expect(placements[const CellAddress(0, 2)], TangoMark.moon);
      expect(placements[const CellAddress(0, 3)], TangoMark.sun);
      expect(placements[const CellAddress(0, 5)], TangoMark.sun);
    });

    test('does nothing on a fully solved row', () {
      // Row: S S M S M M  — 6 cells filled.
      // Build full solved board so other rows don't conflict.
      final p = pos(
        'SSMSMM' 'MMSMSS' 'SMMSSM' 'MSSMMS' 'SMSMSM' 'MSMSMS',
      );
      // CompositeFallback returns nothing on lines with 0 empties.
      // (Other lines also have 0 empties, so total empty.)
      expect(const CompositeFallback().apply(p), isEmpty);
    });

    test('handles 2-empties unique completion (sun at one cell)', () {
      // Row: S M S M S _ : counts 3S+2M, last cell must be M.
      final p = pos('SMSMS_' '______' '______' '______' '______' '______');
      final ded = const CompositeFallback().apply(p).toList();
      const tag = Heuristic('tango', 'Composite(unknown)');
      final rowDeds = ded.where((d) => d.heuristic == tag).toList();
      expect(rowDeds, isNotEmpty);
      // Just verify (0,5) → moon appears.
      var saw = false;
      for (final d in rowDeds) {
        if (d.forcedMark == TangoMark.moon &&
            d.forcedCells.contains(const CellAddress(0, 5))) {
          saw = true;
        }
      }
      expect(saw, isTrue);
    });

    test('emits Composite(unknown) heuristic tag', () {
      final p = pos('SS_M_M' '______' '______' '______' '______' '______');
      final ded = const CompositeFallback().apply(p).toList();
      expect(ded, isNotEmpty);
      expect(
        ded.every(
          (d) => d.heuristic ==
              const Heuristic('tango', 'Composite(unknown)'),
        ),
        isTrue,
      );
    });
  });
}
