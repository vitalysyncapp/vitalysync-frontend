import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

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
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: child,
    );
  }
}
