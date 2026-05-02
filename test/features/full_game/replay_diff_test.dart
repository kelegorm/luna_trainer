import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/fsrs_repository.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/engine/fsrs/fsrs_scheduler.dart';
import 'package:luna_traineer/engine/mastery/baseline_provider.dart';
import 'package:luna_traineer/features/full_game/replay_diff.dart';

const _parity = Heuristic('tango', 'ParityFill');
const _trio = Heuristic('tango', 'TrioAvoidance');
const _sign = Heuristic('tango', 'SignPropagation');
const _pair = Heuristic('tango', 'PairCompletion');
const _composite = Heuristic('tango', 'Composite(unknown)');

class _FlatBaselines extends BaselineProvider {
  const _FlatBaselines(this.medianMs)
      : super(
          defaultSpec: const BaselineSpec(medianMs: 0, sigmaLog: 0.5),
        );
  final int medianMs;

  @override
  BaselineSpec forHeuristic(Heuristic _) =>
      BaselineSpec(medianMs: medianMs, sigmaLog: 0.5);
}

ReplayMove _move({
  required Heuristic heuristic,
  required int latencyMs,
  bool contaminated = false,
  bool wasCorrect = true,
  int hintStepReached = 0,
}) {
  return ReplayMove(
    heuristic: heuristic,
    latencyMs: latencyMs,
    contaminated: contaminated,
    wasCorrect: wasCorrect,
    hintStepReached: hintStepReached,
  );
}

