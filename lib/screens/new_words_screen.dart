import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../services/word_search.dart';
import '../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.state.vocabulary.query,
    );
  }

  @override
  void dispose() {
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
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.newWords)),
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

    return Column(
      children: <Widget>[
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
                isFavorite: isFav,
                isLearned: isLearned,
                onFavoriteToggle: () => widget.state.favorites.toggle(word.id),
                onLearnedToggle: () =>
                    widget.state.memorization.setLearned(word.id, !isLearned),
                onTap: () => WordDetailsSheet.show(
                  context,
                  word: word,
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
      ],
    );
  }
}
