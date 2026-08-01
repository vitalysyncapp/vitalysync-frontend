import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/nutrition_quantity_field.dart';

void main() {
  testWidgets('fills and updates quantity from the meal name', (tester) async {
    final mealNameController = TextEditingController();
    final quantityController = TextEditingController();
    addTearDown(mealNameController.dispose);
    addTearDown(quantityController.dispose);

    await _pumpField(tester, mealNameController, quantityController);

    await tester.enterText(
      find.byKey(const ValueKey('meal-name')),
      'white rice',
    );
    await tester.pump();
    expect(quantityController.text, '1/2 cup');
    expect(quantityController.selection.baseOffset, 0);
    expect(quantityController.selection.extentOffset, '1/2 cup'.length);

    await tester.enterText(
      find.byKey(const ValueKey('meal-name')),
      'miso soup',
    );
    await tester.pump();
    expect(quantityController.text, '1 bowl');
  });

  testWidgets('never replaces a quantity the user edits or erases', (
    tester,
  ) async {
    final mealNameController = TextEditingController();
    final quantityController = TextEditingController();
    addTearDown(mealNameController.dispose);
    addTearDown(quantityController.dispose);

    await _pumpField(tester, mealNameController, quantityController);

    await tester.enterText(
      find.byKey(const ValueKey('meal-name')),
      'white rice',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manual-meal-quantity-field')),
      '3/4 cup',
    );
    await tester.enterText(find.byKey(const ValueKey('meal-name')), 'rice');
    await tester.pump();
    expect(quantityController.text, '3/4 cup');

    await tester.enterText(
      find.byKey(const ValueKey('manual-meal-quantity-field')),
      '',
    );
    await tester.enterText(
      find.byKey(const ValueKey('meal-name')),
      'rice soup',
    );
    await tester.pump();
    expect(quantityController.text, isEmpty);
  });
}

Future<void> _pumpField(
  WidgetTester tester,
  TextEditingController mealNameController,
  TextEditingController quantityController,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(
              key: const ValueKey('meal-name'),
              controller: mealNameController,
            ),
            NutritionQuantityField(
              mealNameController: mealNameController,
              quantityController: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
      ),
    ),
  );
}
