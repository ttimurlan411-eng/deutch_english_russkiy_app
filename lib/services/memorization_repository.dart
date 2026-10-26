import 'package:shared_preferences/shared_preferences.dart';

import '../models/review_record.dart';

/// Persists the memorization status and the review history locally.
///
/// Two keys are used:
/// * `learned_word_ids` — the ids of the words marked as learned;
/// * `review_records` — the review history as JSON strings.
///
/// The repository never talks to the dataset, it only stores ids and review
/// records. Missing or malformed entries are ignored instead of throwing, so
/// a corrupted storage file can never break the app.
class MemorizationRepository {
  /// [preferences] is an optional injection point used by tests; when it is
  /// omitted the platform default instance is resolved lazily.
  MemorizationRepository([this._preferences]);

  /// Storage key of the learned word ids.
  static const String learnedIdsKey = 'learned_word_ids';

  /// Storage key of the review history.
  static const String reviewRecordsKey = 'review_records';

  /// Upper bound of the stored review history so the preferences file cannot
  /// grow without limit. The most recent records are kept.
  static const int maxStoredRecords = 1000;

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Reads the ids of the words that were marked as learned.
  Future<Set<String>> loadLearnedIds() async {
    final prefs = await _prefs;
    return (prefs.getStringList(learnedIdsKey) ?? const <String>[])
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Writes the ids of the words that are marked as learned.
  Future<void> saveLearnedIds(Set<String> ids) async {
    final prefs = await _prefs;
    final sorted = ids.where((id) => id.isNotEmpty).toList()..sort();
    await prefs.setStringList(learnedIdsKey, sorted);
  }

  /// Reads the review history, skipping malformed entries.
  Future<List<ReviewRecord>> loadReviewRecords() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(reviewRecordsKey) ?? const <String>[];
    final records = <ReviewRecord>[];
    for (final entry in raw) {
      final record = ReviewRecord.tryParse(entry);
      if (record != null) records.add(record);
    }
    return records;
  }

  /// Writes the review history, keeping only the most recent records.
  Future<void> saveReviewRecords(List<ReviewRecord> records) async {
    final prefs = await _prefs;
    final trimmed = records.length > maxStoredRecords
        ? records.sublist(records.length - maxStoredRecords)
        : records;
    await prefs.setStringList(
      reviewRecordsKey,
      trimmed.map((record) => record.toJsonString()).toList(),
    );
  }

  /// Removes every stored memorization and review entry.
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(learnedIdsKey);
    await prefs.remove(reviewRecordsKey);
  }
}
