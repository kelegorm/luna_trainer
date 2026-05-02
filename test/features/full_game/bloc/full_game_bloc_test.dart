import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/move_events_repository.dart';
import 'package:luna_traineer/data/repositories/sessions_repository.dart';
import 'package:luna_traineer/engine/mastery/mastery_scorer.dart';
import 'package:luna_traineer/engine/telemetry/contamination_detector.dart';
import 'package:luna_traineer/engine/telemetry/lifecycle_observer.dart';
import 'package:luna_traineer/engine/telemetry/motion_detector.dart';
import 'package:luna_traineer/engine/telemetry/move_event_kind.dart';
import 'package:luna_traineer/engine/telemetry/move_timer_service.dart';
import 'package:luna_traineer/features/full_game/bloc/full_game_bloc.dart';
import 'package:luna_traineer/features/full_game/replay_diff.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_position.dart';
import 'package:luna_traineer/puzzles/tango/generator/board_shape.dart';
import 'package:luna_traineer/puzzles/tango/generator/difficulty_band.dart';
import 'package:luna_traineer/puzzles/tango/generator/diversity_filter.dart';
import 'package:luna_traineer/puzzles/tango/generator/generator_result.dart';
import 'package:luna_traineer/puzzles/tango/generator/mix_histogram.dart';
import 'package:luna_traineer/puzzles/tango/generator/tango_level_generator.dart';
import 'package:luna_traineer/puzzles/tango/generator/tango_puzzle.dart';
import 'package:luna_traineer/puzzles/tango/generator/target_mix.dart';

/// Build a deterministic Tango solution: checkerboard sun/moon. Each
/// row alternates → 3 sun + 3 moon, no triple. Each column same. No
/// edge constraints needed.
TangoPosition _checkerboardSolution() {
  final cells = List<List<TangoMark?>>.generate(
    6,
    (r) => List<TangoMark?>.generate(
      6,
      (c) => (r + c).isEven ? TangoMark.sun : TangoMark.moon,
    ),
  );
  return TangoPosition(cells: cells, constraints: const []);
}

TangoPosition _withCleared(TangoPosition source, List<(int, int)> clears) {
  var pos = source;
  for (final (r, c) in clears) {
    pos = pos.withCell(r, c, null);
  }
  return pos;
}

/// Test double for the level generator. Returns a pre-cooked puzzle
/// with a controllable initial position. We can't pass a generator
/// without subclassing because [TangoLevelGenerator] is concrete.
class _StubGenerator extends TangoLevelGenerator {
  _StubGenerator({required this.puzzle}) : super();

  final TangoPuzzle puzzle;

  @override
  GeneratorResult generate({
    required TargetMix mix,
    required BoardShape shape,
    int? seed,
    DiversityFilter? diversity,
    DifficultyBand? band,
  }) {
    return GeneratorSuccess(puzzle: puzzle, histogram: puzzle.histogram);
  }
}

class _FakeClock {
  _FakeClock(DateTime start) : _now = start;
  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

class _RecordingReplayDiff {
  int callCount = 0;
  List<ReplayMove>? lastMoves;
  ReplayDiffResult result = const ReplayDiffResult(
    candidates: [],
    scheduledHeuristics: [],
  );

  Future<ReplayDiffResult> call(List<ReplayMove> moves) async {
    callCount++;
    lastMoves = moves;
    return result;
  }
}

class _RecordingMastery {
  final List<MasteryEvent> events = [];