void main() {
  group('ReplayDiff.selectCandidates — pure logic', () {
    const baselines = _FlatBaselines(2000);

    test(
      'happy AE6: 28 moves, 3 above 2.5x baseline → top-3 picked, ordered by gap',
      () {
        final moves = <ReplayMove>[
          // 25 fast moves under baseline.
          for (var i = 0; i < 25; i++)
            _move(heuristic: _parity, latencyMs: 1000),
          // 3 stuck moves: gap = 5000 / 9000 / 13000.
          _move(heuristic: _parity, latencyMs: 7000),
          _move(heuristic: _trio, latencyMs: 11000),
          _move(heuristic: _sign, latencyMs: 15000),
        ];

        const diff = ReplayDiff(maxPicks: 3);
        final picks = diff.selectCandidates(
          moves: moves,
          baselines: baselines,
        );

        expect(picks, hasLength(3));
        expect(
          picks.map((c) => c.heuristic).toList(),
          [_sign, _trio, _parity],
          reason: 'sorted by gapMs descending',
        );
        expect(picks.first.gapMs, 13000);
        expect(picks.first.baselineMs, 2000);
      },
    );

    test('perfect game (all latencies ≤ baseline) → 0 candidates', () {
      final moves = [
        for (var i = 0; i < 28; i++) _move(heuristic: _parity, latencyMs: 1500),
      ];
      const diff = ReplayDiff();

      final picks = diff.selectCandidates(moves: moves, baselines: baselines);

      expect(picks, isEmpty);
    });

    test('contaminated moves are dropped', () {
      final moves = [
        _move(heuristic: _parity, latencyMs: 12000, contaminated: true),
        _move(heuristic: _trio, latencyMs: 8000),
      ];
      const diff = ReplayDiff();

      final picks = diff.selectCandidates(moves: moves, baselines: baselines);

      expect(picks.map((c) => c.heuristic).toList(), [_trio]);
    });

    test('Composite(unknown) is dropped (R10)', () {
      final moves = [
        _move(heuristic: _composite, latencyMs: 99999),
        _move(heuristic: _trio, latencyMs: 8000),
      ];
      const diff = ReplayDiff();

      final picks = diff.selectCandidates(moves: moves, baselines: baselines);

      expect(picks.map((c) => c.heuristic).toList(), [_trio]);
    });

    test('dedup by heuristic — repeat picks for same heuristic collapse', () {
      final moves = [
        _move(heuristic: _parity, latencyMs: 8000), // gap 6000
        _move(heuristic: _parity, latencyMs: 11000), // gap 9000
        _move(heuristic: _trio, latencyMs: 7000), // gap 5000
      ];
      const diff = ReplayDiff(maxPicks: 3);

      final picks = diff.selectCandidates(moves: moves, baselines: baselines);

      expect(picks, hasLength(2));
      expect(picks[0].heuristic, _parity);
      expect(picks[0].gapMs, 9000,
          reason: 'highest-gap occurrence kept after dedup');
      expect(picks[1].heuristic, _trio);
    });

    test('maxPicks caps the result even when many heuristics are stuck', () {
      final moves = [
        _move(heuristic: _parity, latencyMs: 8000),
        _move(heuristic: _trio, latencyMs: 9000),
        _move(heuristic: _sign, latencyMs: 10000),
        _move(heuristic: _pair, latencyMs: 11000),
      ];
      const diff = ReplayDiff(maxPicks: 3);

      final picks = diff.selectCandidates(moves: moves, baselines: baselines);

      expect(picks, hasLength(3));
      expect(picks.map((c) => c.heuristic).toList(), [_pair, _sign, _trio]);
    });

    test('minGapMs respected — moves only marginally over baseline ignored', () {
      const tightDiff = ReplayDiff(minGapMs: 1000);
      final moves = [
        _move(heuristic: _parity, latencyMs: 2500), // gap 500 — under floor
        _move(heuristic: _trio, latencyMs: 4000), // gap 2000 — over floor
      ];

      final picks = tightDiff.selectCandidates(
        moves: moves,
        baselines: baselines,
      );

      expect(picks.map((c) => c.heuristic).toList(), [_trio]);
    });
  });

  group('ReplayDiff.run — schedules FSRS cards', () {
    late LunaDatabase db;
    late FsrsRepository fsrsRepo;
    late FsrsScheduler scheduler;

    setUp(() {
      db = LunaDatabase.forTesting(NativeDatabase.memory());
      fsrsRepo = FsrsRepository(db);
      scheduler = FsrsScheduler(fsrsRepository: fsrsRepo);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'AE6: 3 stuck → 3 FSRS cards scheduled, due ≈ tomorrow (within 2 days)',
      () async {
        const baselines = _FlatBaselines(2000);
        final moves = [
          for (var i = 0; i < 25; i++)
            _move(heuristic: _parity, latencyMs: 1000),
          _move(heuristic: _parity, latencyMs: 7000),
          _move(heuristic: _trio, latencyMs: 11000),
          _move(heuristic: _sign, latencyMs: 15000),
        ];
        const diff = ReplayDiff(maxPicks: 3);
        final now = DateTime.utc(2026, 5, 1, 12);

        final result = await diff.run(
          moves: moves,
          baselines: baselines,
          scheduler: scheduler,
          fsrsRepository: fsrsRepo,
          now: now,
        );

        expect(result.count, 3);
        expect(result.scheduledHeuristics.toSet(),
            {_parity, _trio, _sign});

        final dueWindowEnd = now.add(const Duration(days: 2));
        for (final h in result.scheduledHeuristics) {
          final row = await fsrsRepo.find(h);
          expect(row, isNotNull, reason: 'card persisted for $h');
          final due = DateTime.fromMillisecondsSinceEpoch(row!.dueAt,
              isUtc: true);
          expect(due.isAfter(now), isTrue,
              reason: 'due moves forward from review-time');
          expect(due.isBefore(dueWindowEnd), isTrue,
              reason: 'Hard rating yields ≤ 2-day interval for fresh card');
        }
      },
    );

    test('clean game → run returns empty result, no cards scheduled', () async {
      const baselines = _FlatBaselines(5000);
      final moves = [
        for (var i = 0; i < 28; i++) _move(heuristic: _parity, latencyMs: 2000),
      ];
      const diff = ReplayDiff();

      final result = await diff.run(
        moves: moves,
        baselines: baselines,
        scheduler: scheduler,
        fsrsRepository: fsrsRepo,
      );

      expect(result.isEmpty, isTrue);
      expect(result.count, 0);
      expect(await fsrsRepo.find(_parity), isNull);
    });

    test('toJson exposes scheduled_count + per-candidate gap', () {
      const result = ReplayDiffResult(
        candidates: [
          ReplayDiffCandidate(
            heuristic: _trio,
            latencyMs: 9000,
            baselineMs: 2000,
            gapMs: 7000,
          ),
        ],
        scheduledHeuristics: [_trio],
      );

      final json = result.toJson();

      expect(json['scheduled_count'], 1);
      final c0 = (json['candidates'] as List).first as Map<String, dynamic>;
      expect(c0['kind'], 'tango');
      expect(c0['tag'], 'TrioAvoidance');
      expect(c0['gap_ms'], 7000);
    });
  });
}
