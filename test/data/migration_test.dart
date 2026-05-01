import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_traineer/data/database.dart';

import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('current schema matches v1 snapshot', () async {
    final connection = await verifier.startAt(1);
    final db = LunaDatabase.forTesting(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });

  test('opening a fresh database creates v1 schema cleanly', () async {
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
}
