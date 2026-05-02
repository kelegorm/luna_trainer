import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../puzzles/tango/domain/tango_position.dart';
import '../../puzzles/tango/generator/difficulty_band.dart';
import '../full_game/bloc/full_game_bloc.dart' show RecordedMove;
import '../full_game/replay_diff.dart';
import 'bloc/summary_bloc.dart';
import 'widgets/post_session_actions.dart';

/// Factory signature: takes `currentBand` so the SummaryBloc handlers
/// can compute the next band/userAdjusted off it.
typedef SummaryBlocFactory = SummaryBloc Function(
  BuildContext context,
  DifficultyBand currentBand,
);

/// Экран «end-of-session» (R23): per-heuristic дельты («прокачал /
/// замедлился»), число drill-cards, заведённых replay-diff-ом, и
/// 4 post-session кнопки (R37) под `PostSessionActions`. На любой из
/// 4-х кнопок Bloc emit-ит `nextGameRequest` → экран pop-ит этот
/// `NextGameRequest`, launcher принимает его и поднимает следующую
/// партию с новым band/userAdjusted.
///
/// «Подробнее» (AE7) ведёт на MasteryScreen, который пока не
/// реализован (U13) — кнопка показывает SnackBar-stub.
class EndOfSessionScreen extends StatelessWidget {
  const EndOfSessionScreen({
    super.key,
    required this.recordedMoves,
    required this.replayDiff,
    required this.currentBand,
    this.initialPosition,
    this.summaryBlocFactory,
  });

  final List<RecordedMove> recordedMoves;
  final ReplayDiffResult? replayDiff;

  /// Band только что сыгранной партии — нужен `PostSessionActions`-у
  /// для disabled-состояний boundary-кнопок и `SummaryBloc`-у для
  /// расчёта next band.
  final DifficultyBand currentBand;

  /// Стартовая позиция партии — нужна для R32 bias детектора в
  /// SummaryBloc-е. `null` в легаси-тестах / smoke runs без DI;
  /// тогда секция «Bias-флаги» просто не рендерится.
  final TangoPosition? initialPosition;

  /// Optional override for tests / DI. В runtime приложение
  /// инжектит SummaryBloc через repository-стек.
  final SummaryBlocFactory? summaryBlocFactory;

  @override
  Widget build(BuildContext context) {
    final factory = summaryBlocFactory;
    if (factory == null) {
      // Tests / smoke runs without DI: render the static body off the
      // pre-baked replay-diff data without touching MasteryScorer.
      return _StaticEndOfSession(
        recordedMoves: recordedMoves,
        replayDiff: replayDiff,
        currentBand: currentBand,
      );
    }
    return BlocProvider<SummaryBloc>(
      create: (ctx) {
        final bloc = factory(ctx, currentBand);
        bloc.add(SummaryRequested(
          recordedMoves: recordedMoves,
          replayDiff: replayDiff,
          initialPosition: initialPosition,
        ));
        return bloc;
      },
      child: _SummaryView(currentBand: currentBand),
    );
  }
}

/// Light-weight fallback used when no SummaryBloc factory was passed.
/// Shows the drill-cards banner + the same `PostSessionActions` strip,
/// but pops with synthesised `NextGameRequest`s instead of going through
/// `SummaryBloc`. Used by tests / smoke runs without a MasteryScorer.
class _StaticEndOfSession extends StatelessWidget {
  const _StaticEndOfSession({
    required this.recordedMoves,
    required this.replayDiff,
    required this.currentBand,
  });

  final List<RecordedMove> recordedMoves;
  final ReplayDiffResult? replayDiff;
  final DifficultyBand currentBand;

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
            PostSessionActions(
              currentBand: currentBand,
              // No rotator available — auto reuses currentBand. Fine
              // for tests / smoke; real flow goes through SummaryBloc.
              onAuto: () => Navigator.of(context).pop(
                NextGameRequest(band: currentBand, userAdjusted: false),
              ),
              onSame: () => Navigator.of(context).pop(
                NextGameRequest(band: currentBand, userAdjusted: true),
              ),
              onHarder: () => Navigator.of(context).pop(
                NextGameRequest(
                  band: currentBand.bumpUp(),
                  userAdjusted: true,
                ),
              ),
              onEasier: () => Navigator.of(context).pop(
                NextGameRequest(
                  band: currentBand.bumpDown(),
                  userAdjusted: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.currentBand});

  final DifficultyBand currentBand;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SummaryBloc, SummaryState>(
      listenWhen: (a, b) =>
          a.nextGameRequest == null && b.nextGameRequest != null,
      listener: (context, state) {
        Navigator.of(context).pop(state.nextGameRequest);
      },
      child: Scaffold(
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
                return _SummaryBody(state: state, currentBand: currentBand);
            }
          },
        ),
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.state, required this.currentBand});
  final SummaryState state;
  final DifficultyBand currentBand;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SummaryBloc>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrillCardsBanner(count: state.drillCardsAdded),
          const SizedBox(height: 16),
          if (state.modeBreakdown != null && !state.modeBreakdown!.isEmpty) ...[
            _ModeBreakdownSection(breakdown: state.modeBreakdown!),
            const SizedBox(height: 16),
          ],
          if (state.biasIncidents.isNotEmpty) ...[
            _BiasFlagsSection(incidents: state.biasIncidents),
            const SizedBox(height: 16),
          ],
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('summary-details'),
              onPressed: () {
                // U13 — MasteryScreen ещё не реализован. Заглушка.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mastery screen — coming in U13'),
                  ),
                );
              },
              child: const Text('Details'),
            ),
          ),
          const SizedBox(height: 8),
          PostSessionActions(
            currentBand: currentBand,
            onAuto: () => bloc.add(const NextAuto()),
            onSame: () => bloc.add(const NextSame()),
            onHarder: () => bloc.add(const NextHarder()),
            onEasier: () => bloc.add(const NextEasier()),
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

/// R31 — секция «Propagation/Hunt» с долями и slowest-hunt-паттерном.
class _ModeBreakdownSection extends StatelessWidget {
  const _ModeBreakdownSection({required this.breakdown});
  final ModeBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final propPct = (breakdown.propagationFraction * 100).round();
    final huntPct = (breakdown.huntFraction * 100).round();
    final slowest = breakdown.slowestHuntHeuristic;
    final slowestP99 = slowest == null
        ? null
        : breakdown.p99HuntLatencyByHeuristic[slowest];
    return Card(
      key: const ValueKey('summary-mode-breakdown'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Propagation / Hunt',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Propagation $propPct% · Hunt $huntPct%'),
            if (slowest != null && slowestP99 != null) ...[
              const SizedBox(height: 4),
              Text(
                'Slowest hunt: ${slowest.tagId} (p99 $slowestP99 ms)',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// R32 — секция «Bias-флаги»: список line_completion инцидентов.
class _BiasFlagsSection extends StatelessWidget {
  const _BiasFlagsSection({required this.incidents});
  final List<BiasIncident> incidents;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('summary-bias-flags'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bias-флаги',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final inc in incidents)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Move #${inc.atMoveIndex + 1}: ${inc.reason} '
                  '(${(inc.elapsedMs / 1000).toStringAsFixed(1)} s)'
                  ' — (${inc.missedRow},${inc.missedCol})',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
