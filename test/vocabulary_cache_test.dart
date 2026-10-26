import 'dart:convert';

import 'package:english_deutch_ruskiy/app_state.dart';
import 'package:english_deutch_ruskiy/models/review_record.dart';
import 'package:english_deutch_ruskiy/models/verb_forms.dart';
import 'package:english_deutch_ruskiy/models/word.dart';
import 'package:english_deutch_ruskiy/services/dictionary_data_service.dart';
import 'package:english_deutch_ruskiy/services/favorites_repository.dart';
import 'package:english_deutch_ruskiy/services/speech_service.dart';
import 'package:english_deutch_ruskiy/services/vocabulary_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_asset_bundle.dart';
import 'support/fake_flutter_tts.dart';

/// Uses a broken asset bundle first and the sample dataset after [succeed].
class _SwitchableDataService extends DictionaryDataService {
  _SwitchableDataService() : super(bundle: FakeAssetBundle(<String, String>{}));

  final DictionaryDataService _working = DictionaryDataService(
    bundle: SampleData.bundle(),
  );

  bool succeed = false;

  @override
  Future<DictionaryData> load() {
    return succeed ? _working.load() : super.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late DictionaryData sampleData;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    sampleData = await DictionaryDataService(
      bundle: SampleData.bundle(),
    ).load();
  });

  group('VocabularyCacheRepository', () {
    test('returns null on a cold start with no cache', () async {
      final cache = VocabularyCacheRepository(prefs);

      expect(await cache.load(), isNull);
    });

    test('writes and reads the parsed dictionary after recreation', () async {
      await VocabularyCacheRepository(prefs).save(sampleData);

      final reopened = VocabularyCacheRepository(prefs);
      final cached = await reopened.load();

      expect(cached, isNotNull);
      expect(
        cached!.words.map((word) => word.id),
        sampleData.words.map((word) => word.id),
      );
      expect(cached.words.first.german, 'die Mutter');
      expect(cached.verbs, hasLength(1));
      expect(cached.verbs.single.infinitiveEn, 'to be');
      expect(cached.verbs.single.hilfsverb, 'sein');
    });

    test('discards a corrupted cache and removes the bad entry', () async {
      await prefs.setString(VocabularyCacheRepository.storageKey, '{broken');

      final cached = await VocabularyCacheRepository(prefs).load();

      expect(cached, isNull);
      expect(prefs.getString(VocabularyCacheRepository.storageKey), isNull);
    });

    test('discards a cache written by an unsupported version', () async {
      await prefs.setString(
        VocabularyCacheRepository.storageKey,
        jsonEncode(<String, Object?>{
          'version': VocabularyCacheRepository.formatVersion + 1,
          'words': <Object?>[],
          'verbs': <Object?>[],
        }),
      );

      final cached = await VocabularyCacheRepository(prefs).load();

      expect(cached, isNull);
      expect(prefs.getString(VocabularyCacheRepository.storageKey), isNull);
    });

    test('does not overwrite a good cache with an empty dataset', () async {
      final cache = VocabularyCacheRepository(prefs);
      await cache.save(sampleData);

      await cache.save(
        const DictionaryData(words: <Word>[], verbs: <VerbForms>[]),
      );

      final cached = await cache.load();
      expect(cached, isNotNull);
      expect(cached!.words, hasLength(6));
    });
  });

  group('AppState vocabulary cache fallback', () {
    test('loads cached vocabulary when bundled assets fail', () async {
      await VocabularyCacheRepository(prefs).save(sampleData);
      final state = AppState(
        dataService: DictionaryDataService(
          bundle: FakeAssetBundle(<String, String>{}),
        ),
        cacheRepository: VocabularyCacheRepository(prefs),
        favoritesRepository: FavoritesRepository(prefs),
        speechService: SpeechService(tts: FakeFlutterTts()),
      );

      await state.initialize();

      expect(state.status, LoadStatus.ready);
      expect(state.usingCache, isTrue);
      expect(state.refreshError, contains('Failed to read asset'));
      expect(state.words, hasLength(6));
      expect(state.verbs, hasLength(1));
      expect(state.words.first.english, 'mother');
    });

    test(
      'reports an error when neither assets nor cache are available',
      () async {
        final state = AppState(
          dataService: DictionaryDataService(
            bundle: FakeAssetBundle(<String, String>{}),
          ),
          cacheRepository: VocabularyCacheRepository(prefs),
          favoritesRepository: FavoritesRepository(prefs),
          speechService: SpeechService(tts: FakeFlutterTts()),
        );

        await state.initialize();

        expect(state.status, LoadStatus.error);
        expect(state.usingCache, isFalse);
        expect(state.errorMessage, contains('Failed to read asset'));
        expect(state.words, isEmpty);
      },
    );

    test('recovers from a corrupt cache by rebuilding it from assets without '
        'deleting user learning data', () async {
      final review = ReviewRecord(
        wordId: 'A1|mother',
        outcome: ReviewOutcome.remembered,
        reviewedAt: DateTime.utc(2026, 1, 1),
        nextReviewAt: DateTime.utc(2026, 1, 2),
        streak: 1,
      );
      await prefs.setStringList('favorite_word_ids', <String>['A1|to be']);
      await prefs.setStringList('learned_word_ids', <String>['A1|mother']);
      await prefs.setStringList('review_records', <String>[
        review.toJsonString(),
      ]);
      await prefs.setString('ui_language', 'ru');
      await prefs.setBool('speech_enabled', false);
      await prefs.setDouble('speech_rate', 0.6);
      await prefs.setString(VocabularyCacheRepository.storageKey, '{broken');

      final state = AppState(
        dataService: DictionaryDataService(bundle: SampleData.bundle()),
        cacheRepository: VocabularyCacheRepository(prefs),
        favoritesRepository: FavoritesRepository(prefs),
        speechService: SpeechService(tts: FakeFlutterTts()),
      );

      await state.initialize();

      expect(state.status, LoadStatus.ready);
      expect(state.usingCache, isFalse);
      expect(state.words, hasLength(6));
      expect(state.favorites.contains('A1|to be'), isTrue);
      expect(state.memorization.isLearned('A1|mother'), isTrue);
      expect(state.memorization.reviewHistory, hasLength(1));
      expect(state.memorization.reviewHistory.single.wordId, 'A1|mother');
      expect(state.settings.languageCode, 'ru');
      expect(state.settings.speechEnabled, isFalse);
      expect(state.settings.speechRate, 0.6);

      final repaired = await VocabularyCacheRepository(prefs).load();
      expect(repaired, isNotNull);
      expect(repaired!.words, hasLength(6));
    });

    test('retries a failed load and drops the cached copy', () async {
      await VocabularyCacheRepository(prefs).save(sampleData);
      final service = _SwitchableDataService();
      final state = AppState(
        dataService: service,
        cacheRepository: VocabularyCacheRepository(prefs),
        favoritesRepository: FavoritesRepository(prefs),
        speechService: SpeechService(tts: FakeFlutterTts()),
      );

      await state.initialize();
      expect(state.status, LoadStatus.ready);
      expect(state.usingCache, isTrue);

      service.succeed = true;
      await state.initialize();

      expect(state.status, LoadStatus.ready);
      expect(state.usingCache, isFalse);
      expect(state.refreshError, isNull);
      expect(state.words, hasLength(6));
    });

    test(
      'keeps favorites, learned ids, reviews and settings during recovery',
      () async {
        final review = ReviewRecord(
          wordId: 'A1|mother',
          outcome: ReviewOutcome.remembered,
          reviewedAt: DateTime.utc(2026, 1, 1),
          nextReviewAt: DateTime.utc(2026, 1, 2),
          streak: 1,
        );
        await prefs.setStringList('favorite_word_ids', <String>['A1|to be']);
        await prefs.setStringList('learned_word_ids', <String>['A1|mother']);
        await prefs.setStringList('review_records', <String>[
          review.toJsonString(),
        ]);
        await prefs.setString('ui_language', 'ru');
        await prefs.setBool('speech_enabled', false);
        await prefs.setDouble('speech_rate', 0.6);
        await VocabularyCacheRepository(prefs).save(sampleData);

        final state = AppState(
          dataService: DictionaryDataService(
            bundle: FakeAssetBundle(<String, String>{}),
          ),
          cacheRepository: VocabularyCacheRepository(prefs),
          favoritesRepository: FavoritesRepository(prefs),
          speechService: SpeechService(tts: FakeFlutterTts()),
        );

        await state.initialize();

        expect(state.status, LoadStatus.ready);
        expect(state.usingCache, isTrue);
        expect(state.favorites.contains('A1|to be'), isTrue);
        expect(state.memorization.isLearned('A1|mother'), isTrue);
        expect(state.memorization.reviewHistory, hasLength(1));
        expect(state.memorization.reviewHistory.single.wordId, 'A1|mother');
        expect(state.settings.languageCode, 'ru');
        expect(state.settings.speechEnabled, isFalse);
        expect(state.settings.speechRate, 0.6);
      },
    );
  });
}
