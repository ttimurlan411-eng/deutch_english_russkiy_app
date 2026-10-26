import 'dart:async';

import 'package:english_deutch_ruskiy/app_state.dart';
import 'package:english_deutch_ruskiy/main.dart';
import 'package:english_deutch_ruskiy/models/verb_forms.dart';
import 'package:english_deutch_ruskiy/models/word.dart';
import 'package:english_deutch_ruskiy/screens/favorites_screen.dart';
import 'package:english_deutch_ruskiy/screens/home_screen.dart';
import 'package:english_deutch_ruskiy/screens/settings_screen.dart';
import 'package:english_deutch_ruskiy/screens/vocabulary_screen.dart';
import 'package:english_deutch_ruskiy/services/dictionary_data_service.dart';
import 'package:english_deutch_ruskiy/services/favorites_repository.dart';
import 'package:english_deutch_ruskiy/services/speech_service.dart';
import 'package:english_deutch_ruskiy/services/vocabulary_cache.dart';
import 'package:english_deutch_ruskiy/widgets/level_tile.dart';
import 'package:english_deutch_ruskiy/widgets/word_card.dart';
import 'package:english_deutch_ruskiy/widgets/word_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_asset_bundle.dart';
import 'support/fake_flutter_tts.dart';

/// A data service that never completes until the test releases it.
class _GatedDataService extends DictionaryDataService {
  final Completer<void> gate = Completer<void>();

  @override
  Future<DictionaryData> load() async {
    await gate.future;
    return const DictionaryData(words: <Word>[], verbs: <VerbForms>[]);
  }
}

AppState buildState([DictionaryDataService? service, FakeFlutterTts? tts]) {
  return AppState(
    dataService: service ?? DictionaryDataService(bundle: SampleData.bundle()),
    favoritesRepository: FavoritesRepository(),
    speechService: SpeechService(tts: tts ?? FakeFlutterTts()),
  );
}

/// Uses a phone-sized viewport so the whole dashboard fits on screen.
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Scopes a finder to one screen of the navigation shell.
Finder inScreen(Type screen, Finder finder) {
  return find.descendant(of: find.byType(screen), matching: finder);
}

/// The favorite toggle of the first word card.
Finder firstCardFavoriteButton() => find
    .descendant(
      of: find.byType(WordCard),
      matching: find.byIcon(Icons.favorite_border),
    )
    .first;