  Future<void> call(MasteryEvent e) async {
    events.add(e);
  }
}

void main() {
  late LunaDatabase db;
  late SessionsRepository sessionsRepo;
  late MoveEventsRepository movesRepo;
  late LifecycleObserver lifecycle;
  late StreamController<MotionSample> motionStream;
  late MotionDetector motion;
  late ContaminationDetector contamination;
  late MoveTimerService moveTimer;
  late _FakeClock clock;
  late _RecordingReplayDiff replay;
  late _RecordingMastery mastery;

  late TangoPosition solution;
  late TangoPosition initialOneEmpty;
  late TangoPosition initialTwoEmpty;
  late TangoPuzzle puzzleOneEmpty;
  late TangoPuzzle puzzleTwoEmpty;

  setUp(() {
    db = LunaDatabase.forTesting(NativeDatabase.memory());
    sessionsRepo = SessionsRepository(db);
    movesRepo = MoveEventsRepository(db);

    clock = _FakeClock(DateTime(2026, 5, 1, 12));
    lifecycle = LifecycleObserver(now: clock.now);
    motionStream = StreamController<MotionSample>.broadcast();
    motion = MotionDetector(samples: motionStream.stream, now: clock.now);
    contamination = ContaminationDetector(
      lifecycle: lifecycle,
      motion: motion,
    );
    moveTimer = MoveTimerService(
      contamination: contamination,
      now: clock.now,
    );

    replay = _RecordingReplayDiff();
    mastery = _RecordingMastery();

    solution = _checkerboardSolution();
    initialOneEmpty = _withCleared(solution, const [(0, 0)]);
    initialTwoEmpty = _withCleared(solution, const [(0, 0), (0, 1)]);
    puzzleOneEmpty = TangoPuzzle(
      initialPosition: initialOneEmpty,
      solution: solution,
      shape: BoardShape.full6x6(),
      histogram: const MixHistogram({}),
      seed: 1,
    );
    puzzleTwoEmpty = TangoPuzzle(
      initialPosition: initialTwoEmpty,
      solution: solution,
      shape: BoardShape.full6x6(),
      histogram: const MixHistogram({}),
      seed: 2,
    );
  });

  tearDown(() async {
    await moveTimer.dispose();
    lifecycle.dispose();
    await motion.dispose();
    await motionStream.close();
    await db.close();
  });

  FullGameBloc buildBloc({TangoPuzzle? puzzle}) {
    return FullGameBloc(
      sessionsRepository: sessionsRepo,
      moveEventsRepository: movesRepo,
      moveTimer: moveTimer,
      replayDiffRunner: replay.call,
      masteryUpdater: mastery.call,
      levelGenerator: _StubGenerator(puzzle: puzzle ?? puzzleOneEmpty),
      clock: clock.now,
    );
  }

  group('GameStarted', () {
    blocTest<FullGameBloc, FullGameState>(
      'happy: generates puzzle, opens session, transitions to playing',
      build: buildBloc,
      act: (bloc) => bloc.add(const GameStarted(seed: 1)),
      expect: () => [
        predicate<FullGameState>(
          (s) => s.status == FullGameStatus.generating,
        ),
        predicate<FullGameState>(
          (s) =>
              s.status == FullGameStatus.playing &&
              s.position == initialOneEmpty &&
              s.sessionId != null,
        ),
      ],
      verify: (_) async {
        final row = await sessionsRepo.findById(1);
        expect(row, isNotNull);
        expect(row!.mode, 'full_game');
        expect(row.difficultyBand, DifficultyBand.medium.value);
      },
    );
  });

  group('MoveCommitted', () {
    blocTest<FullGameBloc, FullGameState>(
      'records MoveEvent + advances position',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 1));
        await Future<void>.delayed(Duration.zero);
        clock.advance(const Duration(seconds: 2));
        // Solution at (0,0) is sun (checkerboard, even+even).
        bloc.add(const MoveCommitted(row: 0, col: 0, mark: TangoMark.sun));
      },
      verify: (_) async {
        final rows = await db
            .select(db.moveEvents)
            .get();
        expect(rows, hasLength(1));
        final ev = rows.single;
        expect(ev.wasCorrect, isTrue);
        expect(ev.hintRequested, isFalse);
        expect(ev.hintStepReached, 0);
        expect(ev.eventKind, MoveEventKind.production.wire);
        expect(ev.difficultyBand, DifficultyBand.medium.value);
        expect(ev.userAdjusted, isFalse);
        expect(ev.latencyMs, greaterThanOrEqualTo(2000));
      },
    );

