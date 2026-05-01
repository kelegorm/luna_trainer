import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/mastery/ewma.dart';

void main() {
  group('Ewma.next', () {
    test('first sample with no prior history returns the sample itself', () {
      // For the very first event we have no prior — caller passes
      // null as previous, and the recurrence collapses to the
      // sample. This avoids the bias of "starting at 0".
      expect(Ewma.next(sample: 0.7, previous: null, alpha: 0.1), 0.7);
    });

    test('with α=0.1, m_t = 0.1·sample + 0.9·previous', () {
      // 0.1·1.0 + 0.9·0.0 = 0.1
      expect(Ewma.next(sample: 1.0, previous: 0.0, alpha: 0.1), closeTo(0.1, 1e-12));
      // 0.1·0.0 + 0.9·1.0 = 0.9
      expect(Ewma.next(sample: 0.0, previous: 1.0, alpha: 0.1), closeTo(0.9, 1e-12));
    });

    test('repeatedly applying same sample converges to that sample', () {
      double m = 0.0;
      for (var i = 0; i < 200; i++) {
        m = Ewma.next(sample: 0.42, previous: m, alpha: 0.1);
      }
      expect(m, closeTo(0.42, 1e-6));
    });

    test('output stays in [0, 1] when sample and previous both in [0, 1]', () {
      for (final s in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        for (final p in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final m = Ewma.next(sample: s, previous: p, alpha: 0.1);
          expect(m, inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('default alpha is 0.1 (plan R7)', () {
      // 0.1·1.0 + 0.9·0.0 = 0.1
      expect(Ewma.next(sample: 1.0, previous: 0.0), closeTo(0.1, 1e-12));
    });

    test('rejects alpha outside (0, 1]', () {
      expect(
        () => Ewma.next(sample: 0.5, previous: 0.5, alpha: 0.0),
        throwsArgumentError,
      );
      expect(
        () => Ewma.next(sample: 0.5, previous: 0.5, alpha: 1.5),
        throwsArgumentError,
      );
    });
  });
}
