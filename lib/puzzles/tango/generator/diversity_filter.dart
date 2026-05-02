import 'dart:collection';

import '../domain/tango_constraint.dart';
import '../domain/tango_mark.dart';
import 'tango_puzzle.dart';

/// Bag-of-positions signature: four bit-vectors covering sun-cells,
/// moon-cells, equals-edges, opposite-edges. Hamming distance over the
/// concatenation gives a coarse but stable similarity metric.
class _PuzzleSignature {
  _PuzzleSignature(this.bits);

  factory _PuzzleSignature.of(TangoPuzzle puzzle) {
    final bits = <bool>[];

    // Initial board's sun/moon cells (seed clues only — solution would
    // make every puzzle look identical for a fixed shape).
    final init = puzzle.initialPosition;
    for (final a in puzzle.shape.activeCells) {
      final m = init.cells[a.row][a.col];
      bits.add(m == TangoMark.sun);
      bits.add(m == TangoMark.moon);
    }

    // Constraint placement bits: enumerate every possible adjacency in
    // the active set, then for each one record whether it has an `=`,
    // and whether it has an `×`.
    final adjacencies = _enumerateAdjacencies(puzzle.shape.activeCells);
    final equalsSet = <_Edge>{};
    final oppositeSet = <_Edge>{};
    for (final c in init.constraints) {
      final e = _Edge(c.cellA, c.cellB);
      switch (c.kind) {
        case ConstraintKind.equals:
          equalsSet.add(e);
        case ConstraintKind.opposite:
          oppositeSet.add(e);
      }
    }
    for (final adj in adjacencies) {
      bits.add(equalsSet.contains(adj));
      bits.add(oppositeSet.contains(adj));
    }

    return _PuzzleSignature(List.unmodifiable(bits));
  }

  final List<bool> bits;

  /// Hamming distance, normalised to [0, 1].
  double distance(_PuzzleSignature other) {
    if (bits.length != other.bits.length) {
      // Different shape → maximally different.
      return 1.0;
    }
    if (bits.isEmpty) return 0.0;
    var diff = 0;
    for (var i = 0; i < bits.length; i++) {
      if (bits[i] != other.bits[i]) diff++;
    }
    return diff / bits.length;
  }
}

/// Undirected edge between two cells. Used as a set key, so we
/// normalise the endpoint order.
class _Edge {
  _Edge(CellAddress a, CellAddress b)
      : _a = _min(a, b),
        _b = _max(a, b);

  final CellAddress _a;
  final CellAddress _b;

  static CellAddress _min(CellAddress a, CellAddress b) =>
      _key(a) <= _key(b) ? a : b;
  static CellAddress _max(CellAddress a, CellAddress b) =>
      _key(a) > _key(b) ? a : b;
  static int _key(CellAddress a) => a.row * 16 + a.col;

  @override
  bool operator ==(Object other) =>
      other is _Edge && other._a == _a && other._b == _b;

  @override
  int get hashCode => Object.hash(_a, _b);
}

List<_Edge> _enumerateAdjacencies(List<CellAddress> active) {
  final set = active.toSet();
  final out = <_Edge>[];
  for (final a in active) {
    for (final delta in const [
      [0, 1],
      [1, 0],
    ]) {
      final n = CellAddress(a.row + delta[0], a.col + delta[1]);
      if (set.contains(n)) out.add(_Edge(a, n));
    }
  }
  return out;
}