    blocTest<FullGameBloc, FullGameState>(
      'incorrect mark → wasCorrect=false (R1)',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 1));
        await Future<void>.delayed(Duration.zero);
        // Solution at (0,0) is sun; commit moon to flag wrongness.
        bloc.add(const MoveCommitted(row: 0, col: 0, mark: TangoMark.moon));
      },
      verify: (_) async {
        final ev = (await db.select(db.moveEvents).get()).single;
        expect(ev.wasCorrect, isFalse);
      },
    );

    blocTest<FullGameBloc, FullGameState>(
      'completing the last empty cell triggers GameCompleted + replay-diff',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 1));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const MoveCommitted(row: 0, col: 0, mark: TangoMark.sun));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.status, FullGameStatus.completed);
        expect(bloc.state.replayDiff, isNotNull);
        expect(replay.callCount, 1);
        // Mastery updated for every non-contaminated move (1 here).
        expect(mastery.events, hasLength(1));

        final session = await sessionsRepo.findById(bloc.state.sessionId!);
        expect(session, isNotNull);
        expect(session!.endedAt, isNotNull);
        expect(session.outcomeJson, isNotNull);
        final outcome =
            jsonDecode(session.outcomeJson!) as Map<String, dynamic>;
        expect(outcome['replay_diff'], isMap);
      },
    );
  });

  group('Hint ladder (R12, R13, AE2)', () {
    blocTest<FullGameBloc, FullGameState>(
      'HintRequested → step=1, overlay open',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 1));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const HintRequested());
      },
      skip: 2,
      expect: () => [
        predicate<FullGameState>(
          (s) => s.hintStep == 1 && s.hintOverlayOpen,
        ),
      ],
    );

    blocTest<FullGameBloc, FullGameState>(
      'HintStepAdvanced × 3 → step=4 pauses move timer',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 1));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const HintRequested());
        bloc.add(const HintStepAdvanced());
        bloc.add(const HintStepAdvanced());
        bloc.add(const HintStepAdvanced());
      },
      verify: (bloc) async {
        expect(bloc.state.hintStep, 4);
        expect(bloc.state.hintOverlayOpen, isTrue);
        expect(moveTimer.isPaused, isTrue,
            reason: 'step 4 must pause move-timer (R13/AE2)');
      },
    );

    blocTest<FullGameBloc, FullGameState>(
      'HintDismissed from step 4 resumes the move timer',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 1));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const HintRequested());
        bloc.add(const HintStepAdvanced());
        bloc.add(const HintStepAdvanced());
        bloc.add(const HintStepAdvanced());
        bloc.add(const HintDismissed());
      },
      verify: (_) async {
        expect(moveTimer.isPaused, isFalse);
      },
    );

    blocTest<FullGameBloc, FullGameState>(
      'next move after hint records hint_requested=true + hint_step_reached',
      build: () => buildBloc(puzzle: puzzleTwoEmpty),
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 2));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const HintRequested());
        bloc.add(const HintStepAdvanced()); // step 2
        bloc.add(const HintDismissed());
        bloc.add(const MoveCommitted(row: 0, col: 0, mark: TangoMark.sun));
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) async {
        final rows = await db.select(db.moveEvents).get();
        expect(rows, hasLength(1));
        expect(rows.single.hintRequested, isTrue);
        expect(rows.single.hintStepReached, 2);
      },
    );
  });

  group('GameCompleted', () {
    blocTest<FullGameBloc, FullGameState>(
      'is idempotent — second GameCompleted is a no-op',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 1));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const MoveCommitted(row: 0, col: 0, mark: TangoMark.sun));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const GameCompleted()); // already completed
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) async {
        expect(replay.callCount, 1,
            reason: 'replay-diff must run only once per game');
      },
    );

    blocTest<FullGameBloc, FullGameState>(
      'two-move game streams 2 mastery events on completion',
      build: () => buildBloc(puzzle: puzzleTwoEmpty),
      act: (bloc) async {
        bloc.add(const GameStarted(seed: 2));
        await Future<void>.delayed(Duration.zero);
        // Solution: (0,0)=sun, (0,1)=moon.
        bloc.add(const MoveCommitted(row: 0, col: 0, mark: TangoMark.sun));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const MoveCommitted(row: 0, col: 1, mark: TangoMark.moon));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.status, FullGameStatus.completed);
        expect(mastery.events, hasLength(2));
      },
    );
  });
}
