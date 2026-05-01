import 'package:drift/drift.dart';

/// One FSRS card per heuristic. The card state is owned by the `fsrs`
/// package; we only persist its serialized blob here so we can resume
/// review schedules across launches.
@DataClassName('FsrsCardRow')
class FsrsCards extends Table {
  TextColumn get kindId => text()();
  TextColumn get heuristicTag => text()();

  /// Opaque serialization of the `fsrs` Card object (v1: JSON bytes).
  /// We treat this as a black box — never read from app code, only
  /// round-trip through `fsrs`.
  BlobColumn get stateBlob => blob()();

  /// Unix epoch ms; indexed for fast `due_at <= now` queries.
  IntColumn get dueAt => integer()();

  IntColumn get lastReviewedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {kindId, heuristicTag};
}
