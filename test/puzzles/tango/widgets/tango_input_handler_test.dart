import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/puzzles/tango/domain/tango_mark.dart';
import 'package:luna_traineer/puzzles/tango/widgets/tango_input_handler.dart';

void main() {
  group('nextTangoMark', () {
    test('empty → sun', () {
      expect(nextTangoMark(null), TangoMark.sun);
    });

    test('sun → moon', () {
      expect(nextTangoMark(TangoMark.sun), TangoMark.moon);
    });

    test('moon → empty', () {
      expect(nextTangoMark(TangoMark.moon), isNull);
    });

    test('full cycle returns to start after three taps', () {
      TangoMark? mark;
      mark = nextTangoMark(mark);
      mark = nextTangoMark(mark);
      mark = nextTangoMark(mark);
      expect(mark, isNull);
    });
  });
}
