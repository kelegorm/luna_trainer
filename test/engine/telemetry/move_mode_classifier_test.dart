import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/telemetry/move_mode_classifier.dart';

PreviousMoveContext prev({
  required int row,
  required int col,
  required int atMs,
}) {
  return PreviousMoveContext(
    row: row,
    col: col,
    at: DateTime.fromMillisecondsSinceEpoch(atMs),
  );
}

void main() {
  group('MoveModeClassifier', () {
    test('first move (no previous) is hunt', () {
      final mode = MoveModeClassifier.classify(
        previous: null,
        currentRow: 3,
        currentCol: 4,
        currentAt: DateTime.fromMillisecondsSinceEpoch(0),
        previousConnectedBySign: false,
      );
      expect(mode, MoveMode.hunt);
    });

    test('adjacent cell (Chebyshev ≤ 1) within Δt=5s → propagation', () {
      // (2,3) → (3,4): king-neighbour.
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 2, col: 3, atMs: 0),
        currentRow: 3,
        currentCol: 4,
        currentAt: DateTime.fromMillisecondsSinceEpoch(2000),
        previousConnectedBySign: false,
      );
      expect(mode, MoveMode.propagation);
    });

    test('orthogonal neighbour with Δt=2s → propagation', () {
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 0, col: 0, atMs: 0),
        currentRow: 0,
        currentCol: 1,
        currentAt: DateTime.fromMillisecondsSinceEpoch(2000),
        previousConnectedBySign: false,
      );
      expect(mode, MoveMode.propagation);
    });

    test('far cell (Δrow=3, Δcol=0) within 8s → hunt', () {
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 0, col: 0, atMs: 0),
        currentRow: 3,
        currentCol: 0,
        currentAt: DateTime.fromMillisecondsSinceEpoch(8000),
        previousConnectedBySign: false,
      );
      expect(mode, MoveMode.hunt);
    });

    test('non-adjacent but sign-connected (=) within Δt=3s → propagation', () {
      // (0,0) and (5,5) — нет смежности, но по знаку = (R31).
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 0, col: 0, atMs: 0),
        currentRow: 5,
        currentCol: 5,
        currentAt: DateTime.fromMillisecondsSinceEpoch(3000),
        previousConnectedBySign: true,
      );
      expect(mode, MoveMode.propagation);
    });

    test('adjacent cell but Δt > 5s → hunt (slow scan, not propagation)',
        () {
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 1, col: 1, atMs: 0),
        currentRow: 1,
        currentCol: 2,
        currentAt: DateTime.fromMillisecondsSinceEpoch(5001),
        previousConnectedBySign: false,
      );
      expect(mode, MoveMode.hunt);
    });

    test('exactly Δt=5000ms is propagation (≤ boundary inclusive)', () {
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 1, col: 1, atMs: 0),
        currentRow: 1,
        currentCol: 2,
        currentAt: DateTime.fromMillisecondsSinceEpoch(5000),
        previousConnectedBySign: false,
      );
      expect(mode, MoveMode.propagation);
    });

    test('Chebyshev=1 diagonal qualifies (not just orthogonal)', () {
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 2, col: 2, atMs: 0),
        currentRow: 3,
        currentCol: 3,
        currentAt: DateTime.fromMillisecondsSinceEpoch(1000),
        previousConnectedBySign: false,
      );
      expect(mode, MoveMode.propagation);
    });

    test('Chebyshev=2 (knight-leap) is not adjacent → hunt without sign',
        () {
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 0, col: 0, atMs: 0),
        currentRow: 2,
        currentCol: 2,
        currentAt: DateTime.fromMillisecondsSinceEpoch(1000),
        previousConnectedBySign: false,
      );
      expect(mode, MoveMode.hunt);
    });

    test('sign-connected but Δt > 5s → hunt (time threshold dominates)',
        () {
      final mode = MoveModeClassifier.classify(
        previous: prev(row: 0, col: 0, atMs: 0),
        currentRow: 5,
        currentCol: 5,
        currentAt: DateTime.fromMillisecondsSinceEpoch(6000),
        previousConnectedBySign: true,
      );
      expect(mode, MoveMode.hunt);
    });
  });

  group('MoveModeWire', () {
    test('round-trip wire strings stable', () {
      expect(MoveMode.propagation.wire, 'propagation');
      expect(MoveMode.hunt.wire, 'hunt');
    });
  });
}
