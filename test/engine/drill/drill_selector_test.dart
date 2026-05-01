import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/fsrs_repository.dart';
import 'package:luna_traineer/data/repositories/mastery_repository.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/engine/drill/drill_selector.dart';
import 'package:luna_traineer/engine/fsrs/fsrs_scheduler.dart';

const _h1 = Heuristic('tango', 'ParityFill');
const _h2 = Heuristic('tango', 'SignPropagation');
const _h3 = Heuristic('tango', 'TrioAvoidance');
const _h4 = Heuristic('tango', 'EdgeForcedFill');
const _h5 = Heuristic('tango', 'BalancedRow');

void main() {
  late LunaDatabase db;
  late FsrsRepository fsrsRepo;
  late MasteryRepository masteryRepo;
  late FsrsScheduler scheduler;
  late DrillSelector selector;

  Future<void> primeMastery(
    Heuristic h, {
    required bool isCalibrating,
    required double ewmaPercentile,
    double errorRate = 0.0,
    double hintRate = 0.0,
    int eventCount = 50,
  }) {
    return masteryRepo.upsert(
      MasteryStateCompanion.insert(
        kindId: h.kindId,
        heuristicTag: h.tagId,
        eventCount: Value(eventCount),
        ewmaPercentile: Value(ewmaPercentile),
        errorRate: Value(errorRate),
        hintRate: Value(hintRate),
        lastUpdatedAt: 0,
        isCalibrating: Value(isCalibrating),
      ),
    );
  }

  setUp(() {
    db = LunaDatabase.forTesting(NativeDatabase.memory());
    fsrsRepo = FsrsRepository(db);
    masteryRepo = MasteryRepository(db);
    scheduler = FsrsScheduler(
      fsrsRepository: fsrsRepo,
      scheduler: Scheduler(enableFuzzing: false),
    );
    selector = DrillSelector(
      scheduler: scheduler,
      masteryRepository: masteryRepo,
      fsrsRepository: fsrsRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('pickNext', () {
    test('empty state → empty DrillBatch', () async {
      final batch = await selector.pickNext(now: DateTime.utc(2026, 5, 1));
      expect(batch.slots, isEmpty);
      expect(batch.isEmpty, isTrue);
    });

    test('due + non-calibrating → returns due slots, oldest due first',
        () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      // Three Goods at staggered times → distinct due timestamps.
      await scheduler.reviewCard(_h1, Rating.good, now: t0);
      await scheduler.reviewCard(_h2, Rating.good,
          now: t0.add(const Duration(seconds: 1)));
      await scheduler.reviewCard(_h3, Rating.good,
          now: t0.add(const Duration(seconds: 2)));

      // All three have non-calibrating mastery rows.
      await primeMastery(_h1, isCalibrating: false, ewmaPercentile: 0.5);
      await primeMastery(_h2, isCalibrating: false, ewmaPercentile: 0.5);
      await primeMastery(_h3, isCalibrating: false, ewmaPercentile: 0.5);

      final later = t0.add(const Duration(days: 30));
      final batch = await selector.pickNext(count: 10, now: later);

      expect(batch.slots.length, 3);
      expect(
          batch.slots.map((s) => s.kind), everyElement(DrillSlotKind.due));
      expect(batch.slots.map((s) => s.heuristic), [_h1, _h2, _h3]);
    });

    test('R10: calibrating heuristic with due card is NEVER drilled',
        () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      await scheduler.reviewCard(_h1, Rating.good, now: t0);
      // _h1 has only 5 events → still calibrating.
      await primeMastery(_h1,
          isCalibrating: true, ewmaPercentile: 0.5, eventCount: 5);

      final later = t0.add(const Duration(days: 30));
      final batch = await selector.pickNext(count: 10, now: later);
      expect(batch.slots, isEmpty);
    });

    test('5 due + 3 non-calibrating non-due → 8 slots, due then weakness fill',
        () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      // 5 cards reviewed → 5 due in 30 days.
      for (final h in [_h1, _h2, _h3, _h4, _h5]) {
        await scheduler.reviewCard(h, Rating.good, now: t0);
        await primeMastery(h, isCalibrating: false, ewmaPercentile: 0.5);
      }

      // 3 more heuristics with no FSRS row, but weak mastery — these
      // become weakness-fill candidates. Lower ewmaPercentile means
      // slower → weaker.
      const h6 = Heuristic('tango', 'A');
      const h7 = Heuristic('tango', 'B');
      const h8 = Heuristic('tango', 'C');
      await primeMastery(h6, isCalibrating: false, ewmaPercentile: 0.1);
      await primeMastery(h7, isCalibrating: false, ewmaPercentile: 0.2);
      await primeMastery(h8, isCalibrating: false, ewmaPercentile: 0.3);

      final later = t0.add(const Duration(days: 30));
      final batch = await selector.pickNext(count: 10, now: later);

      expect(batch.slots.length, 8);
      // First 5 = due, last 3 = weakness fill, ordered by weakness desc.
      expect(
        batch.slots.take(5).map((s) => s.kind),
        everyElement(DrillSlotKind.due),
      );
      expect(
        batch.slots.skip(5).map((s) => s.kind),
        everyElement(DrillSlotKind.weaknessFill),
      );
      // h6 (ewma=0.1, weakness=0.36) is weakest → drilled first.
      expect(batch.slots[5].heuristic, h6);
      expect(batch.slots[6].heuristic, h7);
      expect(batch.slots[7].heuristic, h8);
    });

    test('weakness fill respects count cap', () async {
      // No FSRS rows; 5 weak heuristics; count=3.
      const h6 = Heuristic('tango', 'A');
      const h7 = Heuristic('tango', 'B');
      const h8 = Heuristic('tango', 'C');
      await primeMastery(_h1, isCalibrating: false, ewmaPercentile: 0.9);
      await primeMastery(_h2, isCalibrating: false, ewmaPercentile: 0.8);
      await primeMastery(h6, isCalibrating: false, ewmaPercentile: 0.1);
      await primeMastery(h7, isCalibrating: false, ewmaPercentile: 0.2);
      await primeMastery(h8, isCalibrating: false, ewmaPercentile: 0.3);

      final batch = await selector.pickNext(
        count: 3,
        now: DateTime.utc(2026, 5, 1),
      );

      expect(batch.slots.length, 3);
      expect(batch.slots.map((s) => s.heuristic), [h6, h7, h8]);
    });

    test('due not yet reached → not picked, weakness fill backstops',
        () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      await scheduler.reviewCard(_h1, Rating.easy, now: t0);
      await primeMastery(_h1, isCalibrating: false, ewmaPercentile: 0.5);
      // _h2 has no FSRS row but is weak → falls into weakness fill.
      await primeMastery(_h2, isCalibrating: false, ewmaPercentile: 0.1);

      // Just one hour later, _h1's Easy interval still pending.
      final batch = await selector.pickNext(
        count: 10,
        now: t0.add(const Duration(hours: 1)),
      );
      expect(batch.slots.length, 1);
      expect(batch.slots.single.heuristic, _h2);
      expect(batch.slots.single.kind, DrillSlotKind.weaknessFill);
    });

    test(
        'integration: pickNext → review → pickNext does not put it first '
        'next time', () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      await scheduler.reviewCard(_h1, Rating.good, now: t0);
      await scheduler.reviewCard(_h2, Rating.good,
          now: t0.add(const Duration(seconds: 1)));
      await primeMastery(_h1, isCalibrating: false, ewmaPercentile: 0.5);
      await primeMastery(_h2, isCalibrating: false, ewmaPercentile: 0.5);

      final later = t0.add(const Duration(days: 30));
      final first = await selector.pickNext(count: 2, now: later);
      expect(first.slots.first.heuristic, _h1);

      // User solves the first puzzle and gets a Good — _h1's due
      // jumps far into the future.
      await scheduler.reviewCard(_h1, Rating.good, now: later);

      final second = await selector.pickNext(count: 2, now: later);
      expect(second.slots.first.heuristic, _h2,
          reason: '_h1 is no longer the most-overdue');
    });
  });
}
