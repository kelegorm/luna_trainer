import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../puzzles/tango/domain/tango_position.dart';
import '../../../puzzles/tango/solver/tango_deduction.dart';
import '../bloc/full_game_bloc.dart';
import 'training_field.dart';

/// Лесенка hint-ов (R12, R13, AE2). 4 шага:
///
/// 1. Имя heuristic-а («это ParityFill»).
/// 2. Preconditions на учебной мини-доске (TrainingField). Основная
///    доска не пачкается.
/// 3. Optimal move — какую клетку и в какой mark поставить.
/// 4. Explanation. **На этом шаге Bloc паузит move-таймер** (R13).
///
/// Все state-переходы делаются через FullGameBloc.add(...).
class HintLadderOverlay extends StatelessWidget {
  const HintLadderOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FullGameBloc, FullGameState>(
      buildWhen: (a, b) =>
          a.hintOverlayOpen != b.hintOverlayOpen ||
          a.hintStep != b.hintStep ||
          a.suggestedDeduction != b.suggestedDeduction,
      builder: (context, state) {
        if (!state.hintOverlayOpen) return const SizedBox.shrink();
        return Material(
          color: Colors.black.withValues(alpha: 0.6),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _HintBody(state: state),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HintBody extends StatelessWidget {
  const _HintBody({required this.state});
  final FullGameState state;

  @override
  Widget build(BuildContext context) {
    final step = state.hintStep;
    final deduction = state.suggestedDeduction;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hint — step $step / 4',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (deduction == null)
          const Text(
            'Solver not finding a cheap deduction here.\n'
            'Try a few moves and reopen the hint.',
          )
        else
          _stepBody(context, step, deduction, state.position!),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              key: const ValueKey('hint-dismiss'),
              onPressed: () =>
                  context.read<FullGameBloc>().add(const HintDismissed()),
              child: const Text('Close'),
            ),
            FilledButton(
              key: const ValueKey('hint-next'),
              onPressed: step >= 4
                  ? null
                  : () => context
                      .read<FullGameBloc>()
                      .add(const HintStepAdvanced()),
              child: Text(step >= 4 ? 'Done' : 'Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepBody(
    BuildContext context,
    int step,
    TangoDeduction deduction,
    TangoPosition position,
  ) {
    switch (step) {
      case 1:
        return _StepName(deduction: deduction);
      case 2:
        return _StepPreconds(position: position, deduction: deduction);
      case 3:
        return _StepOptimalMove(deduction: deduction);
      case 4:
        return _StepExplanation(deduction: deduction);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StepName extends StatelessWidget {
  const _StepName({required this.deduction});
  final TangoDeduction deduction;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Technique: ${deduction.heuristic.tagId}',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class _StepPreconds extends StatelessWidget {
  const _StepPreconds({required this.position, required this.deduction});
  final TangoPosition position;
  final TangoDeduction deduction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Look at the highlighted cells on this practice board:'),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: TrainingField(position: position, deduction: deduction),
        ),
      ],
    );
  }
}

class _StepOptimalMove extends StatelessWidget {
  const _StepOptimalMove({required this.deduction});
  final TangoDeduction deduction;

  @override
  Widget build(BuildContext context) {
    final cells = deduction.forcedCells
        .map((c) => '(${c.row + 1}, ${c.col + 1})')
        .join(', ');
    return Text(
      'Place ${deduction.forcedMark.name} in $cells.',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class _StepExplanation extends StatelessWidget {
  const _StepExplanation({required this.deduction});
  final TangoDeduction deduction;

  @override
  Widget build(BuildContext context) {
    return Text(
      _explanationFor(deduction.heuristic.tagId),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  String _explanationFor(String tag) {
    switch (tag) {
      case 'ParityFill':
        return 'A row/column already has 3 of one mark, so the remaining '
            'cells must take the other.';
      case 'TrioAvoidance':
        return 'Two equal marks together force the next cell to be the '
            'opposite — three in a row are illegal.';
      case 'SignPropagation':
        return '`=` and `×` edges propagate marks across the line.';
      case 'PairCompletion':
        return 'A pair of identical marks at the right offset forces the '
            'cells between them.';
      case 'AdvancedMidLineInference':
        return 'Mid-line inference: backtrack the only valid completion of '
            'a 2-empty pattern.';
      case 'ChainExtension':
        return 'Apply the previous deduction one step further along the '
            'same line.';
      default:
        return 'Combination of cheap rules — keep practicing.';
    }
  }
}
