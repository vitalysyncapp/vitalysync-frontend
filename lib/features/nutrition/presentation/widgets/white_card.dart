import 'package:flutter/material.dart';

class WhiteCard extends StatelessWidget {
  final Widget child;

  const WhiteCard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isCompact ? 10 : 14,
            offset: Offset(0, isCompact ? 4 : 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
