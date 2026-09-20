import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_api.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/nutrition_review_dialog.dart';

void main() {
  testWidgets(
    'wide review animates in and keeps food edits and totals in sync',
    (tester) async {
      final items = [_food('Grilled chicken'), _food('Steamed rice')];
      await _openReview(tester, items: items, size: const Size(1100, 900));

      expect(tester.getSize(find.byType(BackdropFilter)).width, 840);
      expect(find.text('🍗'), findsOneWidget);
      expect(find.text('🍚'), findsOneWidget);
      expect(find.text('400 kcal'), findsOneWidget);
      await tester.tap(find.text('Grilled chicken'));
      await tester.pumpAndSettle();
      final foodField = find.widgetWithText(TextFormField, 'Grilled chicken');
      await tester.enterText(foodField, 'Salmon');
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Salmon'),
        'Salmon fillet',
      );
      await tester.pump();
      expect(items.first.foodName, 'Salmon fillet');
      expect(find.text('🐟'), findsOneWidget);
      final calorieField = find
          .byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.labelText == 'Calories',
          )
          .first;
      await tester.enterText(calorieField, '350');
      await tester.pump();
      expect(find.text('550 kcal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'save blocks duplicate submissions and dismissal until complete',
    (tester) async {
      final save = Completer<String?>();
      var calls = 0;
      NutritionReviewAction? result;
      await _openReview(
        tester,
        onConfirm: () {
          calls++;
          return save.future;
        },
        onResult: (action) => result = action,
      );

      await tester.tap(find.text('Confirm log'));
      await tester.pump();
      expect(find.text('Saving...'), findsOneWidget);
      await tester.tap(find.text('Saving...'));
      final context = tester.element(find.byType(NutritionReviewDialog));
      await Navigator.of(context).maybePop();
      await tester.pump();
      expect(find.byType(NutritionReviewDialog), findsOneWidget);
      expect(calls, 1);

      save.complete(null);
      await tester.pumpAndSettle();
      expect(result, NutritionReviewAction.saved);
      expect(find.byType(NutritionReviewDialog), findsNothing);
    },
  );

  testWidgets('save failure stays in the dialog and can be retried', (
    tester,
  ) async {
    var calls = 0;
    await _openReview(
      tester,
      onConfirm: () async {
        calls++;
        return calls == 1 ? 'Connection lost. Please try again.' : null;
      },
    );
    await tester.tap(find.text('Confirm log'));
    await tester.pumpAndSettle();
    expect(find.text('Connection lost. Please try again.'), findsOneWidget);
    expect(find.text('Grilled chicken'), findsOneWidget);
    await tester.tap(find.text('Confirm log'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(NutritionReviewDialog), findsNothing);
  });

  testWidgets(
    'removing the last food disables save and leaves retry available',
    (tester) async {
      NutritionReviewAction? result;
      await _openReview(tester, onResult: (action) => result = action);
      await tester.tap(find.text('Grilled chicken'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Remove food'));
      await tester.tap(find.text('Remove food'));
      await tester.pumpAndSettle();
      expect(find.text('Identified foods (0)'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton).last)
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(result, NutritionReviewAction.retry);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('compact $brightness review supports large text and keyboard', (
      tester,
    ) async {
      await _openReview(
        tester,
        size: const Size(320, 568),
        brightness: brightness,
        textScale: 1.6,
        disableAnimations: true,
        items: [_food('Grilled chicken with vegetables and steamed rice')],
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.text('Grilled chicken with vegetables and steamed rice'),
      );
      await tester.tap(
        find.text('Grilled chicken with vegetables and steamed rice'),
      );
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 230);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Confirm log').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('closing a review returns without saving', (tester) async {
    var saved = false;
    var dismissed = false;
    await _openReview(
      tester,
      onConfirm: () async {
        saved = true;
        return null;
      },
      onResult: (result) => dismissed = result == null,
    );
    await tester.tap(find.byTooltip('Cancel review'));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
    expect(dismissed, isTrue);
  });
}

NutritionReviewItem _food(String name) => NutritionReviewItem(
  foodName: name,
  usdaFdcId: null,
  servingQty: 1,
  servingUnit: 'serving',
  calories: 200,
  proteinG: 20,
  carbsG: 25,
  fatG: 5,
  confidence: 0.9,
);

Future<void> _openReview(
  WidgetTester tester, {
  List<NutritionReviewItem>? items,
  Size size = const Size(800, 900),
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = false,
  Future<String?> Function()? onConfirm,
  ValueChanged<NutritionReviewAction?>? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1EAD83),
          brightness: brightness,
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showNutritionReviewDialog(
                context: context,
                items: items ?? [_food('Grilled chicken')],
                mealLabel: 'Lunch',
                onConfirm: onConfirm ?? () async => null,
              );
              onResult?.call(result);
            },
            child: const Text('Open review'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open review'));
  await tester.pump();
  if (!disableAnimations) {
    await tester.pump(const Duration(milliseconds: 100));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(NutritionReviewDialog),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, allOf(greaterThan(0), lessThan(1)));
  }
  await tester.pumpAndSettle();
}
