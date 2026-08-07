part of 'floating_smart_nudge_assistant.dart';

class _AssistantQuickLogBar extends StatelessWidget {
  final bool isHydrationOpen;
  final bool compact;
  final VoidCallback onLogWater;
  final VoidCallback onLogMeal;

  const _AssistantQuickLogBar({
    required this.isHydrationOpen,
    this.compact = false,
    required this.onLogWater,
    required this.onLogMeal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const ValueKey('assistant-quick-log-bar'),
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 5 : 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AssistantQuickLogButton(
              icon: Icons.water_drop_rounded,
              label: isHydrationOpen ? 'Hide water' : 'Log water',
              selected: isHydrationOpen,
              compact: compact,
              onTap: onLogWater,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: _AssistantQuickLogButton(
              icon: Icons.restaurant_menu_rounded,
              label: 'Log meal',
              selected: false,
              compact: compact,
              onTap: onLogMeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantQuickLogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _AssistantQuickLogButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : pagePrimaryTextColor(context);
    final background = selected
        ? const Color(0xFF1FB489)
        : pageSurfaceColor(context);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 8 : 11,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 16 : 18, color: foreground),
              SizedBox(width: compact ? 5 : 7),
              Flexible(
                child: LocalizedText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantHydrationQuickLogSection extends StatelessWidget {
  final double amountLiters;
  final double todayHydrationLiters;
  final bool hasTodayLog;
  final bool isLoading;
  final bool isSaving;
  final String? helperText;
  final bool compact;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback onSave;
  final VoidCallback onOpenLog;

  const _AssistantHydrationQuickLogSection({
    required this.amountLiters,
    required this.todayHydrationLiters,
    required this.hasTodayLog,
    required this.isLoading,
    required this.isSaving,
    required this.helperText,
    this.compact = false,
    required this.onAmountChanged,
    required this.onSave,
    required this.onOpenLog,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = hasTodayLog
        ? const Color(0xFF0891B2)
        : const Color(0xFF1FB489);
    final statusLabel = hasTodayLog
        ? '${_formatLiters(todayHydrationLiters)} logged today'
        : todayHydrationLiters > 0
        ? '${_formatLiters(todayHydrationLiters)} waiting for log page'
        : 'No daily check-in yet';

    if (compact) {
      return _buildCompact(context, accent, statusLabel);
    }

    return AnimatedContainer(
      key: const ValueKey('assistant-hydration-quick-log'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.water_drop_rounded, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'Quick water log',
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LocalizedText(
                      isLoading ? 'Checking today...' : statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [0.25, 0.5, 0.75, 1.0].map((amount) {
              final selected = amountLiters == amount;
              return ChoiceChip(
                label: LocalizedText('+${_formatLiters(amount)}'),
                selected: selected,
                onSelected: (_) => onAmountChanged(amount),
                selectedColor: accent.withValues(alpha: 0.18),
                labelStyle: TextStyle(
                  color: selected ? accent : pageSecondaryTextColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              );
            }).toList(),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 10),
            LocalizedText(
              helperText!,
              style: TextStyle(
                color: helperText!.startsWith('Unable')
                    ? const Color(0xFFDC2626)
                    : pageSecondaryTextColor(context),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSaving || isLoading ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: LocalizedText(isSaving ? 'Saving...' : 'Add water'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (!hasTodayLog) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Open daily log'.localizedCopy(context),
                  onPressed: onOpenLog,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context, Color accent, String statusLabel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      key: const ValueKey('assistant-hydration-quick-log'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.water_drop_rounded, color: accent, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'Quick water log',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    LocalizedText(
                      isLoading ? 'Checking today...' : statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 5,
                  runSpacing: 4,
                  children: const [0.25, 0.5, 0.75, 1.0].map((amount) {
                    final selected = amountLiters == amount;
                    return ChoiceChip(
                      label: LocalizedText('+${_formatLiters(amount)}'),
                      selected: selected,
                      onSelected: (_) => onAmountChanged(amount),
                      selectedColor: accent.withValues(alpha: 0.18),
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                      labelStyle: TextStyle(
                        color: selected
                            ? accent
                            : pageSecondaryTextColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 118,
                child: ElevatedButton.icon(
                  onPressed: isSaving || isLoading ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 16),
                  label: LocalizedText(isSaving ? 'Saving...' : 'Add water'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (!hasTodayLog) ...[
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: 'Open daily log'.localizedCopy(context),
                  onPressed: onOpenLog,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                ),
              ],
            ],
          ),
          if (helperText != null) ...[
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: LocalizedText(
                helperText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: helperText!.startsWith('Unable')
                      ? const Color(0xFFDC2626)
                      : pageSecondaryTextColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatLiters(double value) {
    final normalized = value == value.roundToDouble()
        ? value.toInt().toString()
        : value
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
    return '${normalized}L';
  }
}
