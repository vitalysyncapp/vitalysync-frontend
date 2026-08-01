import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class WellnessProfileCard extends StatefulWidget {
  final String lifestyleType;
  final String currentRole;
  final String usualSleepTime;
  final String usualWakeTime;
  final String workIntensity;
  final String burnoutLevel;
  final int burnoutScore;
  final double? heightCm;
  final double? weightKg;
  final bool isSaving;
  final bool isSavingBaseline;
  final VoidCallback onEdit;
  final VoidCallback onRetakeBaseline;

  const WellnessProfileCard({
    super.key,
    required this.lifestyleType,
    required this.currentRole,
    required this.usualSleepTime,
    required this.usualWakeTime,
    required this.workIntensity,
    required this.burnoutLevel,
    required this.burnoutScore,
    required this.heightCm,
    required this.weightKg,
    required this.isSaving,
    required this.isSavingBaseline,
    required this.onEdit,
    required this.onRetakeBaseline,
  });

  @override
  State<WellnessProfileCard> createState() => _WellnessProfileCardState();
}

class _WellnessProfileCardState extends State<WellnessProfileCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final primary = pagePrimaryTextColor(context);
    final secondary = pageSecondaryTextColor(context);
    final themePrimary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F6BFF), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'Wellness profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LocalizedText(
                      'Baseline from your profile and onboarding',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _rowItem(
            emoji: '\u{1F33F}',
            icon: Icons.directions_walk_rounded,
            label: 'Lifestyle type',
            value: _sentenceCaseCategory(widget.lifestyleType),
          ),
          if (_isExpanded) ...[
            _rowItem(
              emoji: '\u{1F4BC}',
              icon: Icons.work_outline_rounded,
              label: 'Current role',
              value: _sentenceCaseCategory(widget.currentRole),
            ),
            _rowItem(
              emoji: '\u{1F319}',
              icon: Icons.bedtime_outlined,
              label: 'Usual sleep time',
              value: widget.usualSleepTime,
            ),
            _rowItem(
              emoji: '\u2600\uFE0F',
              icon: Icons.wb_sunny_outlined,
              label: 'Usual wake time',
              value: widget.usualWakeTime,
            ),
            _rowItem(
              emoji: '\u{1F4CF}',
              icon: Icons.height_rounded,
              label: 'Height',
              value: _formatMetric(widget.heightCm, unit: 'cm'),
            ),
            _rowItem(
              emoji: '\u{1F4AA}',
              icon: Icons.monitor_weight_rounded,
              label: 'Weight',
              value: _formatMetric(widget.weightKg, unit: 'kg'),
            ),
            _rowItem(
              emoji: '\u{1F4CA}',
              icon: Icons.calculate_outlined,
              label: 'BMI',
              value: _formatBmi(heightCm: widget.heightCm, weightKg: widget.weightKg),
            ),
            _rowItemWithBadge(
              emoji: '\u26A1',
              label: 'Work intensity',
              value: _sentenceCaseCategory(widget.workIntensity),
            ),
            _rowItem(
              emoji: '\u{1F525}',
              icon: Icons.local_fire_department_outlined,
              label: 'Initial burnout',
              value: '${_sentenceCaseCategory(widget.burnoutLevel)} (${widget.burnoutScore}%)',
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: themePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: themePrimary.withValues(alpha: 0.12)),
              ),
              child: LocalizedText(
                'Your baseline helps VitalySync compare your daily logs with your usual routine.',
                style: TextStyle(height: 1.4, fontSize: 13, color: secondary),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.isSaving ? null : widget.onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const LocalizedText(
                  'Edit wellness profile',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: themePrimary,
                  side: BorderSide(color: pageBorderColor(context)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.isSavingBaseline ? null : widget.onRetakeBaseline,
                icon: widget.isSavingBaseline
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.restart_alt_rounded),
                label: LocalizedText(
                  widget.isSavingBaseline ? 'Saving baseline...' : 'Retake baseline',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color.fromARGB(255, 55, 66, 156)
                      : themePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              label: LocalizedText(
                _isExpanded ? 'Hide' : 'More',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: themePrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowItem({
    required String emoji,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return _WellnessDataRow(
      emoji: emoji,
      icon: icon,
      label: label,
      value: value,
    );
  }

  Widget _rowItemWithBadge({
    required String emoji,
    required String label,
    required String value,
  }) {
    Color badgeColor;
    Color textColor;

    switch (value.toLowerCase()) {
      case 'high':
        badgeColor = const Color(0xFFFFE5D0);
        textColor = const Color(0xFFDC2626);
        break;
      case 'medium':
        badgeColor = const Color(0xFFFFF4CC);
        textColor = const Color(0xFFD97706);
        break;
      default:
        badgeColor = const Color(0xFFE6F4EA);
        textColor = const Color(0xFF16A34A);
    }

    return _WellnessDataRow(
      emoji: emoji,
      icon: Icons.speed_outlined,
      label: label,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: LocalizedText(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

String _sentenceCaseCategory(String value) {
  final text = value.trim();
  if (text.length < 2) return text;
  return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
}

String _formatMetric(double? value, {required String unit}) {
  if (value == null) return 'Not set';
  final formatted = value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
  return '$formatted $unit';
}

String _formatBmi({required double? heightCm, required double? weightKg}) {
  if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
    return 'Not set';
  }

  final heightM = heightCm / 100;
  return (weightKg / (heightM * heightM)).toStringAsFixed(1);
}

class _WellnessDataRow extends StatelessWidget {
  final String emoji;
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  const _WellnessDataRow({
    required this.emoji,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = pagePrimaryTextColor(context);
    final secondary = pageSecondaryTextColor(context);
    final themePrimary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: themePrimary.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: themePrimary),
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: LocalizedText(emoji, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 3),
                LocalizedText(
                  value ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
