import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/engine/telemetry/move_mode_classifier.dart';
import 'package:luna_traineer/features/full_game/recorded_move.dart';
import 'package:luna_traineer/features/full_game/replay_diff.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';

const _parity = Heuristic('tango', 'ParityFill');
const _trio = Heuristic('tango', 'TrioAvoidance');
const _sign = Heuristic('tango', 'SignPropagation');
const _composite = Heuristic('tango', 'Composite(unknown)');

final _t0 = DateTime.utc(2026, 5, 1, 12);

RecordedMove _move({
  required Heuristic heuristic,
  required MoveMode mode,
  int latencyMs = 2000,
  bool contaminated = false,
  int row = 0,
  int col = 0,
  TangoMark? mark,
  DateTime? createdAt,
}) {
  return RecordedMove(
    heuristic: heuristic,
    row: row,
    col: col,
    mark: mark,
    latencyMs: latencyMs,
    contaminated: contaminated,
    idleSoftSignal: false,
    motionSignal: false,
    lifecycleSignal: false,
    wasCorrect: true,
    hintRequested: false,
    hintStepReached: 0,
    mode: mode,
    createdAt: createdAt ?? _t0,
  );
}

TangoPosition _positionWith(Map<List<int>, TangoMark> filled) {
  var p = TangoPosition.empty();
  for (final entry in filled.entries) {
    p = p.withCell(entry.key[0], entry.key[1], entry.value);
  }
  return p;
}

