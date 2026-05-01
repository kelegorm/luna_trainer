import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/generator/board_shape.dart';
import 'package:luna_traineer/puzzles/tango/generator/diversity_filter.dart';
import 'package:luna_traineer/puzzles/tango/generator/mix_histogram.dart';
import 'package:luna_traineer/puzzles/tango/generator/tango_puzzle.dart';

TangoPuzzle _puzzleFromInitial(
  TangoPosition initial, {
  BoardShape? shape,
  int seed = 0,
}) {
  final s = shape ?? BoardShape.singleRow();
  return TangoPuzzle(
    initialPosition: initial,
    solution: initial,
    shape: s,
    histogram: const MixHistogram({}),
    seed: seed,
  );
}

TangoPosition _seedRow(List<TangoMark?> row) {
  final cells = List<List<TangoMark?>>.generate(
    kTangoBoardSize,
    (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
  );
  for (var c = 0; c < kTangoBoardSize; c++) {
    cells[0][c] = row[c];
  }
  return TangoPosition(cells: cells, constraints: const []);
}

void main() {
  group('DiversityFilter', () {
    test('accepts a fresh puzzle when buffer is empty', () {
      final filter = DiversityFilter();
      final puzzle = _puzzleFromInitial(_seedRow(const [
        TangoMark.sun, null, null, null, null, null,
      ]));
      expect(filter.accepts(puzzle), isTrue);
    });

    test('rejects an identical puzzle after recording', () {
      final filter = DiversityFilter();
      final puzzle = _puzzleFromInitial(_seedRow(const [
        TangoMark.sun, null, null, null, null, null,
      ]));
      filter.record(puzzle);
      expect(filter.accepts(puzzle), isFalse);
    });

    test('accepts a sufficiently different puzzle after recording', () {
      final filter = DiversityFilter(minDistance: 0.2);
      final a = _puzzleFromInitial(_seedRow(const [
        TangoMark.sun, TangoMark.moon, TangoMark.sun, null, null, null,
      ]));
      final b = _puzzleFromInitial(_seedRow(const [
        null, null, null, TangoMark.moon, TangoMark.sun, TangoMark.moon,
      ]));
      filter.record(a);
      expect(filter.accepts(b), isTrue);
    });

    test('rolling buffer drops oldest after bufferSize records', () {
      // Lower threshold — the puzzles below differ by only one cell
      // each, so the absolute Hamming distance is small.
      final filter = DiversityFilter(bufferSize: 3, minDistance: 0.05);
      final puzzles = <TangoPuzzle>[];
      for (var i = 0; i < 5; i++) {
        // Each puzzle marks a different cell — all far apart enough to
        // both accept and not collide.
        final cells = List<List<TangoMark?>>.generate(
          kTangoBoardSize,
          (_) => List<TangoMark?>.filled(kTangoBoardSize, null),
        );
        cells[0][i] = TangoMark.sun;
        puzzles.add(_puzzleFromInitial(
          TangoPosition(cells: cells, constraints: const []),
          seed: i,
        ));
        filter.record(puzzles.last);
      }
      expect(filter.bufferLength, 3);
      // The first two puzzles should have been forgotten — recording
      // them again is fine.
      expect(filter.accepts(puzzles[0]), isTrue);
      // The most recent one is still in buffer, so it's rejected.
      expect(filter.accepts(puzzles[4]), isFalse);
    });
  });
}
