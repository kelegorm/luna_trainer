import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/app.dart';

void main() {
  testWidgets('Home screen renders Full game and Drill buttons', (
    tester,
  ) async {
    await tester.pumpWidget(const LunaTrainerApp());

    expect(find.text('Luna Trainer'), findsOneWidget);
    expect(find.text('Full game'), findsOneWidget);
    expect(find.text('Drill'), findsOneWidget);
  });
}
