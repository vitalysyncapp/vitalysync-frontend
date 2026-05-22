import 'package:flutter/material.dart';

class WhiteCard extends StatelessWidget {
  final Widget child;

  const WhiteCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isCompact ? 8 : 10,
            offset: Offset(0, isCompact ? 3 : 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
