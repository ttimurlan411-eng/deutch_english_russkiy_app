import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// The header of a list in selection mode.
///
/// Shows how many visible words are selected and offers a button that selects
/// or deselects every currently visible word.
class BulkSelectionHeader extends StatelessWidget {
  const BulkSelectionHeader({
    super.key,
    required this.selectedCount,
    required this.allSelected,
    required this.onToggleAll,
  });

  final int selectedCount;
  final bool allSelected;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppTheme.tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.checklist_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.selectedCount(selectedCount),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onToggleAll,
            child: Text(allSelected ? l10n.deselectAll : l10n.selectAll),
          ),
        ],
      ),
    );
  }
}

/// The action panel shown below a list in selection mode.
class BulkSelectionActions extends StatelessWidget {
  const BulkSelectionActions({
    super.key,
    required this.enabled,
    required this.onMarkLearned,
    required this.onAddToFavorites,
    required this.onClearSelected,
  });

  final bool enabled;
  final VoidCallback onMarkLearned;
  final VoidCallback onAddToFavorites;
  final VoidCallback onClearSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: <Widget>[
          FilledButton.tonalIcon(
            onPressed: enabled ? onMarkLearned : null,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: Text(l10n.markSelectedLearned),
          ),
          OutlinedButton.icon(
            onPressed: enabled ? onAddToFavorites : null,
            icon: const Icon(Icons.favorite_border, size: 20),
            label: Text(l10n.addSelectedToFavorites),
          ),
          TextButton.icon(
            onPressed: enabled ? onClearSelected : null,
            icon: const Icon(Icons.close_rounded, size: 20),
            label: Text(l10n.clearSelected),
          ),
        ],
      ),
    );
  }
}
