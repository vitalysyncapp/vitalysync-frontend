import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_page_style.dart';

class OnboardingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const OnboardingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: pageSurfaceColor(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: pageBorderColor(context)),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.06 : 0.38),
                Colors.white.withValues(alpha: isDark ? 0.01 : 0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.7],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              // Primary depth shadow
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.28)
                    : const Color(0xFF65CDB2).withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              // Accent outer glow
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.06 : 0.05),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              // Inner highlight glow
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.12),
                blurRadius: 1,
                spreadRadius: -1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
