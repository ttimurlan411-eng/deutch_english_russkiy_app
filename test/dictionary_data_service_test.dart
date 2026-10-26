import 'package:english_deutch_ruskiy/services/dictionary_data_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DictionaryDataService against the bundled dataset', () {
    late DictionaryDataService service;

    setUp(() {
      service = DictionaryDataService();
    });

    test('reads every declared CSV asset through the Flutter bundle', () async {
      final paths = <String>[
        ...DictionaryDataService.levelFiles,
        DictionaryDataService.tensesEnFile,
        DictionaryDataService.tensesDeFile,
      ];

      for (final path in paths) {
        final content = await rootBundle.loadString(path);
        expect(content, isNotEmpty, reason: path);
        expect(content, contains('level'), reason: path);
      }
    });

    test('loads every vocabulary record from the four master files', () async {
      final words = await service.loadWords();

      expect(words, hasLength(2816));

      final byLevel = <String, int>{};
      for (final word in words) {
        byLevel[word.level] = (byLevel[word.level] ?? 0) + 1;
      }
      expect(byLevel, <String, int>{
        'A1': 667,
        'A2': 565,
        'B1': 876,
        'B2': 708,
      });
    });

    test(
      'keeps the English, German and Russian values of every record',
      () async {
        final words = await service.loadWords();

        for (final word in words) {
          expect(word.level, isNotEmpty);
          expect(word.english, isNotEmpty);
          expect(word.german, isNotEmpty);
          expect(word.russian, isNotEmpty);
        }

        final mother = words.firstWhere((word) => word.english == 'mother');
        expect(mother.level, 'A1');
        expect(mother.german, 'die Mutter');
        expect(mother.russian, 'мама');
      },
    );

    test('strips the UTF-8 BOM from the header of every file', () async {
      final words = await service.loadWords();
      final verbs = await service.loadVerbs();

      for (final word in words) {
        expect(word.level.codeUnitAt(0), isNot(0xFEFF));
      }
      for (final verb in verbs) {
        expect(verb.level.codeUnitAt(0), isNot(0xFEFF));
        expect(verb.infinitiveEn.codeUnitAt(0), isNot(0xFEFF));
      }
    });

    test('does not leak carriage returns into parsed values', () async {
      final words = await service.loadWords();

      for (final word in words) {
        expect(word.english, isNot(contains('\r')));
        expect(word.german, isNot(contains('\r')));
        expect(word.russian, isNot(contains('\r')));
      }
    });

    test('keeps quoted fields containing commas intact', () async {
      final words = await service.loadWords();

      final doMake = words.firstWhere(
        (word) => word.english == 'to do, to make',
      );
      expect(doMake.german, 'machen');
      expect(doMake.russian, 'делать');
    });

    test('merges the two tenses files row by row', () async {
      final verbs = await service.loadVerbs();

      expect(verbs, hasLength(233));

      final be = verbs.first;
      expect(be.level, 'A1');
      expect(be.infinitiveEn, 'to be');
      expect(be.pastSimple, 'was/were');
      expect(be.pastParticiple, 'been');
      expect(be.infinitivDe, 'sein');
      expect(be.praesensErSieEs, 'ist');
      expect(be.praeteritum, 'war');
      expect(be.partizipII, 'gewesen');
      expect(be.hilfsverb, 'sein');
      expect(be.russianInf, 'быть');
    });

    test('indexes verb records by the matching vocabulary entry', () async {
      final data = await service.load();
      final index = data.verbsByWordId();

      expect(index, hasLength(233));
      expect(index['A1|to be'], isNotNull);
      expect(index['A1|to be']!.infinitivDe, 'sein');
    });
  });

  group('DictionaryDataService error handling', () {
    test(
      'keeps vocabulary when the optional verb dataset is missing',
      () async {
        final contents = Map<String, String>.of(SampleData.bundle().contents)
          ..remove(DictionaryDataService.tensesEnFile);
        final service = DictionaryDataService(
          bundle: FakeAssetBundle(contents),
        );

        final data = await service.load();

        expect(data.words, hasLength(6));
        expect(data.verbs, isEmpty);
      },
    );

    test(
      'retries an asset that becomes available after a failed read',
      () async {
        final bundle = FakeAssetBundle(<String, String>{});
        final service = DictionaryDataService(bundle: bundle);

        await expectLater(
          service.loadWords(),
          throwsA(isA<DataLoadException>()),
        );

        bundle.contents.addAll(SampleData.bundle().contents);
        final words = await service.loadWords();

        expect(words, hasLength(6));
      },
    );

    test('raises when an asset file is missing', () async {
      final service = DictionaryDataService(
        bundle: FakeAssetBundle(<String, String>{}),
      );

      expect(
        () => service.loadWords(),
        throwsA(
          isA<DataLoadException>().having(
            (e) => e.message,
            'message',
            contains('Failed to read asset'),
          ),
        ),
      );
    });

    test('raises when a required column is missing', () async {
      final service = DictionaryDataService(
        bundle: FakeAssetBundle(<String, String>{
          for (final path in DictionaryDataService.levelFiles)
            path: 'level,english,german\r\nA1,mother,die Mutter\r\n',
          DictionaryDataService.tensesEnFile: SampleData.tensesEnCsv,
          DictionaryDataService.tensesDeFile: SampleData.tensesDeCsv,
        }),
      );

      expect(
        () => service.loadWords(),
        throwsA(
          isA<DataLoadException>().having(
            (e) => e.message,
            'message',
            contains('russian'),
          ),
        ),
      );
    });

    test('raises when the tenses files have different row counts', () async {
      final service = DictionaryDataService(
        bundle: FakeAssetBundle(<String, String>{
          ...SampleData.bundle().contents,
          DictionaryDataService.tensesDeFile:
              '${SampleData.tensesDeCsv}A2,gehen,geht,ging,gegangen,sein,идти,иду,шел,буду идти\r\n',
        }),
      );

      expect(
        () => service.loadVerbs(),
        throwsA(
          isA<DataLoadException>().having(
            (e) => e.message,
            'message',
            contains('different row counts'),
          ),
        ),
      );
    });

    test('raises when the tenses levels are not aligned', () async {
      final service = DictionaryDataService(
        bundle: FakeAssetBundle(<String, String>{
          ...SampleData.bundle().contents,
          DictionaryDataService.tensesDeFile: SampleData.tensesDeCsv
              .replaceFirst('A1,sein', 'A2,sein'),
        }),
      );

      expect(
        () => service.loadVerbs(),
        throwsA(
          isA<DataLoadException>().having(
            (e) => e.message,
            'message',
            contains('level mismatch'),
          ),
        ),
      );
    });

    test('raises instead of returning an empty dictionary', () async {
      final service = DictionaryDataService(
        bundle: FakeAssetBundle(<String, String>{
          for (final path in DictionaryDataService.levelFiles)
            path: '\uFEFFlevel,english,german,russian\r\n',
          DictionaryDataService.tensesEnFile: SampleData.tensesEnCsv,
          DictionaryDataService.tensesDeFile: SampleData.tensesDeCsv,
        }),
      );

      expect(
        () => service.loadWords(),
        throwsA(
          isA<DataLoadException>().having(
            (e) => e.message,
            'message',
            contains('No vocabulary records'),
          ),
        ),
      );
    });
  });

  group('DictionaryDataService with controlled payloads', () {
    test('parses BOM, CRLF and quoted fields from a single file', () async {
      final service = DictionaryDataService(
        bundle: FakeAssetBundle(<String, String>{
          for (final path in DictionaryDataService.levelFiles)
            path: SampleData.motherCsv,
          DictionaryDataService.tensesEnFile: SampleData.tensesEnCsv,
          DictionaryDataService.tensesDeFile: SampleData.tensesDeCsv,
        }),
      );

      final words = await service.loadWords();

      // The sample payload is served for all four level files.
      expect(words, hasLength(12));
      expect(words.first.level, 'A1');
      expect(words.first.english, 'mother');
      expect(words[1].english, 'to do, to make');
      expect(words[2].german, 'sein');
    });
  });
}
