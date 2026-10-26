import '../models/review_record.dart';
import '../models/word.dart';

/// Learned and new word counts of a single CEFR level.
class LevelStatistics {
  const LevelStatistics({
    required this.level,
    required this.total,
    required this.learned,
  });

  /// The CEFR level (A1, A2, B1, B2).
  final String level;

  /// Number of words of the dataset in this level.
  final int total;

  /// Number of words of this level that are marked as learned.
  final int learned;

  /// Number of words of this level that are still new.
  int get newWords => total - learned;

  /// Fraction of the level that is learned (0.0 – 1.0).
  double get fraction => total == 0 ? 0 : learned / total;

  /// Percentage of the level that is learned (0 – 100).
  int get percent => (fraction * 100).round();
}

/// Learning statistics derived from the dataset and the persisted state.
///
/// Every number is calculated from the real data: the totals come from the
/// loaded vocabulary, the learned counts from the persisted memorization
/// status and the review numbers from the persisted review history. Words
/// are never counted twice.
class LearningStatistics {
  /// Calculates the statistics of [words] for the given [learnedIds].
  factory LearningStatistics({
    required List<Word> words,
    required Set<String> learnedIds,
    List<ReviewRecord> reviewHistory = const <ReviewRecord>[],
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final totals = <String, int>{};
    final learnedPerLevel = <String, int>{};
    var learned = 0;

    for (final word in words) {
      totals[word.level] = (totals[word.level] ?? 0) + 1;
      if (learnedIds.contains(word.id)) {
        learned++;
        learnedPerLevel[word.level] = (learnedPerLevel[word.level] ?? 0) + 1;
      }
    }

    final history = List<ReviewRecord>.unmodifiable(reviewHistory);

    return LearningStatistics._(
      totalWords: words.length,
      learnedCount: learned,
      newWordCount: words.length - learned,
      byLevel: <String, LevelStatistics>{
        for (final level in levels)
          level: LevelStatistics(
            level: level,
            total: totals[level] ?? 0,
            learned: learnedPerLevel[level] ?? 0,
          ),
      },
      reviewHistory: history,
      reviewCount: history.length,
      rememberedCount: history
          .where((record) => record.outcome == ReviewOutcome.remembered)
          .length,
      needsLearningCount: history
          .where((record) => record.outcome == ReviewOutcome.needsLearning)
          .length,
      reviewsToday: history
          .where((record) => _isSameDay(record.reviewedAt, moment))
          .length,
    );
  }

  const LearningStatistics._({
    required this.totalWords,
    required this.learnedCount,
    required this.newWordCount,
    required this.byLevel,
    required this.reviewHistory,
    required this.reviewCount,
    required this.rememberedCount,
    required this.needsLearningCount,
    required this.reviewsToday,
  });

  /// The CEFR levels of the dataset.
  static const List<String> levels = <String>['A1', 'A2', 'B1', 'B2'];

  /// Total number of words of the dataset.
  final int totalWords;

  /// Number of words that are marked as learned.
  final int learnedCount;

  /// Number of words that are still new.
  final int newWordCount;

  /// Learned and new counts per level.
  final Map<String, LevelStatistics> byLevel;

  /// The review history the statistics were calculated from.
  final List<ReviewRecord> reviewHistory;

  /// Total number of recorded reviews.
  final int reviewCount;

  /// Number of reviews answered with "remembered".
  final int rememberedCount;

  /// Number of reviews answered with "needs learning".
  final int needsLearningCount;

  /// Number of reviews recorded today.
  final int reviewsToday;

  /// Fraction of the dataset that is learned (0.0 – 1.0).
  double get learnedFraction {
    if (totalWords <= 0) return 0;
    return learnedCount / totalWords;
  }

  /// Percentage of the dataset that is learned (learned / total × 100).
  double get learnedPercent => learnedFraction * 100;

  /// Percentage of the dataset that is learned, rounded to a whole number.
  int get learnedPercentRounded => learnedPercent.round();

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
