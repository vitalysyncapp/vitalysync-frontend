part of 'log_widgets.dart';

extension _LogWidgetSharedBuilders on LogWidgets {
  Widget _buildCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(15),
    Color accentColor = const Color(0xFF1FB489),
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF18283C).withValues(alpha: 0.96),
                      Color.alphaBlend(
                        accentColor.withValues(alpha: 0.035),
                        const Color(0xFF112235).withValues(alpha: 0.96),
                      ),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.96),
                      Color.alphaBlend(
                        accentColor.withValues(alpha: 0.035),
                        const Color(0xFFF8FFFC).withValues(alpha: 0.94),
                      ),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Color.alphaBlend(
                accentColor.withValues(alpha: isDark ? 0.13 : 0.09),
                pageBorderColor(context),
              ),
            ),
            boxShadow: [
              ...pageCardShadow(context),
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.06 : 0.045),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -42,
                top: -52,
                child: IgnorePointer(
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withValues(alpha: isDark ? 0.11 : 0.075),
                          accentColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                right: 22,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0),
                          accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
                          accentColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          iconColor.withValues(alpha: 0.22),
                          iconColor.withValues(alpha: 0.11),
                        ]
                      : [iconBg, Colors.white.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 1),
                  LocalizedText(
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
      accentColor: iconColor,
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
                      child: _LogPressable(
                        onTap: () => onChanged(value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
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
                              LocalizedText(
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
                                child: LocalizedText(
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
              LocalizedText(
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

          return _LogPressable(
            onTap: () => onHydrationAdd(addAmount),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF00A3D7).withValues(alpha: 0.12)
                    : const Color(0xFFEAF7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pageBorderColor(context)),
              ),
              child: Center(
                child: LocalizedText(
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
    return _LogPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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

        return _LogPressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
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
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
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
                    child: LocalizedText(
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
