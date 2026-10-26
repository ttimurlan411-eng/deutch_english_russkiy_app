import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/word_search.dart';
import '../theme/app_theme.dart';

/// The row of CEFR level chips used by the new and the learned words list.
class LevelFilter extends StatelessWidget {
  const LevelFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// The selected level, or `null` for "all levels".
  final String? selected;

  /// Called with the new level, or `null` when "all levels" is selected.
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(l10n.allLevels),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: selected == null ? Colors.white : AppTheme.textPrimary,
              ),
              showCheckmark: false,
            ),
          ),
          for (final level in WordSearch.levels)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(level),
                selected: selected == level,
                onSelected: (_) => onSelected(level),
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: selected == level
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}
