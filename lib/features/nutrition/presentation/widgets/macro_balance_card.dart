import 'package:flutter/material.dart';
import 'white_card.dart';

class MacroBalanceCard extends StatelessWidget {
  const MacroBalanceCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro Balance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 22),
          MacroProgressRow(
            label: 'Protein',
            current: '54g',
            goal: '100g',
            progress: 0.54,
            color: Color(0xFFA855F7),
          ),
          SizedBox(height: 18),
          MacroProgressRow(
            label: 'Carbs',
            current: '126g',
            goal: '200g',
            progress: 0.63,
            color: Color(0xFFF97316),
          ),
          SizedBox(height: 18),
          MacroProgressRow(
            label: 'Fats',
            current: '31g',
            goal: '65g',
            progress: 0.48,
            color: Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class MacroProgressRow extends StatelessWidget {
  final String label;
  final String current;
  final String goal;
  final double progress;
  final Color color;

  const MacroProgressRow({
    Key? key,
    required this.label,
    required this.current,
    required this.goal,
    required this.progress,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$current / $goal',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}