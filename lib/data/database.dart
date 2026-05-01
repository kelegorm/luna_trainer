import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/fsrs_cards_table.dart';
import 'tables/mastery_state_table.dart';
import 'tables/move_events_table.dart';
import 'tables/sessions_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Sessions, MoveEvents, MasteryState, FsrsCards],
)
class LunaDatabase extends _$LunaDatabase {
  LunaDatabase() : super(_openConnection());

  /// Test-only constructor. In-memory database with the same schema.
  LunaDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2 (U7, R29/R31/R34/R36/R38): drop-and-recreate move_events.
        // Old `mode` column carried full_game/drill — that role moves
        // entirely to sessions.mode; new `mode TEXT NULL` carries
        // propagation/hunt (R31). Table is empty in v1 (Phase A/B
        // engine never wrote MoveEvent), so drop-and-create is atomic
        // and ambiguity-free. Sessions adds difficulty_band and
        // user_adjusted via ALTER (preserves any rows).
        await m.deleteTable('move_events');
        await m.createTable(moveEvents);
        await m.addColumn(sessions, sessions.difficultyBand);
        await m.addColumn(sessions, sessions.userAdjusted);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_move_events_kind_tag_created '
          'ON move_events (kind_id, heuristic_tag, created_at)',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX idx_move_events_kind_tag_created '
      'ON move_events (kind_id, heuristic_tag, created_at)',
    );
    await customStatement(
      'CREATE INDEX idx_fsrs_cards_due_at ON fsrs_cards (due_at)',
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'luna_trainer');
}
