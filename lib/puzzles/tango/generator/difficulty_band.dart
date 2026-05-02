/// Difficulty band for a single Tango full-game session (R34, R36).
///
/// The integer payload is the on-disk representation persisted in
/// `sessions.difficulty_band` / `move_events.difficulty_band` (1=easy,
/// 2=medium, 3=hard). The default for a fresh user session is [medium];
/// the band rotator (U11) bumps it up/down on user feedback.
enum DifficultyBand {
  easy(1),
  medium(2),
  hard(3);

  const DifficultyBand(this.value);

  /// On-disk integer code. Stable across versions — do not renumber.
  final int value;

  /// Maps an arbitrary `int` (e.g. read from disk) into a band, clamping
  /// out-of-range values to the nearest legal band. Defensive against
  /// stale rows / migration bugs.
  static DifficultyBand clamp(int raw) {
    if (raw <= 1) return DifficultyBand.easy;
    if (raw >= 3) return DifficultyBand.hard;
    return DifficultyBand.medium;
  }

  /// Returns the next-harder band, or `this` if already [hard].
  ///
  /// Used by U11 post-session "harder, please" button.
  DifficultyBand bumpUp() {
    switch (this) {
      case DifficultyBand.easy:
        return DifficultyBand.medium;
      case DifficultyBand.medium:
        return DifficultyBand.hard;
      case DifficultyBand.hard:
        return DifficultyBand.hard;
    }
  }

  /// Returns the next-easier band, or `this` if already [easy].
  ///
  /// Used by U11 post-session "easier, please" button.
  DifficultyBand bumpDown() {
    switch (this) {
      case DifficultyBand.easy:
        return DifficultyBand.easy;
      case DifficultyBand.medium:
        return DifficultyBand.easy;
      case DifficultyBand.hard:
        return DifficultyBand.medium;
    }
  }
}
