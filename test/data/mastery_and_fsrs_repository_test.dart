import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/fsrs_repository.dart';
import 'package:luna_traineer/data/repositories/mastery_repository.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';

const _parityFill = Heuristic('tango', 'ParityFill');

void main() {
  late LunaDatabase db;
  late MasteryRepository mastery;
  late FsrsRepository fsrs;

  setUp(() {
    db = LunaDatabase.forTesting(NativeDatabase.memory());
    mastery = MasteryRepository(db);
    fsrs = FsrsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MasteryRepository', () {
    test('upsert respects composite (kindId, heuristicTag) PK — no dupes',
        () async {
      await mastery.upsert(
        MasteryStateCompanion.insert(
          kindId: _parityFill.kindId,
          heuristicTag: _parityFill.tagId,
          eventCount: const Value(5),
          lastUpdatedAt: 100,
        ),
      );
      await mastery.upsert(
        MasteryStateCompanion.insert(
          kindId: _parityFill.kindId,
          heuristicTag: _parityFill.tagId,
          eventCount: const Value(7),
          lastUpdatedAt: 200,
        ),
      );

      final all = await mastery.watchAll().first;
      expect(all.length, 1, reason: 'composite PK upsert merges');
      expect(all.single.eventCount, 7);
      expect(all.single.lastUpdatedAt, 200);
    });

    test('empty DB — find returns null, watchAll yields empty', () async {
      expect(await mastery.find(_parityFill), isNull);
      expect(await mastery.watchAll().first, isEmpty);
    });

    test('isCalibrating defaults to true', () async {
      await mastery.upsert(
        MasteryStateCompanion.insert(
          kindId: _parityFill.kindId,
          heuristicTag: _parityFill.tagId,
          lastUpdatedAt: 1,
        ),
      );
      final row = await mastery.find(_parityFill);
      expect(row!.isCalibrating, isTrue);
    });
  });

  group('FsrsRepository', () {
    test('dueAt returns only cards whose due_at <= now, oldest first',
        () async {
      Future<void> insertCard(Heuristic h, int dueAt) {
        return fsrs.upsert(
          FsrsCardsCompanion.insert(
            kindId: h.kindId,
            heuristicTag: h.tagId,
            stateBlob: Uint8List.fromList(const [0]),
            dueAt: dueAt,
          ),
        );
      }

      const a = Heuristic('tango', 'A');
      const b = Heuristic('tango', 'B');
      const c = Heuristic('tango', 'C');

      await insertCard(a, 100);
      await insertCard(b, 50);
      await insertCard(c, 1000);

      final due = await fsrs.dueAt(
        DateTime.fromMillisecondsSinceEpoch(200),
      );
      expect(
        due.map((r) => r.heuristicTag).toList(),
        ['B', 'A'],
        reason: 'oldest due first; future cards excluded',
      );
    });

    test('upsert is idempotent on composite PK', () async {
      await fsrs.upsert(
        FsrsCardsCompanion.insert(
          kindId: _parityFill.kindId,
          heuristicTag: _parityFill.tagId,
          stateBlob: Uint8List.fromList(const [1, 2, 3]),
          dueAt: 100,
        ),
      );
      await fsrs.upsert(
        FsrsCardsCompanion.insert(
          kindId: _parityFill.kindId,
          heuristicTag: _parityFill.tagId,
          stateBlob: Uint8List.fromList(const [9]),
          dueAt: 200,
        ),
      );
      final row = await fsrs.find(_parityFill);
      expect(row!.dueAt, 200);
      expect(row.stateBlob, Uint8List.fromList(const [9]));
    });
  });
}