/// Stateful filter that rejects puzzles too similar (in the bag-of-
/// positions metric) to any of the last 50 accepted ones.
///
/// Pure in-memory; persistence ships in a later phase. The caller owns
/// the instance and threads it across [TangoLevelGenerator.generate]
/// calls when batch-generating.
///
/// **R39 / U6.1 extension.** The filter accepts an optional
/// `recentSignatures` list (last 10 signatures from the persistent log,
/// joined from `sessions JOIN preview-data`) and an optional
/// `previousBandSignature` (the signature of the immediately-previous
/// session of the same band). Exact-match against either causes a
/// force-reject. The static helper [verifyVarietyHorizon] returns true
/// iff a 10-signature history contains ≥6 distinct entries — used by
/// callers that want to assert R39's "≥6 different forms in 10
/// consecutive games" guarantee.
class DiversityFilter {
  DiversityFilter({
    this.minDistance = 0.30,
    this.bufferSize = 50,
    List<String> recentSignatures = const [],
    String? previousBandSignature,
  })  : _recentSignatures = List.unmodifiable(recentSignatures),
        _previousBandSignature = previousBandSignature;

  /// Hamming distance threshold. Below this → reject.
  final double minDistance;

  /// Rolling buffer cap. Older signatures are forgotten.
  final int bufferSize;

  /// Stable signatures pulled from the last-10 persisted sessions for
  /// the active user (R39). Exact-match against any of these forces a
  /// reject — the in-memory `_recent` buffer covers session-local
  /// dedupe; this list covers cross-session dedupe.
  final List<String> _recentSignatures;

  /// Signature of the immediately-previous session of the same
  /// difficulty band (R39 base case — "two consecutive games of the
  /// same band must look different").
  final String? _previousBandSignature;

  final Queue<_PuzzleSignature> _recent = Queue<_PuzzleSignature>();

  /// `true` iff [candidate] is far enough from every recent signature
  /// (Hamming-metric) **and** does not exactly collide with any of the
  /// persisted signatures supplied at construction time.
  bool accepts(TangoPuzzle candidate) {
    final sig = _PuzzleSignature.of(candidate);
    final stable = stableSignatureOf(candidate);
    if (_previousBandSignature != null && stable == _previousBandSignature) {
      return false;
    }
    if (_recentSignatures.contains(stable)) return false;
    for (final r in _recent) {
      if (sig.distance(r) < minDistance) return false;
    }
    return true;
  }

  /// Records [accepted] into the rolling buffer; trims the oldest
  /// signature when the buffer overflows.
  void record(TangoPuzzle accepted) {
    final sig = _PuzzleSignature.of(accepted);
    _recent.addLast(sig);
    while (_recent.length > bufferSize) {
      _recent.removeFirst();
    }
  }

  /// Visible-for-testing snapshot of the buffer length.
  int get bufferLength => _recent.length;

  /// Stable string signature of [puzzle] suitable for cross-session
  /// persistence. Hash of {seed-mark positions, equals-edge positions,
  /// opposite-edge positions} — exact-match metric (Deferred to
  /// Implementation: switching to a perceptual hash later is allowed).
  static String stableSignatureOf(TangoPuzzle puzzle) {
    final sig = _PuzzleSignature.of(puzzle);
    // Pack the bool-vector into a hex digest. Length is bounded by the
    // active-cell count + adjacency count, never huge — direct base16
    // encoding is fine.
    final buf = StringBuffer();
    var byte = 0;
    var bitsInByte = 0;
    for (final b in sig.bits) {
      byte = (byte << 1) | (b ? 1 : 0);
      bitsInByte++;
      if (bitsInByte == 8) {
        buf.write(byte.toRadixString(16).padLeft(2, '0'));
        byte = 0;
        bitsInByte = 0;
      }
    }
    if (bitsInByte > 0) {
      byte <<= (8 - bitsInByte);
      buf.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  /// Variety-horizon check (R39): given the last 10 signatures (oldest
  /// → newest), returns `true` iff there are ≥6 distinct entries.
  ///
  /// Lists shorter than 10 are treated as-is — `verifyVarietyHorizon`
  /// on a 5-entry list with all-distinct entries returns `true`. The
  /// `>=6` floor only kicks in once a full horizon is available.
  static bool verifyVarietyHorizon(List<String> last10Signatures) {
    if (last10Signatures.length < 10) {
      return last10Signatures.toSet().length == last10Signatures.length;
    }
    return last10Signatures.toSet().length >= 6;
  }
}
