import 'package:english_deutch_ruskiy/services/favorites_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('returns an empty set when nothing was stored', () async {
      final repository = FavoritesRepository();

      expect(await repository.load(), isEmpty);
    });

    test('persists favorites across repository instances', () async {
      final repository = FavoritesRepository();
      await repository.save(<String>{'A1|mother', 'B1|to achieve'});

      final reloaded = FavoritesRepository();
      expect(await reloaded.load(), <String>{'A1|mother', 'B1|to achieve'});
    });

    test('overwrites previously stored favorites', () async {
      final repository = FavoritesRepository();
      await repository.save(<String>{'A1|mother'});
      await repository.save(<String>{'B2|to acquire'});

      expect(await repository.load(), <String>{'B2|to acquire'});
    });
  });

  group('FavoritesController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('toggles a favorite on and off', () async {
      final controller = FavoritesController(FavoritesRepository());
      await controller.load();

      expect(controller.contains('A1|mother'), isFalse);

      await controller.toggle('A1|mother');
      expect(controller.contains('A1|mother'), isTrue);
      expect(controller.count, 1);

      await controller.toggle('A1|mother');
      expect(controller.contains('A1|mother'), isFalse);
      expect(controller.count, 0);
    });

    test('notifies listeners when the favorites change', () async {
      final controller = FavoritesController(FavoritesRepository());
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();
      expect(notifications, 1);

      await controller.toggle('A1|mother');
      expect(notifications, 2);
    });

    test('loads the favorites that were persisted earlier', () async {
      final repository = FavoritesRepository();
      await repository.save(<String>{'A2|to remember'});

      final controller = FavoritesController(FavoritesRepository());
      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.ids, <String>{'A2|to remember'});
    });
  });
}
