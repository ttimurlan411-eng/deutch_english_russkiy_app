import 'package:english_deutch_ruskiy/services/bulk_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects only the visible words and toggles them back', () {
    final controller = BulkSelectionController()..enter();

    controller.toggleAll(<String>['A1|mother', 'A1|to be']);
    expect(controller.ids, <String>{'A1|mother', 'A1|to be'});

    controller.toggleAll(<String>['A1|mother', 'A1|to be']);
    expect(controller.ids, isEmpty);

    controller.toggle('A1|mother');
    controller.toggleAll(<String>['A1|mother', 'A1|to be']);
    expect(controller.ids, <String>{'A1|mother', 'A1|to be'});
  });

  test('leaving the selection mode clears every selection', () {
    final controller = BulkSelectionController()..enter();
    controller.toggle('A1|mother');

    controller.toggleMode();

    expect(controller.isActive, isFalse);
    expect(controller.ids, isEmpty);
  });
}
