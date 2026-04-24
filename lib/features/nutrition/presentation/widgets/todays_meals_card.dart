import 'package:flutter/material.dart';

import '../../data/nutrition_api.dart';
import 'white_card.dart';

class TodaysMealsCard extends StatelessWidget {
  final VoidCallback onAddTap;
  final List<NutritionMealLog> meals;

  const TodaysMealsCard({
    Key? key,
    required this.onAddTap,
    required this.meals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Meals",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: onAddTap,
                borderRadius: BorderRadius.circular(50),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.add,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 14 : 18),
          if (meals.isEmpty)
            Text(
              'No meals logged yet today.',
              style: TextStyle(
                fontSize: isCompact ? 13 : 15,
                color: const Color(0xFF64748B),
              ),
            )
          else
            ...meals.map(
              (meal) => Padding(
                padding: EdgeInsets.only(bottom: isCompact ? 10 : 14),
                child: MealItemCard(
                  mealName: _mealLabel(meal.mealType),
                  calories: '${meal.totalCalories.round()} cal',
                  foods: meal.items.map((item) => item.foodName).join(', '),
                  protein: '${meal.totalProteinG.round()}g',
                  carbs: '${meal.totalCarbsG.round()}g',
                  fats: '${meal.totalFatG.round()}g',
                  isCompact: isCompact,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _mealLabel(String value) {
    if (value.isEmpty) {
      return 'Meal';
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

class MealItemCard extends StatelessWidget {
  final String mealName;
  final String calories;
  final String foods;
  final String protein;
  final String carbs;
  final String fats;
  final bool isCompact;

  const MealItemCard({
    Key? key,
    required this.mealName,
    required this.calories,
    required this.foods,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.isCompact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mealName,
                  style: TextStyle(
                    fontSize: isCompact ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                calories,
                style: TextStyle(
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            foods.isEmpty ? 'Saved meal items' : foods,
            maxLines: isCompact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 13 : 15,
              color: const Color(0xFF334155),
              height: 1.4,
            ),
          ),
          SizedBox(height: isCompact ? 10 : 14),
          Row(
            children: [
              Text(
                'P: $protein',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  color: const Color(0xFF9333EA),
                ),
              ),
              SizedBox(width: isCompact ? 12 : 18),
              Text(
                'C: $carbs',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  color: const Color(0xFFF97316),
                ),
              ),
              SizedBox(width: isCompact ? 12 : 18),
              Text(
                'F: $fats',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
