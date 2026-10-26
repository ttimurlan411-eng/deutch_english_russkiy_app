/// A single vocabulary entry from the `master_*.csv` files.
///
/// Columns: `level,english,german,russian`. Values are stored verbatim;
/// nothing is merged, normalized, or discarded.
class Word {
  const Word({
    required this.level,
    required this.english,
    required this.german,
    required this.russian,
  });

  final String level;
  final String english;
  final String german;
  final String russian;

  /// Stable identity used for favorites and lookups.
  String get id => '$level|$english';

  @override
  String toString() => 'Word($level, $english, $german, $russian)';
}
