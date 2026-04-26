import 'package:flutter/material.dart';

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
        const SizedBox(height: 12),
        Row(
          children: options.map((option) {
            final selected = value == option.value;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: option.value == options.last.value ? 0 : 8,
                ),
                child: Tooltip(
                  message: '${option.value} - ${option.label}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onChanged(option.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFF5FBF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : pageBorderColor(context),
                        ),
                      ),
                      child: Text(
                        option.value.toString(),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : pagePrimaryTextColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                options.first.label,
                style: TextStyle(
                  fontSize: 12,
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
                  color: pageSecondaryTextColor(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
