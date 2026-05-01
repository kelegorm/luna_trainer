import 'dart:async';

import 'package:flutter/widgets.dart';

/// Сигнал о фактическом backgrounding-е во время хода: длительность
/// окна между уходом приложения из `resumed` и возвратом обратно.
/// Эмитируется только если окно ≥ debounce (500 ms) — короткие
/// `inactive`-blip-ы (iOS Control Center, notch таскбар) не считаются.
class LifecycleSignal {
  const LifecycleSignal({
    required this.startedAt,
    required this.bgDuration,
  });

  /// Wall-clock время первой не-`resumed` транзиции.
  final DateTime startedAt;

  /// Время от начала pause до возврата в `resumed`.
  final Duration bgDuration;

  @override
  String toString() =>
      'LifecycleSignal(at=$startedAt, bg=${bgDuration.inMilliseconds}ms)';
}

/// Тонкий враппер вокруг lifecycle-состояний — НЕ подписывается на
/// `AppLifecycleListener` сам. Подписку (и трансляцию состояний в
/// [onState]) делает интеграционный слой; такая инверсия упрощает
/// unit-тесты (clock injectable, состояния fed-in явно).
///
/// Семантика: на первой не-`resumed` транзиции фиксируется
/// `_bgStartedAt`; на возвращении в `resumed` считается dur и, если
/// dur ≥ [debounce], эмитируется [LifecycleSignal].
class LifecycleObserver {
  LifecycleObserver({
    DateTime Function()? now,
    this.debounce = const Duration(milliseconds: 500),
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Минимальная длительность ухода в фон, при которой это
  /// засчитывается как реальный pause. iOS pitfall: <500ms почти
  /// всегда «ничего не было».
  final Duration debounce;

  final StreamController<LifecycleSignal> _controller =
      StreamController<LifecycleSignal>.broadcast();

  Stream<LifecycleSignal> get signals => _controller.stream;

  DateTime? _bgStartedAt;
  bool _disposed = false;

  /// Скармливает observer-у новое lifecycle-состояние. На входе
  /// должен быть свежий сигнал из `AppLifecycleListener`-обёртки.
  void onState(AppLifecycleState state) {
    if (_disposed) return;

    if (state == AppLifecycleState.resumed) {
      final pausedAt = _bgStartedAt;
      _bgStartedAt = null;
      if (pausedAt == null) return;
      final dur = _now().difference(pausedAt);
      if (dur >= debounce) {
        _controller.add(
          LifecycleSignal(startedAt: pausedAt, bgDuration: dur),
        );
      }
    } else {
      // Любое не-resumed состояние (inactive / paused / hidden /
      // detached) считается «вне переднего плана» — фиксируем самую
      // раннюю такую точку.
      _bgStartedAt ??= _now();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.close();
  }
}
