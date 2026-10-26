import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/review_record.dart';
import '../models/word.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/level_filter.dart';
import '../widgets/progress_bar.dart';
import '../widgets/speaker_button.dart';
import '../widgets/state_views.dart';

/// The review session over the learned words.
///
/// The session shows the English word first and hides the translations, so
/// the user can try to remember them. After revealing the answer the user
/// decides whether the word was remembered ("Эстедим") or has to be learned
/// again ("Кайра үйрөнөм"). The second option moves the word back to the new
/// words.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final Set<String> _answered = <String>{};
  List<Word> _session = const <Word>[];
  int _index = 0;
  bool _revealed = false;
  bool _completed = false;
  int _remembered = 0;
  int _needsLearning = 0;
  String? _level;

  @override
  void initState() {
    super.initState();
    _session = _buildSession();
    _completed = _session.isEmpty;
  }

  /// Builds the list of the words of the current session.
  ///
  /// Words whose next review is due come first, so the lightweight review
  /// schedule is respected.
  List<Word> _buildSession() {
    final memorization = widget.state.memorization;
    final learned = memorization.learnedIds;
    final due = memorization.dueReviewIds().toSet();

    final words = widget.state.words
        .where(
          (word) =>
              learned.contains(word.id) &&
              (_level == null || word.level == _level),
        )
        .toList();

    words.sort((a, b) {
      final aDue = due.contains(a.id) ? 0 : 1;
      final bDue = due.contains(b.id) ? 0 : 1;
      if (aDue != bDue) return aDue - bDue;
      return a.id.compareTo(b.id);
    });
    return words;
  }

  /// Starts a new session with the current level filter.
  void _startSession() {
    final words = _buildSession();
    setState(() {
      _session = words;
      _index = 0;
      _revealed = false;
      _completed = words.isEmpty;
      _answered.clear();
      _remembered = 0;
      _needsLearning = 0;
    });
  }

  Word? get _currentWord {
    if (_index < 0 || _index >= _session.length) return null;
    return _session[_index];
  }

  void _selectLevel(String? level) {
    if (_level == level) return;
    _level = level;
    _startSession();
  }

  Future<void> _answer(ReviewOutcome outcome) async {
    final word = _currentWord;
    if (word == null) return;

    setState(() => _answered.add(word.id));
    await widget.state.memorization.recordReview(word.id, outcome);
    if (!mounted) return;

    setState(() {
      if (outcome == ReviewOutcome.remembered) {
        _remembered++;
      } else {
        _needsLearning++;
      }
      _advance();
    });
  }

  /// Moves to the next word of the session that was not answered yet.
  void _advance() {
    var next = _index + 1;
    while (next < _session.length && _answered.contains(_session[next].id)) {
      next++;
    }
    if (next >= _session.length) {
      _index = _session.length;
      _completed = true;
    } else {
      _index = next;
      _revealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.state,
        widget.state.memorization,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.review)),
          body: SafeArea(child: _buildBody(l10n)),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    // The screen lives in an IndexedStack, so it is not rebuilt from scratch
    // when the user comes back. Start a session as soon as learned words are
    // available, even if the screen was opened while there were none.
    if (_session.isEmpty && widget.state.memorization.learnedIds.isNotEmpty) {
      _session = _buildSession();
      _completed = _session.isEmpty;
      _index = 0;
      _revealed = false;
      _remembered = 0;
      _needsLearning = 0;
      _answered.clear();
    }

    final word = _currentWord;
    if (word == null || _completed) {
      if (_session.isEmpty) {
        return EmptyView(
          title: l10n.noWordsToReview,
          subtitle: l10n.noWordsToReviewSubtitle,
          icon: Icons.refresh_rounded,
        );
      }
      return _SessionComplete(
        remembered: _remembered,
        needsLearning: _needsLearning,
        total: _session.length,
        onRestart: _startSession,
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: LevelFilter(selected: _level, onSelected: _selectLevel),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: AppProgressBar(
                  value: _session.isEmpty ? 0 : _index / _session.length,
                  height: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_index + 1} / ${_session.length}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ReviewCard(
              key: ValueKey<String>(word.id),
              word: word,
              revealed: _revealed,
              speech: widget.state.speech,
              onReveal: () => setState(() => _revealed = true),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: _revealed
              ? Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('review-again'),
                        onPressed: () => _answer(ReviewOutcome.needsLearning),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.warning,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.needToLearnAgain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('review-remembered'),
                        onPressed: () => _answer(ReviewOutcome.remembered),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.success,
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(l10n.remembered),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('review-reveal'),
                    onPressed: () => setState(() => _revealed = true),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.revealAnswer),
                  ),
                ),
        ),
      ],
    );
  }
}

/// The flashcard of the review session.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    super.key,
    required this.word,
    required this.revealed,
    required this.speech,
    required this.onReveal,
  });

  final Word word;
  final bool revealed;
  final SpeechService speech;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: revealed ? null : AppTheme.brandGradient,
        color: revealed ? AppTheme.surface : null,
        borderRadius: BorderRadius.circular(28),
        border: revealed ? Border.all(color: const Color(0xFFEDEFF6)) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: revealed ? AppTheme.tint : Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    word.level,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: revealed ? AppTheme.primary : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                SpeakerButton(text: word.english, speechService: speech),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              word.english,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: revealed ? AppTheme.textPrimary : Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            if (!revealed)
              Center(
                child: Text(
                  l10n.revealAnswer,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else ...[
              const Divider(height: 24),
              _Translation(label: l10n.german, value: word.german),
              const SizedBox(height: 12),
              _Translation(label: l10n.russian, value: word.russian),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single translation line of the revealed answer.
class _Translation extends StatelessWidget {
  const _Translation({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// The summary shown when every word of the session was answered.
class _SessionComplete extends StatelessWidget {
  const _SessionComplete({
    required this.remembered,
    required this.needsLearning,
    required this.total,
    required this.onRestart,
  });

  final int remembered;
  final int needsLearning;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.reviewFinished,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewSummary(remembered, total),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            if (needsLearning > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.needLearningLabel}: $needsLearning',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.startAgain),
            ),
          ],
        ),
      ),
    );
  }
}
