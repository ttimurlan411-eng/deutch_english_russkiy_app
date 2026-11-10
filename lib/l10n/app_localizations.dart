import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Application strings for every supported locale.
///
/// Kyrgyz (`ky`) is the default language of the app. All user-facing text is
/// resolved through [AppLocalizations] so additional locales can be added
/// without touching the UI code.
class AppLocalizations {
  const AppLocalizations(this.locale, this._values);

  /// The default language of the application.
  static const Locale defaultLocale = Locale('ky');

  /// Locales the app ships translations for.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ky'),
    Locale('en'),
    Locale('ru'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Returns the strings for the closest supported [locale].
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(defaultLocale, _ky);
  }

  final Locale locale;
  final Map<String, String> _values;

  String _t(String key) => _values[key] ?? _ky[key] ?? key;

  String get appTitle => _t('appTitle');
  String get searchHint => _t('searchHint');
  String get allLevels => _t('allLevels');
  String get favorites => _t('favorites');
  String get noFavorites => _t('noFavorites');
  String get noResults => _t('noResults');
  String get loadErrorTitle => _t('loadErrorTitle');
  String get retry => _t('retry');
  String get cachedDataNotice => _t('cachedDataNotice');
  String get english => _t('english');
  String get german => _t('german');
  String get russian => _t('russian');

