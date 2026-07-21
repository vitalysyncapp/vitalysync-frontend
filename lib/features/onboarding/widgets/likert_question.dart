import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_page_style.dart';
import '../models/onboarding_question.dart';

class LikertQuestion extends StatelessWidget {
  final String question;
  final int? value;
  final List<LikertOption> options;
  final ValueChanged<int> onChanged;

  const LikertQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    // Find selected option label for the animated caption.
    final selectedLabel = value != null
        ? options
            .cast<LikertOption?>()
            .firstWhere((o) => o!.value == value, orElse: () => null)
            ?.label
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            height: 1.35,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: pagePrimaryTextColor(context),
          ),
        ),
        const SizedBox(height: 14),

        // Track line behind the buttons to indicate continuous scale.
        Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 24,
              right: 24,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.12),
                      primary.withValues(alpha: 0.25),
                      primary.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: options.map((option) {
                final selected = value == option.value;
                final isLast = option.value == options.last.value;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 6),
                    child: Tooltip(
                      message: '${option.value} – ${option.label}',
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(option.value);
                        },
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          scale: selected ? 1.08 : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(
                                      colors: [
                                        primary,
                                        primary.withValues(alpha: 0.82),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: selected
                                  ? null
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFFF5FBF9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                width: selected ? 1.5 : 1,
                                color: selected
                                    ? primary
                                    : pageBorderColor(context),
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.28),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  option.value.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: selected
                                        ? Colors.white
                                        : pagePrimaryTextColor(context),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Endpoint labels row.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                options.first.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: pageSecondaryTextColor(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                options.last.label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: pageSecondaryTextColor(context),
                ),
              ),
            ),
          ],
        ),

        // Animated caption showing the selected option label.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: selectedLabel != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    child: Container(
                      key: ValueKey(selectedLabel),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            selectedLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
