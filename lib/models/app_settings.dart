import 'package:flutter/widgets.dart';

/// User preferences that are persisted between app launches.
class AppSettings {
  const AppSettings({
    this.languageCode = 'ky',
    this.speechEnabled = true,
    this.speechRate = 0.45,
  });

  /// BCP-47 language code of the interface language.
  final String languageCode;

  /// Whether pronunciation is enabled.
  final bool speechEnabled;

  /// Speaking rate understood by the platform text-to-speech engine.
  final double speechRate;

  /// The interface locale built from [languageCode].
  Locale get locale => Locale(languageCode);

  AppSettings copyWith({
    String? languageCode,
    bool? speechEnabled,
    double? speechRate,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
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
