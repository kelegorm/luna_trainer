import 'dart:math';

import '../../puzzles/tango/generator/difficulty_band.dart';

/// Loads the user's most-recent full-game `DifficultyBand`s, newest
/// first, capped at [limit]. Typically tear-off of
/// `SessionsRepository.recentBands`; abstracted as a function so
/// [BandRotator] stays a pure unit and is trivial to fake in tests.
typedef RecentBandsLoader = Future<List<DifficultyBand>> Function({int limit});

/// Picks the next [DifficultyBand] for the auto "Следующая" button at
/// end-of-session (R34, R37). Algorithm: round-robin over {1, 2, 3} with
/// ±1 jitter — preserves "explore all bands over time" while breaking
/// the deterministic 1→2→3→1 chain that users perceive as boring.
///
/// **Process-kill safety.** The internal step counter is hydrated lazily
/// from [RecentBandsLoader] on the first `next()` call. After Android
/// kills the app while it is backgrounded, the in-memory rotator is
/// reconstructed cold, but `sessions` rows survive in SQLite — so the
/// counter recovers from `history.length` and round-robin continues
/// roughly where it left off. Without this, every cold-start would
/// reset the counter to 0 and bias the user toward `easy` partitions.
///
/// **R34 invariant.** `next(currentBand)` never returns `currentBand`.
/// This implies the strictly weaker "no band 3 times in a row over any
/// horizon" property the plan calls out.
///
/// The algorithm is `Deferred to Implementation` per the plan and will
/// be revisited after ~2 weeks of real play.
class BandRotator {
  BandRotator({
    required RecentBandsLoader loadRecentBands,
    Random? random,
    int hydrationLimit = 5,
  })  : _loadRecentBands = loadRecentBands,
        _random = random ?? Random(),
        _hydrationLimit = hydrationLimit;

  final RecentBandsLoader _loadRecentBands;
  final Random _random;
  final int _hydrationLimit;

  int _step = 0;
  bool _hydrated = false;

  Future<DifficultyBand> next(DifficultyBand currentBand) async {
    if (!_hydrated) {
      final history = await _loadRecentBands(limit: _hydrationLimit);
      _step = history.length;
      _hydrated = true;
    }

    final base = (_step % 3) + 1;
    final jitter = _random.nextInt(3) - 1;
    var candidate = base + jitter;
    if (candidate < 1) candidate = 3;
    if (candidate > 3) candidate = 1;

    if (candidate == currentBand.value) {
      final others = <int>[1, 2, 3]..remove(currentBand.value);
      candidate = others[_random.nextInt(others.length)];
    }

    _step++;
    return DifficultyBand.clamp(candidate);
  }
}
