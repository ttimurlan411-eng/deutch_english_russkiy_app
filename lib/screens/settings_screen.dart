import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

/// The settings screen: interface language and basic speech preferences.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  /// The interface languages offered, each labelled in its own language.
  static const List<({String code, String label})> _languages =
      <({String code, String label})>[
        (code: 'ky', label: 'Кыргызча'),
        (code: 'ru', label: 'Русский'),
        (code: 'en', label: 'English'),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: state.settings,
      builder: (context, _) {
        final settings = state.settings;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settings)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                _SectionHeader(
                  icon: Icons.translate_rounded,
                  title: l10n.interfaceLanguage,
                  subtitle: l10n.interfaceLanguageSubtitle,
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final language in _languages)
                        ChoiceChip(
                          label: Text(language.label),
                          selected: settings.languageCode == language.code,
                          onSelected: (_) =>
                              settings.setLanguage(language.code),
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                            color: settings.languageCode == language.code
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          showCheckmark: false,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  icon: Icons.record_voice_over_outlined,
                  title: l10n.speech,
                  subtitle: l10n.speechSubtitle,
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: <Widget>[
                      SwitchListTile.adaptive(
                        value: settings.speechEnabled,
                        onChanged: settings.setSpeechEnabled,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l10n.speechEnabled,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(l10n.speechEnabledSubtitle),
                      ),
                      const Divider(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.speechRate,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: <Widget>[
                            for (final rate in SpeechRates.all)
                              ChoiceChip(
                                label: Text(_rateLabel(l10n, rate)),
                                selected: settings.speechRate == rate,
                                onSelected: (_) => settings.setSpeechRate(rate),
                                selectedColor: AppTheme.primary,
                                labelStyle: TextStyle(
                                  color: settings.speechRate == rate
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                showCheckmark: false,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  onTap: () => _testVoice(context),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.testVoice,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              l10n.testVoiceSubtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  icon: Icons.info_outline_rounded,
                  title: l10n.about,
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Text(
                    l10n.aboutText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _rateLabel(AppLocalizations l10n, double rate) {
    if (rate == SpeechRates.slow) return l10n.speechRateSlow;
    if (rate == SpeechRates.fast) return l10n.speechRateFast;
    return l10n.speechRateNormal;
  }

  Future<void> _testVoice(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    final ok = await state.speech.speak('Hello', 'en');
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.playAudio : l10n.audioUnavailable),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
