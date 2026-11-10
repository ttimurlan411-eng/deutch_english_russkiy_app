import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../services/bulk_selection_controller.dart';
import '../services/word_search.dart';
import '../theme/app_theme.dart';
import '../widgets/bulk_selection.dart';
import '../widgets/level_filter.dart';
import '../widgets/loading_view.dart';
import '../widgets/state_views.dart';
import '../widgets/word_card.dart';
import '../widgets/word_details_sheet.dart';

/// The list of the words that still have to be learned.
///
/// Only the words whose memorization status is [WordSubset.newWords] are
/// shown: a word that was marked as learned disappears from this list
/// immediately and appears in the learned words list instead.
class NewWordsScreen extends StatefulWidget {
  const NewWordsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<NewWordsScreen> createState() => _NewWordsScreenState();
}

class _NewWordsScreenState extends State<NewWordsScreen> {
  late final TextEditingController _searchController;
  final BulkSelectionController _selection = BulkSelectionController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.state.vocabulary.query,
    );
  }

  @override
  void dispose() {
    _selection.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.state.vocabulary.clearQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.state,
        widget.state.favorites,
        widget.state.vocabulary,
        widget.state.memorization,
        _selection,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.newWords),
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
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.state.vocabulary.setQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: widget.state.vocabulary.hasQuery
                          ? IconButton(
                              tooltip: l10n.clearSearch,
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                LevelFilter(
                  selected: widget.state.vocabulary.level,
                  onSelected: widget.state.vocabulary.setLevel,
                ),
                const SizedBox(height: 4),
                Expanded(child: _buildBody(l10n)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final status = widget.state.status;
    if (status == LoadStatus.loading) {
      return LoadingView(message: l10n.loading);
    }
    if (status == LoadStatus.error) {
      return ErrorView(
        onRetry: widget.state.initialize,
        message: widget.state.errorMessage,
      );
    }

    final results = WordSearch.apply(
      widget.state.words,
      level: widget.state.vocabulary.level,
      query: widget.state.vocabulary.query,
      learnedIds: widget.state.memorization.learnedIds,
      subset: WordSubset.newWords,
    );

    if (results.isEmpty) {
      final filtered =
          widget.state.vocabulary.hasQuery ||
          widget.state.vocabulary.level != null;
      return EmptyView(
        title: filtered ? l10n.noResults : l10n.noNewWords,
        subtitle: filtered ? l10n.noResultsSubtitle : l10n.noNewWordsSubtitle,
        icon: filtered ? Icons.search_off_rounded : Icons.task_alt_rounded,
      );
    }

    final visibleIds = results.map((word) => word.id).toSet();
    final selectedVisibleIds = visibleIds.where(_selection.contains).toSet();
    final allSelected =
        results.isNotEmpty && selectedVisibleIds.length == results.length;

    return Column(
      children: <Widget>[
        if (_selection.isActive)
          BulkSelectionHeader(
            selectedCount: selectedVisibleIds.length,
            allSelected: allSelected,
            onToggleAll: () => _selection.toggleAll(visibleIds),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.wordCount(results.length),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final word = results[index];
              final isFav = widget.state.favorites.contains(word.id);
              final isLearned = widget.state.memorization.isLearned(word.id);
              return WordCard(
                word: word,
                learningLanguageCode:
                    widget.state.settings.learningLanguageCode,
                translationLanguageCodes:
                    widget.state.settings.translationLanguageCodes,
                isFavorite: isFav,
                isLearned: isLearned,
                example: widget.state.exampleFor(word),
                selectionMode: _selection.isActive,
                isSelected: _selection.contains(word.id),
                onSelectionChanged: (selected) =>
                    _selection.setSelected(word.id, selected ?? false),
                onFavoriteToggle: () => widget.state.favorites.toggle(word.id),
                onLearnedToggle: () =>
                    widget.state.memorization.setLearned(word.id, !isLearned),
                onTap: () => WordDetailsSheet.show(
                  context,
                  word: word,
                  learningLanguageCode:
                      widget.state.settings.learningLanguageCode,
                  translationLanguageCodes:
                      widget.state.settings.translationLanguageCodes,
                  isFavorite: isFav,
                  isLearned: isLearned,
                  onFavoriteToggle: () =>
                      widget.state.favorites.toggle(word.id),
                  onMemorizationToggle: () =>
                      widget.state.memorization.setLearned(word.id, !isLearned),
                  speech: widget.state.speech,
                  verb: widget.state.verbFor(word),
                ),
                speech: widget.state.speech,
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
    await widget.state.memorization.markLearnedAll(ids);
    if (!mounted) return;
    _selection.clear();
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.bulkLearnedDone(ids.length))));
  }

  Future<void> _addSelectedToFavorites(Set<String> ids) async {
    if (ids.isEmpty) return;
    await widget.state.favorites.addAll(ids);
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
