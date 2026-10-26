import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts] that degrades gracefully when the platform
/// (or an individual language) has no available voice.
class SpeechService {
  SpeechService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;
  bool _available = true;
  double _appliedRate = 0.45;

  /// Whether pronunciation is switched on by the user.
  bool enabled = true;

  /// Speaking rate requested by the user.
  double rate = 0.45;

  bool get isAvailable => _available;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _tts.setSpeechRate(rate);
      _appliedRate = rate;
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (error) {
      _available = false;
      debugPrint('SpeechService init failed: $error');
    }
  }

  /// Applies the current [rate] to the engine when it changed.
  Future<void> _applyRate() async {
    if (_appliedRate == rate) return;
    try {
      await _tts.setSpeechRate(rate);
      _appliedRate = rate;
    } catch (error) {
      debugPrint('SpeechService.setSpeechRate failed: $error');
    }
  }

  /// Speaks [text] in [languageCode] (e.g. `en`, `de`, `ru`).
  ///
  /// Returns `false` when speech is unavailable instead of throwing.
  Future<bool> speak(String text, String languageCode) async {
    if (!enabled) return false;
    if (text.trim().isEmpty) return false;
    await _ensureInitialized();
    if (!_available) return false;
    try {
      await _applyRate();
      final supported = await _isLanguageAvailable(languageCode);
      if (!supported) return false;
      await _tts.setLanguage(languageCode);
      await _tts.stop();
      await _tts.speak(text);
      return true;
    } catch (error) {
      debugPrint('SpeechService.speak failed: $error');
      return false;
    }
  }

  Future<bool> _isLanguageAvailable(String languageCode) async {
    try {
      final dynamic languages = await _tts.getLanguages;
      if (languages is! List) return true;
      return languages.any(
        (dynamic lang) => lang.toString().toLowerCase().startsWith(
          languageCode.toLowerCase(),
        ),
      );
    } catch (_) {
      // If the platform cannot enumerate voices, optimistically try.
      return true;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore: stopping is best-effort.
    }
  }
}
