import 'package:flutter/foundation.dart';

import '../models/example_sentence.dart';
import '../models/verb_forms.dart';
import '../models/word.dart';
import '../services/dictionary_data_service.dart';
import '../services/favorites_repository.dart';
import '../services/learning_statistics.dart';
import '../services/memorization_controller.dart';
import '../services/memorization_repository.dart';
import '../services/settings_repository.dart';
import '../services/speech_service.dart';
import '../services/vocabulary_cache.dart';
import '../services/vocabulary_controller.dart';

enum LoadStatus { loading, ready, error }

/// Top-level application state: dataset loading, favorites, memorization
/// status and settings.
class AppState extends ChangeNotifier {
  AppState({
    DictionaryDataService? dataService,
    VocabularyCacheRepository? cacheRepository,
    FavoritesRepository? favoritesRepository,
    SettingsRepository? settingsRepository,
    SpeechService? speechService,
    MemorizationRepository? memorizationRepository,
    MemorizationController? memorizationController,
  }) : _dataService = dataService ?? DictionaryDataService(),
       _cache = cacheRepository ?? VocabularyCacheRepository(),
       _favorites = FavoritesController(
         favoritesRepository ?? FavoritesRepository(),
       ),
       _memorization =
           memorizationController ??
           MemorizationController(
             memorizationRepository ?? MemorizationRepository(),
           ),
       settings = SettingsController(
         settingsRepository ?? SettingsRepository(),
       ),
       speech = speechService ?? SpeechService() {
    settings.addListener(_applySpeechSettings);
    _memorization.addListener(_onMemorizationChanged);
  }

  final DictionaryDataService _dataService;
  final VocabularyCacheRepository _cache;
  final FavoritesController _favorites;
  final MemorizationController _memorization;
  final SpeechService speech;

  /// User preferences (interface language, speech).
  final SettingsController settings;

  /// Search query and level filter of the vocabulary screen.
  final VocabularyController vocabulary = VocabularyController();

  LoadStatus _status = LoadStatus.loading;
  String? _errorMessage;
  String? _refreshError;
  bool _usingCache = false;
  List<Word> _words = const <Word>[];
  List<VerbForms> _verbs = const <VerbForms>[];
  Map<String, VerbForms> _verbsByWordId = const <String, VerbForms>{};
  Map<String, ExampleSentence> _examplesByWordId =
      const <String, ExampleSentence>{};
  bool _disposed = false;

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Whether the current vocabulary came from the local cache because the
  /// bundled assets could not be read.
  bool get usingCache => _usingCache;

  /// The technical error that prevented a fresh asset load, when [usingCache]
  /// is true.
  String? get refreshError => _refreshError;

  List<Word> get words => _words;
  List<VerbForms> get verbs => _verbs;
  FavoritesController get favorites => _favorites;

  /// Memorization status ("new" / "learned") of the vocabulary.
  MemorizationController get memorization => _memorization;

  /// Returns the verb record attached to [word], if the dataset contains one.
  VerbForms? verbFor(Word word) => _verbsByWordId[word.id];

  /// Returns the example sentence attached to [word], if one exists.
  ExampleSentence? exampleFor(Word word) => _examplesByWordId[word.id];

  /// Learning statistics derived from the dataset and the persisted state.
  LearningStatistics get statistics => LearningStatistics(
    words: _words,
    learnedIds: _memorization.learnedIds,
    reviewHistory: _memorization.reviewHistory,
  );

  /// Pushes the current speech preferences into the speech engine.
  void _applySpeechSettings() {
    speech.enabled = settings.speechEnabled;
    speech.rate = settings.speechRate;
    // Language preferences affect every word card, so screens listening to
    // the app state have to rebuild when they change.
    if (!_disposed) notifyListeners();
  }

  /// Propagates memorization changes to every listening screen.
  void _onMemorizationChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> initialize() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    _refreshError = null;
    _usingCache = false;
    notifyListeners();

    // The interface language is loaded first so the UI never flashes in the
    // wrong language while the (much larger) dataset is read.
    try {
      await settings.load();
      _applySpeechSettings();
    } catch (error, stackTrace) {
      _logFailure('loading the settings', error, stackTrace);
    }

    DictionaryData? data;
    Object? dataError;
    StackTrace? dataStackTrace;
    try {
      data = await _dataService.load();
      try {
        await _cache.save(data);
      } catch (error, stackTrace) {
        _logFailure('saving the vocabulary cache', error, stackTrace);
      }
    } catch (error, stackTrace) {
      dataError = error;
      dataStackTrace = stackTrace;
      _logFailure('loading the bundled dictionary', error, stackTrace);
    }

    if (data == null) {
      final cached = await _readCache();
      if (cached != null) {
        data = cached;
        _usingCache = true;
        _refreshError = dataError?.toString();
        debugPrint(
          'AppState: the bundled dictionary failed; using the cached copy.',
        );
      }
    }

    if (data == null) {
      _status = LoadStatus.error;
      _errorMessage = dataError is DataLoadException
          ? dataError.message
          : (dataError?.toString() ?? 'The dictionary could not be loaded.');
      if (dataStackTrace != null) {
        _logFailure(
          'the dictionary could not be loaded and no cache is available',
          dataError ?? StateError('Unknown dictionary error'),
          dataStackTrace,
        );
      }
      notifyListeners();
      return;
    }

    _words = data.words;
    _verbs = data.verbs;
    _verbsByWordId = data.verbsByWordId();
    _examplesByWordId = data.examplesByWordId();

    try {
      await _favorites.load();
      await _memorization.load();
      // Ids of words that are not part of the dataset anymore are dropped, so
      // they never show up in the statistics.
      await _memorization.pruneUnknown(_words.map((word) => word.id).toSet());
    } catch (error, stackTrace) {
      _logFailure('loading the user learning data', error, stackTrace);
    }

    _status = LoadStatus.ready;
    notifyListeners();
  }

  Future<DictionaryData?> _readCache() async {
    try {
      return await _cache.load();
    } catch (error, stackTrace) {
      _logFailure('reading the vocabulary cache', error, stackTrace);
      return null;
    }
  }

  void _logFailure(String operation, Object error, StackTrace stackTrace) {
    debugPrint('AppState: $operation failed: $error');
    if (error is DataLoadException && error.cause != null) {
      debugPrint('AppState: original error: ${error.cause}');
      debugPrintStack(stackTrace: error.stackTrace ?? stackTrace);
      return;
    }
    debugPrintStack(stackTrace: stackTrace);
  }

  @override
  void dispose() {
    _disposed = true;
    settings.removeListener(_applySpeechSettings);
    _memorization.removeListener(_onMemorizationChanged);
    super.dispose();
  }
}
