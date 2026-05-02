import 'package:flutter/material.dart';

import '../../../puzzles/tango/generator/difficulty_band.dart';

/// End-of-session «что дальше» — 4 кнопки выбора следующей партии
/// (R37). Чисто презентационный виджет: ничего не знает про
/// `BandRotator` или `SummaryBloc`, только дёргает callback на нажатии.
/// Wiring в bloc/launcher живёт уровнем выше.
///
/// **R34 invariant.** Цифру band-а виджет **не показывает** — ни в
/// явном виде, ни внутри строк лейблов. Направления передаются
/// иконками `▲/▼` и текстом «Сложнее»/«Легче», поэтому пользователь
/// видит относительный nudge без числовой обратной связи. Виджет-тест
/// (`post_session_actions_test.dart`) поднимает дерево и проверяет,
/// что ни одна `Text`-нода не содержит цифр 1/2/3 в любом контексте.
class PostSessionActions extends StatelessWidget {
  const PostSessionActions({
    super.key,
    required this.currentBand,
    required this.onAuto,
    required this.onSame,
    required this.onHarder,
    required this.onEasier,
  });

  /// Band только что сыгранной партии — нужен для disabled-состояний
  /// boundary-кнопок («Сложнее» при hard, «Лёгче» при easy).
  final DifficultyBand currentBand;

  /// «Следующая»: rotator выбирает band автоматически, `userAdjusted=false`.
  final VoidCallback onAuto;

  /// «Ещё такую же»: тот же band, `userAdjusted=true`. Rotator state
  /// **не** сдвигается (контракт с R37).
  final VoidCallback onSame;

  /// «Сложнее ▲»: `currentBand.bumpUp()`, `userAdjusted=true`.
  /// Disabled при `currentBand == hard`.
  final VoidCallback onHarder;

  /// «Легче ▼»: `currentBand.bumpDown()`, `userAdjusted=true`.
  /// Disabled при `currentBand == easy`.
  final VoidCallback onEasier;

  @override
  Widget build(BuildContext context) {
    final canHarder = currentBand != DifficultyBand.hard;
    final canEasier = currentBand != DifficultyBand.easy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const ValueKey('post-session-auto'),
          onPressed: onAuto,
          child: const Text('Следующая'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('post-session-same'),
          onPressed: onSame,
          child: const Text('Ещё такую же'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('post-session-easier'),
                onPressed: canEasier ? onEasier : null,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Легче'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('post-session-harder'),
                onPressed: canHarder ? onHarder : null,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Сложнее'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
