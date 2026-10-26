import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/verb_forms.dart';
import '../models/word.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import 'speaker_button.dart';

/// Bottom sheet with the full entry: all three translations, level badge,
/// favorite toggle, the memorization action, a speaker button for
/// pronunciation and — when the dataset has a matching conjugation record —
/// the verb forms.
class WordDetailsSheet extends StatefulWidget {
  const WordDetailsSheet({
    super.key,
    required this.word,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.speech,
    this.verb,
    this.isLearned = false,
    this.onMemorizationToggle,
  });

  final Word word;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final SpeechService speech;
  final VerbForms? verb;

  /// Whether the word is marked as learned.
  final bool isLearned;

  /// Marks the word as learned or moves it back to the new words.
  final VoidCallback? onMemorizationToggle;

  static Future<void> show(
    BuildContext context, {
    required Word word,
    required bool isFavorite,
    required VoidCallback onFavoriteToggle,
    required SpeechService speech,
    VerbForms? verb,
    bool isLearned = false,
    VoidCallback? onMemorizationToggle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => WordDetailsSheet(
        word: word,
        isFavorite: isFavorite,
        onFavoriteToggle: onFavoriteToggle,
        speech: speech,
        verb: verb,
        isLearned: isLearned,
        onMemorizationToggle: onMemorizationToggle,
      ),
    );
  }

  @override
  State<WordDetailsSheet> createState() => _WordDetailsSheetState();
}

class _WordDetailsSheetState extends State<WordDetailsSheet> {
  late bool _isLearned = widget.isLearned;

  @override
  void didUpdateWidget(covariant WordDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLearned != oldWidget.isLearned) {
      _isLearned = widget.isLearned;
    }
  }

  void _toggleMemorization() {
    final callback = widget.onMemorizationToggle;
    if (callback == null) return;
    setState(() => _isLearned = !_isLearned);
    callback();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.word.english,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.word.level,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(
                label: l10n.english,
                value: widget.word.english,
                languageCode: 'en',
                speech: widget.speech,
              ),
              const Divider(height: 24),
              _DetailRow(
                label: l10n.german,
                value: widget.word.german,
                languageCode: 'de',
                speech: widget.speech,
              ),
              const Divider(height: 24),
              _DetailRow(
                label: l10n.russian,
                value: widget.word.russian,
                languageCode: 'ru',
                speech: widget.speech,
              ),
              const Divider(height: 24),
              _VerbFormsSection(verb: widget.verb),
              const SizedBox(height: 24),
              if (widget.onMemorizationToggle != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('word-details-memorization'),
                    onPressed: _toggleMemorization,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isLearned
                          ? AppTheme.success
                          : AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      _isLearned
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      _isLearned ? l10n.markAsNew : l10n.markAsLearned,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onFavoriteToggle,
                  style: widget.isFavorite
                      ? FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE96443),
                          foregroundColor: Colors.white,
                        )
                      : null,
                  icon: Icon(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text(l10n.favorites),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the conjugation table of a verb in all three languages.
class _VerbFormsSection extends StatelessWidget {
  const _VerbFormsSection({required this.verb});

  final VerbForms? verb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final forms = verb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 18,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.forms,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (forms == null)
          Text(
            l10n.noVerbData,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          )
        else ...[
          _FormGroup(
            title: l10n.englishForms,
            entries: <(String, String)>[
              (l10n.infinitive, forms.infinitiveEn),
              (l10n.pastSimple, forms.pastSimple),
              (l10n.pastParticiple, forms.pastParticiple),
            ],
          ),
          const SizedBox(height: 10),
          _FormGroup(
            title: l10n.germanForms,
            entries: <(String, String)>[
              (l10n.infinitive, forms.infinitivDe),
              (l10n.praesens, forms.praesensErSieEs),
              (l10n.praeteritum, forms.praeteritum),
              (l10n.partizipII, forms.partizipII),
              (l10n.hilfsverb, forms.hilfsverb),
            ],
          ),
          const SizedBox(height: 10),
          _FormGroup(
            title: l10n.russianForms,
            entries: <(String, String)>[
              (l10n.russianInfinitive, forms.russianInf),
              (l10n.russianPresent, forms.ruPresentYa),
              (l10n.russianPast, forms.ruPastOn),
              (l10n.russianFuture, forms.ruFutureYa),
            ],
          ),
        ],
      ],
    );
  }
}

class _FormGroup extends StatelessWidget {
  const _FormGroup({required this.title, required this.entries});

  final String title;
  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = entries
        .where((entry) => entry.$2.trim().isNotEmpty)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: AppTheme.tint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final entry in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      entry.$1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(entry.$2, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.languageCode,
    required this.speech,
  });

  final String label;
  final String value;
  final String languageCode;
  final SpeechService speech;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '—' : value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SpeakerButton(
          text: value,
          languageCode: languageCode,
          speechService: speech,
        ),
      ],
    );
  }
}
