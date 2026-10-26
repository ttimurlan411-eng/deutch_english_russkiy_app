import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'learned_words_screen.dart';
import 'new_words_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

/// Hosts the bottom navigation shell with the main screens of the app.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.state});

  final AppState state;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  int _index = 0;

  void _select(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compactNavigation = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          HomeScreen(
            state: widget.state,
            onOpenVocabulary: () => _select(1),
            onOpenLearnedWords: () => _select(2),
            onOpenReview: () => _select(3),
            onOpenFavorites: () => _select(4),
            onOpenStatistics: () => _select(5),
            onOpenSettings: () => _select(6),
          ),
          NewWordsScreen(state: widget.state),
          LearnedWordsScreen(state: widget.state),
          ReviewScreen(state: widget.state),
          FavoritesScreen(state: widget.state),
          StatisticsScreen(state: widget.state),
          SettingsScreen(state: widget.state),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        backgroundColor: AppTheme.surface,
        indicatorColor: const Color(0xFFE6E9FB),
        labelBehavior: compactNavigation
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(
              Icons.home_rounded,
              color: AppTheme.primary,
            ),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(
              Icons.menu_book_rounded,
              color: AppTheme.primary,
            ),
            label: l10n.navNewWords,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(
              Icons.school_rounded,
              color: AppTheme.primary,
            ),
            label: l10n.navLearnedWords,
          ),
          NavigationDestination(
            icon: const Icon(Icons.refresh_rounded),
            selectedIcon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.primary,
            ),
            label: l10n.navReview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite, color: AppTheme.primary),
            label: l10n.navFavorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(
              Icons.insights_rounded,
              color: AppTheme.primary,
            ),
            label: l10n.navStatistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(
              Icons.settings_rounded,
              color: AppTheme.primary,
            ),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
