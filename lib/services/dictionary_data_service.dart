import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/verb_forms.dart';
import '../models/word.dart';

/// Raised when the bundled dataset cannot be loaded or is inconsistent.
class DataLoadException implements Exception {
  const DataLoadException(this.message, {this.cause, this.stackTrace});

  final String message;

  /// The original exception, when this error wraps an asset or parser failure.
  final Object? cause;

  /// Stack trace of [cause], retained for debug logging.
  final StackTrace? stackTrace;

  @override
  String toString() => 'DataLoadException: $message';
}

/// Loads the offline dictionary dataset from `assets/data/`.
///
/// The six CSV files are read-only copies of the original `123456.zip`
/// contents. Nothing is merged, normalized, or dropped: every row is parsed
/// as-is (UTF-8, BOM stripped from headers only).
class DictionaryDataService {
  DictionaryDataService({this.bundle});

  /// Override for tests; defaults to the app asset bundle.
  final AssetBundle? bundle;

  static const List<String> levelFiles = <String>[
    'assets/data/master_A1.csv',
    'assets/data/master_A2.csv',
    'assets/data/master_B1.csv',
    'assets/data/master_B2.csv',
  ];

  static const String tensesEnFile = 'assets/data/tenses_en_ru.csv';
  static const String tensesDeFile = 'assets/data/tenses_de_ru.csv';

  /// Columns every `master_*.csv` file must provide.
  static const List<String> wordColumns = <String>[
    'level',
    'english',
    'german',
    'russian',
  ];

  /// Columns every `tenses_*.csv` file must provide.
  static const List<String> tensesEnColumns = <String>[
    'level',
    'infinitive_en',
    'past_simple',
    'past_participle',
    'russian_inf',
    'ru_present_ya',
    'ru_past_on',
    'ru_future_ya',
  ];

  static const List<String> tensesDeColumns = <String>[
    'level',
    'infinitiv_de',
    'praesens_er_sie_es',
    'praeteritum',
    'partizip_ii',
    'hilfsverb',
    'russian_inf',
    'ru_present_ya',
    'ru_past_on',
    'ru_future_ya',
  ];

  AssetBundle get _bundle => bundle ?? rootBundle;

  /// Loads vocabulary and verbs together.
  ///
  /// The four vocabulary files are required. The optional verb dataset is
  /// allowed to fail: the dictionary still opens with its vocabulary and the
  /// original error is written to the debug log instead of blocking the app.
  Future<DictionaryData> load() async {
    final words = await loadWords();
    List<VerbForms> verbs = const <VerbForms>[];
    try {
      verbs = await loadVerbs();
    } on DataLoadException catch (error) {
      debugPrint(
        'DictionaryDataService: optional verb data could not be loaded; '
        'continuing with vocabulary only. ${error.message}',
      );
      if (error.cause != null) {
        debugPrint('DictionaryDataService: caused by ${error.cause}');
      }
      debugPrintStack(stackTrace: error.stackTrace);
    }
    return DictionaryData(words: words, verbs: verbs);
  }

  /// Parses the four `master_*.csv` files into [Word] records.
  Future<List<Word>> loadWords() async {
    final words = <Word>[];
    for (final path in levelFiles) {
      final rows = await _readCsv(path, wordColumns);
      for (final row in rows) {
        final level = row['level']?.trim() ?? '';
        final english = row['english']?.trim() ?? '';
        final german = row['german']?.trim() ?? '';
        final russian = row['russian']?.trim() ?? '';
        if (level.isEmpty &&
            english.isEmpty &&
            german.isEmpty &&
            russian.isEmpty) {
          continue;
        }
        words.add(
          Word(
            level: level,
            english: english,
            german: german,
            russian: russian,
          ),
        );
      }
    }
    if (words.isEmpty) {
      throw const DataLoadException(
        'No vocabulary records were loaded from the master CSV files.',
      );
    }
    return words;
  }

