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
import '../../puzzles/tango/generator/difficulty_band.dart';
import '../summary/bloc/summary_bloc.dart';
import 'band_rotator.dart';
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
/// Loops while the user keeps tapping a post-session button: each
/// `NextGameRequest` returned from `EndOfSessionScreen` reseeds
/// `band`/`userAdjusted` for the next iteration. Returning to the
/// home screen happens when the user backs out (route returns `null`).
///
/// `BandRotator` lives across iterations — its round-robin counter
/// must persist so two consecutive «Следующая» taps don't repeatedly
/// hit the same step. After the first `next()`, the rotator hydrates
/// from `sessionsRepository.recentBands`, so even an Android process-
/// kill mid-stack doesn't reset the counter to 0.
///
/// Plain `Navigator.push` — no router yet (deferred per plan U1).
Future<void> launchFullGame(BuildContext context) async {
  final db = _db();
  final sessionsRepo = SessionsRepository(db);
  final rotator = BandRotator(loadRecentBands: sessionsRepo.recentBands);

  var band = DifficultyBand.medium;
  var userAdjusted = false;
  while (true) {
    if (!context.mounted) return;
    final result = await Navigator.of(context).push<NextGameRequest>(
      MaterialPageRoute<NextGameRequest>(
        builder: (_) => FullGameScreen(
          createBloc: (_) => _buildBloc(
            band: band,
            userAdjusted: userAdjusted,
          ),
          summaryBlocFactory: (_, currentBand) =>
              buildSummaryBloc(currentBand: currentBand, rotator: rotator),
        ),
      ),
    );
    if (result == null) return;
    band = result.band;
    userAdjusted = result.userAdjusted;
  }
}

FullGameBloc _buildBloc({
  DifficultyBand band = DifficultyBand.medium,
  bool userAdjusted = false,
}) {
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
    band: band,
    userAdjusted: userAdjusted,
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

/// Build a [SummaryBloc] hooked into the runtime [MasteryScorer] and
/// the per-launch [BandRotator]. Used by the runtime end-of-session
/// route; tests inject directly.
SummaryBloc buildSummaryBloc({
  required DifficultyBand currentBand,
  required BandRotator rotator,
}) {
  final db = _db();
  final masteryRepo = MasteryRepository(db);
  final movesRepo = MoveEventsRepository(db);
  return SummaryBloc(
    masteryScorer: MasteryScorer(
      masteryRepository: masteryRepo,
      moveEventsRepository: movesRepo,
    ),
    bandRotator: rotator,
    currentBand: currentBand,
  );
}

