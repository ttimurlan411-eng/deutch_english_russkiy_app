import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/verb_forms.dart';
import '../models/word.dart';
import 'dictionary_data_service.dart';

/// Persists the parsed dictionary so it can be shown without reading the
/// bundled CSV assets again.
///
/// The cache only contains vocabulary and verb records. User learning data
/// (favorites, learned words, review history and settings) lives under
/// different keys and is never touched here.
///
/// The payload is versioned. An outdated or corrupted entry is discarded and
/// the next successful asset load writes a fresh copy.
class VocabularyCacheRepository {
  /// [preferences] is an optional injection point used by tests; when it is
  /// omitted the platform default instance is resolved lazily.
  VocabularyCacheRepository([this._preferences]);

  /// Storage key of the parsed dictionary cache.
  static const String storageKey = 'dictionary_cache';

  /// Version of the cache payload format.
  static const int formatVersion = 1;

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Reads the cached dictionary.
  ///
  /// Returns `null` when no cache exists. A malformed or outdated entry is
  /// removed and also reported as `null`, so callers can fall back to the
  /// bundled assets without deleting any user data.
  Future<DictionaryData?> load() async {
    final prefs = await _prefs;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('The cache payload is not a JSON object.');
      }

      final version = decoded['version'];
      if (version != formatVersion) {
        throw FormatException(
          'Unsupported cache version: $version (expected $formatVersion).',
        );
      }

      final words = _decodeWords(decoded['words']);
      if (words.isEmpty) {
        throw const FormatException('The cache contains no vocabulary.');
      }
      final verbs = _decodeVerbs(decoded['verbs']);
      return DictionaryData(words: words, verbs: verbs);
    } catch (error, stackTrace) {
      debugPrint(
        'VocabularyCacheRepository: discarding an unreadable cache: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      await prefs.remove(storageKey);
      return null;
    }
  }

  /// Writes [data] as the current cache payload.
  ///
  /// Nothing is written when the dataset is empty, so a failed load can never
  /// replace a good cache with an empty one.
  Future<void> save(DictionaryData data) async {
    if (data.words.isEmpty) return;
    final prefs = await _prefs;
    final payload = jsonEncode(<String, Object?>{
      'version': formatVersion,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'words': data.words.map(_encodeWord).toList(growable: false),
      'verbs': data.verbs.map(_encodeVerb).toList(growable: false),
    });
    await prefs.setString(storageKey, payload);
  }

  /// Removes the cached dictionary without touching user data.
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(storageKey);
  }

  static Map<String, Object?> _encodeWord(Word word) {
    return <String, Object?>{
      'level': word.level,
      'english': word.english,
      'german': word.german,
      'russian': word.russian,
    };
  }

  static Map<String, Object?> _encodeVerb(VerbForms verb) {
    return <String, Object?>{
      'level': verb.level,
      'infinitiveEn': verb.infinitiveEn,
      'pastSimple': verb.pastSimple,
      'pastParticiple': verb.pastParticiple,
      'infinitivDe': verb.infinitivDe,
      'praesensErSieEs': verb.praesensErSieEs,
      'praeteritum': verb.praeteritum,
      'partizipII': verb.partizipII,
      'hilfsverb': verb.hilfsverb,
      'russianInf': verb.russianInf,
      'ruPresentYa': verb.ruPresentYa,
      'ruPastOn': verb.ruPastOn,
      'ruFutureYa': verb.ruFutureYa,
    };
  }

  static List<Word> _decodeWords(Object? value) {
    if (value is! List) {
      throw const FormatException('The cached vocabulary list is missing.');
    }
    return value.map(_decodeWord).toList(growable: false);
  }

  static Word _decodeWord(Object? value) {
    if (value is! Map) {
      throw const FormatException('A cached vocabulary entry is malformed.');
    }
    final level = _readString(value, 'level');
    final english = _readString(value, 'english');
    final german = _readString(value, 'german');
    final russian = _readString(value, 'russian');
    if (level.isEmpty || english.isEmpty || german.isEmpty || russian.isEmpty) {
      throw const FormatException('A cached vocabulary entry is incomplete.');
    }
    return Word(
      level: level,
      english: english,
      german: german,
      russian: russian,
    );
  }

  static List<VerbForms> _decodeVerbs(Object? value) {
    if (value == null) return const <VerbForms>[];
    if (value is! List) {
      throw const FormatException('The cached verb list is malformed.');
    }
    return value.map(_decodeVerb).toList(growable: false);
  }

  static VerbForms _decodeVerb(Object? value) {
    if (value is! Map) {
      throw const FormatException('A cached verb entry is malformed.');
    }
    final level = _readString(value, 'level');
    final infinitiveEn = _readString(value, 'infinitiveEn');
    if (level.isEmpty || infinitiveEn.isEmpty) {
      throw const FormatException('A cached verb entry is incomplete.');
    }
    return VerbForms(
      level: level,
      infinitiveEn: infinitiveEn,
      pastSimple: _readString(value, 'pastSimple'),
      pastParticiple: _readString(value, 'pastParticiple'),
      infinitivDe: _readString(value, 'infinitivDe'),
      praesensErSieEs: _readString(value, 'praesensErSieEs'),
      praeteritum: _readString(value, 'praeteritum'),
      partizipII: _readString(value, 'partizipII'),
      hilfsverb: _readString(value, 'hilfsverb'),
      russianInf: _readString(value, 'russianInf'),
      ruPresentYa: _readString(value, 'ruPresentYa'),
      ruPastOn: _readString(value, 'ruPastOn'),
      ruFutureYa: _readString(value, 'ruFutureYa'),
    );
  }

  static String _readString(Map<dynamic, dynamic> value, String key) {
    final result = value[key];
    if (result is! String) {
      throw FormatException('The cached field "$key" is missing or invalid.');
    }
    return result;
  }
}