  /// Loads both tenses files and merges them row-by-row.
  ///
  /// Row counts and per-row level alignment are validated; a mismatch raises
  /// a [DataLoadException] instead of producing a partial/incorrect merge.
  Future<List<VerbForms>> loadVerbs() async {
    final enRows = await _readCsv(tensesEnFile, tensesEnColumns);
    final deRows = await _readCsv(tensesDeFile, tensesDeColumns);

    if (enRows.length != deRows.length) {
      throw DataLoadException(
        'Tenses files have different row counts: '
        '$tensesEnFile has ${enRows.length}, '
        '$tensesDeFile has ${deRows.length}.',
      );
    }

    final verbs = <VerbForms>[];
    for (var i = 0; i < enRows.length; i++) {
      final en = enRows[i];
      final de = deRows[i];
      final enLevel = en['level']?.trim() ?? '';
      final deLevel = de['level']?.trim() ?? '';
      if (enLevel != deLevel) {
        throw DataLoadException(
          'Tenses level mismatch at row ${i + 1}: '
          'English "$enLevel" vs German "$deLevel".',
        );
      }
      verbs.add(
        VerbForms(
          level: enLevel,
          infinitiveEn: en['infinitive_en']?.trim() ?? '',
          pastSimple: en['past_simple']?.trim() ?? '',
          pastParticiple: en['past_participle']?.trim() ?? '',
          infinitivDe: de['infinitiv_de']?.trim() ?? '',
          praesensErSieEs: de['praesens_er_sie_es']?.trim() ?? '',
          praeteritum: de['praeteritum']?.trim() ?? '',
          partizipII: de['partizip_ii']?.trim() ?? '',
          hilfsverb: de['hilfsverb']?.trim() ?? '',
          russianInf: en['russian_inf']?.trim() ?? '',
          ruPresentYa: en['ru_present_ya']?.trim() ?? '',
          ruPastOn: en['ru_past_on']?.trim() ?? '',
          ruFutureYa: en['ru_future_ya']?.trim() ?? '',
        ),
      );
    }
    if (verbs.isEmpty) {
      throw const DataLoadException(
        'No verb records were loaded from the tenses CSV files.',
      );
    }
    return verbs;
  }

  /// Reads a CSV asset into a list of header-keyed rows.
  ///
  /// [requiredColumns] must all be present in the header, otherwise a
  /// [DataLoadException] is raised rather than yielding silently empty rows.
  Future<List<Map<String, String>>> _readCsv(
    String path,
    List<String> requiredColumns,
  ) async {
    final String raw;
    try {
      raw = await _bundle.loadString(path);
    } catch (error, stackTrace) {
      _bundle.evict(path);
      throw DataLoadException(
        'Failed to read asset "$path": $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    final text = _normalizeLineEndings(_stripBom(raw));

    final List<List<dynamic>> table;
    try {
      table = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(text);
    } catch (error, stackTrace) {
      _bundle.evict(path);
      throw DataLoadException(
        'Failed to parse CSV "$path": $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (table.isEmpty) {
      throw DataLoadException('CSV "$path" is empty.');
    }

    final header = table.first
        .map((cell) => _stripBom(cell.toString()).trim())
        .toList();
    final missing = requiredColumns
        .where((column) => !header.contains(column))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw DataLoadException(
        'CSV "$path" is missing required column(s): ${missing.join(', ')}.',
      );
    }

    final rows = <Map<String, String>>[];
    for (var i = 1; i < table.length; i++) {
      final line = table[i];
      if (line.isEmpty ||
          line.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }
      final map = <String, String>{};
      for (var c = 0; c < header.length; c++) {
        map[header[c]] = c < line.length ? line[c].toString().trim() : '';
      }
      rows.add(map);
    }
    return rows;
  }

  /// Removes a leading UTF-8 BOM (U+FEFF) if present.
  String _stripBom(String value) {
    if (value.isNotEmpty && value.codeUnitAt(0) == 0xFEFF) {
      return value.substring(1);
    }
    return value;
  }

  /// Converts CRLF line endings to LF so the parser sees a single consistent
  /// row separator regardless of how the asset was authored.
  String _normalizeLineEndings(String value) {
    return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }
}

/// Immutable bundle of everything loaded from the dataset.
class DictionaryData {
  const DictionaryData({required this.words, required this.verbs});

  final List<Word> words;
  final List<VerbForms> verbs;

  /// Indexes verb records by the `(level, english)` key of their vocabulary
  /// entry so the details view can attach conjugations to a word.
  Map<String, VerbForms> verbsByWordId() {
    final index = <String, VerbForms>{};
    for (final verb in verbs) {
      index['${verb.level}|${verb.infinitiveEn}'] = verb;
    }
    return index;
  }
}
