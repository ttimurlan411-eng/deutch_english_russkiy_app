import 'dart:convert';

import 'package:flutter/services.dart';

/// In-memory [AssetBundle] used by the tests to feed controlled CSV payloads
/// to the dictionary service.
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.contents);

  /// Creates a bundle that serves [files] keyed by their asset path.
  factory FakeAssetBundle.fromFiles(Map<String, String> files) {
    return FakeAssetBundle(files);
  }

  final Map<String, String> contents;

  @override
  Future<ByteData> load(String key) async {
    final value = contents[key];
    if (value == null) {
      throw Exception('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

/// A tiny but complete dataset covering all six asset files.
///
/// The rows deliberately include a UTF-8 BOM, CRLF line endings, a quoted
/// field containing a comma and an em dash, so the parsing edge cases of the
/// real dataset are covered by the widget tests as well.
class SampleData {
  const SampleData._();

  static const String motherCsv = '''
\uFEFFlevel,english,german,russian\r
A1,mother,die Mutter,мама\r
A1,"to do, to make",machen,делать\r
A1,to be,sein,быть\r
''';

  static const String a2Csv = '''
\uFEFFlevel,english,german,russian\r
A2,to remember,sich erinnern,помнить\r
''';

  static const String b1Csv = '''
\uFEFFlevel,english,german,russian\r
B1,to achieve,erreichen,достигать\r
''';

  static const String b2Csv = '''
\uFEFFlevel,english,german,russian\r
B2,to acquire,erwerben,приобретать\r
''';

  static const String tensesEnCsv = '''
\uFEFFlevel,infinitive_en,past_simple,past_participle,russian_inf,ru_present_ya,ru_past_on,ru_future_ya\r
A1,to be,was/were,been,быть,—,был,буду\r
''';

  static const String tensesDeCsv = '''
\uFEFFlevel,infinitiv_de,praesens_er_sie_es,praeteritum,partizip_ii,hilfsverb,russian_inf,ru_present_ya,ru_past_on,ru_future_ya\r
A1,sein,ist,war,gewesen,sein,быть,—,был,буду\r
''';

  /// Builds a bundle serving the sample dataset for the standard asset paths.
  static FakeAssetBundle bundle() {
    return FakeAssetBundle(<String, String>{
      'assets/data/master_A1.csv': motherCsv,
      'assets/data/master_A2.csv': a2Csv,
      'assets/data/master_B1.csv': b1Csv,
      'assets/data/master_B2.csv': b2Csv,
      'assets/data/tenses_en_ru.csv': tensesEnCsv,
      'assets/data/tenses_de_ru.csv': tensesDeCsv,
    });
  }
}
