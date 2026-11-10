import 'package:flutter/foundation.dart';

import '../models/memorization.dart';
import '../models/review_record.dart';
import 'memorization_repository.dart';
import 'review_schedule.dart';

/// Holds the memorization status of every word and the review history.
///
/// The controller is the single source of truth for
/// "learned" / "new": the screens listen to it, so a status change is
/// reflected everywhere immediately. The state is persisted through
/// [MemorizationRepository] and survives app restarts.
class MemorizationController extends ChangeNotifier {
  MemorizationController(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MemorizationRepository _repository;
  final DateTime Function() _now;

  final Set<String> _learnedIds = <String>{};
  final List<ReviewRecord> _history = <ReviewRecord>[];
  bool _loaded = false;

  /// Whether the persisted state was already read.
  bool get isLoaded => _loaded;

  /// Ids of the words that are marked as learned.
  Set<String> get learnedIds => Set<String>.unmodifiable(_learnedIds);

  /// Number of words marked as learned.
  int get learnedCount => _learnedIds.length;

  /// The complete review history, oldest entry first.
  List<ReviewRecord> get reviewHistory =>
      List<ReviewRecord>.unmodifiable(_history);

  /// The current status of the word with the given [wordId].
  ///
  /// Words that are unknown or that were removed from the dataset are new.
  MemorizationStatus statusOf(String wordId) {
    return _learnedIds.contains(wordId)
        ? MemorizationStatus.learned
        : MemorizationStatus.newWord;
  }

  /// Whether the word with the given [wordId] is marked as learned.
  bool isLearned(String wordId) => _learnedIds.contains(wordId);

  /// Reads the persisted state.
  Future<void> load() async {
    final learned = await _repository.loadLearnedIds();
    final history = await _repository.loadReviewRecords();
    _learnedIds
      ..clear()
      ..addAll(learned);
    _history
      ..clear()
      ..addAll(history);
    _loaded = true;
    notifyListeners();
  }

  /// Marks the word as learned.
  ///
  /// Calling this for an already learned word does nothing, so the operation
  /// is idempotent and never creates duplicate entries.
  Future<void> markLearned(String wordId) async {
    if (wordId.isEmpty) return;
    if (!_learnedIds.add(wordId)) return;
    notifyListeners();
    await _repository.saveLearnedIds(_learnedIds);
  }

  /// Marks several words as learned in one batch.
  ///
  /// Already learned words are ignored, so the operation is idempotent and
  /// the learned ids are stored only once per batch.
  Future<void> markLearnedAll(Iterable<String> wordIds) async {
    var changed = false;
    for (final wordId in wordIds) {
      if (wordId.isEmpty) continue;
      if (_learnedIds.add(wordId)) changed = true;
    }
    if (!changed) return;
    notifyListeners();
    await _repository.saveLearnedIds(_learnedIds);
  }

  /// Moves the word back to the new words.
  ///
  /// Calling this for a new word does nothing.
  Future<void> markNew(String wordId) async {
    if (wordId.isEmpty) return;
    if (!_learnedIds.remove(wordId)) return;
    notifyListeners();
    await _repository.saveLearnedIds(_learnedIds);
  }

  /// Sets the memorization status of the word.
  Future<void> setLearned(String wordId, bool learned) {
    return learned ? markLearned(wordId) : markNew(wordId);
  }

  /// Records the result of a review and applies it to the memorization
  /// status: a remembered word stays learned, a word that has to be learned
  /// again returns to the new words.
  Future<void> recordReview(
    String wordId,
    ReviewOutcome outcome, {
    DateTime? at,
  }) async {
    if (wordId.isEmpty) return;

    final timestamp = at ?? _now();
    final previous = latestReviewFor(wordId);
    final streak = outcome == ReviewOutcome.remembered
        ? (previous?.streak ?? 0) + 1
        : 0;

    final record = ReviewRecord(
      wordId: wordId,
      outcome: outcome,
      reviewedAt: timestamp,
      nextReviewAt: ReviewSchedule.nextReviewAt(
        outcome: outcome,
        streak: streak,
        from: timestamp,
      ),
      streak: streak,
    );

    _history.add(record);
    if (outcome == ReviewOutcome.remembered) {
      _learnedIds.add(wordId);
    } else {
      _learnedIds.remove(wordId);
    }

    notifyListeners();
    await _repository.saveLearnedIds(_learnedIds);
    await _repository.saveReviewRecords(_history);
  }

  /// The most recent review of the given [wordId], if there is one.
  ReviewRecord? latestReviewFor(String wordId) {
    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].wordId == wordId) return _history[i];
    }
    return null;
  }

  /// All reviews of the given [wordId], oldest entry first.
  List<ReviewRecord> reviewsFor(String wordId) {
    return _history
        .where((record) => record.wordId == wordId)
        .toList(growable: false);
  }

  /// Total number of recorded reviews.
  int get reviewCount => _history.length;

  /// Number of reviews that were answered with "remembered".
  int get rememberedCount => _history
      .where((record) => record.outcome == ReviewOutcome.remembered)
      .length;

  /// Number of reviews that were answered with "needs learning".
  int get needsLearningCount => _history
      .where((record) => record.outcome == ReviewOutcome.needsLearning)
      .length;

  /// Number of reviews recorded on the given calendar [day].
  int reviewsOn(DateTime day) {
    return _history
        .where((record) => _isSameDay(record.reviewedAt, day))
        .length;
  }

  /// Number of reviews recorded today.
  int get reviewsToday => reviewsOn(_now());

  /// Ids of the learned words whose next review is due.
  ///
  /// Words that were never reviewed are not due — they are simply new for the
  /// review session.
  List<String> dueReviewIds({DateTime? at}) {
    final moment = at ?? _now();
    final due = <String>[];
    for (final wordId in _learnedIds) {
      final record = latestReviewFor(wordId);
      if (record != null && !record.nextReviewAt.isAfter(moment)) {
        due.add(wordId);
      }
    }
    due.sort();
    return due;
  }

  /// Removes the ids that are not part of the dataset anymore.
  ///
  /// The method is safe to call with an incomplete list of ids: only the
  /// ids that are really missing are dropped.
  Future<void> pruneUnknown(Set<String> knownIds) async {
    final stale = _learnedIds
        .where((id) => !knownIds.contains(id))
        .toList(growable: false);
    if (stale.isEmpty) return;
    _learnedIds.removeAll(stale);
    notifyListeners();
    await _repository.saveLearnedIds(_learnedIds);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
