import 'package:english_deutch_ruskiy/models/word.dart';
import 'package:english_deutch_ruskiy/services/word_search.dart';
import 'package:flutter_test/flutter_test.dart';

const List<Word> _words = <Word>[
  Word(level: 'A1', english: 'mother', german: 'die Mutter', russian: 'мама'),
  Word(level: 'A1', english: 'father', german: 'der Vater', russian: 'папа'),
  Word(
    level: 'A2',
    english: 'to remember',
    german: 'sich erinnern',
    russian: 'помнить',
  ),
  Word(
    level: 'B1',
    english: 'to achieve',
    german: 'erreichen',
    russian: 'достигать',
  ),
];

void main() {
  group('WordSearch', () {
    test('returns every word for an empty query', () {
      expect(WordSearch.apply(_words), hasLength(4));
      expect(WordSearch.apply(_words, query: '   '), hasLength(4));
    });

    test('matches the English column', () {
      final results = WordSearch.apply(_words, query: 'mother');

      expect(results, hasLength(1));
      expect(results.single.english, 'mother');
    });

    test('matches the German column', () {
      final results = WordSearch.apply(_words, query: 'Mutter');

      expect(results, hasLength(1));
      expect(results.single.german, 'die Mutter');
    });

    test('matches the Russian column', () {
      final results = WordSearch.apply(_words, query: 'помнить');

      expect(results, hasLength(1));
      expect(results.single.russian, 'помнить');
    });

    test('ignores case', () {
      expect(WordSearch.apply(_words, query: 'MOTHER'), hasLength(1));
      expect(WordSearch.apply(_words, query: 'erreichen'), hasLength(1));
      expect(WordSearch.apply(_words, query: 'МАМА'), hasLength(1));
    });

    test('matches partial words', () {
      expect(WordSearch.apply(_words, query: 'moth'), hasLength(1));
      expect(WordSearch.apply(_words, query: 'erinner'), hasLength(1));
      expect(WordSearch.apply(_words, query: 'достиг'), hasLength(1));
    });

    test('returns nothing when no column matches', () {
      expect(WordSearch.apply(_words, query: 'xyzzy'), isEmpty);
    });

    test('filters by level', () {
      expect(WordSearch.apply(_words, level: 'A1'), hasLength(2));
      expect(WordSearch.apply(_words, level: 'B1'), hasLength(1));
      expect(WordSearch.apply(_words, level: 'B2'), isEmpty);
    });

    test('combines level filter and query', () {
      final results = WordSearch.apply(_words, level: 'A1', query: 'father');

      expect(results, hasLength(1));
      expect(results.single.level, 'A1');
    });

    test('filters by favorite ids', () {
      final results = WordSearch.apply(
        _words,
        favoriteIds: <String>{'A1|mother', 'B1|to achieve'},
      );

      expect(results, hasLength(2));
      expect(
        results.map((word) => word.id),
        containsAll(<String>['A1|mother', 'B1|to achieve']),
      );
    });
  });
}
