import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:luna_traineer/data/database.dart';
import 'package:luna_traineer/data/repositories/fsrs_repository.dart';
import 'package:luna_traineer/engine/domain/heuristic.dart';
import 'package:luna_traineer/engine/fsrs/fsrs_scheduler.dart';

const _parityFill = Heuristic('tango', 'ParityFill');
const _signProp = Heuristic('tango', 'SignPropagation');

void main() {
  late LunaDatabase db;
  late FsrsRepository repo;
  late FsrsScheduler scheduler;

  setUp(() {
    db = LunaDatabase.forTesting(NativeDatabase.memory());
    repo = FsrsRepository(db);
    scheduler = FsrsScheduler(
      fsrsRepository: repo,
      // Disable fuzzing for deterministic intervals in tests.
      scheduler: Scheduler(enableFuzzing: false),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('reviewCard — first review', () {
    test('new card + Good → due_at > now (interval ≥ 1 minute)', () async {
      final now = DateTime.utc(2026, 5, 1, 12);
      final reviewed = await scheduler.reviewCard(_parityFill, Rating.good,
          now: now);

      expect(reviewed.heuristic, _parityFill);
      expect(reviewed.due.isAfter(now), isTrue);
      expect(reviewed.lastReview, now);

      // Persisted row mirrors the returned due timestamp.
      final row = await repo.find(_parityFill);
      expect(row, isNotNull);
      expect(row!.dueAt, reviewed.due.millisecondsSinceEpoch);
      expect(row.lastReviewedAt, now.millisecondsSinceEpoch);
    });

    test('new card + Easy → graduates to review with multi-day due', () async {
      final now = DateTime.utc(2026, 5, 1, 12);
      final reviewed = await scheduler.reviewCard(_parityFill, Rating.easy,
          now: now);

      // Easy on first review jumps straight to the review state with
      // a stability-derived interval of at least 1 day.
      final delta = reviewed.due.difference(now);
      expect(delta.inDays, greaterThanOrEqualTo(1));
    });

    test('new card + Again → short relearn-style step', () async {
      final now = DateTime.utc(2026, 5, 1, 12);
      final reviewed = await scheduler.reviewCard(_parityFill, Rating.again,
          now: now);

      final delta = reviewed.due.difference(now);
      // First learning step is 1 minute by default — Again resets to it.
      expect(delta, lessThan(const Duration(hours: 1)));
    });
  });

  group('reviewCard — repeat reviews advance the due date', () {
    test('two Goods in a row → second due is later than the first', () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      final first = await scheduler.reviewCard(_parityFill, Rating.good,
          now: t0);

      // Move clock forward past the first due.
      final t1 = first.due.add(const Duration(minutes: 1));
      final second = await scheduler.reviewCard(_parityFill, Rating.good,
          now: t1);

      expect(second.due.isAfter(first.due), isTrue);
      expect(second.lastReview, t1);
    });
  });

  group('serialization round-trip', () {
    test('persisted blob decodes back into an equivalent Card', () async {
      final now = DateTime.utc(2026, 5, 1, 12);
      await scheduler.reviewCard(_parityFill, Rating.good, now: now);

      final row = await repo.find(_parityFill);
      expect(row, isNotNull);

      // We treat the blob as opaque from app code (per fsrs_cards
      // table comment), but the package guarantees fromMap(toMap) ==.
      final map = jsonDecode(utf8.decode(row!.stateBlob)) as Map<String, dynamic>;
      final decoded = Card.fromMap(map);
      expect(decoded.due.millisecondsSinceEpoch, row.dueAt);
    });

    test('reviewing twice loads prior state from blob (no reset)', () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      final first = await scheduler.reviewCard(_parityFill, Rating.good,
          now: t0);

      // Re-instantiate the scheduler to prove state lives in the DB,
      // not in scheduler memory.
      final fresh = FsrsScheduler(
        fsrsRepository: repo,
        scheduler: Scheduler(enableFuzzing: false),
      );
      final t1 = first.due.add(const Duration(minutes: 1));
      final second = await fresh.reviewCard(_parityFill, Rating.good, now: t1);

      expect(second.due.isAfter(first.due), isTrue);
    });
  });

  group('dueCards', () {
    test('returns cards with due ≤ now, oldest first', () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      // ParityFill: Again → 1-min step. Sign: Good → 10-min step.
      await scheduler.reviewCard(_parityFill, Rating.again, now: t0);
      await scheduler.reviewCard(_signProp, Rating.good, now: t0);

      // 30 minutes later both are due.
      final later = t0.add(const Duration(minutes: 30));
      final due = await scheduler.dueCards(now: later);

      expect(due.length, 2);
      // Oldest first — _parityFill (1-min step) before _signProp (10-min).
      expect(due[0].heuristic, _parityFill);
      expect(due[1].heuristic, _signProp);
    });

    test('returns empty when nothing scheduled yet', () async {
      final due = await scheduler.dueCards(now: DateTime.utc(2026, 5, 1));
      expect(due, isEmpty);
    });

    test('cards not yet due are excluded', () async {
      final t0 = DateTime.utc(2026, 5, 1, 12);
      await scheduler.reviewCard(_parityFill, Rating.easy, now: t0);

      // 1 hour later the Easy multi-day interval is still pending.
      final due = await scheduler.dueCards(
        now: t0.add(const Duration(hours: 1)),
      );
      expect(due, isEmpty);
    });
  });
}
