import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_api.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/macro_balance_card.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/today_nutrition_card.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/todays_meals_card.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/white_card.dart';
import 'package:vitalysync/shared/widgets/app_skeleton.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('nutrition summary shows remaining calories and macro values', (
    tester,
  ) async {
    await _pumpNutritionWidget(
      tester,
      const TodayNutritionCard(
        calories: 1450,
        proteinG: 75,
        carbsG: 180,
        fatG: 42,
        calorieGoal: 2200,
        balancedCalorieGoal: 2150,
      ),
    );

    expect(find.text('1,450 kcal'), findsOneWidget);
    expect(find.text('2,200 kcal'), findsOneWidget);
    expect(find.text('Balanced kcal: 2,150'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('balanced-calories-indicator')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('calories-remaining')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calories-remaining')))
          .data,
      '750',
    );
    expect(find.text('180g'), findsOneWidget);
    expect(find.text('75g'), findsOneWidget);
    expect(find.text('42g'), findsOneWidget);

    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(progress.value, closeTo(1450 / 2200, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('nutrition summary clamps over-goal remaining calories to zero', (
    tester,
  ) async {
    await _pumpNutritionWidget(
      tester,
      const TodayNutritionCard(
        calories: 2400,
        proteinG: 110,
        carbsG: 250,
        fatG: 80,
        calorieGoal: 2000,
      ),
    );

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calories-remaining')))
          .data,
      '0',
    );
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      1,
    );
  });

  testWidgets('macro balance uses the asymmetric nutrition card shape', (
    tester,
  ) async {
    await _pumpNutritionWidget(
      tester,
      const MacroBalanceCard(proteinG: 70, carbsG: 150, fatG: 45),
    );

    final surface = tester.widget<WhiteCard>(
      find.byKey(const ValueKey('macro-balance-surface')),
    );
    final radius = surface.borderRadius! as BorderRadius;
    expect(radius.topRight.x, greaterThan(radius.topLeft.x));
    expect(find.text('70g / 100g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meal carousel renders fixed slots and logged meal details', (
    tester,
  ) async {
    await _pumpNutritionWidget(
      tester,
      TodaysMealsCard(
        onAddTap: () {},
        onMealTypeAddTap: (_) {},
        meals: [_lunchLog],
      ),
      height: 260,
    );

    for (final mealType in ['breakfast', 'lunch', 'snack', 'dinner']) {
      expect(
        find.byKey(ValueKey('meal-card-$mealType'), skipOffstage: false),
        findsOneWidget,
      );
    }
    expect(find.text('Chicken rice bowl'), findsOneWidget);
    expect(find.text('P 36g  •  C 58g  •  F 14g'), findsOneWidget);
    expect(find.text('🍳'), findsOneWidget);
    expect(find.text('🥗'), findsOneWidget);
    expect(find.text('🍉', skipOffstage: false), findsOneWidget);
    expect(find.text('🍲', skipOffstage: false), findsOneWidget);
    expect(find.byKey(const ValueKey('add-meal-lunch')), findsNothing);
    expect(find.text('Not logged yet', skipOffstage: false), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('meal carousel skeleton keeps the updated card layout', (
    tester,
  ) async {
    await _pumpNutritionWidget(
      tester,
      const TodaysMealsSkeleton(),
      height: 260,
    );

    expect(find.byType(AppSkeleton), findsOneWidget);
    for (final mealType in ['breakfast', 'lunch', 'snack', 'dinner']) {
      expect(
        find.byKey(ValueKey('meal-card-$mealType'), skipOffstage: false),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'meal section reveals when vertical scrolling brings it onscreen',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await _pumpNutritionWidget(
        tester,
        SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              const SizedBox(height: 620),
              TodaysMealsCard(
                onAddTap: () {},
                onMealTypeAddTap: (_) {},
                meals: const [],
                verticalScrollController: scrollController,
              ),
              const SizedBox(height: 160),
            ],
          ),
        ),
        width: 390,
        height: 420,
        disableAnimations: false,
      );

      FadeTransition reveal() => tester.widget<FadeTransition>(
        find.byKey(const ValueKey('todays-meals-scroll-reveal')),
      );

      expect(reveal().opacity.value, 0);

      scrollController.jumpTo(520);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(reveal().opacity.value, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('meal actions preserve header log and pass empty slot type', (
    tester,
  ) async {
    var headerTapped = false;
    String? selectedMealType;

    await _pumpNutritionWidget(
      tester,
      TodaysMealsCard(
        onAddTap: () => headerTapped = true,
        onMealTypeAddTap: (mealType) => selectedMealType = mealType,
        meals: const [],
      ),
      height: 260,
    );

    await tester.tap(find.byKey(const ValueKey('manual-log-meals-header')));
    await tester.pump();
    expect(headerTapped, isTrue);

    await tester.tap(find.byKey(const ValueKey('add-meal-breakfast')));
    await tester.pump();
    expect(selectedMealType, 'breakfast');
  });

  testWidgets('meal strip free-scrolls horizontally on a compact dark layout', (
    tester,
  ) async {
    await _pumpNutritionWidget(
      tester,
      TodaysMealsCard(
        onAddTap: () {},
        onMealTypeAddTap: (_) {},
        meals: [_lunchLog],
      ),
      width: 320,
      height: 260,
      brightness: Brightness.dark,
    );

    final dinnerFinder = find.byKey(
      const ValueKey('meal-card-dinner'),
      skipOffstage: false,
    );
    final beforeDrag = tester.getTopLeft(dinnerFinder).dx;

    await tester.drag(
      find.byKey(const ValueKey('todays-meals-carousel')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();

    final afterDrag = tester.getTopLeft(dinnerFinder).dx;
    expect(afterDrag, lessThan(beforeDrag));
    expect(tester.takeException(), isNull);
  });
}

final _lunchLog = NutritionMealLog(
  nutritionLogId: 7,
  mealType: 'lunch',
  totalCalories: 520,
  totalProteinG: 36,
  totalCarbsG: 58,
  totalFatG: 14,
  createdAt: DateTime(2026, 7, 15, 12),
  updatedAt: DateTime(2026, 7, 15, 12),
  items: [
    NutritionReviewItem(
      foodName: 'Chicken rice bowl',
      usdaFdcId: null,
      servingQty: 1,
      servingUnit: 'bowl',
      calories: 520,
      proteinG: 36,
      carbsG: 58,
      fatG: 14,
      confidence: 0.9,
    ),
  ],
);

Future<void> _pumpNutritionWidget(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double height = 420,
  Brightness brightness = Brightness.light,
  bool disableAnimations = true,
}) async {
  final theme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1EAD83),
      brightness: brightness,
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
