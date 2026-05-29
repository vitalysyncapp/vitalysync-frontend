import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../dashboard/data/burnout_score_api.dart';

class BurnoutInfoDialog extends StatelessWidget {
  final int score;
  final String status;
  final BurnoutScoreSnapshot? latestScore;
  final BurnoutPatternSummary? patternSummary;
  final List<Color> accentColors;

  const BurnoutInfoDialog({
    super.key,
    required this.score,
    required this.status,
    required this.latestScore,
    required this.patternSummary,
    required this.accentColors,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 380;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = math.min(620.0, math.max(320.0, screenSize.height - 48));
    final surfaceColor = isDark ? const Color(0xFF102033) : Colors.white;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 22,
        vertical: 24,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border.all(color: pageBorderColor(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, isCompact),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 20,
                      16,
                      isCompact ? 16 : 20,
                      isCompact ? 16 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoSection(
                          icon: Icons.speed_rounded,
                          color: const Color(0xFF2563EB),
                          title: 'What the score means',
                          child: Text(
                            'Your score is $score/100. Higher scores mean stronger burnout-risk signals from recent logs, baseline answers, workload, and recovery patterns.',
                            style: _bodyStyle(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InfoSection(
                          icon: Icons.shield_outlined,
                          color: _riskColor(_riskLevel),
                          title: 'Risk level meaning',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Pill(
                                label: '${_humanize(_riskLevel)} risk',
                                color: _riskColor(_riskLevel),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _riskMeaning(_riskLevel),
                                style: _bodyStyle(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InfoSection(
                          icon: Icons.verified_outlined,
                          color: const Color(0xFF16A34A),
                          title: 'Confidence score',
                          child: _buildConfidence(context),
                        ),
                        const SizedBox(height: 10),
                        _InfoSection(
                          icon: Icons.fact_check_outlined,
                          color: const Color(0xFFF97316),
                          title: 'Missing data',
                          child: _buildMissingData(context),
                        ),
                        const SizedBox(height: 10),
                        _InfoSection(
                          icon: Icons.center_focus_strong_rounded,
                          color: const Color(0xFF7C3AED),
                          title: 'Main contributing factors',
                          child: _buildContributingFactors(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isCompact ? 16 : 20, 16, 8, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: accentColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Burnout score details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.white,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidence(BuildContext context) {
    final scoreSnapshot = latestScore;
    final patternConfidence = patternSummary?.adaptiveState.confidenceScore;
    final confidence = scoreSnapshot?.confidenceScore ?? patternConfidence;

    if (confidence == null || confidence <= 0) {
      return Text(
        'Confidence appears after enough daily data is available. Complete logs make the score easier to trust.',
        style: _bodyStyle(context),
      );
    }

    final completeness = scoreSnapshot?.completenessScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              label: '${confidence.round()}% confidence',
              color: const Color(0xFF16A34A),
            ),
            if (completeness != null)
              _Pill(
                label: '${completeness.round()}% complete',
                color: const Color(0xFF2563EB),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'This reflects how complete the current inputs are. Missing logs lower confidence, so recommendations stay gentler.',
          style: _bodyStyle(context),
        ),
      ],
    );
  }

  Widget _buildMissingData(BuildContext context) {
    final fields = latestScore?.missingFields ?? const <String>[];

    if (fields.isEmpty) {
      return Text(
        latestScore == null
            ? 'No daily burnout score has been generated yet. Complete check-ins to unlock richer details.'
            : 'No missing fields reported for this score.',
        style: _bodyStyle(context),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fields
          .map(
            (field) => _Pill(
              label: _humanize(field),
              color: const Color(0xFFF97316),
              icon: Icons.add_task_rounded,
            ),
          )
          .toList(),
    );
  }

  Widget _buildContributingFactors(BuildContext context) {
    final factors = latestScore?.contributingFactors ?? const [];

    if (factors.isNotEmpty) {
      return Column(
        children: factors.take(4).map((factor) {
          final label = factor.label.trim().isEmpty
              ? _humanize(factor.key)
              : factor.label;

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _FactorRow(label: label, score: factor.score),
          );
        }).toList(),
      );
    }

    final window = patternSummary?.windowForDays(7);
    final pattern = patternSummary?.patterns.isNotEmpty == true
        ? patternSummary!.patterns.first
        : null;
    final fallbackItems = <String>[
      if (window?.dominantDimensionLabel != null)
        '${window!.dominantDimensionLabel!} is the strongest tracked signal.',
      if (pattern != null) pattern.message,
      if (patternSummary?.adaptiveState.reason.trim().isNotEmpty == true)
        patternSummary!.adaptiveState.reason,
    ].where((item) => item.trim().isNotEmpty).toList();

    if (fallbackItems.isEmpty) {
      return Text(
        'Main factors will appear after VitalySync has enough recent score data to compare patterns.',
        style: _bodyStyle(context),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fallbackItems.take(3).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(width: 7),
              Expanded(child: Text(item, style: _bodyStyle(context))),
            ],
          ),
        );
      }).toList(),
    );
  }

  String get _riskLevel {
    final fromSnapshot = latestScore?.riskLevel.trim().toLowerCase();
    if (fromSnapshot != null && fromSnapshot.isNotEmpty) {
      return fromSnapshot;
    }

    final fromBaselineStatus = _riskLevelFromBaselineStatus(status);
    if (fromBaselineStatus != null) {
      return fromBaselineStatus;
    }

    if (score >= 81) return 'critical';
    if (score >= 61) return 'high';
    if (score >= 41) return 'moderate';
    return 'low';
  }

  String? _riskLevelFromBaselineStatus(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.startsWith('very low')) {
      return 'very_low';
    }

    if (normalized.startsWith('low')) {
      return 'low';
    }

    if (normalized.startsWith('moderate')) {
      return 'moderate';
    }

    if (normalized.startsWith('very high')) {
      return 'very_high';
    }

    if (normalized.startsWith('high')) {
      return 'high';
    }

    return null;
  }

  String _riskMeaning(String risk) {
    switch (risk) {
      case 'very_low':
        return 'Baseline signals look very steady. Keep protecting recovery and routine consistency.';
      case 'low':
        return 'Current signals look steady. Keep protecting recovery and routine consistency.';
      case 'moderate':
        return 'Some strain signals are present. Watch sleep, workload, mood, and recovery trends.';
      case 'high':
        return 'Several signals are elevated. Prioritize recovery time, support, and lighter load where possible.';
      case 'very_high':
        return 'Baseline signals are very elevated. Prioritize support, recovery time, and a lighter load where possible.';
      case 'critical':
        return 'Risk signals are very elevated. Treat rest and support as urgent, and consider professional help if distress feels hard to manage.';
      default:
        return 'VitalySync is still collecting enough context to classify this score clearly.';
    }
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'very_low':
        return const Color(0xFF0EA5E9);
      case 'low':
        return const Color(0xFF16A34A);
      case 'moderate':
        return const Color(0xFFCA8A04);
      case 'high':
        return const Color(0xFFF97316);
      case 'very_high':
        return const Color(0xFFEA580C);
      case 'critical':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _titleCase(String value) {
    if (value.isEmpty) return 'Unknown';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _humanize(String value) {
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) => _titleCase(word))
        .join(' ');
  }

  TextStyle _bodyStyle(BuildContext context) {
    return TextStyle(
      color: pageSecondaryTextColor(context),
      fontSize: 12.8,
      height: 1.38,
      fontWeight: FontWeight.w600,
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _InfoSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Pill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final String label;
  final double score;

  const _FactorRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final value = score.clamp(0, 100).toDouble();
    final color = value >= 65
        ? const Color(0xFFDC2626)
        : value >= 45
        ? const Color(0xFFF97316)
        : const Color(0xFF16A34A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value.round().toString(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
