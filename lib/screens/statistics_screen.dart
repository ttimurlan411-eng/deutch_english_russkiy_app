import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../services/learning_statistics.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/progress_bar.dart';
import '../widgets/state_views.dart';

/// The learning dashboard: how much of the vocabulary is learned, how many
/// words are still new and how the reviews went.
///
/// Every number is derived from the dataset and the persisted state.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[state, state.memorization]),
      builder: (context, _) {
        final statistics = state.statistics;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.statistics)),
          body: SafeArea(child: _buildStatus(context, l10n, statistics)),
        );
      },
    );
  }

  Widget _buildStatus(
    BuildContext context,
    AppLocalizations l10n,
    LearningStatistics statistics,
  ) {
    switch (state.status) {
      case LoadStatus.loading:
        return LoadingView(message: l10n.loading);
      case LoadStatus.error:
        return ErrorView(
          onRetry: state.initialize,
          message: state.errorMessage,
        );
      case LoadStatus.ready:
        return _buildBody(context, l10n, statistics);
    }
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    LearningStatistics statistics,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        _ProgressHero(statistics: statistics, label: l10n.progressLabel),
        const SizedBox(height: 16),
        _StatTile(
          icon: Icons.check_circle_rounded,
          color: AppTheme.success,
          label: l10n.learnedWords,
          value: l10n.wordCount(statistics.learnedCount),
        ),
        const SizedBox(height: 12),
        _StatTile(
          icon: Icons.fiber_new_rounded,
          color: AppTheme.primary,
          label: l10n.newWords,
          value: l10n.wordCount(statistics.newWordCount),
        ),
        const SizedBox(height: 12),
        _StatTile(
          icon: Icons.menu_book_rounded,
          color: AppTheme.secondary,
          label: l10n.totalWords,
          value: l10n.wordCount(statistics.totalWords),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: l10n.byLevel),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: <Widget>[
              for (final level in LearningStatistics.levels)
                _LevelRow(statistics: statistics.byLevel[level]!),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: l10n.reviewResults),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: <Widget>[
              _ReviewRow(
                label: l10n.reviewedToday,
                value: statistics.reviewsToday,
              ),
              const Divider(height: 20),
              _ReviewRow(
                label: l10n.rememberedLabel,
                value: statistics.rememberedCount,
              ),
              const Divider(height: 20),
              _ReviewRow(
                label: l10n.needLearningLabel,
                value: statistics.needsLearningCount,
              ),
              const Divider(height: 20),
              _ReviewRow(
                label: l10n.totalReviews,
                value: statistics.reviewCount,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.datasetTotalNote,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

/// The hero card with the overall learning progress.
class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.statistics, required this.label});

  final LearningStatistics statistics;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SoftContainer(
      gradient: AppTheme.brandGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${statistics.learnedPercent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          AppProgressBar(
            value: statistics.learnedFraction,
            height: 8,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),
          Text(
            '${statistics.learnedCount} / ${statistics.totalWords} '
            '${l10n.wordCountSuffix}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single statistic: an icon, a label and the value.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// The learned and new counts of a single level.
class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.statistics});

  final LevelStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statistics.level,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${statistics.learned} / ${statistics.total}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${statistics.percent}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppProgressBar(
            value: statistics.fraction,
            height: 6,
            color: AppTheme.success,
          ),
        ],
      ),
    );
  }
}

/// A label with the number of reviews of one kind.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// The title of a section of the dashboard.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
