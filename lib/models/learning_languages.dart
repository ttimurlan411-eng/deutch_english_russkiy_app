/// Languages the app can teach and display for every vocabulary entry.
///
/// The codes match the `Word` fields and the language codes understood by
/// [SpeechService], so they can be used directly for pronunciation.
class LearningLanguages {
  const LearningLanguages._();

  static const String english = 'en';
  static const String german = 'de';
  static const String russian = 'ru';

  /// Every language in the order used throughout the UI.
  static const List<String> all = <String>[english, german, russian];

  static bool isSupported(String code) => all.contains(code);
}
