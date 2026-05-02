import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../full_game/bloc/full_game_bloc.dart' show RecordedMove;
import '../full_game/replay_diff.dart';
import 'bloc/summary_bloc.dart';

/// Экран «end-of-session» (R23): per-heuristic дельты («прокачал /
/// замедлился»), число drill-cards, заведённых replay-diff-ом, и одна
/// кнопка «Next game». Базовая U11 — кнопок 1 (post-session 4 buttons
/// — амендмент R37/R38 для отдельного юнита).
///
/// «Подробнее» (AE7) ведёт на MasteryScreen, который пока не
/// реализован (U13). Поэтому кнопка показывает SnackBar-stub.
class EndOfSessionScreen extends StatelessWidget {
  const EndOfSessionScreen({
    super.key,
    required this.recordedMoves,
    required this.replayDiff,
    this.summaryBlocFactory,
  });

  final List<RecordedMove> recordedMoves;
  final ReplayDiffResult? replayDiff;

  /// Optional override for tests / DI. В runtime приложение
  /// инжектит SummaryBloc через repository-стек.
  final SummaryBloc Function(BuildContext)? summaryBlocFactory;

  @override
  Widget build(BuildContext context) {
    final factory = summaryBlocFactory;
    if (factory == null) {
      // Tests / smoke runs without DI: render the static body off the
      // pre-baked replay-diff data without touching MasteryScorer.
      return _StaticEndOfSession(
        recordedMoves: recordedMoves,
        replayDiff: replayDiff,
      );
    }
    return BlocProvider<SummaryBloc>(
      create: (ctx) {
        final bloc = factory(ctx);
        bloc.add(SummaryRequested(
          recordedMoves: recordedMoves,
          replayDiff: replayDiff,
        ));
        return bloc;
      },
      child: const _SummaryView(),
    );
  }
}

/// Light-weight fallback used when no SummaryBloc factory was passed.
/// Shows just the drill-cards banner + a Next-game button — no
/// per-heuristic deltas (those need MasteryScorer).
class _StaticEndOfSession extends StatelessWidget {
  const _StaticEndOfSession({
    required this.recordedMoves,
    required this.replayDiff,
  });

  final List<RecordedMove> recordedMoves;
  final ReplayDiffResult? replayDiff;

  @override
  Widget build(BuildContext context) {
    final drillCount = replayDiff?.count ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Game complete')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrillCardsBanner(count: drillCount),
            const Spacer(),
            FilledButton(
              key: const ValueKey('summary-next-game'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Next game'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game complete')),
      body: BlocBuilder<SummaryBloc, SummaryState>(
        builder: (context, state) {
          switch (state.status) {
            case SummaryStatus.idle:
            case SummaryStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case SummaryStatus.failed:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not build summary: ${state.errorMessage ?? 'unknown'}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            case SummaryStatus.ready:
              return _SummaryBody(state: state);
          }
        },
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.state});
  final SummaryState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrillCardsBanner(count: state.drillCardsAdded),
          const SizedBox(height: 16),
          if (state.deltas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nothing to add — every move was clean.',
                textAlign: TextAlign.center,
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: state.deltas.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _DeltaTile(delta: state.deltas[i]),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                key: const ValueKey('summary-details'),
                onPressed: () {
                  // U13 — MasteryScreen ещё не реализован. Заглушка.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mastery screen — coming in U13',
                      ),
                    ),
                  );
                },
                child: const Text('Details'),
              ),
              FilledButton(
                key: const ValueKey('summary-next-game'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Next game'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrillCardsBanner extends StatelessWidget {
  const _DrillCardsBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count == 0
        ? 'No drill cards added — clean game.'
        : '$count drill ${count == 1 ? 'card' : 'cards'} added for tomorrow.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _DeltaTile extends StatelessWidget {
  const _DeltaTile({required this.delta});
  final HeuristicDelta delta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (delta.direction) {
      SummaryDirection.improved => Icons.trending_up,
      SummaryDirection.regressed => Icons.trending_down,
      SummaryDirection.flat => Icons.trending_flat,
    };
    final iconColor = switch (delta.direction) {
      SummaryDirection.improved => colors.primary,
      SummaryDirection.regressed => colors.error,
      SummaryDirection.flat => colors.onSurfaceVariant,
    };
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(delta.heuristic.tagId),
      subtitle: Text(
        '${delta.eventCount} moves · '
        'median ${delta.medianLatencyMs ?? 0} ms · '
        'errors ${(delta.errorRate * 100).toStringAsFixed(0)}%',
      ),
    );
  }
}
