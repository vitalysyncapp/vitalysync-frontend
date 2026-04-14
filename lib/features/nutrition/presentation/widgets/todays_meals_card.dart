import 'package:flutter/material.dart';
import 'white_card.dart';

class TodaysMealsCard extends StatelessWidget {
  final VoidCallback onAddTap;

  const TodaysMealsCard({
    Key? key,
    required this.onAddTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  fontSize: 18,
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
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const MealItemCard(
            mealName: 'Breakfast',
            time: '8:30 AM',
            calories: '420 cal',
            foods: 'Oatmeal with berries • Banana • Coffee',
            protein: '12g',
            carbs: '78g',
            fats: '9g',
          ),
          const SizedBox(height: 14),
          const MealItemCard(
            mealName: 'Lunch',
            time: '1:15 PM',
            calories: '580 cal',
            foods: 'Grilled chicken salad • Quinoa • Olive oil dressing',
            protein: '42g',
            carbs: '48g',
            fats: '22g',
          ),
        ],
      ),
    );
  }
}

class MealItemCard extends StatelessWidget {
  final String mealName;
  final String time;
  final String calories;
  final String foods;
  final String protein;
  final String carbs;
  final String fats;

  const MealItemCard({
    Key? key,
    required this.mealName,
    required this.time,
    required this.calories,
    required this.foods,
    required this.protein,
    required this.carbs,
    required this.fats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                calories,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            foods,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'P: $protein',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9333EA),
                ),
              ),
              const SizedBox(width: 18),
              Text(
                'C: $carbs',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 18),
              Text(
                'F: $fats',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}