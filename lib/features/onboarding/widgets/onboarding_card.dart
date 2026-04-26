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

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: pageSurfaceColor(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.22)
                    : const Color(0xFF65CDB2).withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
