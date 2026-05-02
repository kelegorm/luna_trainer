import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../puzzles/tango/generator/difficulty_band.dart';
import '../../puzzles/tango/widgets/tango_board.dart';
import '../summary/bloc/summary_bloc.dart';
import '../summary/end_of_session_screen.dart';
import 'bloc/full_game_bloc.dart';
import 'widgets/hint_ladder_overlay.dart';

/// Полноразмерный экран обычной партии (F1, R1, R12, R13).
///
/// Bloc-инстанс этот экран **не создаёт сам** — он принимает
/// [createBloc] callback. В runtime приложении главный навигатор
/// собирает Bloc-граф (sessions repo, mastery scorer, replay-diff и
/// т.п.) и передаёт фабрику. В тестах достаточно подложить fake-Bloc.
///
/// Согласно R16 / R22 экран **не показывает** ни таймер, ни индикатор
/// «слабая техника» — только доска, кнопка hint и AppBar.
class FullGameScreen extends StatelessWidget {
  const FullGameScreen({
    super.key,
    required this.createBloc,
    this.summaryBlocFactory,
  });

  /// Фабрика Bloc-а — экран сам стартует партию (`GameStarted`)
  /// в момент создания Bloc-а.
  final FullGameBloc Function(BuildContext) createBloc;

  /// Фабрика SummaryBloc-а для post-game route. Передаётся как-есть
  /// в [EndOfSessionScreen]. В тестах можно опустить.
  final SummaryBlocFactory? summaryBlocFactory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FullGameBloc>(
      create: (ctx) => createBloc(ctx)..add(const GameStarted()),
      child: _FullGameView(summaryBlocFactory: summaryBlocFactory),
    );
  }
}

class _FullGameView extends StatelessWidget {
  const _FullGameView({this.summaryBlocFactory});

  final SummaryBlocFactory? summaryBlocFactory;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FullGameBloc, FullGameState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == FullGameStatus.completed) {
          // Push end-of-session screen on top. Bloc остаётся в state
          // `completed`; replay-diff уже сохранён в outcome_json.
          // Pass the band that just played — `EndOfSessionScreen`
          // pops with a `NextGameRequest` derived from it (R37/R38).
          final band = state.currentBand ?? DifficultyBand.medium;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<NextGameRequest>(
              builder: (_) => EndOfSessionScreen(
                recordedMoves: state.recordedMoves,
                replayDiff: state.replayDiff,
                currentBand: band,
                initialPosition: state.puzzle?.initialPosition,
                summaryBlocFactory: summaryBlocFactory,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tango'),
            actions: [
              if (state.isPlaying)
                IconButton(
                  key: const ValueKey('hint-button'),
                  icon: const Icon(Icons.lightbulb_outline),
                  tooltip: 'Hint',
                  onPressed: state.hintOverlayOpen
                      ? null
                      : () => context
                          .read<FullGameBloc>()
                          .add(const HintRequested()),
                ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                _buildBody(context, state),
                const HintLadderOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FullGameState state) {
    switch (state.status) {
      case FullGameStatus.idle:
      case FullGameStatus.generating:
        return const Center(child: CircularProgressIndicator());
      case FullGameStatus.failed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not start the game: ${state.errorMessage ?? 'unknown'}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      case FullGameStatus.playing:
      case FullGameStatus.completed:
        final position = state.position;
        if (position == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: TangoBoard(
                position: position,
                onMove: (m) => context.read<FullGameBloc>().add(
                      MoveCommitted(row: m.row, col: m.col, mark: m.mark),
                    ),
              ),
            ),
          ),
        );
    }
  }
}
