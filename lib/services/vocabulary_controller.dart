import 'package:flutter/foundation.dart';

/// Holds the search query and level filter of the vocabulary screen.
///
/// The state lives outside the widget so the home screen can pre-select a
/// level and the vocabulary screen can restore it.
class VocabularyController extends ChangeNotifier {
  String? _level;
  String _query = '';

  /// The selected CEFR level, or `null` for "all levels".
  String? get level => _level;

  /// The current free-text query.
  String get query => _query;

  bool get hasQuery => _query.trim().isNotEmpty;

  void setLevel(String? level) {
    if (_level == level) return;
    _level = level;
    notifyListeners();
  }

  void setQuery(String query) {
    if (_query == query) return;
    _query = query;
    notifyListeners();
  }

  void clearQuery() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }
}
