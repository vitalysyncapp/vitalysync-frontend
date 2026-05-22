import 'package:flutter/material.dart';

import 'white_card.dart';

class MacroBalanceCard extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroBalanceCard({
    super.key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

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
              fontSize: isCompact ? 15.5 : 16.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: isCompact ? 11 : 14),
          MacroProgressRow(
            label: 'Protein',
            current: '${proteinG.round()}g',
            goal: '100g',
            progress: (proteinG / 100).clamp(0, 1).toDouble(),
            color: const Color(0xFFA855F7),
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 10 : 12),
          MacroProgressRow(
            label: 'Carbs',
            current: '${carbsG.round()}g',
            goal: '200g',
            progress: (carbsG / 200).clamp(0, 1).toDouble(),
            color: const Color(0xFFF97316),
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 10 : 12),
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
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.progress,
    required this.color,
    required this.isCompact,
  });

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
                  fontSize: isCompact ? 12.5 : 14,
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$current / $goal',
              style: TextStyle(
                fontSize: isCompact ? 12.5 : 14,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 6 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: isCompact ? 7 : 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
