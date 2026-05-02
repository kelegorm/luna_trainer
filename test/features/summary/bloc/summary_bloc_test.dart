import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/mastery_repository.dart';
import 'package:luna_traineer/data/repositories/move_events_repository.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/engine/mastery/mastery_scorer.dart';
import 'package:luna_traineer/features/full_game/bloc/full_game_bloc.dart';
import 'package:luna_traineer/features/full_game/replay_diff.dart';
import 'package:luna_traineer/features/summary/bloc/summary_bloc.dart';

const _parity = Heuristic('tango', 'ParityFill');
const _trio = Heuristic('tango', 'TrioAvoidance');
const _sign = Heuristic('tango', 'SignPropagation');
const _composite = Heuristic('tango', 'Composite(unknown)');

RecordedMove _move({
  required Heuristic heuristic,
  int latencyMs = 2000,
  bool contaminated = false,
  bool wasCorrect = true,
  bool hintRequested = false,
  int hintStepReached = 0,
}) {
  return RecordedMove(
    heuristic: heuristic,
    row: 0,
    col: 0,
    latencyMs: latencyMs,
    contaminated: contaminated,
    idleSoftSignal: false,
    motionSignal: false,
    lifecycleSignal: false,
    wasCorrect: wasCorrect,
    hintRequested: hintRequested,
    hintStepReached: hintStepReached,
    mode: MoveMode.hunt,
    createdAt: DateTime(2026, 5, 1),
  );
}

void main() {
  late LunaDatabase db;
  late MasteryScorer scorer;

  setUp(() {
    db = LunaDatabase.forTesting(NativeDatabase.memory());
    final masteryRepo = MasteryRepository(db);
    final movesRepo = MoveEventsRepository(db);
    scorer = MasteryScorer(
      masteryRepository: masteryRepo,
      moveEventsRepository: movesRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  blocTest<SummaryBloc, SummaryState>(
    'happy: groups by heuristic, drops contaminated + Composite(unknown)',
    build: () => SummaryBloc(masteryScorer: scorer),
    act: (bloc) => bloc.add(SummaryRequested(
      recordedMoves: [
        _move(heuristic: _parity, latencyMs: 1500),
        _move(heuristic: _parity, latencyMs: 2500),
        _move(heuristic: _trio, latencyMs: 3000),
        _move(heuristic: _parity, contaminated: true, latencyMs: 99999),
        _move(heuristic: _composite, latencyMs: 99999),
      ],
      replayDiff: const ReplayDiffResult(
        candidates: [],
        scheduledHeuristics: [],
      ),
    )),
    skip: 1, // skip loading
    verify: (bloc) {
      final state = bloc.state;
      expect(state.status, SummaryStatus.ready);
      expect(state.deltas, hasLength(2));
      final byHeuristic = {for (final d in state.deltas) d.heuristic: d};
      expect(byHeuristic.keys, containsAll([_parity, _trio]));
      expect(byHeuristic[_parity]!.eventCount, 2,
          reason: 'contaminated row dropped from group');
      expect(byHeuristic[_parity]!.medianLatencyMs, 2500);
      expect(byHeuristic[_trio]!.eventCount, 1);
    },
  );

  blocTest<SummaryBloc, SummaryState>(
    'replay-diff scheduled heuristic → marked regressed',
    build: () => SummaryBloc(masteryScorer: scorer),
    act: (bloc) => bloc.add(SummaryRequested(
      recordedMoves: [
        _move(heuristic: _sign, latencyMs: 9000),
      ],
      replayDiff: const ReplayDiffResult(
        candidates: [
          ReplayDiffCandidate(
            heuristic: _sign,
            latencyMs: 9000,
            baselineMs: 2000,
            gapMs: 7000,
          ),
        ],
        scheduledHeuristics: [_sign],
      ),
    )),
    skip: 1,
    verify: (bloc) {
      final state = bloc.state;
      expect(state.status, SummaryStatus.ready);
      final delta = state.deltas.single;
      expect(delta.heuristic, _sign);
      expect(delta.direction, SummaryDirection.regressed);
      expect(state.drillCardsAdded, 1);
      expect(state.topRegression?.heuristic, _sign);
    },
  );

  blocTest<SummaryBloc, SummaryState>(
    'errorRate > 0.5 forces regression even without replay-diff entry',
    build: () => SummaryBloc(masteryScorer: scorer),
    act: (bloc) => bloc.add(SummaryRequested(
      recordedMoves: [
        _move(heuristic: _trio, wasCorrect: false),
        _move(heuristic: _trio, wasCorrect: false),
        _move(heuristic: _trio, wasCorrect: true),
      ],
      replayDiff: null,
    )),
    skip: 1,
    verify: (bloc) {
      final delta = bloc.state.deltas.single;
      expect(delta.errorRate, closeTo(0.667, 0.01));
      expect(delta.direction, SummaryDirection.regressed);
    },
  );

  blocTest<SummaryBloc, SummaryState>(
    'clean run with no errors / no hints / no replay-diff → improved or flat',
    build: () => SummaryBloc(masteryScorer: scorer),
    act: (bloc) => bloc.add(SummaryRequested(
      recordedMoves: [
        _move(heuristic: _parity, latencyMs: 1200),
        _move(heuristic: _parity, latencyMs: 1100),
      ],
      replayDiff: const ReplayDiffResult(
        candidates: [],
        scheduledHeuristics: [],
      ),
    )),
    skip: 1,
    verify: (bloc) {
      final delta = bloc.state.deltas.single;
      expect(delta.errorRate, 0.0);
      expect(delta.hintRate, 0.0);
      // Calibrating mastery → score.shrunkPercentile defaults to mean,
      // which falls in [0,1]; either improved or flat is acceptable.
      expect(
        delta.direction,
        anyOf(SummaryDirection.improved, SummaryDirection.flat),
      );
    },
  );

  blocTest<SummaryBloc, SummaryState>(
    'empty session → no deltas, drillCardsAdded=0',
    build: () => SummaryBloc(masteryScorer: scorer),
    act: (bloc) => bloc.add(const SummaryRequested(
      recordedMoves: [],
      replayDiff: null,
    )),
    skip: 1,
    verify: (bloc) {
      expect(bloc.state.status, SummaryStatus.ready);
      expect(bloc.state.deltas, isEmpty);
      expect(bloc.state.drillCardsAdded, 0);
    },
  );
}
