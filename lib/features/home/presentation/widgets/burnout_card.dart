import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/sensitive_content_guard.dart';
import '../../../dashboard/data/burnout_score_api.dart';
import '../pages/about_burnout_page.dart';
import 'burnout_info_dialog.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class BurnoutCard extends StatelessWidget {
  final int? score;
  final String? sourceLabel;
  final String? riskLevel;
  final String status;
  final bool isLoading;
  final BurnoutScoreSnapshot? latestScore;
  final BurnoutPatternSummary? patternSummary;

  const BurnoutCard({
    super.key,
    required this.score,
    required this.status,
    this.isLoading = false,
    this.sourceLabel,
    this.riskLevel,
    this.latestScore,
    this.patternSummary,
  });

  String get _riskLevel =>
      riskLevel ??
      latestScore?.riskLevel ??
      (score == null
          ? 'unknown'
          : score! < 34
          ? 'low'
          : score! < 60
          ? 'moderate'
          : score! < 80
          ? 'high'
          : 'critical');

  List<Color> _baseGradientColors() => switch (_riskLevel) {
    'very_low' => const [Color(0xFF096EB1), Color(0xFF5DADE2)],
    'low' => const [Color(0xFF5DADE2), Color(0xFF48C9B0)],
    'moderate' => const [
      Color.fromARGB(255, 19, 169, 9),
      Color.fromARGB(255, 134, 203, 49),
    ],
    'high' => const [Color(0xFFD46E14), Color(0xFFF5B041)],
    'very_high' || 'critical' => const [Color(0xFFE74C3C), Color(0xFFDB3710)],
    _ => const [Color(0xFF475569), Color(0xFF64748B)],
  };

  // Adjust gradient and glow for dark mode
  List<Color> getGradientColors(bool isDark) {
    final colors = _baseGradientColors();
    if (isDark) {
      return colors
          .map((color) => Color.lerp(const Color(0xFF071827), color, 0.72)!)
          .toList();
    }
    return colors;
  }

  IconData getIcon() => switch (_riskLevel) {
    'very_low' || 'low' => Icons.sentiment_satisfied_alt_rounded,
    'moderate' => Icons.self_improvement_rounded,
    'high' => Icons.warning_amber_rounded,
    'very_high' || 'critical' => Icons.local_fire_department_rounded,
    _ => Icons.insights_rounded,
  };

  Color getIconColor() => _baseGradientColors().first;

  String getIconLabel() => score == null
      ? 'No estimate yet'
      : '${_riskLevel.replaceAll('_', ' ')} burnout risk';

  Color getGlowColor() => switch (_riskLevel) {
    'very_high' || 'critical' => Colors.redAccent.withValues(alpha: 0.6),
    'high' => Colors.orangeAccent.withValues(alpha: 0.5),
    _ => Colors.transparent,
  };

  void _openAboutBurnout(BuildContext context) {
    final route = MaterialPageRoute<void>(
      builder: (_) => const AboutBurnoutPage(),
    );

    Navigator.of(context).push(route);
  }

  void _showInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BurnoutInfoDialog(
          score: score!,
          status: status,
          latestScore: latestScore,
          patternSummary: patternSummary,
          accentColors: getGradientColors(isDark),
          onLearnMore: () {
            Navigator.of(dialogContext).pop();
            _openAboutBurnout(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = getGradientColors(isDark);
    final glowColor = getGlowColor();
    final textColor = Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: glowColor != Colors.transparent
            ? [
                BoxShadow(
                  color: isDark ? glowColor.withValues(alpha: 0.42) : glowColor,
                  blurRadius: isDark ? 18 : 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: AppSkeleton(
        enabled: isLoading,
        child: SensitiveContentGuard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: LocalizedText(
                      'Burnout Risk estimate',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'About burnout score'.localizedCopy(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 11,
                        color: textColor,
                        onPressed: score == null
                            ? null
                            : () => _showInfoDialog(context),
                        icon: const Icon(Icons.question_mark_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LocalizedText(
                    score == null ? '--' : '$score/100',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Semantics(
                    label: getIconLabel(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ExcludeSemantics(
                        child: Icon(getIcon(), color: getIconColor(), size: 28),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LocalizedText(
                  status,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ),
              if (sourceLabel != null) ...[
                const SizedBox(height: 8),
                LocalizedText(
                  sourceLabel!,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
