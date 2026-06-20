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

  Widget _buildDimensionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.12)
            : accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.18 : 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 11.5,
                    height: 1.24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildLikertLevelCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> labels,
    required int? selectedLevel,
    required ValueChanged<int> onChanged,
    required String emptyMessage,
    required String selectedMessagePrefix,
  }) {
    return _buildCard(
      child: Builder(
        builder: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                icon: icon,
                iconBg: iconBg,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle,
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(labels.length, (index) {
                  final value = index + 1;
                  final selected = selectedLevel == value;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == labels.length - 1 ? 0 : 6,
                      ),
                      child: GestureDetector(
                        onTap: () => onChanged(value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? iconColor.withValues(alpha: 0.14)
                                : pageSubtleSurfaceColor(context),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: selected
                                  ? iconColor
                                  : pageBorderColor(context),
                              width: selected ? 1.7 : 1.1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: iconColor.withValues(alpha: 0.16),
                                      blurRadius: 9,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$value',
                                style: TextStyle(
                                  color: selected
                                      ? iconColor
                                      : pagePrimaryTextColor(context),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  labels[index],
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: selected
                                        ? iconColor
                                        : pagePrimaryTextColor(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 9),
              Text(
                selectedLevel == null
                    ? emptyMessage
                    : '$selectedMessagePrefix ${labels[selectedLevel - 1].toLowerCase()}.',
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        },
      ),
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
