import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/features/full_game/band_rotator.dart';
import 'package:luna_traineer/puzzles/tango/generator/difficulty_band.dart';

/// Builds a `recentBands` loader that returns a fixed history and
/// records how many times it was called — lets us assert that
/// hydration happens exactly once.
({RecentBandsLoader loader, int Function() callCount}) _stubLoader(
  List<DifficultyBand> history,
) {
  var calls = 0;
  Future<List<DifficultyBand>> load({int limit = 5}) async {
    calls++;
    return history.take(limit).toList();
  }

  return (loader: load, callCount: () => calls);
}

void main() {
  group('BandRotator', () {
    test('cold-start (empty history) never returns currentBand', () async {
      final stub = _stubLoader(const []);
      final rotator = BandRotator(
        loadRecentBands: stub.loader,
        random: Random(42),
      );

      final next = await rotator.next(DifficultyBand.medium);

      expect(next, isNot(DifficultyBand.medium));
      expect(stub.callCount(), 1);
    });

    test('process-kill survival: hydrates from history on first next()',
        () async {
      // Plan AE11 / process-kill survival scenario: recentBands returns
      // [2, 1, 3, 2] (newest first) → freshly-constructed rotator must
      // use that history, not cold-start.
      final stub = _stubLoader(const [
        DifficultyBand.medium,
        DifficultyBand.easy,
        DifficultyBand.hard,
        DifficultyBand.medium,
      ]);
      final rotator = BandRotator(
        loadRecentBands: stub.loader,
        random: Random(7),
      );

      final next = await rotator.next(DifficultyBand.medium);

      // R34 round-robin invariant: never the band just played.
      expect(next, isNot(DifficultyBand.medium));
      expect(next == DifficultyBand.easy || next == DifficultyBand.hard, isTrue);
    });

    test('hydrates exactly once across many next() calls', () async {
      final stub = _stubLoader(const [DifficultyBand.medium]);
      final rotator = BandRotator(
        loadRecentBands: stub.loader,
        random: Random(0),
      );

      var current = DifficultyBand.medium;
      for (var i = 0; i < 5; i++) {
        current = await rotator.next(current);
      }

      expect(stub.callCount(), 1);
    });

    test('seeded random → deterministic sequence', () async {
      Future<List<DifficultyBand>> sequence(int seed) async {
        final stub = _stubLoader(const []);
        final rotator = BandRotator(
          loadRecentBands: stub.loader,
          random: Random(seed),
        );
        final out = <DifficultyBand>[];
        var current = DifficultyBand.medium;
        for (var i = 0; i < 20; i++) {
          current = await rotator.next(current);
          out.add(current);
        }
        return out;
      }

      expect(await sequence(123), await sequence(123));
    });

    test('round-robin invariant: never returns the same band twice in a row',
        () async {
      // The "no 3-in-a-row over 10 calls" requirement is implied by the
      // strictly stronger "never repeat current" invariant — assert that
      // directly across a long horizon and many seeds.
      for (var seed = 0; seed < 8; seed++) {
        final stub = _stubLoader(const []);
        final rotator = BandRotator(
          loadRecentBands: stub.loader,
          random: Random(seed),
        );
        var current = DifficultyBand.medium;
        for (var i = 0; i < 30; i++) {
          final next = await rotator.next(current);
          expect(
            next,
            isNot(current),
            reason: 'seed=$seed step=$i: rotator must not repeat current band',
          );
          current = next;
        }
      }
    });

    test('explores all three bands over a long horizon', () async {
      // Round-robin should visit every band, not get stuck on two values.
      final stub = _stubLoader(const []);
      final rotator = BandRotator(
        loadRecentBands: stub.loader,
        random: Random(11),
      );
      final visited = <DifficultyBand>{};
      var current = DifficultyBand.medium;
      for (var i = 0; i < 50; i++) {
        current = await rotator.next(current);
        visited.add(current);
      }
      expect(visited, {
        DifficultyBand.easy,
        DifficultyBand.medium,
        DifficultyBand.hard,
      });
    });
  });
}
