part of 'log_widgets.dart';

extension _LogWidgetSharedBuilders on LogWidgets {
  Widget _buildCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) {
    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: pageSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pageBorderColor(context), width: 1),
            boxShadow: pageCardShadow(context),
          ),
          child: child,
        );
      },
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? iconColor.withValues(alpha: 0.18) : iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: pageSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _hydrationButton(String label, double addAmount) {
    return Expanded(
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return GestureDetector(
            onTap: () => onHydrationAdd(addAmount),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF00A3D7).withValues(alpha: 0.12)
                    : const Color(0xFFEAF7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pageBorderColor(context)),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF67E8F9)
                        : const Color(0xFF0F4C81),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _selectionBox({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double width = 150,
    double height = 48,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
    ),
    AlignmentGeometry alignment = Alignment.center,
    IconData? leadingIcon,
    double iconSize = 16,
    double fontSize = 12.5,
    double checkIconSize = 16,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            padding: contentPadding,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(
                      0xFF2563EB,
                    ).withValues(alpha: isDark ? 0.16 : 0.08)
                  : pageSubtleSurfaceColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF2563EB)
                    : pageBorderColor(context),
                width: selected ? 2 : 1.3,
              ),
            ),
            child: Align(
              alignment: alignment,
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    Icon(
                      leadingIcon,
                      size: iconSize,
                      color: selected
                          ? const Color(0xFF60A5FA)
                          : pageSecondaryTextColor(context),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected
                            ? const Color(0xFF60A5FA)
                            : pagePrimaryTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: checkIconSize,
                    color: selected
                        ? const Color(0xFF60A5FA)
                        : pageSecondaryTextColor(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
