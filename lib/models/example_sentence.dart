/// An example sentence attached to a vocabulary entry.
///
/// The [wordId] is the stable [Word.id] of the related word, so the example
/// dataset can stay separate from the master CSV files.
class ExampleSentence {
  const ExampleSentence({
    required this.wordId,
    required this.english,
    this.german = '',
    required this.russian,
  });

  final String wordId;
  final String english;
  final String german;
  final String russian;

  bool get isEmpty =>
      wordId.trim().isEmpty ||
      (english.trim().isEmpty &&
          german.trim().isEmpty &&
          russian.trim().isEmpty);

  /// Returns the sentence in [languageCode] (`en`, `de`, `ru`).
  String textFor(String languageCode) {
    switch (languageCode) {
      case 'de':
        return german;
      case 'ru':
        return russian;
      case 'en':
      default:
        return english;
    }
  }

  @override
  String toString() => 'ExampleSentence($wordId, $english)';
}
