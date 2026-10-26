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
import 'statistics_screen.dart';

/// The list of the words the user marked as learned ("Жаттадым").
///
/// The list can be searched in all three languages and filtered by CEFR
/// level. A learned word can be moved back to the new words at any time.
class LearnedWordsScreen extends StatefulWidget {
  const LearnedWordsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<LearnedWordsScreen> createState() => _LearnedWordsScreenState();
}

class _LearnedWordsScreenState extends State<LearnedWordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _level;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.state,
        widget.state.favorites,
        widget.state.memorization,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.learnedWords),
            actions: <Widget>[
              IconButton(
                tooltip: l10n.openStatistics,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StatisticsScreen(state: widget.state),
                  ),
                ),
                icon: const Icon(Icons.insights_outlined),
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
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
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
                  selected: _level,
                  onSelected: (level) => setState(() => _level = level),
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
      level: _level,
      query: _query,
      learnedIds: widget.state.memorization.learnedIds,
      subset: WordSubset.learnedWords,
    );

    if (results.isEmpty) {
      final filtered = _query.trim().isNotEmpty || _level != null;
      return EmptyView(
        title: filtered ? l10n.noResults : l10n.noLearnedWords,
        subtitle: filtered
            ? l10n.noResultsSubtitle
            : l10n.noLearnedWordsSubtitle,
        icon: filtered ? Icons.search_off_rounded : Icons.school_outlined,
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
              return WordCard(
                word: word,
                isFavorite: isFav,
                isLearned: true,
                onFavoriteToggle: () => widget.state.favorites.toggle(word.id),
                onLearnedToggle: () =>
                    widget.state.memorization.markNew(word.id),
                onTap: () => WordDetailsSheet.show(
                  context,
                  word: word,
                  isFavorite: isFav,
                  isLearned: true,
                  onFavoriteToggle: () =>
                      widget.state.favorites.toggle(word.id),
                  onMemorizationToggle: () =>
                      widget.state.memorization.markNew(word.id),
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