void main() {
  // ────────────────────────────────────────────────────────────────────
  // R31 — propagation/hunt summary
  // ────────────────────────────────────────────────────────────────────
  group('computeModeBreakdown — R31', () {
    test('AE10 happy: 60% propagation / 40% hunt — fractions match', () {
      final moves = [
        for (var i = 0; i < 6; i++)
          _move(heuristic: _parity, mode: MoveMode.propagation),
        for (var i = 0; i < 4; i++)
          _move(heuristic: _trio, mode: MoveMode.hunt, latencyMs: 5000),
      ];

      final out = computeModeBreakdown(moves);

      expect(out.totalCounted, 10);
      expect(out.propagationCount, 6);
      expect(out.huntCount, 4);
      expect(out.propagationFraction, closeTo(0.6, 0.001));
      expect(out.huntFraction, closeTo(0.4, 0.001));
      expect(out.slowestHuntHeuristic, _trio);
    });

    test('contaminated and Composite(unknown) moves are excluded', () {
      final moves = [
        _move(heuristic: _parity, mode: MoveMode.propagation),
        _move(
          heuristic: _parity,
          mode: MoveMode.hunt,
          contaminated: true,
          latencyMs: 99999,
        ),
        _move(heuristic: _composite, mode: MoveMode.hunt, latencyMs: 88888),
      ];

      final out = computeModeBreakdown(moves);

      expect(out.totalCounted, 1);
      expect(out.propagationCount, 1);
      expect(out.huntCount, 0);
      expect(out.p99HuntLatencyByHeuristic, isEmpty);
      expect(out.slowestHuntHeuristic, isNull);
    });

    test(
      'p99 hunt latency: heuristic with the highest p99 wins '
      'slowestHuntHeuristic',
      () {
        final moves = [
          // ParityFill hunt latencies: 9× 1000ms, 1× 4000ms → p99 = 4000.
          for (var i = 0; i < 9; i++)
            _move(heuristic: _parity, mode: MoveMode.hunt, latencyMs: 1000),
          _move(heuristic: _parity, mode: MoveMode.hunt, latencyMs: 4000),
          // Trio hunt latencies: 9× 1000ms, 1× 7000ms → p99 = 7000.
          for (var i = 0; i < 9; i++)
            _move(heuristic: _trio, mode: MoveMode.hunt, latencyMs: 1000),
          _move(heuristic: _trio, mode: MoveMode.hunt, latencyMs: 7000),
          // Sign with one slow hunt — p99 = 6500.
          _move(heuristic: _sign, mode: MoveMode.hunt, latencyMs: 6500),
        ];

        final out = computeModeBreakdown(moves);

        expect(out.huntCount, 21);
        expect(out.p99HuntLatencyByHeuristic[_parity], 4000);
        expect(out.p99HuntLatencyByHeuristic[_trio], 7000);
        expect(out.p99HuntLatencyByHeuristic[_sign], 6500);
        expect(out.slowestHuntHeuristic, _trio);
      },
    );

    test('empty moves → isEmpty=true, fractions=0', () {
      final out = computeModeBreakdown(const []);

      expect(out.isEmpty, isTrue);
      expect(out.totalCounted, 0);
      expect(out.propagationFraction, 0.0);
      expect(out.huntFraction, 0.0);
      expect(out.slowestHuntHeuristic, isNull);
    });

    test('toJson surfaces propagation/hunt counts and p99 map', () {
      final moves = [
        _move(heuristic: _parity, mode: MoveMode.propagation),
        _move(heuristic: _trio, mode: MoveMode.hunt, latencyMs: 4500),
      ];

      final json = computeModeBreakdown(moves).toJson();

      expect(json['propagation'], 1);
      expect(json['hunt'], 1);
      expect(json['total'], 2);
      final p99 = json['p99_hunt_ms'] as Map;
      expect(p99['TrioAvoidance'], 4500);
      expect(json['slowest_hunt'], 'TrioAvoidance');
    });
  });

  // ────────────────────────────────────────────────────────────────────
  // R32 — line_completion bias detector
  // ────────────────────────────────────────────────────────────────────
  group('detectLineCompletionBias — R32', () {
    // Initial: row 0 = [sun, moon, sun, moon, _, _]. 2 suns, 2 moons, 2
    // empty. No parity fires yet.
    final baseInitial = _positionWith({
      [0, 0]: TangoMark.sun,
      [0, 1]: TangoMark.moon,
      [0, 2]: TangoMark.sun,
      [0, 3]: TangoMark.moon,
    });

    test(
      'happy: move that triggers 1-empty ParityFill, '
      'then unrelated move 5 s later → 1 bias incident at index 1',
      () {
        // Move 0 at t0+1s: place sun at (0,4). Row 0 now has 3 suns + 2
        // moons + 1 empty (col 5) → 1-empty ParityFill, force moon.
        // Move 1 at t0+6s (5 s after move 0): place sun at (3,3) — not
        // the parity cell. Δt from when ParityFill became available
        // = 5 s ≥ 3 s → bias.
        final moves = [
          _move(
            heuristic: _parity,
            mode: MoveMode.propagation,
            row: 0,
            col: 4,
            mark: TangoMark.sun,
            latencyMs: 1000,
            createdAt: _t0.add(const Duration(milliseconds: 1000)),
          ),
          _move(
            heuristic: _trio,
            mode: MoveMode.hunt,
            row: 3,
            col: 3,
            mark: TangoMark.sun,
            latencyMs: 5000,
            createdAt: _t0.add(const Duration(milliseconds: 6000)),
          ),
        ];

        final incidents = detectLineCompletionBias(
          initialPosition: baseInitial,
          moves: moves,
          sessionStartedAt: _t0,
        );

        expect(incidents, hasLength(1));
        final inc = incidents.single;
        expect(inc.atMoveIndex, 1);
        expect(inc.missedRow, 0);
        expect(inc.missedCol, 5);
        expect(inc.elapsedMs, 5000);
        expect(inc.reason, contains('line_completion'));
      },
    );

    test(
      'edge: 1-empty ParityFill becomes available and user fills it '
      'within 3 s → no bias',
      () {
        // Move 0: place sun at (0,4) → parity 1-empty at (0,5)=moon.
        // Move 1 at t0+3s: place moon at (0,5) — took it. No bias.
        final moves = [
          _move(
            heuristic: _parity,
            mode: MoveMode.propagation,
            row: 0,
            col: 4,
            mark: TangoMark.sun,
            latencyMs: 1000,
            createdAt: _t0.add(const Duration(milliseconds: 1000)),
          ),
          _move(
            heuristic: _parity,
            mode: MoveMode.propagation,
            row: 0,
            col: 5,
            mark: TangoMark.moon,
            latencyMs: 2000,
            createdAt: _t0.add(const Duration(milliseconds: 3000)),
          ),
        ];

        final incidents = detectLineCompletionBias(
          initialPosition: baseInitial,
          moves: moves,
          sessionStartedAt: _t0,
        );

        expect(incidents, isEmpty);
      },
    );

    test(
      'edge: unrelated move within 3 s of parity becoming available '
      '→ no bias (reaction-time gate)',
      () {
        // Move 0 makes parity 1-empty. Move 1 is 1.5 s later at an
        // unrelated cell — fast enough to be reaction-time, not bias.
        final moves = [
          _move(
            heuristic: _parity,
            mode: MoveMode.propagation,
            row: 0,
            col: 4,
            mark: TangoMark.sun,
            latencyMs: 1000,
            createdAt: _t0.add(const Duration(milliseconds: 1000)),
          ),
          _move(
            heuristic: _trio,
            mode: MoveMode.hunt,
            row: 3,
            col: 3,
            mark: TangoMark.sun,
            latencyMs: 1500,
            createdAt: _t0.add(const Duration(milliseconds: 2500)),
          ),
        ];

        final incidents = detectLineCompletionBias(
          initialPosition: baseInitial,
          moves: moves,
          sessionStartedAt: _t0,
        );

        expect(incidents, isEmpty);
      },
    );

    test('empty moves → empty incidents', () {
      final incidents = detectLineCompletionBias(
        initialPosition: TangoPosition.empty(),
        moves: const [],
        sessionStartedAt: _t0,
      );
      expect(incidents, isEmpty);
    });

    test(
      'no 1-empty ParityFill ever appears → empty incidents '
      '(initial position completely empty)',
      () {
        final moves = [
          _move(
            heuristic: _trio,
            mode: MoveMode.hunt,
            row: 0,
            col: 0,
            mark: TangoMark.sun,
            latencyMs: 6000,
            createdAt: _t0.add(const Duration(milliseconds: 6000)),
          ),
        ];

        final incidents = detectLineCompletionBias(
          initialPosition: TangoPosition.empty(),
          moves: moves,
          sessionStartedAt: _t0,
        );

        expect(incidents, isEmpty);
      },
    );

    test(
      'one bias key fires once even if it remains available across '
      'multiple irrelevant moves (no double-flagging)',
      () {
        // Move 0: trigger parity at (0,5).
        // Move 1: 4 s later, place sun at (3,3). Bias at index 1.
        // Move 2: another 4 s later, place sun at (4,4). Parity at
        // (0,5) was already consumed from tracking — should NOT
        // double-flag.
        final moves = [
          _move(
            heuristic: _parity,
            mode: MoveMode.propagation,
            row: 0,
            col: 4,
            mark: TangoMark.sun,
            latencyMs: 1000,
            createdAt: _t0.add(const Duration(milliseconds: 1000)),
          ),
          _move(
            heuristic: _trio,
            mode: MoveMode.hunt,
            row: 3,
            col: 3,
            mark: TangoMark.sun,
            latencyMs: 4000,
            createdAt: _t0.add(const Duration(milliseconds: 5000)),
          ),
          _move(
            heuristic: _trio,
            mode: MoveMode.hunt,
            row: 4,
            col: 4,
            mark: TangoMark.sun,
            latencyMs: 4000,
            createdAt: _t0.add(const Duration(milliseconds: 9000)),
          ),
        ];

        final incidents = detectLineCompletionBias(
          initialPosition: baseInitial,
          moves: moves,
          sessionStartedAt: _t0,
        );

        // After move 1 fires bias, the (0,5,moon) key is permanently
        // marked alreadyFlagged for this game. Subsequent ignored
        // moves don't re-flag — one game ⇒ one signal per missed
        // line_completion.
        expect(incidents, hasLength(1));
        expect(incidents.first.atMoveIndex, 1);
      },
    );
  });
}
