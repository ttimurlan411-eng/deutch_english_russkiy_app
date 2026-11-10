import 'package:english_deutch_ruskiy/l10n/app_localizations.dart';
import 'package:english_deutch_ruskiy/models/app_settings.dart';
import 'package:english_deutch_ruskiy/models/learning_languages.dart';
import 'package:english_deutch_ruskiy/services/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SettingsRepository', () {
    test('returns the defaults when nothing was stored', () async {
      final settings = await SettingsRepository().load();

      expect(settings.languageCode, 'ky');
      expect(settings.learningLanguageCode, LearningLanguages.english);
      expect(settings.displayLanguageCodes, LearningLanguages.all);
      expect(settings.speechEnabled, isTrue);
      expect(settings.speechRate, SpeechRates.normal);
    });

    test('reads the stored learning languages', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SettingsRepository.learningLanguageKey: 'de',
        SettingsRepository.translationLanguagesKey: <String>[
          'en',
          'ru',
          'de',
          'xx',
        ],
      });

      final settings = await SettingsRepository().load();

      expect(settings.learningLanguageCode, 'de');
      expect(settings.translationLanguageCodes, <String>{'en', 'ru'});
      expect(settings.displayLanguageCodes, <String>['de', 'en', 'ru']);
    });

    test('reads the stored values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SettingsRepository.languageKey: 'ru',
        SettingsRepository.speechEnabledKey: false,
        SettingsRepository.speechRateKey: SpeechRates.fast,
      });

      final settings = await SettingsRepository().load();

      expect(settings.languageCode, 'ru');
      expect(settings.speechEnabled, isFalse);
      expect(settings.speechRate, SpeechRates.fast);
    });

    test('falls back to the default for an unsupported language', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SettingsRepository.languageKey: 'de',
      });

      final settings = await SettingsRepository().load();

      expect(
        settings.languageCode,
        AppLocalizations.defaultLocale.languageCode,
      );
    });

    test('saves every value it is given', () async {
      final repository = SettingsRepository();

      await repository.saveLanguage('en');
      await repository.saveSpeechEnabled(false);
      await repository.saveSpeechRate(SpeechRates.slow);

      final settings = await repository.load();
      expect(settings.languageCode, 'en');
      expect(settings.speechEnabled, isFalse);
      expect(settings.speechRate, SpeechRates.slow);
    });
  });

  group('SettingsController', () {
    test('starts with the default language', () async {
      final controller = SettingsController(SettingsRepository());
      await controller.load();

      expect(controller.languageCode, 'ky');
      expect(controller.locale.languageCode, 'ky');
      expect(controller.isLoaded, isTrue);
    });

    test('notifies listeners when the language changes', () async {
      final controller = SettingsController(SettingsRepository());
      await controller.load();

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setLanguage('en');
      expect(controller.languageCode, 'en');
      expect(controller.locale.languageCode, 'en');
      expect(notifications, 1);

      // Setting the same language again changes nothing.
      await controller.setLanguage('en');
      expect(notifications, 1);
    });

    test('keeps the previous learning language as a translation', () async {
      final repository = SettingsRepository();
      final controller = SettingsController(repository);
      await controller.load();

      await controller.setLearningLanguage('de');

      expect(controller.learningLanguageCode, 'de');
      expect(controller.translationLanguageCodes, <String>{'en', 'ru'});
      expect(controller.displayLanguageCodes, <String>['de', 'en', 'ru']);

      final reloaded = await repository.load();
      expect(reloaded.learningLanguageCode, 'de');
      expect(reloaded.displayLanguageCodes, <String>['de', 'en', 'ru']);
    });

    test(
      'toggles translations and never hides the learning language',
      () async {
        final repository = SettingsRepository();
        final controller = SettingsController(repository);
        await controller.load();

        await controller.setTranslationEnabled('ru', false);
        expect(controller.translationLanguageCodes, <String>{'de'});

        await controller.setTranslationEnabled('en', false);
        expect(controller.translationLanguageCodes, <String>{'de'});

        final reloaded = await repository.load();
        expect(reloaded.translationLanguageCodes, <String>{'de'});
        expect(reloaded.displayLanguageCodes, <String>['en', 'de']);
      },
    );

    test('selects and clears all three languages at once', () async {
      final repository = SettingsRepository();
      final controller = SettingsController(repository);
      await controller.load();

      await controller.setLearningLanguage('de');
      await controller.setAllTranslationsEnabled(false);
      expect(controller.displayLanguageCodes, <String>['de']);

      await controller.setAllTranslationsEnabled(true);
      expect(controller.translationLanguageCodes, <String>{'en', 'ru'});
      expect(controller.displayLanguageCodes, <String>['de', 'en', 'ru']);

      final reloaded = await repository.load();
      expect(reloaded.displayLanguageCodes, <String>['de', 'en', 'ru']);
    });

    test('persists the speech preferences', () async {
      final repository = SettingsRepository();
      final controller = SettingsController(repository);
      await controller.load();

      await controller.setSpeechEnabled(false);
      await controller.setSpeechRate(SpeechRates.fast);

      expect(controller.speechEnabled, isFalse);
      expect(controller.speechRate, SpeechRates.fast);

      final reloaded = await repository.load();
      expect(reloaded.speechEnabled, isFalse);
      expect(reloaded.speechRate, SpeechRates.fast);
    });
  });
}
