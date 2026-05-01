import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../data/database.dart';
import '../../data/repositories/fsrs_repository.dart';
import '../domain/heuristic.dart';

/// Read-model for one row in [FsrsCards] after a review. Returned by
/// [FsrsScheduler.reviewCard] and [FsrsScheduler.dueCards] so callers
/// (drill selector, UI) never touch the raw blob.
class ReviewedCard {
  const ReviewedCard({
    required this.heuristic,
    required this.due,
    required this.lastReview,
  });

  final Heuristic heuristic;
  final DateTime due;
  final DateTime? lastReview;
}

/// Thin wrapper over the `fsrs` package. Holds one shared [Scheduler]
/// instance (stock OSR defaults; fuzzing kept off in v1 for stable
/// review-time behavior — can be re-enabled once we have telemetry on
/// review clustering). Per-heuristic [Card] state is round-tripped
/// through [FsrsRepository] as a JSON blob in `fsrs_cards.stateBlob`.
class FsrsScheduler {
  FsrsScheduler({
    required FsrsRepository fsrsRepository,
    fsrs.Scheduler? scheduler,
  })  : _fsrs = fsrsRepository,
        _scheduler = scheduler ?? fsrs.Scheduler(enableFuzzing: false);

  final FsrsRepository _fsrs;
  final fsrs.Scheduler _scheduler;

  /// Apply [rating] to the persisted card for [h]. Creates a fresh
  /// card the first time a heuristic is reviewed.
  Future<ReviewedCard> reviewCard(
    Heuristic h,
    fsrs.Rating rating, {
    DateTime? now,
  }) async {
    final reviewAt = (now ?? DateTime.now()).toUtc();
    final existing = await _fsrs.find(h);
    final card = existing != null
        ? _decodeCard(existing.stateBlob)
        : fsrs.Card(cardId: reviewAt.millisecondsSinceEpoch);

    final result = _scheduler.reviewCard(
      card,
      rating,
      reviewDateTime: reviewAt,
    );

    await _fsrs.upsert(
      FsrsCardsCompanion.insert(
        kindId: h.kindId,
        heuristicTag: h.tagId,
        stateBlob: _encodeCard(result.card),
        dueAt: result.card.due.millisecondsSinceEpoch,
        lastReviewedAt: Value(
          result.card.lastReview?.millisecondsSinceEpoch,
        ),
      ),
    );

    return ReviewedCard(
      heuristic: h,
      due: result.card.due,
      lastReview: result.card.lastReview,
    );
  }

  /// All heuristics whose card is due at or before [now], oldest due
  /// first. Drill selector consumes this directly.
  Future<List<ReviewedCard>> dueCards({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).toUtc();
    final rows = await _fsrs.dueAt(cutoff);
    return rows.map(_rowToReviewed).toList(growable: false);
  }

  ReviewedCard _rowToReviewed(FsrsCardRow row) {
    return ReviewedCard(
      heuristic: Heuristic(row.kindId, row.heuristicTag),
      due: DateTime.fromMillisecondsSinceEpoch(row.dueAt, isUtc: true),
      lastReview: row.lastReviewedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.lastReviewedAt!,
              isUtc: true,
            ),
    );
  }

  Uint8List _encodeCard(fsrs.Card card) {
    return Uint8List.fromList(utf8.encode(jsonEncode(card.toMap())));
  }

  fsrs.Card _decodeCard(Uint8List blob) {
    final decoded = jsonDecode(utf8.decode(blob)) as Map<String, dynamic>;
    return fsrs.Card.fromMap(decoded);
  }
}
