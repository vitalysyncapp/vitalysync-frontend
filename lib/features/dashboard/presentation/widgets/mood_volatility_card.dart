import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../data/weekly_user_metrics.dart';

class MoodVolatilityCard extends StatefulWidget {
  const MoodVolatilityCard({super.key});

  @override
  State<MoodVolatilityCard> createState() => _MoodVolatilityCardState();
}

class _MoodVolatilityCardState extends State<MoodVolatilityCard> {
  late Future<WeeklyUserMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = WeeklyUserMetricsService.loadCurrentWeek();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeeklyUserMetrics>(
      future: _future,
      builder: (context, snapshot) {
        final metrics = snapshot.data;
        final days = metrics?.days ?? const <DailyUserMetric>[];
        final progress = ((metrics?.moodIndex ?? 0) / 100).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood Trend',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: Color(0xFF1FB489),
                    size: 28,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'This week',
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Text(
                    metrics?.moodStabilityLabel ?? 'Loading',
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: pageBorderColor(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF11C95D),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: days.map((day) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: pageSubtleSurfaceColor(context),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: pageBorderColor(context)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _moodEmoji(day.moodIndex),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: pagePrimaryTextColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.dayLabel.substring(0, 1),
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _moodEmoji(int? value) {
    switch (value) {
      case 4:
        return '\u{1F60A}';
      case 3:
        return '\u{1F642}';
      case 2:
        return '\u{1F610}';
      case 1:
        return '\u{1F641}';
      case 0:
        return '\u{1F61E}';
      default:
        return '--';
    }
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
