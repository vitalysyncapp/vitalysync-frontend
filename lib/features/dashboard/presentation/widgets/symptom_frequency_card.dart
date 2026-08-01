import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../../data/weekly_user_metrics.dart';
import 'package:vitalysync/l10n/localized_text.dart';

const Color _symptomAccent = Color(0xFF6172E8);
const List<Color> _symptomPalette = [
  Color(0xFF6172E8),
  Color(0xFF1FA68A),
  Color(0xFF8B6FD6),
  Color(0xFF3B8CCB),
];

class SymptomFrequencyCard extends StatelessWidget {
  final WeeklyUserMetrics? metrics;
  final bool isLoading;

  const SymptomFrequencyCard({
    super.key,
    required this.metrics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final counts = metrics?.symptomCounts ?? const <String, int>{};
    final rows = counts.entries.toList()
      ..sort((a, b) {
        final frequencyComparison = b.value.compareTo(a.value);
        if (frequencyComparison != 0) return frequencyComparison;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    final visibleRows = rows.take(4).toList();
    final loggedDays = metrics?.loggedDays ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SymptomCardHeader(),
          const SizedBox(height: 16),
          AnalyticsContentSwitcher(
            isLoading: isLoading,
            loading: const SizedBox(
              height: 232,
              child: AppSkeletonRows(count: 4, showLeading: true),
            ),
            contentKey: Object.hashAll([
              loggedDays,
              ...visibleRows.expand((entry) => [entry.key, entry.value]),
            ]),
            child: visibleRows.isEmpty
                ? _SymptomEmptyState(loggedDays: loggedDays)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopSymptomSummary(entry: visibleRows.first),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: LocalizedText(
                              'Reported days',
                              style: TextStyle(
                                color: pageSecondaryTextColor(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          LocalizedText(
                            '7-day scale',
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(visibleRows.length, (index) {
                        final entry = visibleRows[index];
                        return RevealOnBuild(
                          delay: Duration(milliseconds: 65 * index),
                          duration: const Duration(milliseconds: 360),
                          beginOffset: const Offset(0, 0.08),
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visibleRows.length - 1 ? 0 : 13,
                            ),
                            child: _SymptomFrequencyRow(
                              rank: index + 1,
                              label: entry.key,
                              dayCount: entry.value,
                              color: _symptomPalette[index],
                            ),
                          ),
                        );
                      }),
                      if (rows.length > visibleRows.length) ...[
                        const SizedBox(height: 12),
                        LocalizedText(
                          '+${rows.length - visibleRows.length} more reported ${rows.length - visibleRows.length == 1 ? 'symptom' : 'symptoms'}',
                          style: TextStyle(
                            color: pageSecondaryTextColor(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: pageSurfaceColor(context),
      borderRadius: BorderRadius.circular(18),
      boxShadow: pageCardShadow(context),
      border: Border.all(color: pageBorderColor(context)),
    );
  }
}

class _SymptomCardHeader extends StatelessWidget {
  const _SymptomCardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _symptomAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            color: _symptomAccent,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                'Symptom frequency',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 2),
              LocalizedText(
                'How often symptoms were reported this week',
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopSymptomSummary extends StatelessWidget {
  final MapEntry<String, int> entry;

  const _TopSymptomSummary({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _symptomAccent.withValues(alpha: 0.12),
            _symptomAccent.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _symptomAccent.withValues(alpha: 0.17)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _symptomAccent.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: _symptomAccent,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'Most reported',
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                LocalizedText(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: pageSurfaceColor(context),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _symptomAccent.withValues(alpha: 0.2)),
            ),
            child: LocalizedText(
              '${entry.value} of 7 days',
              style: const TextStyle(
                color: _symptomAccent,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomFrequencyRow extends StatelessWidget {
  final int rank;
  final String label;
  final int dayCount;
  final Color color;

  const _SymptomFrequencyRow({
    required this.rank,
    required this.label,
    required this.dayCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clampedCount = dayCount.clamp(0, 7);
    final dayLabel = clampedCount == 1 ? 'day' : 'days';

    return Semantics(
      key: ValueKey('symptom-frequency-$label'),
      container: true,
      label: '$label reported on $clampedCount of 7 days',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LocalizedText(
                '$rank',
                translate: false,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LocalizedText(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: pagePrimaryTextColor(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      LocalizedText(
                        '$clampedCount $dayLabel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _SevenDayFrequencyBar(
                    label: label,
                    dayCount: clampedCount,
                    color: color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SevenDayFrequencyBar extends StatelessWidget {
  final String label;
  final int dayCount;
  final Color color;

  const _SevenDayFrequencyBar({
    required this.label,
    required this.dayCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      key: ValueKey('symptom-frequency-bar-$label'),
      tween: Tween<double>(begin: 0, end: dayCount.toDouble()),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 680),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Row(
          children: List.generate(7, (index) {
            final fill = (value - index).clamp(0.0, 1.0);
            return Expanded(
              child: Container(
                height: 8,
                margin: EdgeInsets.only(right: index == 6 ? 0 : 3),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    pageBorderColor(context).withValues(alpha: 0.6),
                    color,
                    fill,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SymptomEmptyState extends StatelessWidget {
  final int loggedDays;

  const _SymptomEmptyState({required this.loggedDays});

  @override
  Widget build(BuildContext context) {
    final hasLogs = loggedDays > 0;

    return Container(
      key: const ValueKey('symptom-frequency-empty-state'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 184),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pageSubtleSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (hasLogs ? const Color(0xFF1FA68A) : _symptomAccent)
                  .withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasLogs
                  ? Icons.check_circle_outline_rounded
                  : Icons.edit_calendar_rounded,
              color: hasLogs ? const Color(0xFF1FA68A) : _symptomAccent,
              size: 27,
            ),
          ),
          const SizedBox(height: 11),
          LocalizedText(
            hasLogs ? 'No symptoms reported' : 'No symptom data yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          LocalizedText(
            hasLogs
                ? 'None were selected across your $loggedDays logged ${loggedDays == 1 ? 'day' : 'days'} this week.'
                : 'Add a daily log to start building your weekly view.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
