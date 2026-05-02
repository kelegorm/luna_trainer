import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../data/database.dart';
import '../../data/repositories/fsrs_repository.dart';
import '../../data/repositories/mastery_repository.dart';
import '../../data/repositories/move_events_repository.dart';
import '../../data/repositories/sessions_repository.dart';
import '../../engine/fsrs/fsrs_scheduler.dart';
import '../../engine/mastery/baseline_provider.dart';
import '../../engine/mastery/mastery_scorer.dart';
import '../../engine/telemetry/contamination_detector.dart';
import '../../engine/telemetry/lifecycle_observer.dart';
import '../../engine/telemetry/motion_detector.dart';
import '../../engine/telemetry/move_timer_service.dart';
import '../summary/bloc/summary_bloc.dart';
import 'bloc/full_game_bloc.dart';
import 'full_game_screen.dart';
import 'replay_diff.dart';

/// Single shared DB instance used across the runtime DI graph for
/// full-game launch. v1: lazy global; replaced by a real DI graph
/// (provider/get_it) post-MVP.
LunaDatabase? _runtimeDb;
LunaDatabase _db() => _runtimeDb ??= LunaDatabase();

/// Launches the full-game screen with a fully-wired Bloc graph
/// (sessions repo, mastery scorer, replay-diff, FSRS scheduler).
///
/// Plain `Navigator.push` — no router yet (deferred per plan U1).
Future<void> launchFullGame(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const FullGameScreen(
        createBloc: _buildBloc,
        summaryBlocFactory: buildSummaryBloc,
      ),
    ),
  );
}

FullGameBloc _buildBloc(BuildContext _) {
  final db = _db();
  final sessionsRepo = SessionsRepository(db);
  final movesRepo = MoveEventsRepository(db);
  final masteryRepo = MasteryRepository(db);
  final fsrsRepo = FsrsRepository(db);

  final masteryScorer = MasteryScorer(
    masteryRepository: masteryRepo,
    moveEventsRepository: movesRepo,
  );
  final fsrsScheduler = FsrsScheduler(fsrsRepository: fsrsRepo);

  final lifecycle = LifecycleObserver();
  // Best-effort sensor stream — if the platform is missing it (e.g. on
  // a desktop test runner), MotionDetector silently runs with no data.
  final motionStream = _safeMotionStream();
  final motion = MotionDetector(samples: motionStream);
  final contamination = ContaminationDetector(
    lifecycle: lifecycle,
    motion: motion,
  );
  final moveTimer = MoveTimerService(contamination: contamination);

  const replayDiff = ReplayDiff();
  Future<ReplayDiffResult> runReplayDiff(List<ReplayMove> moves) async {
    return replayDiff.run(
      moves: moves,
      baselines: const BaselineProvider(),
      scheduler: fsrsScheduler,
      fsrsRepository: fsrsRepo,
    );
  }

  Future<void> updateMastery(MasteryEvent e) async {
    await masteryScorer.updateOnEvent(e);
  }

  return FullGameBloc(
    sessionsRepository: sessionsRepo,
    moveEventsRepository: movesRepo,
    moveTimer: moveTimer,
    replayDiffRunner: runReplayDiff,
    masteryUpdater: updateMastery,
  );
}

/// Wraps [userAccelerometerEventStream] with a typed-conversion +
/// onError fallback. Engine consumes [MotionSample]; sensors_plus
/// emits [UserAccelerometerEvent].
Stream<MotionSample> _safeMotionStream() {
  try {
    return userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).map(
      (e) => MotionSample(x: e.x, y: e.y, z: e.z),
    );
  } catch (_) {
    return const Stream<MotionSample>.empty();
  }
}

/// Build a [SummaryBloc] hooked into the runtime [MasteryScorer].
/// Used by the runtime end-of-session route; tests inject directly.
SummaryBloc buildSummaryBloc(BuildContext _) {
  final db = _db();
  final masteryRepo = MasteryRepository(db);
  final movesRepo = MoveEventsRepository(db);
  return SummaryBloc(
    masteryScorer: MasteryScorer(
      masteryRepository: masteryRepo,
      moveEventsRepository: movesRepo,
    ),
  );
}

