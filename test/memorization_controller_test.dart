import 'package:english_deutch_ruskiy/services/memorization_controller.dart';
import 'package:english_deutch_ruskiy/services/memorization_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('marks several words as learned without duplicates', () async {
    final controller = MemorizationController(MemorizationRepository());
    await controller.load();
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.markLearnedAll(<String>[
      'A1|mother',
      'A1|mother',
      'B1|to achieve',
    ]);

    expect(controller.learnedIds, <String>{'A1|mother', 'B1|to achieve'});
    expect(controller.learnedCount, 2);
    expect(notifications, 1);
    expect(
      await MemorizationRepository().loadLearnedIds(),
      <String>{'A1|mother', 'B1|to achieve'},
    );

    await controller.markLearnedAll(<String>['A1|mother']);
    expect(controller.learnedCount, 2);
    expect(notifications, 1);
  });
}
