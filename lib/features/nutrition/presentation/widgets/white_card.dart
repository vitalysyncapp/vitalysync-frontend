import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class WhiteCard extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry? borderRadius;

  const WhiteCard({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 15),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius:
            borderRadius ?? BorderRadius.circular(isCompact ? 18 : 22),
        border: Border.all(color: pageBorderColor(context), width: 1.05),
        boxShadow: pageCardShadow(context),
      ),
      child: child,
    );
  }
}
