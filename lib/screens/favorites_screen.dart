import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/word.dart';
import '../services/word_search.dart';
import '../widgets/loading_view.dart';
import '../widgets/state_views.dart';
import '../widgets/word_card.dart';
import '../widgets/word_details_sheet.dart';

/// The list of words the user marked as favorite.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        state,
        state.favorites,
        state.memorization,
      ]),
      builder: (context, _) {
        final favorites = state.favorites;
        final words = WordSearch.apply(state.words, favoriteIds: favorites.ids);

        return Scaffold(
          appBar: AppBar(title: Text(l10n.favorites)),
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: words.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final word = words[index];
        final isFav = state.favorites.contains(word.id);
        final isLearned = state.memorization.isLearned(word.id);
        return WordCard(
          word: word,
          isFavorite: isFav,
          isLearned: isLearned,
          onFavoriteToggle: () => state.favorites.toggle(word.id),
          onLearnedToggle: () =>
              state.memorization.setLearned(word.id, !isLearned),
          onTap: () => WordDetailsSheet.show(
            context,
            word: word,
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
    );
  }
}
