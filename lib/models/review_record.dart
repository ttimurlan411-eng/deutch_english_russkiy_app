import 'dart:convert';

/// Outcome of a single review answer.
enum ReviewOutcome {
  /// The user remembered the word ("Эстедим").
  remembered,

  /// The user needs to learn the word again ("Кайра үйрөнөм").
  needsLearning;

  /// Stable value used when the record is written to the local storage.
  String get storageValue =>
      this == ReviewOutcome.remembered ? 'remembered' : 'needs_learning';

  /// Reads an outcome back from its stored [value].
  ///
  /// Unknown or missing values fall back to [ReviewOutcome.needsLearning] so
  /// a corrupted record can never mark a word as learned by accident.
  static ReviewOutcome fromStorage(String? value) {
    return value == ReviewOutcome.remembered.storageValue
        ? ReviewOutcome.remembered
        : ReviewOutcome.needsLearning;
  }
}

/// One completed review of a vocabulary word.
///
/// Records are persisted locally; they are the source of the review history
/// and of the lightweight review schedule.
class ReviewRecord {
  const ReviewRecord({
    required this.wordId,
    required this.outcome,
    required this.reviewedAt,
    required this.nextReviewAt,
    this.streak = 0,
  });

  /// Stable id of the reviewed word (see `Word.id`).
  final String wordId;

  /// Whether the user remembered the word or needs to learn it again.
  final ReviewOutcome outcome;

  /// Moment the word was reviewed.
  final DateTime reviewedAt;

  /// Moment the word is suggested for the next review.
  final DateTime nextReviewAt;

  /// Number of consecutive successful reviews (reset by "needs learning").
  final int streak;

  /// Serializes the record so it can be stored as a JSON string.
  Map<String, Object?> toJson() => <String, Object?>{
    'wordId': wordId,
    'outcome': outcome.storageValue,
    'reviewedAt': reviewedAt.toIso8601String(),
    'nextReviewAt': nextReviewAt.toIso8601String(),
    'streak': streak,
  };

  /// Serializes the record into a compact JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Reads a record back from a decoded JSON map.
  ///
  /// Returns `null` when the payload is malformed so a single broken entry
  /// cannot break the whole history.
  static ReviewRecord? fromJson(Map<String, Object?> json) {
    final wordId = json['wordId'];
    if (wordId is! String || wordId.isEmpty) return null;

    final reviewedAt = DateTime.tryParse('${json['reviewedAt'] ?? ''}');
    if (reviewedAt == null) return null;

    final nextReviewAt =
        DateTime.tryParse('${json['nextReviewAt'] ?? ''}') ?? reviewedAt;

    final rawStreak = json['streak'];
    final streak = rawStreak is int ? rawStreak : 0;

    return ReviewRecord(
      wordId: wordId,
      outcome: ReviewOutcome.fromStorage(json['outcome'] as String?),
      reviewedAt: reviewedAt,
      nextReviewAt: nextReviewAt,
      streak: streak,
    );
  }

  /// Parses a record from its stored JSON string.
  ///
  /// Returns `null` for malformed payloads instead of throwing.
  static ReviewRecord? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = <String, Object?>{
        for (final entry in decoded.entries) '${entry.key}': entry.value,
      };
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'ReviewRecord($wordId, ${outcome.storageValue}, $reviewedAt)';
}
