import 'package:english_deutch_ruskiy/app_state.dart';
import 'package:english_deutch_ruskiy/services/dictionary_data_service.dart';
import 'package:english_deutch_ruskiy/services/favorites_repository.dart';
import 'package:english_deutch_ruskiy/services/speech_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_asset_bundle.dart';
import 'support/fake_flutter_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  AppState buildState(DictionaryDataService service) {
    return AppState(
      dataService: service,
      favoritesRepository: FavoritesRepository(),
      speechService: SpeechService(tts: FakeFlutterTts()),
    );
  }

  test('reports the ready state with the loaded dataset', () async {
    final state = buildState(
      DictionaryDataService(bundle: SampleData.bundle()),
    );

    expect(state.status, LoadStatus.loading);

    await state.initialize();

    expect(state.status, LoadStatus.ready);
    expect(state.errorMessage, isNull);
    expect(state.words, hasLength(6));
    expect(state.verbs, hasLength(1));
  });

  test('attaches verb records to the matching vocabulary entry', () async {
    final state = buildState(
      DictionaryDataService(bundle: SampleData.bundle()),
    );
    await state.initialize();

    final toBe = state.words.firstWhere((word) => word.english == 'to be');
    final verb = state.verbFor(toBe);

    expect(verb, isNotNull);
    expect(verb!.infinitivDe, 'sein');
    expect(verb.russianInf, 'быть');
  });

  test('reports the error state when the dataset cannot be loaded', () async {
    final state = buildState(
      DictionaryDataService(bundle: FakeAssetBundle(<String, String>{})),
    );

    await state.initialize();

    expect(state.status, LoadStatus.error);
    expect(state.errorMessage, isNotNull);
    expect(state.errorMessage, contains('Failed to read asset'));
    expect(state.words, isEmpty);
  });

  test('restores persisted favorites while initializing', () async {
    await FavoritesRepository().save(<String>{'A1|mother'});

    final state = buildState(
      DictionaryDataService(bundle: SampleData.bundle()),
    );
    await state.initialize();

    expect(state.status, LoadStatus.ready);
    expect(state.favorites.contains('A1|mother'), isTrue);
    expect(state.favorites.count, 1);
  });
}
