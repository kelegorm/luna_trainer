import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX idx_move_events_kind_tag_created '
        'ON move_events (kind_id, heuristic_tag, created_at)',
      );
      await customStatement(
        'CREATE INDEX idx_fsrs_cards_due_at ON fsrs_cards (due_at)',
      );
    },
    onUpgrade: (m, from, to) async {
      // No upgrades yet — every future migration grows from v1.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'luna_trainer.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
