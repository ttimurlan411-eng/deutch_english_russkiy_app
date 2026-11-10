import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/word.dart';
import '../services/bulk_selection_controller.dart';
import '../services/word_search.dart';
import '../widgets/bulk_selection.dart';
import '../widgets/loading_view.dart';
import '../widgets/state_views.dart';
import '../widgets/word_card.dart';
import '../widgets/word_details_sheet.dart';

/// The list of words the user marked as favorite.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.state});

  final AppState state;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final BulkSelectionController _selection = BulkSelectionController();

  AppState get state => widget.state;

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        state,
        state.favorites,
        state.memorization,
        _selection,
      ]),
      builder: (context, _) {
        final favorites = state.favorites;
        final words = WordSearch.apply(state.words, favoriteIds: favorites.ids);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.favorites),
            actions: <Widget>[
              IconButton(
                tooltip: _selection.isActive
                    ? l10n.exitSelectMode
                    : l10n.selectMode,
                onPressed: _selection.toggleMode,
                icon: Icon(
                  _selection.isActive
                      ? Icons.close_rounded
                      : Icons.checklist_rounded,
                ),
              ),
            ],
          ),
          body: SafeArea(child: _buildBody(l10n, words)),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n, List<Word> words) {
    switch (state.status) {
      case LoadStatus.loading:
        return LoadingView(message: l10n.loading);
      case LoadStatus.error:
        return ErrorView(
          onRetry: state.initialize,
          message: state.errorMessage,
        );
      case LoadStatus.ready:
        break;
    }

    if (words.isEmpty) {
      return EmptyView(
        title: l10n.noFavorites,
        subtitle: l10n.favoritesEmptySubtitle,
        icon: Icons.favorite_border,
      );
    }

    final visibleIds = words.map((word) => word.id).toSet();
    final selectedVisibleIds = visibleIds.where(_selection.contains).toSet();
    final allSelected =
        words.isNotEmpty && selectedVisibleIds.length == words.length;

    return Column(
      children: <Widget>[
        if (_selection.isActive)
          BulkSelectionHeader(
            selectedCount: selectedVisibleIds.length,
            allSelected: allSelected,
            onToggleAll: () => _selection.toggleAll(visibleIds),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: words.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final word = words[index];
              final isFav = state.favorites.contains(word.id);
              final isLearned = state.memorization.isLearned(word.id);
              return WordCard(
                word: word,
                learningLanguageCode: state.settings.learningLanguageCode,
                translationLanguageCodes:
                    state.settings.translationLanguageCodes,
                isFavorite: isFav,
                isLearned: isLearned,
                example: state.exampleFor(word),
                selectionMode: _selection.isActive,
                isSelected: _selection.contains(word.id),
                onSelectionChanged: (selected) =>
                    _selection.setSelected(word.id, selected ?? false),
                onFavoriteToggle: () => state.favorites.toggle(word.id),
                onLearnedToggle: () =>
                    state.memorization.setLearned(word.id, !isLearned),
                onTap: () => WordDetailsSheet.show(
                  context,
                  word: word,
                  learningLanguageCode: state.settings.learningLanguageCode,
                  translationLanguageCodes:
                      state.settings.translationLanguageCodes,
                  isFavorite: isFav,
                  isLearned: isLearned,
                  onFavoriteToggle: () => state.favorites.toggle(word.id),
                  onMemorizationToggle: () =>
                      state.memorization.setLearned(word.id, !isLearned),
                  speech: state.speech,
                  verb: state.verbFor(word),
                ),
                speech: state.speech,
              );
            },
          ),
        ),
        if (_selection.isActive)
          BulkSelectionActions(
            enabled: selectedVisibleIds.isNotEmpty,
            onMarkLearned: () => _markSelectedLearned(selectedVisibleIds),
            onAddToFavorites: () => _addSelectedToFavorites(selectedVisibleIds),
            onClearSelected: _selection.clear,
          ),
      ],
    );
  }

  Future<void> _markSelectedLearned(Set<String> ids) async {
    if (ids.isEmpty) return;
    await state.memorization.markLearnedAll(ids);
    if (!mounted) return;
    _selection.clear();
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.bulkLearnedDone(ids.length))));
  }

  Future<void> _addSelectedToFavorites(Set<String> ids) async {
    if (ids.isEmpty) return;
    await state.favorites.addAll(ids);
    if (!mounted) return;
    _selection.clear();
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.bulkFavoritesDone(ids.length))),
      );
  }
}
