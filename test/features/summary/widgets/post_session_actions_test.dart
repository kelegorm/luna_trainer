import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/features/summary/widgets/post_session_actions.dart';
import 'package:luna_traineer/puzzles/tango/generator/difficulty_band.dart';

Widget _host({
  required DifficultyBand band,
  VoidCallback? onAuto,
  VoidCallback? onSame,
  VoidCallback? onHarder,
  VoidCallback? onEasier,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PostSessionActions(
        currentBand: band,
        onAuto: onAuto ?? () {},
        onSame: onSame ?? () {},
        onHarder: onHarder ?? () {},
        onEasier: onEasier ?? () {},
      ),
    ),
  );
}

void main() {
  group('PostSessionActions', () {
    testWidgets('renders exactly the 4 whitelisted button labels',
        (tester) async {
      await tester.pumpWidget(_host(band: DifficultyBand.medium));

      // Plan AE12: ровно 4 кнопки с whitelisted-лейблами.
      expect(find.text('Следующая'), findsOneWidget);
      expect(find.text('Ещё такую же'), findsOneWidget);
      expect(find.text('Сложнее'), findsOneWidget);
      expect(find.text('Легче'), findsOneWidget);
    });

    testWidgets('R34 invariant: no digit 1/2/3 anywhere in the widget tree',
        (tester) async {
      // Проверяем для всех трёх bands — ни в одном из них
      // current-band-цифра не должна просочиться в UI.
      for (final band in DifficultyBand.values) {
        await tester.pumpWidget(_host(band: band));
        final digitText = find.byWidgetPredicate((w) {
          if (w is! Text) return false;
          final data = w.data;
          if (data == null) return false;
          return RegExp(r'\b[123]\b').hasMatch(data);
        });
        expect(
          digitText,
          findsNothing,
          reason: 'band=$band: ни одна Text-нода не должна содержать 1/2/3',
        );
      }
    });

    ButtonStyleButton btn(WidgetTester tester, String key) {
      return tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key)));
    }

    testWidgets('band=easy: «Легче» disabled, «Сложнее» enabled',
        (tester) async {
      await tester.pumpWidget(_host(band: DifficultyBand.easy));

      expect(btn(tester, 'post-session-easier').enabled, isFalse);
      expect(btn(tester, 'post-session-harder').enabled, isTrue);
    });

    testWidgets('band=hard: «Сложнее» disabled, «Легче» enabled',
        (tester) async {
      await tester.pumpWidget(_host(band: DifficultyBand.hard));

      expect(btn(tester, 'post-session-harder').enabled, isFalse);
      expect(btn(tester, 'post-session-easier').enabled, isTrue);
    });

    testWidgets('band=medium: all 4 buttons enabled', (tester) async {
      await tester.pumpWidget(_host(band: DifficultyBand.medium));

      for (final key in const [
        'post-session-auto',
        'post-session-same',
        'post-session-harder',
        'post-session-easier',
      ]) {
        expect(btn(tester, key).enabled, isTrue,
            reason: '$key must be enabled at band=medium');
      }
    });

    testWidgets('each press fires only the matching callback', (tester) async {
      var auto = 0, same = 0, harder = 0, easier = 0;
      await tester.pumpWidget(_host(
        band: DifficultyBand.medium,
        onAuto: () => auto++,
        onSame: () => same++,
        onHarder: () => harder++,
        onEasier: () => easier++,
      ));

      await tester.tap(find.text('Следующая'));
      await tester.pump();
      expect((auto, same, harder, easier), (1, 0, 0, 0));

      await tester.tap(find.text('Ещё такую же'));
      await tester.pump();
      expect((auto, same, harder, easier), (1, 1, 0, 0));

      await tester.tap(find.text('Сложнее'));
      await tester.pump();
      expect((auto, same, harder, easier), (1, 1, 1, 0));

      await tester.tap(find.text('Легче'));
      await tester.pump();
      expect((auto, same, harder, easier), (1, 1, 1, 1));
    });

    testWidgets('disabled boundary buttons do not fire callbacks',
        (tester) async {
      var harder = 0, easier = 0;

      await tester.pumpWidget(_host(
        band: DifficultyBand.hard,
        onHarder: () => harder++,
      ));
      await tester.tap(
        find.byKey(const ValueKey('post-session-harder')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(harder, 0);

      await tester.pumpWidget(_host(
        band: DifficultyBand.easy,
        onEasier: () => easier++,
      ));
      await tester.tap(
        find.byKey(const ValueKey('post-session-easier')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(easier, 0);
    });
  });
}
