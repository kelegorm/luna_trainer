import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';

void main() {
  group('Heuristic', () {
    test('equal under identical kindId and tagId', () {
      expect(
        const Heuristic('tango', 'ParityFill'),
        equals(const Heuristic('tango', 'ParityFill')),
      );
    });

    test('namespaced by kindId — same tagId across kinds is distinct', () {
      const tango = Heuristic('tango', 'ParityFill');
      const queens = Heuristic('queens', 'ParityFill');

      expect(tango, isNot(equals(queens)));
      expect(tango.hashCode, isNot(equals(queens.hashCode)));
    });

    test('different tagId within the same kind is distinct', () {
      const a = Heuristic('tango', 'ParityFill');
      const b = Heuristic('tango', 'TrioAvoidance');

      expect(a, isNot(equals(b)));
    });

    test('toString is debuggable', () {
      expect(
        const Heuristic('tango', 'ParityFill').toString(),
        'Heuristic(tango/ParityFill)',
      );
    });
  });
}
