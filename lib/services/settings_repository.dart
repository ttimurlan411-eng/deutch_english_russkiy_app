import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/learning_languages.dart';

/// Persists user preferences (interface language, speech) via
/// [SharedPreferences].
class SettingsRepository {
  /// [preferences] is an optional injection point used by tests; when it is
  /// omitted the platform default instance is resolved lazily.
  SettingsRepository([this._preferences]);

  static const String languageKey = 'ui_language';
  static const String learningLanguageKey = 'learning_language';
  static const String translationLanguagesKey = 'translation_languages';
  static const String speechEnabledKey = 'speech_enabled';
  static const String speechRateKey = 'speech_rate';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<AppSettings> load() async {
    final prefs = await _prefs;
    final language = prefs.getString(languageKey);
    final supported = AppLocalizations.supportedLocales
        .map((Locale locale) => locale.languageCode)
        .toSet();

    final supportedLearning = LearningLanguages.all.toSet();
    final storedLearning = prefs.getString(learningLanguageKey);
    final learning =
        storedLearning != null && supportedLearning.contains(storedLearning)
        ? storedLearning
        : LearningLanguages.english;

    final storedTranslations = prefs.getStringList(translationLanguagesKey);
    final translations = storedTranslations == null
        ? LearningLanguages.all.where((code) => code != learning).toSet()
        : storedTranslations
              .where(supportedLearning.contains)
              .where((code) => code != learning)
              .toSet();

    return AppSettings(
      languageCode: language != null && supported.contains(language)
          ? language
          : AppLocalizations.defaultLocale.languageCode,
      learningLanguageCode: learning,
      translationLanguageCodes: translations,
      speechEnabled: prefs.getBool(speechEnabledKey) ?? true,
      speechRate: prefs.getDouble(speechRateKey) ?? SpeechRates.normal,
    );
  }

  Future<void> saveLanguage(String languageCode) async {
    final prefs = await _prefs;
    await prefs.setString(languageKey, languageCode);
  }

  Future<void> saveLearningLanguage(String languageCode) async {
    final prefs = await _prefs;
    await prefs.setString(learningLanguageKey, languageCode);
  }

  Future<void> saveTranslationLanguages(Set<String> languageCodes) async {
    final prefs = await _prefs;
    final ordered = LearningLanguages.all
        .where(languageCodes.contains)
        .toList(growable: false);
    await prefs.setStringList(translationLanguagesKey, ordered);
  }

  Future<void> saveSpeechEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(speechEnabledKey, enabled);
  }

  Future<void> saveSpeechRate(double rate) async {
    final prefs = await _prefs;
    await prefs.setDouble(speechRateKey, rate);
  }
}

/// Holds the current settings and notifies listeners on changes.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  bool get isLoaded => _loaded;

  AppSettings get settings => _settings;

  String get languageCode => _settings.languageCode;

  String get learningLanguageCode => _settings.learningLanguageCode;

  Set<String> get translationLanguageCodes =>
      _settings.translationLanguageCodes;

  /// Every visible language, with the learning language first.
  List<String> get displayLanguageCodes => _settings.displayLanguageCodes;

  bool get speechEnabled => _settings.speechEnabled;

  double get speechRate => _settings.speechRate;

  /// The interface locale matching the selected [languageCode].
  Locale get locale => _settings.locale;

  Future<void> load() async {
    _settings = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_settings.languageCode == languageCode) return;
    _settings = _settings.copyWith(languageCode: languageCode);
    notifyListeners();
    await _repository.saveLanguage(languageCode);
  }

  Future<void> setLearningLanguage(String languageCode) async {
    if (!LearningLanguages.isSupported(languageCode)) return;
    if (_settings.learningLanguageCode == languageCode) return;
    // Keep every language that was visible: the previous learning language
    // becomes a translation of the new one.
    final translations = Set<String>.of(_settings.translationLanguageCodes)
      ..remove(languageCode)
      ..add(_settings.learningLanguageCode);
    _settings = _settings.copyWith(
      learningLanguageCode: languageCode,
      translationLanguageCodes: translations,
    );
    notifyListeners();
    await _repository.saveLearningLanguage(languageCode);
    await _repository.saveTranslationLanguages(translations);
  }

  Future<void> setTranslationEnabled(String languageCode, bool enabled) async {
    if (!LearningLanguages.isSupported(languageCode)) return;
    if (languageCode == _settings.learningLanguageCode) return;
    final translations = Set<String>.of(_settings.translationLanguageCodes);
    if (enabled) {
      translations.add(languageCode);
    } else {
      translations.remove(languageCode);
    }
    if (setEquals(translations, _settings.translationLanguageCodes)) return;
    _settings = _settings.copyWith(translationLanguageCodes: translations);
    notifyListeners();
    await _repository.saveTranslationLanguages(translations);
  }

  /// Shows every supported language at once (the learning language plus both
  /// translations), or only the learning language when [enabled] is false.
  Future<void> setAllTranslationsEnabled(bool enabled) async {
    final translations = enabled
        ? <String>{
            for (final code in LearningLanguages.all)
              if (code != _settings.learningLanguageCode) code,
          }
        : <String>{};
    if (setEquals(translations, _settings.translationLanguageCodes)) return;
    _settings = _settings.copyWith(translationLanguageCodes: translations);
    notifyListeners();
    await _repository.saveTranslationLanguages(translations);
  }

  Future<void> setSpeechEnabled(bool enabled) async {
    if (_settings.speechEnabled == enabled) return;
    _settings = _settings.copyWith(speechEnabled: enabled);
    notifyListeners();
    await _repository.saveSpeechEnabled(enabled);
  }

  Future<void> setSpeechRate(double rate) async {
    if (_settings.speechRate == rate) return;
    _settings = _settings.copyWith(speechRate: rate);
    notifyListeners();
    await _repository.saveSpeechRate(rate);
  }
}
