import 'package:flutter_tts/flutter_tts.dart';

/// Test double for [FlutterTts].
///
/// Records the spoken text and lets a test control which voices the platform
/// reports as available.
class FakeFlutterTts implements FlutterTts {
  FakeFlutterTts({
    this.availableLanguages = const <String>['en-US', 'de-DE', 'ru-RU'],
    this.failOnSpeak = false,
  });

  final List<String> availableLanguages;
  final bool failOnSpeak;

  /// Every text that was passed to [speak].
  final List<String> spoken = <String>[];

  /// Languages that were requested through [setLanguage].
  final List<String> requestedLanguages = <String>[];

  @override
  Future<dynamic> setSpeechRate(double rate) async => null;

  @override
  Future<dynamic> setVolume(double volume) async => null;

  @override
  Future<dynamic> setPitch(double pitch) async => null;

  @override
  Future<dynamic> setLanguage(String language) async {
    requestedLanguages.add(language);
    return 1;
  }

  @override
  Future<dynamic> stop() async => null;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    if (failOnSpeak) {
      throw Exception('no voice');
    }
    spoken.add(text);
    return 1;
  }

  @override
  Future<dynamic> get getLanguages async => availableLanguages;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
