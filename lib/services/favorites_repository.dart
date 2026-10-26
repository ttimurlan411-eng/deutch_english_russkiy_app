import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorite word IDs (see `Word.id`) using [SharedPreferences].
class FavoritesRepository {
  /// [preferences] is an optional injection point used by tests; when it is
  /// omitted the platform default instance is resolved lazily.
  FavoritesRepository([this._preferences]);

  static const String storageKey = 'favorite_word_ids';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<Set<String>> load() async {
    final prefs = await _prefs;
    return (prefs.getStringList(storageKey) ?? const <String>[]).toSet();
  }

  Future<void> save(Set<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(storageKey, ids.toList());
  }
}

/// Holds the current favorites and notifies listeners on changes.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final FavoritesRepository _repository;
  final Set<String> _ids = <String>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Set<String> get ids => Set.unmodifiable(_ids);

  int get count => _ids.length;

  bool contains(String id) => _ids.contains(id);

  Future<void> load() async {
    final stored = await _repository.load();
    _ids
      ..clear()
      ..addAll(stored);
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    await _repository.save(_ids);
  }
}