  /// Localized name of a learning language code (`en`, `de`, `ru`).
  String languageName(String languageCode) {
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

  String get verbs => _t('verbs');
  String get forms => _t('forms');
  String get close => _t('close');
  String get playAudio => _t('playAudio');
  String get audioUnavailable => _t('audioUnavailable');
  String get wordCountSuffix => _t('wordCountSuffix');
  String get levelLabel => _t('levelLabel');
  String get loading => _t('loading');
  String get infinitive => _t('infinitive');
  String get pastSimple => _t('pastSimple');
  String get pastParticiple => _t('pastParticiple');
  String get praesens => _t('praesens');
  String get praeteritum => _t('praeteritum');
  String get partizipII => _t('partizipII');
  String get hilfsverb => _t('hilfsverb');
  String get russianInfinitive => _t('russianInfinitive');
  String get russianPresent => _t('russianPresent');
  String get russianPast => _t('russianPast');
  String get russianFuture => _t('russianFuture');
  String get englishForms => _t('englishForms');
  String get germanForms => _t('germanForms');
  String get russianForms => _t('russianForms');
  String get detailsTitle => _t('detailsTitle');

  // Home screen.
  String get homeSubtitle => _t('homeSubtitle');
  String get totalWords => _t('totalWords');
  String get levels => _t('levels');
  String get quickAccess => _t('quickAccess');
  String get browseAllWords => _t('browseAllWords');
  String get browseAllWordsSubtitle => _t('browseAllWordsSubtitle');
  String get favoritesSubtitle => _t('favoritesSubtitle');
  String get favoritesEmptySubtitle => _t('favoritesEmptySubtitle');
  String get noResultsSubtitle => _t('noResultsSubtitle');
  String get verbsAvailable => _t('verbsAvailable');

  // Navigation.
  String get navHome => _t('navHome');
  String get navWords => _t('navWords');
  String get navFavorites => _t('navFavorites');
  String get navSettings => _t('navSettings');
  String get navNewWords => _t('navNewWords');
  String get navLearnedWords => _t('navLearnedWords');
  String get navReview => _t('navReview');
  String get navStatistics => _t('navStatistics');

  // Memorization.
  String get markAsLearned => _t('markAsLearned');
  String get markAsNew => _t('markAsNew');
  String get newWords => _t('newWords');
  String get learnedWords => _t('learnedWords');
  String get newWordsSubtitle => _t('newWordsSubtitle');
  String get learnedWordsSubtitle => _t('learnedWordsSubtitle');
  String get learnedLabel => _t('learnedLabel');
  String get newLabel => _t('newLabel');
  String get noNewWords => _t('noNewWords');
  String get noNewWordsSubtitle => _t('noNewWordsSubtitle');
  String get noLearnedWords => _t('noLearnedWords');
  String get noLearnedWordsSubtitle => _t('noLearnedWordsSubtitle');
  String get wordMovedToNew => _t('wordMovedToNew');
  String get wordMarkedLearned => _t('wordMarkedLearned');

  // Review.
  String get review => _t('review');
  String get reviewSubtitle => _t('reviewSubtitle');
  String get revealAnswer => _t('revealAnswer');
  String get remembered => _t('remembered');
  String get needToLearnAgain => _t('needToLearnAgain');
  String get reviewFinished => _t('reviewFinished');
  String get reviewProgress => _t('reviewProgress');
  String get dueForReview => _t('dueForReview');
  String get startAgain => _t('startAgain');
  String get noWordsToReview => _t('noWordsToReview');
  String get noWordsToReviewSubtitle => _t('noWordsToReviewSubtitle');

  // Statistics.
  String get statistics => _t('statistics');
  String get statisticsSubtitle => _t('statisticsSubtitle');
  String get openStatistics => _t('openStatistics');
  String get progressLabel => _t('progressLabel');
  String get byLevel => _t('byLevel');
  String get reviewResults => _t('reviewResults');
  String get reviewedToday => _t('reviewedToday');
  String get rememberedLabel => _t('rememberedLabel');
  String get needLearningLabel => _t('needLearningLabel');
  String get totalReviews => _t('totalReviews');
  String get datasetTotalNote => _t('datasetTotalNote');

  // Vocabulary screen.
  String get vocabulary => _t('vocabulary');
  String get clearSearch => _t('clearSearch');
  String get filterByLevel => _t('filterByLevel');
  String get noVerbData => _t('noVerbData');

  // Example sentences.
  String get exampleSentences => _t('exampleSentences');
  String get noExampleSentence => _t('noExampleSentence');

  // Bulk selection.
  String get selectMode => _t('selectMode');
  String get exitSelectMode => _t('exitSelectMode');
  String get selectAll => _t('selectAll');
  String get deselectAll => _t('deselectAll');
  String get markSelectedLearned => _t('markSelectedLearned');
  String get addSelectedToFavorites => _t('addSelectedToFavorites');
  String get clearSelected => _t('clearSelected');

  /// Label with the number of selected words, e.g. `3 тандалды`.
  String selectedCount(int count) {
    return _t('selectedCount').replaceAll('{count}', '$count');
  }

  /// Confirmation after a bulk "mark as learned" action.
  String bulkLearnedDone(int count) {
    return _t('bulkLearnedDone').replaceAll('{count}', '$count');
  }

  /// Confirmation after a bulk "add to favorites" action.
  String bulkFavoritesDone(int count) {
    return _t('bulkFavoritesDone').replaceAll('{count}', '$count');
  }

  // Settings screen.
  String get settings => _t('settings');
  String get interfaceLanguage => _t('interfaceLanguage');
  String get interfaceLanguageSubtitle => _t('interfaceLanguageSubtitle');
  String get learningLanguage => _t('learningLanguage');
  String get learningLanguageSubtitle => _t('learningLanguageSubtitle');
  String get translationLanguages => _t('translationLanguages');
  String get translationLanguagesSubtitle => _t('translationLanguagesSubtitle');
  String get allLanguages => _t('allLanguages');
  String get allLanguagesSubtitle => _t('allLanguagesSubtitle');
  String get speech => _t('speech');
  String get speechSubtitle => _t('speechSubtitle');
  String get speechEnabled => _t('speechEnabled');
  String get speechEnabledSubtitle => _t('speechEnabledSubtitle');
  String get speechRate => _t('speechRate');
  String get speechRateSlow => _t('speechRateSlow');
  String get speechRateNormal => _t('speechRateNormal');
  String get speechRateFast => _t('speechRateFast');
  String get testVoice => _t('testVoice');
  String get testVoiceSubtitle => _t('testVoiceSubtitle');
  String get about => _t('about');
  String get aboutText => _t('aboutText');
  String get dataSource => _t('dataSource');

  /// Word count label, e.g. `12 сөз`.
  String wordCount(int count) => '$count ${_t('wordCountSuffix')}';

  /// Verb count label, e.g. `233 этиш`.
  String verbCount(int count) => '$count ${_t('verbCountSuffix')}';

  /// Summary of a finished review session.
  String reviewSummary(int remembered, int total) {
    return _t(
      'reviewSummary',
    ).replaceAll('{remembered}', '$remembered').replaceAll('{total}', '$total');
  }

  static const Map<String, String> _ky = <String, String>{
    'appTitle': 'Үч тилдүү сөздүк',
    'searchHint': 'Сөз издөө (EN / DE / RU)',
    'allLevels': 'Баары',
    'favorites': 'Тандалмалар',
    'noFavorites': 'Тандалма сөздөр жок',
    'noResults': 'Эч нерсе табылган жок',
    'loadErrorTitle': 'Маалымат жүктөлбөдү',
    'retry': 'Кайра аракет кылуу',
    'cachedDataNotice':
        'Маалымат жаңыртылбады. Сакталган көчүрмө көрсөтүлүүдө.',
    'english': 'Англисче',
    'german': 'Немисче',
    'russian': 'Орусча',
    'verbs': 'Этиштер',
    'forms': 'Формалар',
    'close': 'Жабуу',
    'playAudio': 'Уккула',
    'audioUnavailable': 'Үн жеткиликсиз',
    'wordCountSuffix': 'сөз',
    'verbCountSuffix': 'этиш',
    'levelLabel': 'Деңгээл',
    'loading': 'Жүктөлүүдө…',
    'infinitive': 'Инфинитив',
    'pastSimple': 'Жаңы өткөн убак',
    'pastParticiple': 'Өткөн причастия',
    'praesens': 'Азыркы убак',
    'praeteritum': 'Өткөн убак',
    'partizipII': 'II причастия',
    'hilfsverb': 'Жардамчы этиш',
    'russianInfinitive': 'Инфинитив',
    'russianPresent': 'Азыркы убак (я)',
    'russianPast': 'Өткөн убак (он/она)',
    'russianFuture': 'Келешек убак (я)',
    'englishForms': 'Англисче формалары',
    'germanForms': 'Немисче формалары',
    'russianForms': 'Орусча формалары',
    'detailsTitle': 'Сөздүн маалыматы',
    'homeSubtitle': 'Англисче, немисче жана орусча сөздөрдүн сөздүгү',
    'totalWords': 'Жалпы сөз',
    'levels': 'Деңгээлдер',
    'quickAccess': 'Түз кириш',
    'browseAllWords': 'Бардык сөздөр',
    'browseAllWordsSubtitle': 'Издөө жана деңгээл чүүрткөч менен',
    'favoritesSubtitle': 'Сактап алган сөздөрүңүз',
    'favoritesEmptySubtitle': 'Сөз таңдап, жүргөн басып, таңдалмага кошуңуз',
    'noResultsSubtitle': 'Башка сөз менен издеп көрүңүз',
    'verbsAvailable': 'Этиш формалары бар',
    'navHome': 'Баш бет',
    'navWords': 'Сөздөр',
    'navFavorites': 'Тандалма',
    'navSettings': 'Жөндөөлөр',
    'vocabulary': 'Сөздөр',
    'clearSearch': 'Тазалоо',
    'filterByLevel': 'Деңгээл боюнча чүүртүү',
    'noVerbData': 'Бул сөздүн этиш формасы жок',
    'exampleSentences': 'Мисал сүйлөм',
    'noExampleSentence': 'Мисал азырынча жок',
    'selectMode': 'Тандоо',
    'exitSelectMode': 'Тандоодон чыгуу',
    'selectAll': 'Баарын тандоо',
    'deselectAll': 'Тандоону алып салуу',
    'markSelectedLearned': 'Үйрөндүм деп белгилөө',
    'addSelectedToFavorites': 'Сүйүктүүлөргө кошуу',
    'clearSelected': 'Тандалгандарды алып салуу',
    'selectedCount': '{count} тандалды',
    'bulkLearnedDone': '{count} сөз үйрөнүлдү деп белгиленди',
    'bulkFavoritesDone': '{count} сөз сүйүктүүлөргө кошулду',
    'settings': 'Жөндөөлөр',
    'interfaceLanguage': 'Интерфейс тили',
    'interfaceLanguageSubtitle': 'Колдонмонун тилин тандаңыз',
    'learningLanguage': 'Үйрөнүүчү тил',
    'learningLanguageSubtitle':
        'Кайсы тилди үйрөнөсүз? Башкы сөз ушул тилде көрүнөт',
    'translationLanguages': 'Котормо тилдери',
    'translationLanguagesSubtitle': 'Кошумча көрсөтүлүүчү тилдерди тандаңыз',
    'allLanguages': 'Үч тилдин баары',
    'allLanguagesSubtitle': 'Үйрөнүүчү тил жана эки котормо бирге',
    'speech': 'Үн',
    'speechSubtitle': 'Сөздөрдү угуу мүмкүнчүлүгү',
    'speechEnabled': 'Окуу мүмкүн',
    'speechEnabledSubtitle': 'Сөздөрдү күзгөмөл угуу',
    'speechRate': 'Окуу темпи',
    'speechRateSlow': 'Акырын',
    'speechRateNormal': 'Кадимки',
    'speechRateFast': 'Тез',
    'testVoice': 'Үнүн текшерүү',
    'testVoiceSubtitle': 'Үн жеткиликсиз экенин билүү үчүн',
    'about': 'Колдонмо жөнүндө',
    'aboutText':
        'Бул колдонмо толук оффлайн иштейт. Маалымат CSV файлдарынан окулат.',
    'dataSource': 'Маалымат булагы',
    'navNewWords': 'Жаңы сөз',
    'navLearnedWords': 'Үйрөнгөн',
    'navReview': 'Кайталоо',
    'navStatistics': 'Статистика',
    'markAsLearned': 'Жаттадым',
    'markAsNew': 'Кайра үйрөнөм',
    'newWords': 'Жаңы сөздөр',
    'learnedWords': 'Үйрөнгөн сөздөр',
    'newWordsSubtitle': 'Дагы үйрөнө эле жатышы мүмкүн болгон сөздөр',
    'learnedWordsSubtitle': '«Жаттадым» деп белгилген сөздөр',
    'learnedLabel': 'Үйрөнгөн',
    'newLabel': 'Жаңы',
    'noNewWords': 'Бардык сөздөрдү үйрөнгөнүз',
    'noNewWordsSubtitle':
        'Сөздөрдү «Жаттадым» деп белгилеп, үйрөнүүнүзди улантыңыз',
    'noLearnedWords': 'Үйрөнгөн сөз жок',
    'noLearnedWordsSubtitle':
        '«Жаттадым» деп белгилген сөздөр ушул жерде көрүнөт',
    'wordMovedToNew': 'Сөз жаңы сөздөргө кайтарылды',
    'wordMarkedLearned': 'Сөз жаттадым деп белгиленди',
    'review': 'Кайталоо',
    'reviewSubtitle': 'Үйрөнгөн сөздөрдү текшерүү',
    'revealAnswer': 'Жабыш көрсөтүү',
    'remembered': 'Эстедим',
    'needToLearnAgain': 'Кайра үйрөнөм',
    'reviewFinished': 'Кайталоо аяктады',
    'reviewProgress': 'Кайталоо жүгүртүү',
    'dueForReview': 'Кайталоого убак болду',
    'startAgain': 'Кайта баштоо',
    'noWordsToReview': 'Кайталоо үчүн сөз жок',
    'noWordsToReviewSubtitle':
        '«Жаттадым» деп белгилген сөздөрдү кайталоого кийин кириңиз',
    'reviewSummary': '{remembered} / {total} сөз эстен калды',
    'statistics': 'Статистика',
    'statisticsSubtitle': 'Сөздөрдүн үйрөнүү абалы',
    'openStatistics': 'Статистика',
    'progressLabel': 'Үйрөнүү',
    'byLevel': 'Деңгээл боюнча',
    'reviewResults': 'Кайталоо натыйжалары',
    'reviewedToday': 'Бүгүн кайталоогон',
    'rememberedLabel': 'Эстен калган',
    'needLearningLabel': 'Кайра үйрөнүү керек',
    'totalReviews': 'Бардык кайталоо',
    'datasetTotalNote': 'Жалпы сөз саны маалымат базасына тийкеш',
  };

  static const Map<String, String> _en = <String, String>{
    'appTitle': 'Three-language dictionary',
    'searchHint': 'Search (EN / DE / RU)',
    'allLevels': 'All',
    'favorites': 'Favorites',
    'noFavorites': 'No favorite words yet',
    'noResults': 'Nothing found',
    'loadErrorTitle': 'Could not load the data',
    'retry': 'Retry',
    'cachedDataNotice': 'Could not refresh the data. Showing the saved copy.',
    'english': 'English',
    'german': 'German',
    'russian': 'Russian',
    'verbs': 'Verbs',
    'forms': 'Forms',
    'close': 'Close',
    'playAudio': 'Listen',
    'audioUnavailable': 'Voice unavailable',
    'wordCountSuffix': 'words',
    'verbCountSuffix': 'verbs',
    'levelLabel': 'Level',
    'loading': 'Loading…',
    'infinitive': 'Infinitive',
    'pastSimple': 'Past simple',
    'pastParticiple': 'Past participle',
    'praesens': 'Present tense',
    'praeteritum': 'Preterite',
    'partizipII': 'Participle II',
    'hilfsverb': 'Auxiliary verb',
    'russianInfinitive': 'Infinitive',
    'russianPresent': 'Present (я)',
    'russianPast': 'Past (он/она)',
    'russianFuture': 'Future (я)',
    'englishForms': 'English forms',
    'germanForms': 'German forms',
    'russianForms': 'Russian forms',
    'detailsTitle': 'Word details',
    'homeSubtitle': 'A dictionary of English, German and Russian words',
    'totalWords': 'Total words',
    'levels': 'Levels',
    'quickAccess': 'Quick access',
    'browseAllWords': 'All words',
    'browseAllWordsSubtitle': 'Search and filter by level',
    'favoritesSubtitle': 'The words you saved',
    'favoritesEmptySubtitle': 'Pick a word and tap the heart to save it',
    'noResultsSubtitle': 'Try a different search term',
    'verbsAvailable': 'Verb forms available',
    'navHome': 'Home',
    'navWords': 'Words',
    'navFavorites': 'Favorites',
    'navSettings': 'Settings',
    'vocabulary': 'Words',
    'clearSearch': 'Clear',
    'filterByLevel': 'Filter by level',
    'noVerbData': 'No verb forms for this word',
    'exampleSentences': 'Example sentence',
    'noExampleSentence': 'No example yet',
    'selectMode': 'Select',
    'exitSelectMode': 'Exit selection',
    'selectAll': 'Select all',
    'deselectAll': 'Clear selection',
    'markSelectedLearned': 'Mark as learned',
    'addSelectedToFavorites': 'Add to favorites',
    'clearSelected': 'Remove selected',
    'selectedCount': '{count} selected',
    'bulkLearnedDone': '{count} words marked as learned',
    'bulkFavoritesDone': '{count} words added to favorites',
    'settings': 'Settings',
    'interfaceLanguage': 'Interface language',
    'interfaceLanguageSubtitle': 'Choose the language of the app',
    'learningLanguage': 'Learning language',
    'learningLanguageSubtitle':
        'The language you are studying; shown as the main word',
    'translationLanguages': 'Translation languages',
    'translationLanguagesSubtitle': 'Choose the additional languages to show',
    'allLanguages': 'All three languages',
    'allLanguagesSubtitle': 'Show the learning language and both translations',
    'speech': 'Speech',
    'speechSubtitle': 'Pronouncing the words',
    'speechEnabled': 'Enable pronunciation',
    'speechEnabledSubtitle': 'Hear the words read aloud',
    'speechRate': 'Speaking rate',
    'speechRateSlow': 'Slow',
    'speechRateNormal': 'Normal',
    'speechRateFast': 'Fast',
    'testVoice': 'Test voice',
    'testVoiceSubtitle': 'Check whether a voice is available',
    'about': 'About',
    'aboutText':
        'This app works fully offline. The data is read from CSV files.',
    'dataSource': 'Data source',
    'navNewWords': 'New',
    'navLearnedWords': 'Learned',
    'navReview': 'Review',
    'navStatistics': 'Statistics',
    'markAsLearned': 'Mark as learned',
    'markAsNew': 'Move back to new words',
    'newWords': 'New words',
    'learnedWords': 'Learned words',
    'newWordsSubtitle': 'The words you still have to learn',
    'learnedWordsSubtitle': 'The words you marked as learned',
    'learnedLabel': 'Learned',
    'newLabel': 'New',
    'noNewWords': 'You learned every word',
    'noNewWordsSubtitle': 'Mark words as learned to keep learning',
    'noLearnedWords': 'No learned words yet',
    'noLearnedWordsSubtitle': 'Words you mark as learned appear here',
    'wordMovedToNew': 'The word is back in the new words',
    'wordMarkedLearned': 'The word is marked as learned',
    'review': 'Review',
    'reviewSubtitle': 'Check the words you have learned',
    'revealAnswer': 'Show the answer',
    'remembered': 'Remembered',
    'needToLearnAgain': 'Need to learn again',
    'reviewFinished': 'Review finished',
    'reviewProgress': 'Review progress',
    'dueForReview': 'Due for review',
    'startAgain': 'Start again',
    'noWordsToReview': 'There is nothing to review',
    'noWordsToReviewSubtitle': 'Words marked as learned can be reviewed here',
    'reviewSummary': '{remembered} / {total} words remembered',
    'statistics': 'Statistics',
    'statisticsSubtitle': 'How far you have come',
    'openStatistics': 'Statistics',
    'progressLabel': 'Progress',
    'byLevel': 'By level',
    'reviewResults': 'Review results',
    'reviewedToday': 'Reviewed today',
    'rememberedLabel': 'Remembered',
    'needLearningLabel': 'To learn again',
    'totalReviews': 'Total reviews',
    'datasetTotalNote': 'The total follows the dataset',
  };

  static const Map<String, String> _ru = <String, String>{
    'appTitle': 'Трёхъязычный словарь',
    'searchHint': 'Поиск (EN / DE / RU)',
    'allLevels': 'Все',
    'favorites': 'Избранное',
    'noFavorites': 'Избранных слов пока нет',
    'noResults': 'Ничего не найдено',
    'loadErrorTitle': 'Не удалось загрузить данные',
    'retry': 'Повторить',
    'cachedDataNotice':
        'Не удалось обновить данные. Показана сохранённая копия.',
    'english': 'Английский',
    'german': 'Немецкий',
    'russian': 'Русский',
    'verbs': 'Глаголы',
    'forms': 'Формы',
    'close': 'Закрыть',
    'playAudio': 'Прослушать',
    'audioUnavailable': 'Голос недоступен',
    'wordCountSuffix': 'слов',
    'verbCountSuffix': 'глаголов',
    'levelLabel': 'Уровень',
    'loading': 'Загрузка…',
    'infinitive': 'Инфинитив',
    'pastSimple': 'Past Simple',
    'pastParticiple': 'Past Participle',
    'praesens': 'Präsens',
    'praeteritum': 'Präteritum',
    'partizipII': 'Partizip II',
    'hilfsverb': 'Вспомогательный глагол',
    'russianInfinitive': 'Инфинитив',
    'russianPresent': 'Настоящее (я)',
    'russianPast': 'Прошедшее (он/она)',
    'russianFuture': 'Будущее (я)',
    'englishForms': 'Английские формы',
    'germanForms': 'Немецкие формы',
    'russianForms': 'Русские формы',
    'detailsTitle': 'Сведения о слове',
    'homeSubtitle': 'Словарь английских, немецких и русских слов',
    'totalWords': 'Всего слов',
    'levels': 'Уровни',
    'quickAccess': 'Быстрый доступ',
    'browseAllWords': 'Все слова',
    'browseAllWordsSubtitle': 'Поиск и фильтр по уровню',
    'favoritesSubtitle': 'Слова, которые вы сохранили',
    'favoritesEmptySubtitle': 'Выберите слово и нажмите на сердечко',
    'noResultsSubtitle': 'Попробуйте изменить запрос',
    'verbsAvailable': 'Есть формы глагола',
    'navHome': 'Главная',
    'navWords': 'Слова',
    'navFavorites': 'Избранное',
    'navSettings': 'Настройки',
    'vocabulary': 'Слова',
    'clearSearch': 'Очистить',
    'filterByLevel': 'Фильтр по уровню',
    'noVerbData': 'Форм глагола для этого слова нет',
    'exampleSentences': 'Пример предложения',
    'noExampleSentence': 'Примера пока нет',
    'selectMode': 'Выбор',
    'exitSelectMode': 'Выйти из режима выбора',
    'selectAll': 'Выбрать все',
    'deselectAll': 'Снять выделение',
    'markSelectedLearned': 'Отметить выученными',
    'addSelectedToFavorites': 'Добавить в избранное',
    'clearSelected': 'Убрать выбранные',
    'selectedCount': 'Выбрано: {count}',
    'bulkLearnedDone': '{count} слов отмечено как выученные',
    'bulkFavoritesDone': '{count} слов добавлено в избранное',
    'settings': 'Настройки',
    'interfaceLanguage': 'Язык интерфейса',
    'interfaceLanguageSubtitle': 'Выберите язык приложения',
    'learningLanguage': 'Изучаемый язык',
    'learningLanguageSubtitle':
        'Язык, который вы учите; показывается как основное слово',
    'translationLanguages': 'Языки перевода',
    'translationLanguagesSubtitle': 'Выберите дополнительные языки для показа',
    'allLanguages': 'Все три языка',
    'allLanguagesSubtitle': 'Показать изучаемый язык и оба перевода',
    'speech': 'Произношение',
    'speechSubtitle': 'Чтение слов вслух',
    'speechEnabled': 'Включить озвучивание',
    'speechEnabledSubtitle': 'Слушать слова',
    'speechRate': 'Скорость чтения',
    'speechRateSlow': 'Медленно',
    'speechRateNormal': 'Обычно',
    'speechRateFast': 'Быстро',
    'testVoice': 'Проверить голос',
    'testVoiceSubtitle': 'Узнать, доступен ли голос',
    'about': 'О приложении',
    'aboutText':
        'Приложение работает полностью офлайн. Данные читаются из CSV-файлов.',
    'dataSource': 'Источник данных',
    'navNewWords': 'Новые',
    'navLearnedWords': 'Выучено',
    'navReview': 'Повтор',
    'navStatistics': 'Статистика',
    'markAsLearned': 'Отметить выученным',
    'markAsNew': 'Вернуть в новые слова',
    'newWords': 'Новые слова',
    'learnedWords': 'Выученные слова',
    'newWordsSubtitle': 'Слова, которые ещё нужно выучить',
    'learnedWordsSubtitle': 'Слова, отмеченные как выученные',
    'learnedLabel': 'Выучено',
    'newLabel': 'Новые',
    'noNewWords': 'Вы выучили все слова',
    'noNewWordsSubtitle': 'Отмечайте слова как выученные и продолжайте учиться',
    'noLearnedWords': 'Пока нет выученных слов',
    'noLearnedWordsSubtitle': 'Слова, отмеченные как выученные, появятся здесь',
    'wordMovedToNew': 'Слово снова в новых словах',
    'wordMarkedLearned': 'Слово отмечено как выученное',
    'review': 'Повторение',
    'reviewSubtitle': 'Проверьте выученные слова',
    'revealAnswer': 'Показать ответ',
    'remembered': 'Запомнил',
    'needToLearnAgain': 'Нужно повторить',
    'reviewFinished': 'Повторение завершено',
    'reviewProgress': 'Ход повторения',
    'dueForReview': 'Пора повторить',
    'startAgain': 'Начать заново',
    'noWordsToReview': 'Пока нечего повторять',
    'noWordsToReviewSubtitle':
        'Здесь можно повторять слова, отмеченные как выученные',
    'reviewSummary': '{remembered} / {total} слов запомнено',
    'statistics': 'Статистика',
    'statisticsSubtitle': 'Ваш прогресс в обучении',
    'openStatistics': 'Статистика',
    'progressLabel': 'Прогресс',
    'byLevel': 'По уровням',
    'reviewResults': 'Результаты повторения',
    'reviewedToday': 'Повторено сегодня',
    'rememberedLabel': 'Запомнено',
    'needLearningLabel': 'Надо повторить',
    'totalReviews': 'Всего повторений',
    'datasetTotalNote': 'Общее количество соответствует набору данных',
  };

  static const Map<String, Map<String, String>> _byLanguage =
      <String, Map<String, String>>{'ky': _ky, 'en': _en, 'ru': _ru};
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations._byLanguage.containsKey(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    final values =
        AppLocalizations._byLanguage[locale.languageCode] ??
        AppLocalizations._byLanguage[AppLocalizations
            .defaultLocale
            .languageCode]!;
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(locale, values),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
