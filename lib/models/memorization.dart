/// Memorization status of a single vocabulary word.
///
/// The status is independent of the favorite flag: a word can be a favorite
/// and still be new, and a learned word does not have to be a favorite.
enum MemorizationStatus {
  /// The word has not been marked as learned yet.
  newWord,

  /// The user marked the word as learned ("Жаттадым").
  learned,
}
