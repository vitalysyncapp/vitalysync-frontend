import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const outerRadius = 24.0;
    const innerRadius = 22.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(outerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.03),
                    ]
                  : [
                      Colors.white.withOpacity(0.88),
                      Colors.white.withOpacity(0.45),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFD6F1E8).withOpacity(0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.22)
                    : const Color(0xFF6EC8B2).withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(innerRadius),
              color: isDark
                  ? const Color(0xFF122033).withOpacity(0.55)
                  : Colors.white.withOpacity(0.4),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
