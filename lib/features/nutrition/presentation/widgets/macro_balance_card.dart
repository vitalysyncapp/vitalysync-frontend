import 'package:flutter/material.dart';

import 'white_card.dart';

class MacroBalanceCard extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroBalanceCard({
    Key? key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro Balance',
            style: TextStyle(
              fontSize: isCompact ? 17 : 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: isCompact ? 16 : 22),
          MacroProgressRow(
            label: 'Protein',
            current: '${proteinG.round()}g',
            goal: '100g',
            progress: (proteinG / 100).clamp(0, 1).toDouble(),
            color: const Color(0xFFA855F7),
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 14 : 18),
          MacroProgressRow(
            label: 'Carbs',
            current: '${carbsG.round()}g',
            goal: '200g',
            progress: (carbsG / 200).clamp(0, 1).toDouble(),
            color: const Color(0xFFF97316),
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 14 : 18),
          MacroProgressRow(
            label: 'Fats',
            current: '${fatG.round()}g',
            goal: '65g',
            progress: (fatG / 65).clamp(0, 1).toDouble(),
            color: const Color(0xFFEF4444),
            isCompact: isCompact,
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
  final bool isCompact;

  const MacroProgressRow({
    Key? key,
    required this.label,
    required this.current,
    required this.goal,
    required this.progress,
    required this.color,
    required this.isCompact,
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
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$current / $goal',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 8 : 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: isCompact ? 8 : 10,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
