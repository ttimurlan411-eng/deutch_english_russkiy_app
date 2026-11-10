import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/example_sentence.dart';
import '../models/learning_languages.dart';
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
    required this.learningLanguageCode,
    required this.translationLanguageCodes,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.speech,
    this.isLearned = false,
    this.onLearnedToggle,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.example,
  });

  final Word word;

  /// Language shown as the main word and pronounced by the speaker button.
  final String learningLanguageCode;

  /// Additional languages shown as translations of the main word.
  final Set<String> translationLanguageCodes;

  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final SpeechService speech;

  /// Whether the word is marked as learned.
  final bool isLearned;

  /// Marks the word as learned or moves it back to the new words.
  final VoidCallback? onLearnedToggle;

  /// Whether the list is in selection mode.
  final bool selectionMode;

  /// Whether the word is selected in selection mode.
  final bool isSelected;

  /// Called when the checkbox of the card is toggled.
  final ValueChanged<bool?>? onSelectionChanged;

  /// Example sentence attached to the word, if the dataset contains one.
  final ExampleSentence? example;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final translationCodes = <String>[
      for (final code in LearningLanguages.all)
        if (code != learningLanguageCode &&
            translationLanguageCodes.contains(code))
          code,
    ];

    return Material(
      color: selectionMode && isSelected ? AppTheme.tint : AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: selectionMode
                ? () => onSelectionChanged?.call(!isSelected)
                : onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectionMode) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Checkbox(
                        key: ValueKey<String>('word-checkbox-${word.id}'),
                        value: isSelected,
                        onChanged: onSelectionChanged,
                        activeColor: AppTheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                word.textFor(learningLanguageCode),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _LevelBadge(level: word.level),
                          ],
                        ),
                        for (var i = 0; i < translationCodes.length; i++) ...[
                          SizedBox(height: i == 0 ? 6 : 3),
                          _TranslationLine(
                            language: l10n.languageName(translationCodes[i]),
                            value: word.textFor(translationCodes[i]),
                            color: _languageColor(translationCodes[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!selectionMode) ...<Widget>[
                    const SizedBox(width: 4),
                    SpeakerButton(
                      text: word.textFor(learningLanguageCode),
                      languageCode: learningLanguageCode,
                      speechService: speech,
                    ),
                    if (onLearnedToggle != null)
                      IconButton(
                        onPressed: onLearnedToggle,
                        tooltip: isLearned
                            ? l10n.markAsNew
                            : l10n.markAsLearned,
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
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          _ExampleSection(
            example: example,
            speech: speech,
            languageCodes: <String>[learningLanguageCode, ...translationCodes],
          ),
        ],
      ),
    );
  }
}

/// Collapsible example sentence block shown at the bottom of a word card.
class _ExampleSection extends StatelessWidget {
  const _ExampleSection({
    required this.example,
    required this.speech,
    required this.languageCodes,
  });

  final ExampleSentence? example;
  final SpeechService speech;
  final List<String> languageCodes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sentence = example;
    final lines = <Widget>[
      if (sentence != null)
        for (final code in languageCodes)
          if (sentence.textFor(code).trim().isNotEmpty)
            _ExampleLine(
              label: l10n.languageName(code),
              text: sentence.textFor(code),
              languageCode: code,
              wordId: sentence.wordId,
              speech: speech,
            ),
    ];

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        leading: const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: AppTheme.primary,
        ),
        title: Text(
          l10n.exampleSentences,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: <Widget>[
          if (lines.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.noExampleSentence,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines,
            ),
        ],
      ),
    );
  }
}

class _ExampleLine extends StatelessWidget {
  const _ExampleLine({
    required this.label,
    required this.text,
    required this.languageCode,
    required this.wordId,
    required this.speech,
  });

  final String label;
  final String text;
  final String languageCode;
  final String wordId;
  final SpeechService speech;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          SpeakerButton(
            key: ValueKey<String>('example-$wordId-$languageCode'),
            text: text,
            languageCode: languageCode,
            speechService: speech,
            size: 18,
          ),
        ],
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

Color _languageColor(String languageCode) {
  switch (languageCode) {
    case 'de':
      return AppTheme.secondary;
    case 'ru':
      return AppTheme.success;
    case 'en':
    default:
      return AppTheme.primary;
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
