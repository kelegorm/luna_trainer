import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/engine/drill/drill_selector.dart';
import 'package:luna_traineer/engine/drill/target_mix_builder.dart';

const _parityFill = Heuristic('tango', 'ParityFill');
const _signProp = Heuristic('tango', 'SignPropagation');
const _trio = Heuristic('tango', 'TrioAvoidance');
const _composite = Heuristic('tango', 'Composite');

void main() {
  group('TargetMixBuilder.build', () {
    test('one slot → one TargetMix focused on the slot heuristic', () {
      const batch = DrillBatch([
        DrillSlot(heuristic: _parityFill, kind: DrillSlotKind.due),
      ]);
      final mixes = const TargetMixBuilder().build(batch);

      expect(mixes.length, 1);
      expect(mixes.single.weights.keys, [_parityFill]);
      expect(mixes.single.weights[_parityFill], 1.0);
    });

    test('multiple slots → one TargetMix per slot, in order', () {
      const batch = DrillBatch([
        DrillSlot(heuristic: _parityFill, kind: DrillSlotKind.due),
        DrillSlot(heuristic: _signProp, kind: DrillSlotKind.weaknessFill),
        DrillSlot(heuristic: _trio, kind: DrillSlotKind.due),
      ]);
      final mixes = const TargetMixBuilder().build(batch);

      expect(mixes.length, 3);
      expect(mixes[0].weights.keys.single, _parityFill);
      expect(mixes[1].weights.keys.single, _signProp);
      expect(mixes[2].weights.keys.single, _trio);
    });

    test('skips slots whose heuristic is not drill-eligible (Composite)', () {
      const batch = DrillBatch([
        DrillSlot(heuristic: _parityFill, kind: DrillSlotKind.due),
        DrillSlot(heuristic: _composite, kind: DrillSlotKind.weaknessFill),
        DrillSlot(heuristic: _trio, kind: DrillSlotKind.due),
      ]);
      final mixes = const TargetMixBuilder().build(batch);

      expect(mixes.length, 2);
      expect(mixes[0].weights.keys.single, _parityFill);
      expect(mixes[1].weights.keys.single, _trio);
    });

    test('empty batch → empty list', () {
      final mixes = const TargetMixBuilder().build(const DrillBatch([]));
      expect(mixes, isEmpty);
    });
  });
}
