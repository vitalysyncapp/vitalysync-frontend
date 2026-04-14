import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16), 
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5, 
          sigmaY: 5, 
        ),
        child: Container(
          padding: const EdgeInsets.all(2), 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? Colors.white.withOpacity(0.03) 
                : Colors.white.withOpacity(0.15), 
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.white.withOpacity(0.2),  
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}