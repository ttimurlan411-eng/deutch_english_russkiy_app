import 'package:flutter/widgets.dart';

import 'learning_languages.dart';

/// User preferences that are persisted between app launches.
class AppSettings {
  const AppSettings({
    this.languageCode = 'ky',
    this.learningLanguageCode = LearningLanguages.english,
    this.translationLanguageCodes = const <String>{
      LearningLanguages.german,
      LearningLanguages.russian,
    },
    this.speechEnabled = true,
    this.speechRate = 0.45,
  });

  /// BCP-47 language code of the interface language.
  final String languageCode;

  /// Language the user is currently studying; shown as the main word.
  final String learningLanguageCode;

  /// Additional languages shown as translations of the studied word.
  final Set<String> translationLanguageCodes;

  /// Whether pronunciation is enabled.
  final bool speechEnabled;

  /// Speaking rate understood by the platform text-to-speech engine.
  final double speechRate;

  /// The interface locale built from [languageCode].
  Locale get locale => Locale(languageCode);

  /// All languages that should be visible, with the learning language first.
  List<String> get displayLanguageCodes {
    final result = <String>[learningLanguageCode];
    for (final code in LearningLanguages.all) {
      if (code == learningLanguageCode) continue;
      if (translationLanguageCodes.contains(code)) result.add(code);
    }
    return result;
  }

  AppSettings copyWith({
    String? languageCode,
    String? learningLanguageCode,
    Set<String>? translationLanguageCodes,
    bool? speechEnabled,
    double? speechRate,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      learningLanguageCode: learningLanguageCode ?? this.learningLanguageCode,
      translationLanguageCodes:
          translationLanguageCodes ?? this.translationLanguageCodes,
      speechEnabled: speechEnabled ?? this.speechEnabled,
      speechRate: speechRate ?? this.speechRate,
    );
  }
}

/// The speaking rates offered in the settings screen.
class SpeechRates {
  const SpeechRates._();

  static const double slow = 0.35;
  static const double normal = 0.45;
  static const double fast = 0.6;

  static const List<double> all = <double>[slow, normal, fast];
}
