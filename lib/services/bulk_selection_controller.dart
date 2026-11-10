import 'package:flutter/foundation.dart';

/// Holds the multi-selection state of a word list.
///
/// The selection is intentionally kept outside of the word data: it only
/// stores word ids while the selection mode is active and is cleared as soon
/// as the mode is left, so no stale selection survives a filter change or a
/// screen switch.
class BulkSelectionController extends ChangeNotifier {
  bool _active = false;
  final Set<String> _ids = <String>{};

  /// Whether the list is currently in selection mode.
  bool get isActive => _active;

  /// Ids of the selected words.
  Set<String> get ids => Set<String>.unmodifiable(_ids);

  /// Number of selected words.
  int get count => _ids.length;

  /// Whether the word with the given [id] is selected.
  bool contains(String id) => _ids.contains(id);

  /// Switches the selection mode on or off.
  ///
  /// Leaving the mode always clears the selected words.
  void toggleMode() {
    _active = !_active;
    if (!_active) _ids.clear();
    notifyListeners();
  }

  /// Enables the selection mode.
  void enter() {
    if (_active) return;
    _active = true;
    notifyListeners();
  }

  /// Leaves the selection mode and clears every selected word.
  void exit() {
    if (!_active && _ids.isEmpty) return;
    _active = false;
    _ids.clear();
    notifyListeners();
  }

  /// Selects or deselects the word with the given [id].
  void toggle(String id) {
    if (!_active || id.isEmpty) return;
    if (!_ids.add(id)) _ids.remove(id);
    notifyListeners();
  }

  /// Sets the selection state of the word with the given [id].
  void setSelected(String id, bool selected) {
    if (!_active || id.isEmpty) return;
    final changed = selected ? _ids.add(id) : _ids.remove(id);
    if (changed) notifyListeners();
  }

  /// Selects every word of [visibleIds] or, when all of them are already
  /// selected, deselects them.
  ///
  /// Only the ids that are currently visible are touched, so a filtered list
  /// never selects words that are hidden by the search or the level filter.
  void toggleAll(Iterable<String> visibleIds) {
    if (!_active) return;
    final visible = visibleIds.where((id) => id.isNotEmpty).toSet();
    if (visible.isEmpty) return;
    if (visible.every(_ids.contains)) {
      _ids.removeAll(visible);
    } else {
      _ids.addAll(visible);
    }
    notifyListeners();
  }

  /// Clears the selected words without leaving the selection mode.
  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    notifyListeners();
  }
}
