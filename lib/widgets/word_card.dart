import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/word.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import 'speaker_button.dart';

/// A single vocabulary entry rendered as a readable card.
///
/// Shows the English headword plus the German and Russian translations, a
/// speaker button that reads the word aloud, a favorite toggle, a
/// memorization toggle and a tap target for the details sheet.
class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.speech,
    this.isLearned = false,
    this.onLearnedToggle,
  });

  final Word word;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final SpeechService speech;

  /// Whether the word is marked as learned.
  final bool isLearned;

  /// Marks the word as learned or moves it back to the new words.
  final VoidCallback? onLearnedToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            word.english,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _LevelBadge(level: word.level),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _TranslationLine(
                      language: l10n.german,
                      value: word.german,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 3),
                    _TranslationLine(
                      language: l10n.russian,
                      value: word.russian,
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              SpeakerButton(text: word.english, speechService: speech),
              if (onLearnedToggle != null)
                IconButton(
                  onPressed: onLearnedToggle,
                  tooltip: isLearned ? l10n.markAsNew : l10n.markAsLearned,
                  style: IconButton.styleFrom(
                    foregroundColor: isLearned
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  icon: Icon(
                    isLearned
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 22,
                  ),
                ),
              IconButton(
                onPressed: onFavoriteToggle,
                tooltip: l10n.favorites,
                style: IconButton.styleFrom(
                  foregroundColor: isFavorite
                      ? const Color(0xFFE96443)
                      : AppTheme.textSecondary,
                ),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslationLine extends StatelessWidget {
  const _TranslationLine({
    required this.language,
    required this.value,
    required this.color,
  });

  final String language;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3, right: 8),
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.tint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