/// An icon of the bottom navigation bar.
Finder navIcon(IconData icon) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byIcon(icon),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Home screen', () {
    testWidgets('shows the loading state while the dataset is read', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final service = _GatedDataService();
      await tester.pumpWidget(DictionaryApp(state: buildState(service)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      service.gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows the error state and offers a retry', (tester) async {
      usePhoneViewport(tester);
      final state = buildState(
        DictionaryDataService(bundle: FakeAssetBundle(<String, String>{})),
      );
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      expect(find.textContaining('Маалымат жүктөлбөдү'), findsOneWidget);
      expect(find.textContaining('Failed to read asset'), findsOneWidget);
      expect(find.text('Кайра аракет кылуу'), findsOneWidget);
    });

    testWidgets('retries loading after the assets become available', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final bundle = FakeAssetBundle(<String, String>{});
      final state = buildState(DictionaryDataService(bundle: bundle));
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      expect(find.textContaining('Маалымат жүктөлбөдү'), findsOneWidget);

      bundle.contents.addAll(SampleData.bundle().contents);
      await tester.tap(find.text('Кайра аракет кылуу'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Маалымат жүктөлбөдү'), findsNothing);
      expect(inScreen(HomeScreen, find.text('6')), findsOneWidget);
    });

    testWidgets('retries a failed refresh and hides the cached-data notice', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final cached = await DictionaryDataService(
        bundle: SampleData.bundle(),
      ).load();
      await VocabularyCacheRepository().save(cached);

      final bundle = FakeAssetBundle(<String, String>{});
      final state = buildState(DictionaryDataService(bundle: bundle));
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cached-data-banner')), findsOneWidget);

      bundle.contents.addAll(SampleData.bundle().contents);
      await tester.tap(find.text('Кайра аракет кылуу'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cached-data-banner')), findsNothing);
      expect(inScreen(HomeScreen, find.text('6')), findsOneWidget);
    });

    testWidgets('shows a notice when the vocabulary comes from the cache', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final cached = await DictionaryDataService(
        bundle: SampleData.bundle(),
      ).load();
      await VocabularyCacheRepository().save(cached);

      final state = buildState(
        DictionaryDataService(bundle: FakeAssetBundle(<String, String>{})),
      );
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cached-data-banner')), findsOneWidget);
      expect(find.textContaining('Сакталган көчүрмө'), findsOneWidget);
      expect(inScreen(HomeScreen, find.text('6')), findsOneWidget);
    });

    testWidgets('shows a card per level with its word count', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      final tiles = inScreen(HomeScreen, find.byType(LevelTile));
      expect(tiles, findsNWidgets(4));

      // A1 holds three words in the sample dataset, the other levels one each.
      expect(inScreen(HomeScreen, find.text('3 сөз')), findsOneWidget);
      expect(inScreen(HomeScreen, find.text('1 сөз')), findsNWidgets(3));
    });

    testWidgets('summarises the dataset', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      expect(inScreen(HomeScreen, find.text('Жалпы сөз')), findsOneWidget);
      expect(inScreen(HomeScreen, find.text('6')), findsOneWidget);
      expect(inScreen(HomeScreen, find.text('1 этиш')), findsOneWidget);
    });

    testWidgets('opens the vocabulary filtered by the tapped level', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(inScreen(HomeScreen, find.text('A2')));
      await tester.pumpAndSettle();

      expect(
        inScreen(VocabularyScreen, find.text('to remember')),
        findsOneWidget,
      );
      expect(inScreen(VocabularyScreen, find.byType(WordCard)), findsOneWidget);
    });

    testWidgets('offers quick access to the favorites', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('home-favorites')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(HomeScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const Key('home-favorites')));
      await tester.pumpAndSettle();

      // The favorites tab is selected, so its empty state is on stage.
      expect(find.text('Тандалма сөздөр жок'), findsOneWidget);
    });
  });

  group('Vocabulary screen', () {
    testWidgets('lists the vocabulary with all three translations', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      expect(inScreen(VocabularyScreen, find.text('mother')), findsOneWidget);
      expect(
        inScreen(VocabularyScreen, find.text('die Mutter')),
        findsOneWidget,
      );
      expect(inScreen(VocabularyScreen, find.text('мама')), findsOneWidget);
      expect(inScreen(VocabularyScreen, find.text('6 сөз')), findsOneWidget);
    });

    testWidgets('shows only the visible cards of the lazy list', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      // The list is built lazily, so only the visible cards exist in the tree.
      expect(find.byType(WordCard).evaluate().length, lessThan(6));
    });

    testWidgets('filters by level', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'B1'));
      await tester.pumpAndSettle();

      expect(inScreen(VocabularyScreen, find.byType(WordCard)), findsOneWidget);
      expect(
        inScreen(VocabularyScreen, find.text('to achieve')),
        findsOneWidget,
      );
    });

    testWidgets('searches across the English, German and Russian columns', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      final field = find.byType(TextField);

      await tester.enterText(field, 'Mutter');
      await tester.pumpAndSettle();
      expect(inScreen(VocabularyScreen, find.text('mother')), findsOneWidget);

      await tester.enterText(field, 'erreichen');
      await tester.pumpAndSettle();
      expect(
        inScreen(VocabularyScreen, find.text('to achieve')),
        findsOneWidget,
      );

      await tester.enterText(field, 'помнить');
      await tester.pumpAndSettle();
      expect(
        inScreen(VocabularyScreen, find.text('to remember')),
        findsOneWidget,
      );
    });

    testWidgets('shows the empty state when nothing matches', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyzzy');
      await tester.pumpAndSettle();

      expect(inScreen(VocabularyScreen, find.byType(WordCard)), findsNothing);
      expect(find.text('Эч нерсе табылган жок'), findsOneWidget);
    });

    testWidgets('speaks the word from the card without opening the details', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final tts = FakeFlutterTts();
      await tester.pumpWidget(DictionaryApp(state: buildState(null, tts)));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .descendant(
              of: find.byType(WordCard),
              matching: find.byIcon(Icons.volume_up_rounded),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(tts.spoken, <String>['mother']);
      expect(tts.requestedLanguages, <String>['en']);
      // The speaker button must not open the details sheet.
      expect(find.byType(WordDetailsSheet), findsNothing);
    });

    testWidgets('opens the details sheet with the verb forms', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      await tester.tap(inScreen(VocabularyScreen, find.text('to be')));
      await tester.pumpAndSettle();

      expect(find.text('Англисче'), findsOneWidget);
      expect(find.text('Немисче'), findsOneWidget);
      expect(find.text('Орусча'), findsOneWidget);
      expect(find.text('sein'), findsWidgets);
      expect(find.text('was/were'), findsOneWidget);
      expect(find.text('gewesen'), findsOneWidget);
    });
  });

  group('Localization', () {
    testWidgets('uses Kyrgyz by default', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      expect(find.text('Үч тилдүү сөздүк'), findsOneWidget);

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Сөз издөө (EN / DE / RU)'), findsOneWidget);
    });

    testWidgets('renders another supported locale', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        DictionaryApp(state: buildState(), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Three-language dictionary'), findsOneWidget);

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Search (EN / DE / RU)'), findsOneWidget);
    });
  });

  group('Favorites', () {
    testWidgets('toggles a favorite and counts it on the home screen', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsNothing);

      await tester.tap(firstCardFavoriteButton());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(WordCard),
          matching: find.byIcon(Icons.favorite),
        ),
        findsOneWidget,
      );
    });

    testWidgets('lists the favorites on the favorites screen', (tester) async {
      usePhoneViewport(tester);
      final state = buildState();
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();
      await tester.tap(firstCardFavoriteButton());
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      expect(inScreen(FavoritesScreen, find.byType(WordCard)), findsOneWidget);
      expect(inScreen(FavoritesScreen, find.text('mother')), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no favorites', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(DictionaryApp(state: buildState()));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      expect(find.text('Тандалма сөздөр жок'), findsOneWidget);
    });

    testWidgets('keeps favorites across an app restart', (tester) async {
      usePhoneViewport(tester);
      final state = buildState();
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();
      await tester.tap(firstCardFavoriteButton());
      await tester.pumpAndSettle();

      // A different key forces a fresh State, simulating an app restart.
      final restarted = buildState();
      await tester.pumpWidget(
        DictionaryApp(key: const ValueKey<String>('restart'), state: restarted),
      );
      await tester.pumpAndSettle();

      expect(restarted.favorites.count, 1);
      expect(restarted.favorites.contains('A1|mother'), isTrue);
    });
  });

  group('Settings', () {
    testWidgets('switches the interface language', (tester) async {
      usePhoneViewport(tester);
      final state = buildState();
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(
        inScreen(SettingsScreen, find.text('Интерфейс тили')),
        findsOneWidget,
      );

      await tester.tap(inScreen(SettingsScreen, find.text('English')));
      await tester.pumpAndSettle();

      expect(state.settings.languageCode, 'en');
      expect(
        inScreen(SettingsScreen, find.text('Interface language')),
        findsOneWidget,
      );

      await tester.tap(navIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Three-language dictionary'), findsOneWidget);
    });

    testWidgets('keeps the chosen language across an app restart', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final state = buildState();
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(SettingsScreen, find.text('Русский')));
      await tester.pumpAndSettle();

      expect(state.settings.languageCode, 'ru');

      final restarted = buildState();
      await tester.pumpWidget(
        DictionaryApp(key: const ValueKey<String>('restart'), state: restarted),
      );
      await tester.pumpAndSettle();

      expect(restarted.settings.languageCode, 'ru');
      expect(find.text('Трёхъязычный словарь'), findsOneWidget);
    });

    testWidgets('disables the pronunciation', (tester) async {
      usePhoneViewport(tester);
      final tts = FakeFlutterTts();
      final state = buildState(null, tts);
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(state.settings.speechEnabled, isFalse);
      expect(state.speech.enabled, isFalse);
    });

    testWidgets('changes the speaking rate', (tester) async {
      usePhoneViewport(tester);
      final state = buildState();
      await tester.pumpWidget(DictionaryApp(state: state));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      await tester.tap(inScreen(SettingsScreen, find.text('Тез')));
      await tester.pumpAndSettle();

      expect(state.settings.speechRate, 0.6);
      expect(state.speech.rate, 0.6);
    });
  });
}
