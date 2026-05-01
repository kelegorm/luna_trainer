import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' as v1;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('current schema matches v2 snapshot', () async {
    final connection = await verifier.startAt(2);
    final db = LunaDatabase.forTesting(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 2);
  });

  test('opening a fresh database creates v2 schema cleanly', () async {
    final db = LunaDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%' "
          'ORDER BY name',
        )
        .map((r) => r.read<String>('name'))
        .get();

    expect(
      tables,
      containsAll(<String>[
        'fsrs_cards',
        'mastery_state',
        'move_events',
        'sessions',
      ]),
    );

    final indexes = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .map((r) => r.read<String>('name'))
        .get();

    expect(
      indexes,
      containsAll(<String>[
        'idx_fsrs_cards_due_at',
        'idx_move_events_kind_tag_created',
      ]),
    );
  });

  test('v1 → v2 migration: empty db applies cleanly and matches v2 snapshot',
      () async {
    final connection = await verifier.startAt(1);
    final db = LunaDatabase.forTesting(connection);
    addTearDown(db.close);

    // SchemaVerifier replays the registered MigrationStrategy from v1
    // up to v2 and validates the resulting schema matches the v2
    // snapshot column-for-column.
    await verifier.migrateAndValidate(db, 2);
  });

  test('v1 → v2 migration: sessions row survives with new columns defaulting',
      () async {
    final schemaV1 = await verifier.schemaAt(1);
    final v1Db = v1.DatabaseAtV1(schemaV1.newConnection());
    await v1Db.customStatement(
      "INSERT INTO sessions (mode, started_at) VALUES ('full_game', 1234)",
    );
    await v1Db.close();

    final db = LunaDatabase.forTesting(schemaV1.newConnection());
    addTearDown(db.close);

    final rows = await db.select(db.sessions).get();
    expect(rows.length, 1);
    expect(rows.single.mode, 'full_game');
    expect(rows.single.difficultyBand, 2,
        reason: 'difficulty_band defaults to 2 (medium)');
    expect(rows.single.userAdjusted, isFalse,
        reason: 'user_adjusted defaults to false');
  });

  test('v1 → v2 migration: move_events is dropped-and-recreated empty',
      () async {
    final schemaV1 = await verifier.schemaAt(1);
    final v1Db = v1.DatabaseAtV1(schemaV1.newConnection());
    await v1Db.customStatement(
      "INSERT INTO sessions (mode, started_at) VALUES ('drill', 1)",
    );
    final sessionId = (await v1Db
        .customSelect('SELECT id FROM sessions LIMIT 1')
        .map((r) => r.read<int>('id'))
        .getSingle());
    // Old v1 mode column carried full_game/drill — write a row to
    // confirm v2 migration drops and recreates the table (rows go
    // away, which is intentional: Phase A/B never wrote MoveEvents in
    // production, so this is a greenfield reset).
    await v1Db.customStatement(
      'INSERT INTO move_events ('
      'session_id, kind_id, heuristic_tag, latency_ms, was_correct, '
      'hint_requested, contaminated_flag, idle_soft_signal, motion_signal, '
      'lifecycle_signal, mode, created_at) '
      "VALUES (?, 'tango', 'ParityFill', 100, 1, 0, 0, 0, 0, 0, 'drill', 1)",
      [sessionId],
    );
    await v1Db.close();

    final db = LunaDatabase.forTesting(schemaV1.newConnection());
    addTearDown(db.close);

    final moves = await db.select(db.moveEvents).get();
    expect(moves, isEmpty,
        reason: 'drop-and-recreate intentionally clears v1 rows');

    // Insert a row with the v2 shape — propagation/hunt mode, defaults
    // for difficulty_band and user_adjusted, default 'production'
    // event_kind.
    await db.into(db.moveEvents).insert(
          MoveEventsCompanion.insert(
            sessionId: sessionId,
            kindId: 'tango',
            heuristicTag: 'ParityFill',
            latencyMs: 100,
            wasCorrect: true,
            hintRequested: false,
            contaminatedFlag: false,
            idleSoftSignal: false,
            motionSignal: false,
            lifecycleSignal: false,
            createdAt: 1,
          ),
        );
    final after = await db.select(db.moveEvents).getSingle();
    expect(after.mode, isNull, reason: 'mode is now nullable propagation/hunt');
    expect(after.eventKind, 'production');
    expect(after.difficultyBand, 2);
    expect(after.userAdjusted, isFalse);
  });

  test('v1 → v2 migration is idempotent (re-running v2 stays at v2)',
      () async {
    final schemaV1 = await verifier.schemaAt(1);
    final connection = schemaV1.newConnection();

    final db1 = LunaDatabase.forTesting(connection);
    await db1.customSelect('SELECT 1').get();
    await db1.close();

    final db2 = LunaDatabase.forTesting(schemaV1.newConnection());
    addTearDown(db2.close);
    await verifier.migrateAndValidate(db2, 2);
  });

  test('v2 fresh insert: defaults for new fields match plan', () async {
    final db = LunaDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final sessionId = await db.into(db.sessions).insert(
          SessionsCompanion.insert(mode: 'full_game', startedAt: 1),
        );
    final session = await (db.select(db.sessions)
          ..where((t) => t.id.equals(sessionId)))
        .getSingle();
    expect(session.difficultyBand, 2);
    expect(session.userAdjusted, isFalse);
  });

}
