import '../models/review_record.dart';

/// The lightweight review schedule of the app.
///
/// It is deliberately simple: a word that was remembered comes back after
/// 1, 3, 7, 14 and 30 days, a word that has to be learned again comes back
/// after a few minutes (and is moved back to the new words anyway).
class ReviewSchedule {
  const ReviewSchedule._();

  /// Delays between two reviews of a successfully remembered word.
  static const List<Duration> intervals = <Duration>[
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 14),
    Duration(days: 30),
  ];

  /// Delay before a word that has to be learned again is suggested again.
  static const Duration relearnDelay = Duration(minutes: 10);

  /// Computes the moment the word should be reviewed next.
  ///
  /// [streak] is the number of consecutive successful reviews, starting at 1
  /// for the first success.
  static DateTime nextReviewAt({
    required ReviewOutcome outcome,
    required int streak,
    required DateTime from,
  }) {
    if (outcome == ReviewOutcome.needsLearning) {
      return from.add(relearnDelay);
    }
    final index = streak <= 0 ? 0 : (streak - 1).clamp(0, intervals.length - 1);
    return from.add(intervals[index.toInt()]);
  }
}
