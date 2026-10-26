import 'package:english_deutch_ruskiy/services/speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_flutter_tts.dart';

void main() {
  group('SpeechService', () {
    test('speaks a word when the voice is available', () async {
      final tts = FakeFlutterTts();
      final service = SpeechService(tts: tts);

      final ok = await service.speak('mother', 'en');

      expect(ok, isTrue);
      expect(tts.spoken, <String>['mother']);
      expect(tts.requestedLanguages, <String>['en']);
    });

    test('speaks German and Russian words', () async {
      final tts = FakeFlutterTts();
      final service = SpeechService(tts: tts);

      expect(await service.speak('die Mutter', 'de'), isTrue);
      expect(await service.speak('мама', 'ru'), isTrue);
      expect(tts.spoken, <String>['die Mutter', 'мама']);
    });

    test('returns false when the voice is not available', () async {
      final tts = FakeFlutterTts(availableLanguages: <String>['en-US']);
      final service = SpeechService(tts: tts);

      expect(await service.speak('мама', 'ru'), isFalse);
      expect(tts.spoken, isEmpty);
    });

    test('returns false for empty text', () async {
      final tts = FakeFlutterTts();
      final service = SpeechService(tts: tts);

      expect(await service.speak('   ', 'en'), isFalse);
      expect(tts.spoken, isEmpty);
    });

    test('degrades gracefully when the platform throws', () async {
      final tts = FakeFlutterTts(failOnSpeak: true);
      final service = SpeechService(tts: tts);

      expect(await service.speak('mother', 'en'), isFalse);
    });
  });
}
