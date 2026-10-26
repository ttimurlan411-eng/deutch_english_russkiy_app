import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';

/// Persists user preferences (interface language, speech) via
/// [SharedPreferences].
class SettingsRepository {
  /// [preferences] is an optional injection point used by tests; when it is
  /// omitted the platform default instance is resolved lazily.
  SettingsRepository([this._preferences]);

  static const String languageKey = 'ui_language';
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
    return AppSettings(
      languageCode: language != null && supported.contains(language)
          ? language
          : AppLocalizations.defaultLocale.languageCode,
      speechEnabled: prefs.getBool(speechEnabledKey) ?? true,
      speechRate: prefs.getDouble(speechRateKey) ?? SpeechRates.normal,
    );
  }

  Future<void> saveLanguage(String languageCode) async {
    final prefs = await _prefs;
    await prefs.setString(languageKey, languageCode);
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
