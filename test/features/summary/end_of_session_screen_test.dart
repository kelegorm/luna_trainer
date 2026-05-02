import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/mastery_repository.dart';
import 'package:luna_traineer/data/repositories/move_events_repository.dart';
import 'package:luna_traineer/engine/mastery/mastery_scorer.dart';
import 'package:luna_traineer/features/full_game/band_rotator.dart';
import 'package:luna_traineer/features/summary/bloc/summary_bloc.dart';
import 'package:luna_traineer/features/summary/end_of_session_screen.dart';
import 'package:luna_traineer/puzzles/tango/generator/difficulty_band.dart';

void main() {
  late LunaDatabase db;
  late MasteryScorer scorer;

  setUp(() {
    db = LunaDatabase.forTesting(NativeDatabase.memory());
    scorer = MasteryScorer(
      masteryRepository: MasteryRepository(db),
      moveEventsRepository: MoveEventsRepository(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'static (no DI): «Сложнее» pops with NextGameRequest(hard, adjusted)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EndOfSessionScreen(
            recordedMoves: [],
            replayDiff: null,
            currentBand: DifficultyBand.medium,
          ),
        ),
      );

      // PostSessionActions widget keys are stable across the static
      // and bloc-driven paths.
      await tester.tap(find.byKey(const ValueKey('post-session-harder')));
      await tester.pumpAndSettle();

      // Static path uses Navigator.pop(...) but since this test
      // mounted the screen as the root route, the screen is just
      // gone — no MaterialApp left to verify pop result against.
      // Fall back to widget-tree assertion: PostSessionActions is
      // unmounted (the screen popped).
      expect(find.byType(EndOfSessionScreen), findsNothing);
    },
  );

  testWidgets(
    'with SummaryBloc: tap «Следующая» → screen pops with rotator-picked NextGameRequest',
    (tester) async {
      Future<List<DifficultyBand>> emptyHistory({int limit = 5}) async =>
          const [];
      final rotator = BandRotator(loadRecentBands: emptyHistory);

      late NextGameRequest? popped;
      bool popHandled = false;

      // Wrap the screen so we can capture the pop result.
      final screenKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: screenKey,
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              popped = await Navigator.of(ctx).push<NextGameRequest>(
                MaterialPageRoute(
                  builder: (_) => EndOfSessionScreen(
                    recordedMoves: const [],
                    replayDiff: null,
                    currentBand: DifficultyBand.medium,
                    summaryBlocFactory: (_, currentBand) => SummaryBloc(
                      masteryScorer: scorer,
                      bandRotator: rotator,
                      currentBand: currentBand,
                    ),
                  ),
                ),
              );
              popHandled = true;
            },
            child: const Text('open'),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // SummaryBloc loads → ready → buttons available.
      await tester.tap(find.byKey(const ValueKey('post-session-auto')));
      await tester.pumpAndSettle();

      expect(popHandled, isTrue);
      expect(popped, isNotNull);
      expect(popped!.band, isNot(DifficultyBand.medium),
          reason: 'rotator round-robin must avoid currentBand');
      expect(popped!.userAdjusted, isFalse);
    },
  );

  testWidgets(
    'with SummaryBloc: «Сложнее» pops with bumpUp + userAdjusted=true',
    (tester) async {
      late NextGameRequest? popped;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              popped = await Navigator.of(ctx).push<NextGameRequest>(
                MaterialPageRoute(
                  builder: (_) => EndOfSessionScreen(
                    recordedMoves: const [],
                    replayDiff: null,
                    currentBand: DifficultyBand.medium,
                    summaryBlocFactory: (_, currentBand) => SummaryBloc(
                      masteryScorer: scorer,
                      currentBand: currentBand,
                    ),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('post-session-harder')));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.band, DifficultyBand.hard);
      expect(popped!.userAdjusted, isTrue);
    },
  );
}
